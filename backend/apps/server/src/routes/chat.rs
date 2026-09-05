use axum::{extract::State, routing::post, Json, Router};
use chrono::{Duration, Utc};
use mental_analysis_engine::generate_chat_reply;
use mental_domain::repository::{ChatRepository, JournalRepository, MoodRepository};
use mental_domain::{ChatMessageRecord, ChatRole};
use mental_llm_connector::ChatMessage;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

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
/// see `mental_analysis_engine::generate_chat_reply`. There is still no
/// server-side *live* session store (the client resends the tail of its
/// transcript each turn, as above) — but every turn is now durably
/// persisted to `chat_messages` regardless, so a conversation survives
/// an app reinstall/restart even though it isn't replayed automatically
/// yet. A failure to persist is logged and swallowed rather than failing
/// the request: losing the durable copy of a message the user already
/// received is much better than losing the reply itself over a DB hiccup.
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

    persist_turn(&state, auth.user_id, ChatRole::User, &req.message, false).await;
    persist_turn(&state, auth.user_id, ChatRole::Assistant, &result.reply, result.crisis_flag).await;

    Ok(Json(ChatTurnResponse { reply: result.reply, crisis_flag: result.crisis_flag }))
}

async fn persist_turn(state: &AppState, user_id: Uuid, role: ChatRole, content: &str, crisis_flag: bool) {
    let record = ChatMessageRecord {
        id: Uuid::new_v4(),
        user_id,
        role,
        content: content.to_string(),
        crisis_flag,
        created_at: Utc::now(),
    };
    if let Err(err) = state.chats.add(&record).await {
        tracing::warn!(error = %err, "failed to persist chat message");
    }
}
