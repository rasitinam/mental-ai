use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::generate_life_analysis;
use mental_domain::repository::{JournalRepository, LifeAnalysisRepository, MoodRepository};
use mental_domain::report::LifeAnalysis;

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/life-analysis/latest", get(latest_analysis))
        .route("/life-analysis/generate", post(generate_analysis))
}

async fn latest_analysis(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<LifeAnalysis>>, (axum::http::StatusCode, String)> {
    let analysis = state
        .life_analyses
        .latest_for_user(auth.user_id)
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
    auth: AuthUser,
) -> Result<Json<LifeAnalysis>, (axum::http::StatusCode, String)> {
    let period_end = Utc::now();
    let period_start = period_end - Duration::days(30);

    let moods = state
        .moods
        .list_between(auth.user_id, period_start, period_end)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let journal_entries = state
        .journals
        .list_between(auth.user_id, period_start, period_end)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let analysis = generate_life_analysis(
        auth.user_id,
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
