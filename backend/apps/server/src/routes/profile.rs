use axum::extract::DefaultBodyLimit;
use axum::response::{IntoResponse, Response};
use axum::{
    extract::{Multipart, State},
    http::{header, StatusCode},
    routing::{delete, get, put},
    Json, Router,
};
use chrono::Utc;
use mental_domain::catalog;
use mental_domain::repository::{AuthRepository, PushTokenRepository, UserRepository};
use mental_domain::{DmPolicy, PushToken};
use serde::{Deserialize, Serialize};

use crate::auth::{verify_password, AuthUser};
use crate::state::AppState;

/// Where uploaded avatar images live — one file per user, named by id, no
/// extension (the `avatar_content_type` DB column is what says how to
/// serve it back). Relative, like `database.url`'s `sqlite://data/...`, so
/// it lands next to the database rather than needing its own config entry.
const AVATAR_DIR: &str = "data/avatars";
const MAX_AVATAR_BYTES: usize = 5 * 1024 * 1024;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/profile", get(profile))
        .route("/profile/diagnoses", put(set_diagnoses))
        .route("/profile/preferences", put(set_preferences))
        .route("/profile/avatar", put(upload_avatar).get(get_avatar))
        .layer(DefaultBodyLimit::max(MAX_AVATAR_BYTES + 1024))
        .route("/profile/push-token", put(register_push_token).delete(unregister_push_token))
        .route("/account", delete(delete_account))
}

/// The account as the profile screen needs it. `email` lives in the
/// credentials table rather than on `User`, and `age` is derived, so this is
/// a response shape of its own instead of the domain struct.
#[derive(Debug, Serialize)]
struct ProfileResponse {
    id: String,
    display_name: String,
    email: Option<String>,
    language: String,
    birth_year: Option<i32>,
    age: Option<i32>,
    diagnoses: Vec<String>,
    timezone: String,
    is_admin: bool,
    has_avatar: bool,
    dm_policy: String,
}

