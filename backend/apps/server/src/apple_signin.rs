//! Sign in with Apple: verifying the identity token the device hands the app.
//!
//! The client never gets to say "I'm this Apple user" on its own. It sends
//! the signed JWT Apple issued, and this module checks everything that makes
//! that claim trustworthy: the RS256 signature against Apple's published
//! keys, that it was issued by Apple (`iss`) for *this* app (`aud` is the
//! bundle id), that it hasn't expired, and that its `nonce` is the SHA-256 of
//! the random value the client generated for this sign-in attempt, which is
//! what stops a captured token from being replayed against another attempt.

use std::time::{Duration, Instant};

use jsonwebtoken::jwk::JwkSet;
use jsonwebtoken::{decode, decode_header, Algorithm, DecodingKey, Validation};
use serde::Deserialize;
use sha2::{Digest, Sha256};
use tokio::sync::RwLock;

const APPLE_ISSUER: &str = "https://appleid.apple.com";
const APPLE_KEYS_URL: &str = "https://appleid.apple.com/auth/keys";
/// Apple rotates its signing keys rarely; an hour of caching keeps this off
/// the hot path, and an unknown `kid` forces a refresh sooner anyway.
const KEY_CACHE_TTL: Duration = Duration::from_secs(60 * 60);

/// What a verified identity token vouches for.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppleIdentity {
    /// Stable, app-scoped Apple user id. The only claim safe to key an
    /// account on: the email can be a private relay address and Apple only
    /// promises it on the first sign-in.
    pub subject: String,
    pub email: Option<String>,
    pub email_verified: bool,
}

#[derive(Debug)]
pub enum AppleAuthError {
    /// Malformed, forged, expired, wrong audience/issuer, or wrong nonce.
    InvalidToken(String),
    /// Apple's key endpoint couldn't be reached or returned junk.
    KeysUnavailable(String),
}

impl std::fmt::Display for AppleAuthError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidToken(why) => write!(f, "invalid Apple identity token: {why}"),
            Self::KeysUnavailable(why) => write!(f, "could not load Apple's signing keys: {why}"),
        }
    }
}

#[derive(Debug, Deserialize)]
struct RawClaims {
    sub: String,
    #[serde(default)]
    email: Option<String>,
    /// Apple sends this as a bool or as the string "true"/"false",
    /// depending on the flow.
    #[serde(default)]
    email_verified: Option<serde_json::Value>,
    #[serde(default)]
    nonce: Option<String>,
}

fn is_true(value: &Option<serde_json::Value>) -> bool {
    match value {
        Some(serde_json::Value::Bool(b)) => *b,
        Some(serde_json::Value::String(s)) => s == "true",
        _ => false,
    }
}

/// Lowercase hex SHA-256 — the encoding `sign_in_with_apple` documents for
/// the nonce it forwards to Apple.
pub fn sha256_hex(input: &str) -> String {
    Sha256::digest(input.as_bytes()).iter().map(|b| format!("{b:02x}")).collect()
}

/// Verifies `token` against an already-loaded key set. Split out from the
/// network fetch so it can be exercised without Apple.
pub fn verify_with_keys(
    keys: &JwkSet,
    token: &str,
    audience: &str,
    raw_nonce: &str,
) -> Result<AppleIdentity, AppleAuthError> {
    let header = decode_header(token).map_err(|e| AppleAuthError::InvalidToken(e.to_string()))?;
    let kid = header.kid.ok_or_else(|| AppleAuthError::InvalidToken("token has no key id".to_string()))?;
    let jwk = keys
        .find(&kid)
        .ok_or_else(|| AppleAuthError::InvalidToken("token was signed with an unknown key".to_string()))?;
    let key = DecodingKey::from_jwk(jwk).map_err(|e| AppleAuthError::InvalidToken(e.to_string()))?;

    let mut validation = Validation::new(Algorithm::RS256);
    validation.set_audience(&[audience]);
    validation.set_issuer(&[APPLE_ISSUER]);

    let claims = decode::<RawClaims>(token, &key, &validation)
        .map_err(|e| AppleAuthError::InvalidToken(e.to_string()))?
        .claims;

    if claims.nonce.as_deref() != Some(sha256_hex(raw_nonce).as_str()) {
        return Err(AppleAuthError::InvalidToken("nonce does not match".to_string()));
    }

    Ok(AppleIdentity {
        subject: claims.sub,
        email: claims.email,
        email_verified: is_true(&claims.email_verified),
    })
}

/// Apple's signing keys, fetched lazily and cached.
pub struct AppleKeys {
    client: reqwest::Client,
    cached: RwLock<Option<(Instant, JwkSet)>>,
}

impl AppleKeys {
    pub fn new() -> Self {
        Self { client: reqwest::Client::new(), cached: RwLock::new(None) }
    }

    pub async fn verify(
        &self,
        token: &str,
        audience: &str,
        raw_nonce: &str,
    ) -> Result<AppleIdentity, AppleAuthError> {
        let kid = decode_header(token)
            .map_err(|e| AppleAuthError::InvalidToken(e.to_string()))?
            .kid
            .ok_or_else(|| AppleAuthError::InvalidToken("token has no key id".to_string()))?;

        if let Some((fetched_at, keys)) = self.cached.read().await.as_ref() {
            if fetched_at.elapsed() < KEY_CACHE_TTL && keys.find(&kid).is_some() {
                return verify_with_keys(keys, token, audience, raw_nonce);
            }
        }

        let fresh = self.fetch().await?;
        let result = verify_with_keys(&fresh, token, audience, raw_nonce);
        *self.cached.write().await = Some((Instant::now(), fresh));
        result
    }

    async fn fetch(&self) -> Result<JwkSet, AppleAuthError> {
        let response = self
            .client
            .get(APPLE_KEYS_URL)
            .timeout(Duration::from_secs(10))
            .send()
            .await
            .and_then(|r| r.error_for_status())
            .map_err(|e| AppleAuthError::KeysUnavailable(e.to_string()))?;
        response.json::<JwkSet>().await.map_err(|e| AppleAuthError::KeysUnavailable(e.to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nonce_is_lowercase_hex_sha256() {
        // SHA-256("abc"), the standard test vector.
        assert_eq!(
            sha256_hex("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
    }

    #[test]
    fn email_verified_accepts_bool_and_string() {
        assert!(is_true(&Some(serde_json::json!(true))));
        assert!(is_true(&Some(serde_json::json!("true"))));
        assert!(!is_true(&Some(serde_json::json!("false"))));
        assert!(!is_true(&Some(serde_json::json!(false))));
        assert!(!is_true(&None));
    }

    #[test]
    fn garbage_token_is_rejected() {
        let keys = JwkSet { keys: vec![] };
        assert!(matches!(
            verify_with_keys(&keys, "not-a-jwt", "com.example.app", "nonce"),
            Err(AppleAuthError::InvalidToken(_))
        ));
    }
}
