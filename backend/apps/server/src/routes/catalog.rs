use axum::{
    extract::{Path, State},
    routing::get,
    Json, Router,
};
use mental_analysis_engine::generate_disorder_explainer;
use mental_domain::catalog;
use mental_domain::repository::ExplainerRepository;
use mental_domain::{DisorderCategory, DisorderExplainer};

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/catalog", get(categories))
        .route("/catalog/disorders/:slug", get(explainer))
}

/// The static category/condition tree. No auth: it's reference data, the
/// same for everyone, and the app needs it to render the browse UI before
/// anything user-specific loads.
async fn categories() -> Json<&'static [DisorderCategory]> {
    Json(catalog::CATEGORIES)
}

/// Educational card for one condition. Generated on first request and cached
/// in `disorder_explainers` from then on — the catalog has ~150 entries, and
/// generating on every tap would be both slow and expensive for content that
/// doesn't change between users.
async fn explainer(
    State(state): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<DisorderExplainer>, (axum::http::StatusCode, String)> {
    if catalog::disorder(&slug).is_none() {
        return Err((axum::http::StatusCode::NOT_FOUND, "unknown disorder".to_string()));
    }

    let cached = state
        .explainers
        .get(&slug)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if let Some(cached) = cached {
        return Ok(Json(cached));
    }

    let generated = generate_disorder_explainer(
        &slug,
        state.llm.as_ref(),
        state.research.as_ref(),
        state.vector_store.as_ref(),
        state.embedder.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()))?;

    // A failed write costs a regeneration next time, which is better than
    // failing a response the caller can already use.
    if let Err(err) = state.explainers.save(&generated).await {
        tracing::warn!(error = %err, slug = %slug, "failed to cache disorder explainer");
    }

    Ok(Json(generated))
}
