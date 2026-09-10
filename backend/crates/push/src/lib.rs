//! Sends push notifications via Firebase Cloud Messaging's HTTP v1 API.
//!
//! Authentication is a service account, not the legacy per-project "server
//! key" — Google's newer, more restrictive credential type. The flow is
//! standard OAuth2 JWT-bearer: sign a short-lived JWT with the service
//! account's private key, exchange it at Google's token endpoint for an
//! access token, then send with that as a bearer token. The access token
//! is cached and reused until shortly before it expires (normally an
//! hour), so a burst of notifications costs one token exchange, not one
//! per message.
//!
//! Every call site depends on [`PushProvider`], not [`FcmProvider`]
//! directly, the same shape as `mental_llm_connector::LlmProvider` — swap
//! providers (or fake one in a test) by changing what's constructed at the
//! composition root, not by touching callers.

mod error;

use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};

use async_trait::async_trait;
pub use error::PushError;
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

/// One notification to deliver to one device.
#[derive(Debug, Clone)]
pub struct PushRequest {
    /// The device's FCM registration token.
    pub token: String,
    pub title: String,
    pub body: String,
    /// Extra fields the client reads to decide what to do when the
    /// notification is tapped (e.g. `{"thread_id": "..."}` to deep-link
    /// straight into a DM thread) — never shown to the person, just data.
    pub data: HashMap<String, String>,
}

#[async_trait]
pub trait PushProvider: Send + Sync {
    async fn send(&self, request: PushRequest) -> Result<(), PushError>;
}

#[derive(Debug, Deserialize)]
struct ServiceAccountFile {
    project_id: String,
    private_key: String,
    client_email: String,
    token_uri: String,
}

#[derive(Debug, Serialize)]
struct Claims {
    iss: String,
    scope: &'static str,
    aud: String,
    iat: i64,
    exp: i64,
}

#[derive(Debug, Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: i64,
}

struct CachedToken {
    access_token: String,
    /// When to stop trusting this token and fetch a new one — set a
    /// couple of minutes before Google's own expiry so a request never
    /// races a token that's about to be rejected.
    valid_until: Instant,
}

pub struct FcmProvider {
    project_id: String,
    client_email: String,
    private_key_pem: String,
    token_uri: String,
    http: reqwest::Client,
    cached_token: RwLock<Option<CachedToken>>,
}

impl FcmProvider {
    /// Loads a Firebase service account JSON key (the file Firebase
    /// Console's "Generate new private key" produces). Never committed —
    /// see `.gitignore` — since it grants the ability to send push
    /// notifications as this project to any registered device.
    pub fn from_service_account_file(path: &str) -> Result<Self, PushError> {
        let raw = std::fs::read_to_string(path)
            .map_err(|e| PushError::NotConfigured(format!("{path}: {e}")))?;
        let account: ServiceAccountFile = serde_json::from_str(&raw)
            .map_err(|e| PushError::NotConfigured(format!("{path}: {e}")))?;

        Ok(Self {
            project_id: account.project_id,
            client_email: account.client_email,
            private_key_pem: account.private_key,
            token_uri: account.token_uri,
            http: reqwest::Client::new(),
            cached_token: RwLock::new(None),
        })
    }

    async fn access_token(&self) -> Result<String, PushError> {
        {
            let cached = self.cached_token.read().await;
            if let Some(token) = cached.as_ref() {
                if token.valid_until > Instant::now() {
                    return Ok(token.access_token.clone());
                }
            }
        }

        let now = chrono::Utc::now().timestamp();
        let claims = Claims {
            iss: self.client_email.clone(),
            scope: "https://www.googleapis.com/auth/firebase.messaging",
            aud: self.token_uri.clone(),
            iat: now,
            exp: now + 3600,
        };
        let key = jsonwebtoken::EncodingKey::from_rsa_pem(self.private_key_pem.as_bytes())?;
        let jwt = jsonwebtoken::encode(
            &jsonwebtoken::Header::new(jsonwebtoken::Algorithm::RS256),
            &claims,
            &key,
        )?;

        let response = self
            .http
            .post(&self.token_uri)
            .form(&[
                ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                ("assertion", &jwt),
            ])
            .send()
            .await?;

        if !response.status().is_success() {
            let body = response.text().await.unwrap_or_default();
            return Err(PushError::TokenExchange(body));
        }

        let parsed: TokenResponse = response.json().await?;
        let valid_until = Instant::now() + Duration::from_secs((parsed.expires_in - 120).max(0) as u64);
        *self.cached_token.write().await =
            Some(CachedToken { access_token: parsed.access_token.clone(), valid_until });

        Ok(parsed.access_token)
    }
}

#[async_trait]
impl PushProvider for FcmProvider {
    async fn send(&self, request: PushRequest) -> Result<(), PushError> {
        let access_token = self.access_token().await?;
        let url = format!(
            "https://fcm.googleapis.com/v1/projects/{}/messages:send",
            self.project_id
        );

        let body = serde_json::json!({
            "message": {
                "token": request.token,
                "notification": {
                    "title": request.title,
                    "body": request.body,
                },
                "data": request.data,
                // Android-specific: a stable channel id the client
                // declares (see `push_service.dart`), and normal priority
                // so this behaves like any other messaging app rather
                // than waking the device aggressively.
                "android": {
                    "priority": "high",
                    "notification": { "channel_id": "mental_ai_messages" },
                },
            }
        });

        let response = self
            .http
            .post(&url)
            .bearer_auth(access_token)
            .json(&body)
            .send()
            .await?;

        if !response.status().is_success() {
            let text = response.text().await.unwrap_or_default();
            return Err(PushError::Rejected(text));
        }

        Ok(())
    }
}

/// A provider that does nothing — used when no service account file is
/// configured, so the rest of the app doesn't need an `Option<Arc<dyn
/// PushProvider>>` at every call site. Every `send()` logs and returns
/// `Ok`, matching "no notification sent" without turning a missing
/// optional feature into a hard error for the caller.
pub struct NoopPushProvider;

#[async_trait]
impl PushProvider for NoopPushProvider {
    async fn send(&self, request: PushRequest) -> Result<(), PushError> {
        tracing::debug!(token = %request.token, "push not configured; dropping notification");
        Ok(())
    }
}

/// Builds the configured provider: a real FCM client if
/// `firebase-service-account.json` exists at `path`, a no-op one (with a
/// one-time warning) otherwise.
pub fn build_provider(path: &str) -> Arc<dyn PushProvider> {
    if !std::path::Path::new(path).exists() {
        tracing::warn!(
            path,
            "no Firebase service account file found; push notifications are disabled"
        );
        return Arc::new(NoopPushProvider);
    }

    match FcmProvider::from_service_account_file(path) {
        Ok(provider) => Arc::new(provider),
        Err(err) => {
            tracing::warn!(error = %err, "failed to load push credentials; push notifications are disabled");
            Arc::new(NoopPushProvider)
        }
    }
}
