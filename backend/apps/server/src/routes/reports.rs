use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::generate_daily_report;
use mental_domain::repository::{JournalRepository, MoodRepository, ReportRepository};
use mental_domain::DailyMentalReport;

use crate::auth::AuthUser;
use crate::routes::diagnoses_for;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/reports/latest", get(latest_report))
        .route("/reports", get(list_reports))
        .route("/reports/generate", post(generate_report))
}

/// How far back the "compared to previous days" context reaches.
const PREVIOUS_REPORTS: u32 = 7;
/// Cap for the archive endpoint.
const MAX_REPORTS: u32 = 90;

async fn latest_report(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<DailyMentalReport>>, (axum::http::StatusCode, String)> {
    let report = state
        .reports
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(report))
}

async fn list_reports(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<DailyMentalReport>>, (axum::http::StatusCode, String)> {
    let reports = state
        .reports
        .list_recent(auth.user_id, MAX_REPORTS)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(reports))
}

/// Generates today's report on demand (also triggered on a schedule from
/// `main.rs`). The window for *content* is the last 24h, but the whole mood
/// history and the previous week of reports go in as context so the report
/// can say where today sits relative to the person's usual — see
/// `mental_analysis_engine::generate_daily_report`.
async fn generate_report(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<DailyMentalReport>, (axum::http::StatusCode, String)> {
    let now = Utc::now();
    let since = now - Duration::hours(24);

    let internal =
        |e: anyhow::Error| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string());

    let moods = state
        .moods
        .list_between(auth.user_id, since, now)
        .await
        .map_err(internal)?;
    let journal_entries = state
        .journals
        .list_between(auth.user_id, since, now)
        .await
        .map_err(internal)?;
    let mood_history = state.moods.list_all(auth.user_id).await.map_err(internal)?;
    let previous_reports = state
        .reports
        .list_recent(auth.user_id, PREVIOUS_REPORTS)
        .await
        .map_err(internal)?;
    let diagnoses = diagnoses_for(&state, auth.user_id).await;

    let report = generate_daily_report(
        auth.user_id,
        &moods,
        &journal_entries,
        &mood_history,
        &previous_reports,
        &diagnoses,
        state.llm.as_ref(),
        state.research.as_ref(),
        state.vector_store.as_ref(),
        state.embedder.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state.reports.save(&report).await.map_err(internal)?;

    Ok(Json(report))
}
