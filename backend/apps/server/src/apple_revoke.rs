//! Revoking this app's Sign in with Apple access when an account is
//! deleted (App Store guideline 5.1.1(v)): Apple wants the user's tokens
//! revoked through its REST API, so the app disappears from "Apps Using
//! Apple ID" and a new sign-up starts fresh.
//!
//! The delete-account flow already makes the person sign in with Apple
//! again; that fresh authorization carries a one-time `authorization_code`.
//! It is exchanged for a refresh token here and the refresh token revoked
//! right away — so no Apple tokens are ever stored.
//!
//! Needs a "Sign in with Apple" key from the Apple Developer account:
//! `MENTAL_AI_APPLE_TEAM_ID`, `MENTAL_AI_APPLE_SIWA_KEY_ID`, and
//! `MENTAL_AI_APPLE_SIWA_KEY_PATH` (the downloaded `.p8`). Without them
//! revocation is skipped with a warning; deleting the account still works.

use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{bail, Context};
use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use serde::Serialize;

const APPLE_AUDIENCE: &str = "https://appleid.apple.com";
const TOKEN_URL: &str = "https://appleid.apple.com/auth/token";
const REVOKE_URL: &str = "https://appleid.apple.com/auth/revoke";

struct SiwaKey {
    team_id: String,
    key_id: String,
    pem: Vec<u8>,
}

fn key_from_env() -> anyhow::Result<Option<SiwaKey>> {
    let (Ok(team_id), Ok(key_id), Ok(path)) = (
        std::env::var("MENTAL_AI_APPLE_TEAM_ID"),
        std::env::var("MENTAL_AI_APPLE_SIWA_KEY_ID"),
        std::env::var("MENTAL_AI_APPLE_SIWA_KEY_PATH"),
    ) else {
        return Ok(None);
    };
    let pem = std::fs::read(&path).with_context(|| format!("reading Sign in with Apple key {path}"))?;
    Ok(Some(SiwaKey { team_id, key_id, pem }))
}

#[derive(Serialize)]
struct ClientSecretClaims<'a> {
    iss: &'a str,
    iat: u64,
    exp: u64,
    aud: &'a str,
    sub: &'a str,
}

/// The short-lived ES256 JWT Apple takes in place of a client secret.
fn client_secret(key: &SiwaKey, client_id: &str) -> anyhow::Result<String> {
    let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
    let mut header = Header::new(Algorithm::ES256);
    header.kid = Some(key.key_id.clone());
    let claims = ClientSecretClaims { iss: &key.team_id, iat: now, exp: now + 300, aud: APPLE_AUDIENCE, sub: client_id };
    Ok(encode(&header, &claims, &EncodingKey::from_ec_pem(&key.pem)?)?)
}

/// Exchanges `authorization_code` and revokes the resulting refresh token.
/// Returns `Ok(false)` when no key is configured (nothing was attempted).
pub async fn revoke_with_code(client_id: &str, authorization_code: &str) -> anyhow::Result<bool> {
    let Some(key) = key_from_env()? else {
        return Ok(false);
    };
    let secret = client_secret(&key, client_id)?;
    let http = reqwest::Client::new();

    let token: serde_json::Value = http
        .post(TOKEN_URL)
        .form(&[
            ("client_id", client_id),
            ("client_secret", secret.as_str()),
            ("code", authorization_code),
            ("grant_type", "authorization_code"),
        ])
        .send()
        .await?
        .error_for_status()
        .context("exchanging the Apple authorization code")?
        .json()
        .await?;

    // A refresh token is what Apple asks to be revoked; fall back to the
    // access token if it ever comes back without one.
    let (value, hint) = match (token["refresh_token"].as_str(), token["access_token"].as_str()) {
        (Some(refresh), _) => (refresh, "refresh_token"),
        (None, Some(access)) => (access, "access_token"),
        _ => bail!("Apple returned no token to revoke"),
    };

    http.post(REVOKE_URL)
        .form(&[
            ("client_id", client_id),
            ("client_secret", secret.as_str()),
            ("token", value),
            ("token_type_hint", hint),
        ])
        .send()
        .await?
        .error_for_status()
        .context("revoking the Apple token")?;

    Ok(true)
}
