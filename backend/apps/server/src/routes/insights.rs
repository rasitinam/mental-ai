use std::collections::HashSet;

use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use mental_analysis_engine::synthesize_insights;
use mental_domain::repository::{InsightRepository, ResearchRepository};
use mental_domain::Insight;

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/insights", get(recent_insights))
        .route("/insights/synthesize-now", post(synthesize_now))
}

/// How many already-ingested articles to consider per manual trigger.
const CANDIDATE_POOL: u32 = 60;
/// Same cap as the scheduled cycle (`apps/server/src/scheduler.rs`) —
/// each card costs one LLM call.
const MAX_INSIGHTS_PER_TRIGGER: usize = 5;

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

/// Manually turns already-ingested-but-not-yet-summarized articles into
/// insight cards. The scheduled research-ingest cycle only synthesizes
/// from articles that were newly fetched *that cycle*; if PubMed returns
/// nothing new (e.g. everything was already fetched once before), the
/// feed can stay empty even though the knowledge base has plenty of
/// unsummarized articles sitting in it. This reads the most recent ones,
/// skips any already cited by an existing insight, and synthesizes a
/// small batch from the rest.
async fn synthesize_now(
    State(state): State<AppState>,
) -> Result<Json<Vec<Insight>>, (axum::http::StatusCode, String)> {
    let already_covered: HashSet<_> = state
        .insights
        .recent(1000)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .into_iter()
        .flat_map(|insight| insight.source_article_ids)
        .collect();

    let candidates: Vec<_> = state
        .research
        .recent(CANDIDATE_POOL)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .into_iter()
        // "who" is WHO's general health-news feed (outbreaks, vaccines,
        // policy...), not mental-illness-specific — excluded here too so
        // articles ingested before it was dropped from the default source
        // list (see config/default.toml) don't still leak into new cards.
        .filter(|article| article.source != "who" && !already_covered.contains(&article.id))
        .collect();

    let insights = synthesize_insights(&candidates, MAX_INSIGHTS_PER_TRIGGER, state.llm.as_ref()).await;

    for insight in &insights {
        state
            .insights
            .save(insight)
            .await
            .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    }

    Ok(Json(insights))
}
