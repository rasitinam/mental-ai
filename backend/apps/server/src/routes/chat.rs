use axum::{extract::State, routing::post, Json, Router};
use chrono::{Duration, Utc};
use mental_analysis_engine::generate_chat_reply;
use mental_domain::repository::{JournalRepository, MoodRepository};
use mental_llm_connector::ChatMessage;
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/chat", post(send_message))
}

#[derive(Debug, Deserialize)]
struct ChatTurnRequest {
    message: String,
    /// The visible transcript so far, oldest first, NOT including
    /// `message`. `mental_llm_connector::Role` deserializes from
    /// "user"/"assistant" (matches `ChatSender` on the Flutter side), so
    /// the client can send its own message list close to as-is — see
    /// `ChatApi.sendMessage` in the app. Capped server-side so a
    /// long-running conversation can't grow the prompt unbounded.
    #[serde(default)]
    history: Vec<ChatMessage>,
}

#[derive(Debug, Serialize)]
struct ChatTurnResponse {
    reply: String,
    crisis_flag: bool,
}

/// Only the most recent turns are kept: early rapport-building context
/// matters less than what was just said, and this bounds token cost on
/// long-lived conversations.
const MAX_HISTORY_MESSAGES: usize = 16;

/// Chat with the wellness companion, personalized with the last few days
/// of the user's own mood/journal history, grounded with research
/// relevant to their message, and now with real conversational memory —
/// see `mental_analysis_engine::generate_chat_reply`. No server-side
/// session store: the client already keeps the transcript for display,
/// so it resends the tail of it each turn instead of the backend holding
/// duplicate state.
async fn send_message(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<ChatTurnRequest>,
) -> Result<Json<ChatTurnResponse>, (axum::http::StatusCode, String)> {
    let now = Utc::now();
    let since = now - Duration::days(3);

    let recent_moods = state
        .moods
        .list_between(auth.user_id, since, now)
        .await
        .unwrap_or_default();
    let recent_journal_entries = state
        .journals
        .list_between(auth.user_id, since, now)
        .await
        .unwrap_or_default();

    let history_start = req.history.len().saturating_sub(MAX_HISTORY_MESSAGES);
    let history = &req.history[history_start..];

    let result = generate_chat_reply(
        &req.message,
        history,
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
