use axum::{
    extract::{Path, State},
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::generate_daily_report;
use mental_domain::repository::{JournalRepository, MoodRepository, ReportRepository};
use mental_domain::DailyMentalReport;
use uuid::Uuid;

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/reports/:user_id/latest", get(latest_report))
        .route("/reports/:user_id/generate", post(generate_report))
}

async fn latest_report(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<Option<DailyMentalReport>>, (axum::http::StatusCode, String)> {
    let report = state
        .reports
        .latest_for_user(user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(report))
}

/// Generates today's report on demand (also triggered on a schedule from
/// `main.rs`). Pulls the last 24h of mood/journal data, delegates the
/// actual LLM + RAG work to `mental-analysis-engine`, then persists it.
async fn generate_report(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<DailyMentalReport>, (axum::http::StatusCode, String)> {
    let now = Utc::now();
    let since = now - Duration::hours(24);

    let moods = state
        .moods
        .list_between(user_id, since, now)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let journal_entries = state
        .journals
        .list_between(user_id, since, now)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let report = generate_daily_report(
        user_id,
        &moods,
        &journal_entries,
        state.llm.as_ref(),
        state.vector_store.as_ref(),
        state.embedder.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state
        .reports
        .save(&report)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(report))
}
