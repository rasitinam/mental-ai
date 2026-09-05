use axum::{extract::State, routing::post, Json, Router};
use mental_analysis_engine::screen_for_crisis_language;
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, Role};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/chat", post(send_message))
}

#[derive(Debug, Deserialize)]
struct ChatTurnRequest {
    #[allow(dead_code)]
    user_id: Uuid,
    message: String,
}

#[derive(Debug, Serialize)]
struct ChatTurnResponse {
    reply: String,
    crisis_flag: bool,
}

/// Single-turn chat with the wellness companion. Deliberately stateless
/// at this layer (no server-side conversation history yet) — the Flutter
/// app keeps the visible transcript and resends what's needed as context
/// once multi-turn memory is added.
async fn send_message(
    State(state): State<AppState>,
    Json(req): Json<ChatTurnRequest>,
) -> Result<Json<ChatTurnResponse>, (axum::http::StatusCode, String)> {
    let crisis = screen_for_crisis_language(&req.message);

    let messages = vec![
        ChatMessage {
            role: Role::System,
            content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
        },
        ChatMessage {
            role: Role::User,
            content: req.message,
        },
    ];

    let response = state
        .llm
        .chat(ChatRequest {
            messages,
            tools: vec![],
            // Left unset: see openai_compatible.rs's note on reasoning
            // models rejecting a non-default temperature.
            temperature: None,
        })
        .await
        .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()))?;

    Ok(Json(ChatTurnResponse {
        reply: response.message.content,
        crisis_flag: crisis.flagged,
    }))
}
