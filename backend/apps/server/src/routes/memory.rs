//! What Hearth has learned about a person from their own entries (see
//! `mental_domain::memory`) — theirs to read, switch off and clear. Nothing
//! here calls the model: the memory itself is (re)written in the background
//! after ordinary activity (`crate::refresh`), never on these routes.

use axum::{
    extract::State,
    routing::{get, put},
    Json, Router,
};
use chrono::Utc;
use mental_domain::repository::PersonMemoryRepository;
use mental_domain::PersonMemory;
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/memory", get(get_memory).delete(clear_memory))
        .route("/memory/enabled", put(set_enabled))
}

#[derive(Debug, Serialize)]
struct MemoryView {
    enabled: bool,
    items: Vec<MemoryItemView>,
    generated_at: Option<chrono::DateTime<Utc>>,
}

#[derive(Debug, Serialize)]
struct MemoryItemView {
    kind: String,
    text: String,
}

impl From<PersonMemory> for MemoryView {
    fn from(memory: PersonMemory) -> Self {
        Self {
            enabled: memory.enabled,
            items: memory.items.into_iter().map(|i| MemoryItemView { kind: i.kind, text: i.text }).collect(),
            generated_at: memory.generated_at,
        }
    }
}

/// What Hearth currently remembers — the "Me > Settings > What Hearth
/// remembers" screen. A person with nothing recorded yet (or who never
/// switched anything off) reads as enabled with an empty list, not a 404.
async fn get_memory(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<MemoryView>, (axum::http::StatusCode, String)> {
    let memory = state
        .person_memory
        .get(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .unwrap_or_else(|| PersonMemory::empty(auth.user_id, "tr"));

    Ok(Json(memory.into()))
}

#[derive(Debug, Deserialize)]
struct SetEnabledRequest {
    enabled: bool,
}

/// Switching this off also clears whatever was already remembered — turning
/// it off should mean "forget", not "stop updating but keep what you have".
/// Turning it back on starts from nothing again; the next chat turn, journal
/// entry or check-in builds it up from there (see `crate::refresh`).
async fn set_enabled(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SetEnabledRequest>,
) -> Result<Json<MemoryView>, (axum::http::StatusCode, String)> {
    let language = state
        .person_memory
        .get(auth.user_id)
        .await
        .ok()
        .flatten()
        .map(|m| m.language)
        .unwrap_or_else(|| "tr".to_string());

    // Either direction starts from nothing: off means forget, and back on
    // means building up fresh rather than resuming a stale memory.
    let memory = PersonMemory { user_id: auth.user_id, enabled: req.enabled, items: Vec::new(), language, generated_at: None };

    state
        .person_memory
        .save(&memory)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(memory.into()))
}

/// Clears what is remembered without switching future memory off — "forget
/// what you know, but you can keep learning".
async fn clear_memory(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<MemoryView>, (axum::http::StatusCode, String)> {
    let enabled = state.person_memory.get(auth.user_id).await.ok().flatten().map(|m| m.enabled).unwrap_or(true);

    let memory = PersonMemory { user_id: auth.user_id, enabled, items: Vec::new(), language: "tr".to_string(), generated_at: None };

    state
        .person_memory
        .save(&memory)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(memory.into()))
}
