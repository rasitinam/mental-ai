use axum::response::{IntoResponse, Response};
use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Duration, Utc};
use mental_domain::repository::JournalRepository;
use mental_domain::JournalEntry;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/journal", post(add_journal_entry).get(list_journal))
        .route("/journal/latest", get(latest_journal))
}

/// One entry per day, same reasoning as the mood check-in: "günlük" means a
/// daily record, and enforcing it server-side keeps it true regardless of
/// what the client does.
const COOLDOWN: Duration = Duration::hours(24);

#[derive(Debug, Deserialize)]
struct AddJournalRequest {
    body: String,
}

#[derive(Debug, Serialize)]
struct CooldownError {
    error: &'static str,
    retry_after: DateTime<Utc>,
}

async fn add_journal_entry(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<AddJournalRequest>,
) -> Result<Json<JournalEntry>, Response> {
    let previous = state
        .journals
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response())?;

    if let Some(previous) = previous {
        let retry_after = previous.created_at + COOLDOWN;
        if retry_after > Utc::now() {
            let body = CooldownError {
                error: "Bugünkü günlüğünü zaten yazdın. Yarın tekrar dene.",
                retry_after,
            };
            return Err((axum::http::StatusCode::TOO_MANY_REQUESTS, Json(body)).into_response());
        }
    }

    let entry = JournalEntry {
        id: Uuid::new_v4(),
        user_id: auth.user_id,
        body: req.body,
        detected_themes: None,
        created_at: Utc::now(),
    };

    state
        .journals
        .add(&entry)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response())?;

    Ok(Json(entry))
}

/// The whole archive, newest first, so the app can show past entries by date.
async fn list_journal(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<JournalEntry>>, (axum::http::StatusCode, String)> {
    let entries = state
        .journals
        .list_all(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(entries))
}

async fn latest_journal(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<JournalEntry>>, (axum::http::StatusCode, String)> {
    let entry = state
        .journals
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(entry))
}
