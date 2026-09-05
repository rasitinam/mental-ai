use axum::{extract::State, routing::post, Json, Router};
use chrono::Utc;
use mental_domain::repository::JournalRepository;
use mental_domain::JournalEntry;
use serde::Deserialize;
use uuid::Uuid;

use crate::state::AppState;
use crate::users::ensure_user;

pub fn router() -> Router<AppState> {
    Router::new().route("/journal", post(add_journal_entry))
}

#[derive(Debug, Deserialize)]
struct AddJournalRequest {
    user_id: Uuid,
    body: String,
}

async fn add_journal_entry(
    State(state): State<AppState>,
    Json(req): Json<AddJournalRequest>,
) -> Result<Json<JournalEntry>, (axum::http::StatusCode, String)> {
    ensure_user(&state, req.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let entry = JournalEntry {
        id: Uuid::new_v4(),
        user_id: req.user_id,
        body: req.body,
        detected_themes: None,
        created_at: Utc::now(),
    };

    state
        .journals
        .add(&entry)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(entry))
}
