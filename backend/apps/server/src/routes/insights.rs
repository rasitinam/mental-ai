use std::collections::HashSet;

use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Json, Router,
};
use mental_analysis_engine::{synthesize_insights, translate::translate_card};
use mental_domain::repository::{InsightRepository, ResearchRepository};
use mental_domain::Insight;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::routes::user_for;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/insights", get(recent_insights))
        .route("/insights/:id/translate", get(translate))
        .route("/insights/synthesize-now", post(synthesize_now))
}

/// Cards are synthesized once, for everyone, in this language — there is no
/// per-card language column because there has only ever been one. Sent to
/// the client so it can compare against its own language and ask for a
/// translation, rather than hardcoding "the feed is Turkish" on its side.
const INSIGHT_SOURCE_LANGUAGE: &str = "tr";

/// How many already-ingested articles to consider per manual trigger.
const CANDIDATE_POOL: u32 = 60;
/// Same cap as the scheduled cycle (`apps/server/src/scheduler.rs`) —
/// each card costs one LLM call.
const MAX_INSIGHTS_PER_TRIGGER: usize = 5;

#[derive(Debug, Deserialize)]
struct InsightsQuery {
    /// Catalog category slug. Omitted means the unfiltered ("Genel") feed,
    /// which also includes cards that couldn't be categorized.
    category: Option<String>,
}

/// Insight cards are not generated per-request — they're synthesized in
/// the background right after each research-ingest cycle finds new
/// articles (see `apps/server/src/scheduler.rs`). This endpoint just
/// reads whatever has accumulated so far, newest first.
async fn recent_insights(
    State(state): State<AppState>,
    Query(query): Query<InsightsQuery>,
) -> Result<Json<Vec<InsightCard>>, (axum::http::StatusCode, String)> {
    let insights = match query.category.as_deref() {
        Some(category) => state.insights.recent_in_category(category, 60).await,
        None => state.insights.recent(30).await,
    }
    .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(insights.iter().map(InsightCard::from).collect()))
}

/// An insight plus the language it was written in.
#[derive(Debug, Serialize)]
struct InsightCard {
    id: String,
    title: String,
    body: String,
    language: &'static str,
    tags: Vec<String>,
    category: Option<String>,
    created_at: chrono::DateTime<chrono::Utc>,
}

impl From<&Insight> for InsightCard {
    fn from(insight: &Insight) -> Self {
        Self {
            id: insight.id.to_string(),
            title: insight.title.clone(),
            body: insight.body.clone(),
            language: INSIGHT_SOURCE_LANGUAGE,
            tags: insight.tags.clone(),
            category: insight.category.clone(),
            created_at: insight.created_at,
        }
    }
}

#[derive(Debug, Serialize)]
struct InsightTranslation {
    title: String,
    body: String,
    source_language: &'static str,
}

/// Translates one card into the caller's own account language, cached per
/// (card, language) so the LLM is called once no matter how many readers
/// share a language. Same shape as `stories::translate`.
async fn translate(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<InsightTranslation>, (axum::http::StatusCode, String)> {
    let insight = state
        .insights
        .get(id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((axum::http::StatusCode::NOT_FOUND, "insight not found".to_string()))?;

    let reader_language = user_for(&state, auth.user_id)
        .await
        .map(|u| u.language)
        .unwrap_or_else(|| INSIGHT_SOURCE_LANGUAGE.to_string());

    if reader_language == INSIGHT_SOURCE_LANGUAGE {
        return Ok(Json(InsightTranslation {
            title: insight.title,
            body: insight.body,
            source_language: INSIGHT_SOURCE_LANGUAGE,
        }));
    }

    if let Some((title, body)) = state
        .insights
        .get_translation(id, &reader_language)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    {
        return Ok(Json(InsightTranslation {
            title,
            body,
            source_language: INSIGHT_SOURCE_LANGUAGE,
        }));
    }

    let (title, body) =
        translate_card(&insight.title, &insight.body, &reader_language, state.llm.as_ref())
            .await
            .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()))?;

    if let Err(err) = state.insights.save_translation(id, &reader_language, &title, &body).await {
        tracing::warn!(error = %err, %id, "failed to cache insight translation");
    }

    Ok(Json(InsightTranslation { title, body, source_language: INSIGHT_SOURCE_LANGUAGE }))
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