#[derive(Debug, Deserialize)]
struct SetDiagnosesRequest {
    diagnoses: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct SetPreferencesRequest {
    /// Omitted fields keep their stored value — the screen can save a
    /// language change without also resending a birth year or a name.
    #[serde(default)]
    display_name: Option<String>,
    #[serde(default)]
    language: Option<String>,
    #[serde(default)]
    birth_year: Option<i32>,
    /// "everyone" | "following" — who may open a DM request.
    #[serde(default)]
    dm_policy: Option<String>,
}

async fn profile(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<ProfileResponse>, (axum::http::StatusCode, String)> {
    let user = state
        .users
        .get(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((axum::http::StatusCode::NOT_FOUND, "user not found".to_string()))?;

    // A missing email shouldn't fail the whole screen — it only means the
    // address can't be shown back.
    let email = state.auth.find_email_for_user(auth.user_id).await.ok().flatten();

    Ok(Json(ProfileResponse {
        id: user.id.to_string(),
        display_name: user.display_name.clone(),
        email,
        language: user.language.clone(),
        birth_year: user.birth_year,
        age: user.age(),
        diagnoses: user.diagnoses.clone(),
        timezone: user.timezone.clone(),
        is_admin: user.is_admin,
        has_avatar: user.avatar_content_type.is_some(),
        dm_policy: user.dm_policy.as_str().to_string(),
    }))
}

/// Replaces the self-reported diagnosis list. Slugs are validated against the
/// catalog: an unknown slug would be dead weight in the profile and would
/// silently do nothing when reports and chat read it back for context.
async fn set_diagnoses(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SetDiagnosesRequest>,
) -> Result<Json<ProfileResponse>, (axum::http::StatusCode, String)> {
    if let Some(unknown) = req.diagnoses.iter().find(|slug| catalog::disorder(slug).is_none()) {
        return Err((
            axum::http::StatusCode::BAD_REQUEST,
            format!("unknown diagnosis slug: {unknown}"),
        ));
    }

    state
        .users
        .set_diagnoses(auth.user_id, &req.diagnoses)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    profile(State(state), auth).await
}

/// Display name, interface language and birth year. All three are
/// validated because all three end up in prompts: a blank name would
/// resurrect the "no name given" placeholder logic (`PersonContext`)
/// under a name that only looks meaningful, an unsupported language code
/// would silently fall back, and an impossible birth year would hand the
/// model a nonsense age.
async fn set_preferences(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SetPreferencesRequest>,
) -> Result<Json<ProfileResponse>, (axum::http::StatusCode, String)> {
    let display_name = match req.display_name.as_deref().map(str::trim) {
        Some("") => return Err((axum::http::StatusCode::BAD_REQUEST, "name can't be empty".to_string())),
        other => other,
    };

    if let Some(language) = req.language.as_deref() {
        if !matches!(language, "tr" | "en") {
            return Err((
                axum::http::StatusCode::BAD_REQUEST,
                format!("unsupported language: {language}"),
            ));
        }
    }

    if let Some(year) = req.birth_year {
        let this_year = chrono::Utc::now().format("%Y").to_string().parse::<i32>().unwrap_or(2026);
        if year < this_year - 120 || year > this_year {
            return Err((
                axum::http::StatusCode::BAD_REQUEST,
                format!("birth year out of range: {year}"),
            ));
        }
    }

    let dm_policy = match req.dm_policy.as_deref() {
        None => None,
        Some("everyone") => Some(DmPolicy::Everyone),
        Some("following") => Some(DmPolicy::Following),
        Some(other) => {
            return Err((StatusCode::BAD_REQUEST, format!("unsupported dm policy: {other}")))
        }
    };

    state
        .users
        .set_preferences(
            auth.user_id,
            display_name,
            req.language.as_deref(),
            req.birth_year,
            dm_policy,
        )
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    profile(State(state), auth).await
}

/// Replaces the profile photo. Takes the first (and only expected) field of
/// a multipart body, whatever its field name — the client only ever sends
/// one file — and writes it to `data/avatars/<user_id>`, overwriting
/// whatever was there before.
async fn upload_avatar(
    State(state): State<AppState>,
    auth: AuthUser,
    mut multipart: Multipart,
) -> Result<Json<ProfileResponse>, (StatusCode, String)> {
    let field = multipart
        .next_field()
        .await
        .map_err(|e| (StatusCode::BAD_REQUEST, e.to_string()))?
        .ok_or((StatusCode::BAD_REQUEST, "missing file part".to_string()))?;

    let content_type = field
        .content_type()
        .map(str::to_string)
        .ok_or((StatusCode::BAD_REQUEST, "missing content type".to_string()))?;
    if !matches!(content_type.as_str(), "image/jpeg" | "image/png" | "image/webp") {
        return Err((StatusCode::BAD_REQUEST, format!("unsupported image type: {content_type}")));
    }

    let bytes = field.bytes().await.map_err(|e| (StatusCode::BAD_REQUEST, e.to_string()))?;
    if bytes.len() > MAX_AVATAR_BYTES {
        return Err((StatusCode::BAD_REQUEST, "image too large".to_string()));
    }
    // The multipart `Content-Type` is whatever the client claims, not a
    // verified fact — trusting it alone would let someone upload
    // arbitrary bytes (an HTML/SVG payload, say) labeled as an image and
    // have it served back under that label. Checking the file's own
    // magic bytes against the declared type closes that off regardless
    // of whether a viewer's browser ever MIME-sniffs the response.
    if sniff_image_type(&bytes) != Some(content_type.as_str()) {
        return Err((
            StatusCode::BAD_REQUEST,
            "file content does not match the declared image type".to_string(),
        ));
    }

    tokio::fs::create_dir_all(AVATAR_DIR)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    tokio::fs::write(avatar_path(auth.user_id), &bytes)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state
        .users
        .set_avatar(auth.user_id, Some(&content_type))
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    profile(State(state), auth).await
}

/// The signed-in user's own avatar — there's no route for anyone else's:
/// nothing in the app shows another user's photo, so there's nothing to
/// gate beyond "you can see your own".
async fn get_avatar(State(state): State<AppState>, auth: AuthUser) -> Result<Response, (StatusCode, String)> {
    let user = state
        .users
        .get(auth.user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "user not found".to_string()))?;
    let content_type = user.avatar_content_type.ok_or((StatusCode::NOT_FOUND, "no avatar set".to_string()))?;

    let bytes = tokio::fs::read(avatar_path(auth.user_id))
        .await
        .map_err(|_| (StatusCode::NOT_FOUND, "avatar file missing".to_string()))?;

    Ok(([(header::CONTENT_TYPE, content_type)], bytes).into_response())
}

pub(crate) fn avatar_path(user_id: uuid::Uuid) -> std::path::PathBuf {
    std::path::Path::new(AVATAR_DIR).join(user_id.to_string())
}

/// Identifies a file by its own magic bytes rather than trusting a
/// caller-supplied label — see `upload_avatar`. Only the three types the
/// upload endpoint accepts are recognized; anything else (including a
/// well-formed image type not in that allowlist) returns `None`.
fn sniff_image_type(bytes: &[u8]) -> Option<&'static str> {
    if bytes.starts_with(&[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
        return Some("image/png");
    }
    if bytes.starts_with(&[0xFF, 0xD8, 0xFF]) {
        return Some("image/jpeg");
    }
    if bytes.len() >= 12 && &bytes[0..4] == b"RIFF" && &bytes[8..12] == b"WEBP" {
        return Some("image/webp");
    }
    None
}

#[derive(Debug, Deserialize)]
struct PushTokenRequest {
    token: String,
    /// "android" or "ios" — informational; see `PushToken`.
    platform: String,
}

/// Registers (or re-registers, on token refresh) this device for push
/// notifications. Upserts by token, so calling it again with the same
/// token from a different account reassigns the device rather than
/// creating a duplicate row — the natural outcome of someone logging out
/// of one account and into another on the same phone.
async fn register_push_token(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<PushTokenRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let now = Utc::now();
    state
        .push_tokens
        .register(&PushToken {
            token: req.token,
            user_id: auth.user_id,
            platform: req.platform,
            created_at: now,
            updated_at: now,
        })
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

#[derive(Debug, Deserialize)]
struct UnregisterPushTokenRequest {
    token: String,
}

/// Called on logout: a device that's signed out shouldn't keep receiving
/// notifications for the account it just left.
async fn unregister_push_token(
    State(state): State<AppState>,
    _auth: AuthUser,
    Json(req): Json<UnregisterPushTokenRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    state
        .push_tokens
        .unregister(&req.token)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

#[derive(Debug, Deserialize)]
struct DeleteAccountRequest {
    /// Re-confirms it's really the account holder — a bearer token alone
    /// (which could be a session left open on a shared or stolen device)
    /// isn't enough to authorize something this irreversible.
    password: String,
}

/// Permanently deletes the signed-in account and everything it owns.
/// Required for App Store review (Guideline 5.1.1(v): an app that lets
/// someone create an account must also let them delete it from inside the
/// app, not just by emailing support).
async fn delete_account(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<DeleteAccountRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    let email = state
        .auth
        .find_email_for_user(auth.user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "account not found".to_string()))?;

    let credentials = state
        .auth
        .find_credentials_by_email(&email)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "account not found".to_string()))?;

    if !verify_password(&req.password, &credentials.password_hash) {
        return Err((StatusCode::UNAUTHORIZED, "incorrect password".to_string()));
    }

    // Best-effort: a missing or unremovable avatar file shouldn't block
    // deleting the account itself, which is the part that actually matters.
    let _ = tokio::fs::remove_file(avatar_path(auth.user_id)).await;

    state
        .users
        .delete_account(auth.user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}
