use axum::{
    extract::State,
    routing::{get, put},
    Json, Router,
};
use mental_domain::catalog;
use mental_domain::repository::{AuthRepository, UserRepository};
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/profile", get(profile))
        .route("/profile/diagnoses", put(set_diagnoses))
        .route("/profile/preferences", put(set_preferences))
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
}

#[derive(Debug, Deserialize)]
struct SetDiagnosesRequest {
    diagnoses: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct SetPreferencesRequest {
    /// Omitted fields keep their stored value — the screen can save a
    /// language change without also resending a birth year.
    #[serde(default)]
    language: Option<String>,
    #[serde(default)]
    birth_year: Option<i32>,
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

/// Interface language and birth year. Both are validated because both end up
/// in prompts: an unsupported language code would silently fall back, and an
/// impossible birth year would hand the model a nonsense age.
async fn set_preferences(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SetPreferencesRequest>,
) -> Result<Json<ProfileResponse>, (axum::http::StatusCode, String)> {
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

    state
        .users
        .set_preferences(auth.user_id, req.language.as_deref(), req.birth_year)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    profile(State(state), auth).await
}
