use axum::{extract::State, routing::get, Json, Router};
use mental_domain::repository::InsightRepository;
use mental_domain::Insight;

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/insights", get(recent_insights))
}

/// Insight cards are not generated per-request — they're synthesized in
/// the background right after each research-ingest cycle finds new
/// articles (see `apps/server/src/scheduler.rs`). This endpoint just
/// reads whatever has accumulated so far, newest first.
async fn recent_insights(
    State(state): State<AppState>,
) -> Result<Json<Vec<Insight>>, (axum::http::StatusCode, String)> {
    let insights = state
        .insights
        .recent(30)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(insights))
}
