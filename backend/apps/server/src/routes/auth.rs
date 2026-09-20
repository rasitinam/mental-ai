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
        .route("/auth/apple", post(login_with_apple))
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

/// The `password_hash` of an account created with Sign in with Apple. It is
/// not a valid Argon2 hash, so `verify_password` rejects every guess against
/// it and `/auth/login` can never be used to get into such an account.
pub(crate) const APPLE_PASSWORD_SENTINEL: &str = "!apple";

/// Inserts the `users` row for a brand-new account with the defaults every
/// sign-up path shares.
async fn create_user(
    state: &AppState,
    user_id: Uuid,
    display_name: String,
    timezone: String,
    language: String,
    now: chrono::DateTime<Utc>,
) -> Result<(), (axum::http::StatusCode, String)> {
    state
        .users
        .upsert(&User {
            id: user_id,
            display_name,
            timezone,
            diagnoses: vec![],
            language,
            birth_year: None,
            is_admin: false,
            avatar_content_type: None,
            dm_policy: mental_domain::DmPolicy::Everyone,
            // Asked during onboarding, right after this — see
            // `routes::profile::set_chat_boundaries`.
            chat_boundaries: vec![],
            chat_boundary_note: None,
            // The column defaults, spelled out: reminder on at 21:00, and
            // Turkey's offset until the app reports the device's real one
            // (see `routes::profile::set_preferences`).
            checkin_reminder_enabled: true,
            checkin_reminder_hour: 21,
            utc_offset_minutes: 180,
            created_at: now,
        })
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))
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

    create_user(
        &state,
        user_id,
        req.display_name.unwrap_or_else(|| "Kullanıcı".to_string()),
        req.timezone.unwrap_or_else(|| "UTC".to_string()),
        req.language.unwrap_or_else(|| "tr".to_string()),
        now,
    )
    .await?;

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

    // Checked before touching the database or Argon2, so a lockout costs
    // an attacker nothing to keep probing against — see
    // `rate_limit::LoginRateLimiter`.
    if !state.login_rate_limiter.allow(&email) {
        return Err((
            axum::http::StatusCode::TOO_MANY_REQUESTS,
            "too many attempts, try again later".to_string(),
        ));
    }

    // A missing account counts as a failed attempt too (not just a wrong
    // password) — otherwise the limiter itself would leak whether an
    // email is registered, by letting non-existent ones probe forever.
    let credentials = match state.auth.find_credentials_by_email(&email).await {
        Ok(Some(c)) => c,
        Ok(None) => {
            state.login_rate_limiter.record_failure(&email);
            return Err((axum::http::StatusCode::UNAUTHORIZED, "incorrect email or password".to_string()));
        }
        Err(e) => return Err((axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string())),
    };

    if !verify_password(&req.password, &credentials.password_hash) {
        state.login_rate_limiter.record_failure(&email);
        return Err((axum::http::StatusCode::UNAUTHORIZED, "incorrect email or password".to_string()));
    }

    state.login_rate_limiter.record_success(&email);

    let session = issue_session(&state, credentials.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(SessionResponse {
        user_id: credentials.user_id,
        token: session.token,
        expires_at: session.expires_at,
    }))
}

#[derive(Debug, Deserialize)]
struct AppleLoginRequest {
    /// The signed JWT Apple issued to the device.
    identity_token: String,
    /// The raw (un-hashed) random value the app generated for this attempt;
    /// its SHA-256 is what Apple embedded in the token.
    nonce: String,
    /// Apple only hands the person's name to the app, and only on the very
    /// first authorization, so the app forwards it for account creation.
    #[serde(default)]
    display_name: Option<String>,
    #[serde(default)]
    timezone: Option<String>,
    #[serde(default)]
    language: Option<String>,
}

#[derive(Debug, Serialize)]
struct AppleSessionResponse {
    user_id: Uuid,
    token: String,
    expires_at: chrono::DateTime<Utc>,
    /// True when this call created the account, so the app routes it into
    /// onboarding exactly like a fresh email registration.
    is_new_account: bool,
}

/// Signs in (or signs up) with a verified Apple identity token. Apple's
/// `sub` is the account key; there is deliberately no automatic linking to
/// an existing email/password account with the same address, because email
/// isn't verified at registration here and linking on it would let someone
/// who pre-registered a victim's address keep access to the victim's
/// Apple-created account.
async fn login_with_apple(
    State(state): State<AppState>,
    Json(req): Json<AppleLoginRequest>,
) -> Result<Json<AppleSessionResponse>, (axum::http::StatusCode, String)> {
    use axum::http::StatusCode;
    let internal = |e: anyhow::Error| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string());

    let identity = state
        .apple_keys
        .verify(&req.identity_token, &state.apple_iap.bundle_id, &req.nonce)
        .await
        .map_err(|e| match e {
            crate::apple_signin::AppleAuthError::InvalidToken(_) => (StatusCode::UNAUTHORIZED, e.to_string()),
            crate::apple_signin::AppleAuthError::KeysUnavailable(_) => (StatusCode::BAD_GATEWAY, e.to_string()),
        })?;

    if let Some(user_id) = state.auth.find_user_by_apple_sub(&identity.subject).await.map_err(internal)? {
        let session = issue_session(&state, user_id).await.map_err(internal)?;
        return Ok(Json(AppleSessionResponse {
            user_id,
            token: session.token,
            expires_at: session.expires_at,
            is_new_account: false,
        }));
    }

    // First time we see this Apple user. Use the address Apple shared (often
    // a private relay one); if there isn't one, make one up from a hash of
    // the `sub` so the credentials row's UNIQUE email column stays satisfied.
    let email = identity
        .email
        .as_deref()
        .map(normalize_email)
        .filter(|e| e.contains('@'))
        .unwrap_or_else(|| format!("apple-{}@apple.hearth.invalid", &crate::apple_signin::sha256_hex(&identity.subject)[..24]));

    if state.auth.find_credentials_by_email(&email).await.map_err(internal)?.is_some() {
        return Err((StatusCode::CONFLICT, "an account with this email already exists".to_string()));
    }

    let user_id = Uuid::new_v4();
    let now = Utc::now();
    let display_name = req
        .display_name
        .map(|n| n.trim().to_string())
        .filter(|n| !n.is_empty())
        .unwrap_or_else(|| "Kullanıcı".to_string());

    create_user(
        &state,
        user_id,
        display_name,
        req.timezone.unwrap_or_else(|| "UTC".to_string()),
        req.language.unwrap_or_else(|| "tr".to_string()),
        now,
    )
    .await?;

    state
        .auth
        .create_credentials(&Credentials {
            user_id,
            email,
            password_hash: APPLE_PASSWORD_SENTINEL.to_string(),
            created_at: now,
        })
        .await
        .map_err(internal)?;
    state.auth.link_apple_identity(&identity.subject, user_id).await.map_err(internal)?;

    let session = issue_session(&state, user_id).await.map_err(internal)?;
    Ok(Json(AppleSessionResponse {
        user_id,
        token: session.token,
        expires_at: session.expires_at,
        is_new_account: true,
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
