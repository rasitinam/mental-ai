use axum::{extract::State, routing::post, Json, Router};
use chrono::Utc;
use mental_domain::repository::{AuthRepository, UserRepository};
use mental_domain::{Credentials, User};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::{hash_password, issue_session, verify_password, AuthUser};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/auth/register", post(register))
        .route("/auth/login", post(login))
        .route("/auth/logout", post(logout))
}

#[derive(Debug, Deserialize)]
struct RegisterRequest {
    email: String,
    password: String,
    #[serde(default)]
    display_name: Option<String>,
    #[serde(default)]
    timezone: Option<String>,
    /// The language the app was showing at sign-up, so a new account's very
    /// first generated report comes back in it rather than in the default.
    #[serde(default)]
    language: Option<String>,
}

#[derive(Debug, Deserialize)]
struct LoginRequest {
    email: String,
    password: String,
}

#[derive(Debug, Serialize)]
struct SessionResponse {
    user_id: Uuid,
    token: String,
    expires_at: chrono::DateTime<Utc>,
}

fn normalize_email(email: &str) -> String {
    email.trim().to_lowercase()
}

/// Creates a new account and logs it in immediately (returns a session
/// token in the same response) — there's no separate "verify your
/// email" step in v1, so register and login-after-register would
/// otherwise be two round trips for no benefit.
async fn register(
    State(state): State<AppState>,
    Json(req): Json<RegisterRequest>,
) -> Result<Json<SessionResponse>, (axum::http::StatusCode, String)> {
    let email = normalize_email(&req.email);
    if !email.contains('@') || email.len() < 3 {
        return Err((axum::http::StatusCode::BAD_REQUEST, "enter a valid email address".to_string()));
    }
    if req.password.len() < 8 {
        return Err((
            axum::http::StatusCode::BAD_REQUEST,
            "password must be at least 8 characters".to_string(),
        ));
    }

    let existing = state
        .auth
        .find_credentials_by_email(&email)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    if existing.is_some() {
        return Err((axum::http::StatusCode::CONFLICT, "an account with this email already exists".to_string()));
    }

    let user_id = Uuid::new_v4();
    let now = Utc::now();

    state
        .users
        .upsert(&User {
            id: user_id,
            display_name: req.display_name.unwrap_or_else(|| "Kullanıcı".to_string()),
            timezone: req.timezone.unwrap_or_else(|| "UTC".to_string()),
            diagnoses: vec![],
            language: req.language.unwrap_or_else(|| "tr".to_string()),
            birth_year: None,
            created_at: now,
        })
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let password_hash = hash_password(&req.password)
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state
        .auth
        .create_credentials(&Credentials { user_id, email, password_hash, created_at: now })
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let session = issue_session(&state, user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(SessionResponse {
        user_id,
        token: session.token,
        expires_at: session.expires_at,
    }))
}

async fn login(
    State(state): State<AppState>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<SessionResponse>, (axum::http::StatusCode, String)> {
    let email = normalize_email(&req.email);

    let credentials = state
        .auth
        .find_credentials_by_email(&email)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((axum::http::StatusCode::UNAUTHORIZED, "incorrect email or password".to_string()))?;

    if !verify_password(&req.password, &credentials.password_hash) {
        return Err((axum::http::StatusCode::UNAUTHORIZED, "incorrect email or password".to_string()));
    }

    let session = issue_session(&state, credentials.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(SessionResponse {
        user_id: credentials.user_id,
        token: session.token,
        expires_at: session.expires_at,
    }))
}

async fn logout(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<axum::http::StatusCode, (axum::http::StatusCode, String)> {
    state
        .auth
        .delete_session(&auth.token)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(axum::http::StatusCode::NO_CONTENT)
}
