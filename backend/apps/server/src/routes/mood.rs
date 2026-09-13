use axum::response::{IntoResponse, Response};
use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Duration, Utc};
use mental_domain::repository::MoodRepository;
use mental_domain::MoodEntry;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/mood", post(add_mood))
        .route("/mood/latest", get(latest_mood))
        .route("/mood/history", get(history))
}

/// Once-per-day check-ins are the product's intent ("günlük ruh hali") —
/// enforced here, server-side, rather than only in the UI, so it holds
/// even if a request is replayed or a future client forgets to check.
const COOLDOWN: Duration = Duration::hours(24);

#[derive(Debug, Deserialize)]
struct AddMoodRequest {
    valence: f32,
    arousal: f32,
    #[serde(default)]
    tags: Vec<String>,
    note: Option<String>,
}

#[derive(Debug, Serialize)]
struct CooldownError {
    error: &'static str,
    retry_after: DateTime<Utc>,
}

async fn add_mood(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<AddMoodRequest>,
) -> Result<Json<MoodEntry>, Response> {
    let previous = state
        .moods
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response())?;

    if let Some(previous) = previous {
        let retry_after = previous.recorded_at + COOLDOWN;
        if retry_after > Utc::now() {
            let body = CooldownError {
                error: "Bugünkü ruh hali kaydını zaten oluşturdun. Yarın tekrar dene.",
                retry_after,
            };
            return Err((axum::http::StatusCode::TOO_MANY_REQUESTS, Json(body)).into_response());
        }
    }

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
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response())?;

    Ok(Json(entry))
}

async fn latest_mood(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<MoodEntry>>, (axum::http::StatusCode, String)> {
    let entry = state
        .moods
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(entry))
}

/// Every check-in ever recorded, oldest first — feeds the mood heatmap and
/// the weekly recap, both of which need the actual history rather than
/// just today's reading. Once-a-day check-ins keep this small even over a
/// year of use, so there's no pagination here yet.
async fn history(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<MoodEntry>>, (axum::http::StatusCode, String)> {
    let entries = state
        .moods
        .list_all(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(entries))
}
