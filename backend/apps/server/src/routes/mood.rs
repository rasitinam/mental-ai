use axum::{extract::State, routing::post, Json, Router};
use chrono::Utc;
use mental_domain::repository::MoodRepository;
use mental_domain::MoodEntry;
use serde::Deserialize;
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/mood", post(add_mood))
}

#[derive(Debug, Deserialize)]
struct AddMoodRequest {
    valence: f32,
    arousal: f32,
    #[serde(default)]
    tags: Vec<String>,
    note: Option<String>,
}

async fn add_mood(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<AddMoodRequest>,
) -> Result<Json<MoodEntry>, (axum::http::StatusCode, String)> {
    let entry = MoodEntry {
        id: Uuid::new_v4(),
        user_id: auth.user_id,
        valence: req.valence.clamp(-1.0, 1.0),
        arousal: req.arousal.clamp(-1.0, 1.0),
        tags: req.tags,
        note: req.note,
        recorded_at: Utc::now(),
    };

    state
        .moods
        .add(&entry)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(entry))
}
