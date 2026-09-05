use axum::{extract::State, routing::post, Json, Router};
use chrono::{Duration, Utc};
use mental_analysis_engine::generate_chat_reply;
use mental_domain::repository::{JournalRepository, MoodRepository};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::state::AppState;
use crate::users::ensure_user;

pub fn router() -> Router<AppState> {
    Router::new().route("/chat", post(send_message))
}

#[derive(Debug, Deserialize)]
struct ChatTurnRequest {
    user_id: Uuid,
    message: String,
}

#[derive(Debug, Serialize)]
struct ChatTurnResponse {
    reply: String,
    crisis_flag: bool,
}

/// Single-turn chat with the wellness companion, personalized with the
/// last few days of the user's own mood/journal history and grounded
/// with research relevant to their message — see
/// `mental_analysis_engine::generate_chat_reply`. Deliberately stateless
/// at the *conversation* layer (no server-side message history yet): the
/// Flutter app keeps the visible transcript, and personalization instead
/// comes from the user's mood/journal data, not from replaying prior
/// chat turns.
async fn send_message(
    State(state): State<AppState>,
    Json(req): Json<ChatTurnRequest>,
) -> Result<Json<ChatTurnResponse>, (axum::http::StatusCode, String)> {
    ensure_user(&state, req.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let now = Utc::now();
    let since = now - Duration::days(3);

    let recent_moods = state
        .moods
        .list_between(req.user_id, since, now)
        .await
        .unwrap_or_default();
    let recent_journal_entries = state
        .journals
        .list_between(req.user_id, since, now)
        .await
        .unwrap_or_default();

    let result = generate_chat_reply(
        &req.message,
        &recent_moods,
        &recent_journal_entries,
        state.llm.as_ref(),
        state.vector_store.as_ref(),
        state.embedder.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()))?;

    Ok(Json(ChatTurnResponse { reply: result.reply, crisis_flag: result.crisis_flag }))
}
