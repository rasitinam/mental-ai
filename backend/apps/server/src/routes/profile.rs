use axum::{
    extract::State,
    routing::{get, put},
    Json, Router,
};
use mental_domain::catalog;
use mental_domain::repository::UserRepository;
use mental_domain::User;
use serde::Deserialize;

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/profile", get(profile))
        .route("/profile/diagnoses", put(set_diagnoses))
}

#[derive(Debug, Deserialize)]
struct SetDiagnosesRequest {
    diagnoses: Vec<String>,
}

async fn profile(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<User>, (axum::http::StatusCode, String)> {
    let user = state
        .users
        .get(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((axum::http::StatusCode::NOT_FOUND, "user not found".to_string()))?;

    Ok(Json(user))
}

/// Replaces the self-reported diagnosis list. Slugs are validated against the
/// catalog: an unknown slug would be dead weight in the profile and would
/// silently do nothing when reports and chat read it back for context.
async fn set_diagnoses(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SetDiagnosesRequest>,
) -> Result<Json<User>, (axum::http::StatusCode, String)> {
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
