use axum::{
    extract::{Path, State},
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::generate_life_analysis;
use mental_domain::repository::{JournalRepository, LifeAnalysisRepository, MoodRepository};
use mental_domain::report::LifeAnalysis;
use uuid::Uuid;

use crate::state::AppState;
use crate::users::ensure_user;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/life-analysis/:user_id/latest", get(latest_analysis))
        .route("/life-analysis/:user_id/generate", post(generate_analysis))
}

async fn latest_analysis(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<Option<LifeAnalysis>>, (axum::http::StatusCode, String)> {
    let analysis = state
        .life_analyses
        .latest_for_user(user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(analysis))
}

/// Generates a 30-day narrative on demand. Unlike the daily report this
/// is deliberately not on a schedule — a month-long pattern doesn't
/// change meaningfully hour to hour, so regenerating it is a user action
/// ("show me my last month") rather than a background job.
async fn generate_analysis(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<LifeAnalysis>, (axum::http::StatusCode, String)> {
    ensure_user(&state, user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let period_end = Utc::now();
    let period_start = period_end - Duration::days(30);

    let moods = state
        .moods
        .list_between(user_id, period_start, period_end)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let journal_entries = state
        .journals
        .list_between(user_id, period_start, period_end)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let analysis = generate_life_analysis(
        user_id,
        period_start,
        period_end,
        &moods,
        &journal_entries,
        state.llm.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state
        .life_analyses
        .save(&analysis)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(analysis))
}
