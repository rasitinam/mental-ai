use argon2::password_hash::rand_core::OsRng;
use argon2::password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString};
use argon2::Argon2;
use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use axum::http::StatusCode;
use chrono::{Duration, Utc};
use mental_domain::repository::AuthRepository;
use mental_domain::Session;
use rand::RngCore;
use uuid::Uuid;

use crate::state::AppState;

/// Sessions are valid for 30 days from issuance; there's no refresh
/// flow, so the client just needs to log in again after that. Long
/// enough that a local-first, single-user wellness app doesn't nag
/// people to re-authenticate, short enough that a leaked token doesn't
/// stay valid forever.
const SESSION_LIFETIME_DAYS: i64 = 30;

pub fn hash_password(password: &str) -> anyhow::Result<String> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|e| anyhow::anyhow!("failed to hash password: {e}"))
}

pub fn verify_password(password: &str, hash: &str) -> bool {
    let Ok(parsed_hash) = PasswordHash::new(hash) else {
        return false;
    };
    Argon2::default().verify_password(password.as_bytes(), &parsed_hash).is_ok()
}

fn generate_token() -> String {
    let mut bytes = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut bytes);
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

/// Issues and persists a new session for `user_id`. Called from both
/// `/auth/register` and `/auth/login` — registering logs you in
/// immediately rather than requiring a separate login call.
pub async fn issue_session(state: &AppState, user_id: Uuid) -> anyhow::Result<Session> {
    let now = Utc::now();
    let session = Session {
        token: generate_token(),
        user_id,
        created_at: now,
        expires_at: now + Duration::days(SESSION_LIFETIME_DAYS),
    };
    state.auth.create_session(&session).await?;
    Ok(session)
}

/// Axum extractor that turns an `Authorization: Bearer <token>` header
/// into a verified `Uuid`. Every handler that touches user-scoped data
/// takes `AuthUser` instead of a client-supplied `user_id` — the whole
/// point of adding real accounts was to stop trusting whatever id a
/// request claims to be.
pub struct AuthUser {
    pub user_id: Uuid,
    pub token: String,
}

#[async_trait::async_trait]
impl FromRequestParts<AppState> for AuthUser {
    type Rejection = (StatusCode, String);

    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, Self::Rejection> {
        let header = parts
            .headers
            .get(axum::http::header::AUTHORIZATION)
            .and_then(|v| v.to_str().ok())
            .ok_or((StatusCode::UNAUTHORIZED, "missing Authorization header".to_string()))?;

        let token = header
            .strip_prefix("Bearer ")
            .ok_or((StatusCode::UNAUTHORIZED, "expected a Bearer token".to_string()))?
            .to_string();

        let session = state
            .auth
            .find_session(&token)
            .await
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
            .ok_or((StatusCode::UNAUTHORIZED, "invalid or expired session".to_string()))?;

        if session.expires_at < Utc::now() {
            return Err((StatusCode::UNAUTHORIZED, "session expired".to_string()));
        }

        Ok(AuthUser { user_id: session.user_id, token })
    }
}
