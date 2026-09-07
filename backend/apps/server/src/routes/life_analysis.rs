use axum::response::{IntoResponse, Response};
use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Duration, Utc};
use mental_analysis_engine::generate_life_analysis;
use mental_domain::repository::{
    ChatRepository, JournalRepository, LifeAnalysisRepository, MoodRepository, ReportRepository,
};
use mental_domain::report::LifeAnalysis;
use serde::Serialize;

use crate::auth::AuthUser;
use crate::state::AppState;
use crate::routes::diagnoses_for;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/life-analysis/latest", get(latest_analysis))
        .route("/life-analysis/generate", post(generate_analysis))
}

/// Once a week. A whole-history analysis reads everything the account has
/// ever recorded, so it is both the most expensive call in the app and the
/// one whose answer changes least from day to day — regenerating it daily
/// would cost the most and say the least.
const COOLDOWN: Duration = Duration::days(7);

/// Bounded so a long-lived account doesn't grow this query without limit;
/// the analysis engine caps what it actually sends to the model too.
const MAX_CHAT_MESSAGES: u32 = 400;
const MAX_REPORTS: u32 = 60;

#[derive(Debug, Serialize)]
struct CooldownError {
    error: &'static str,
    retry_after: DateTime<Utc>,
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

/// Generates the whole-history narrative on demand, at most weekly. Unlike
/// the daily report this is never scheduled: it's something someone asks for
/// ("show me the big picture"), not something that should appear on its own.
async fn generate_analysis(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<LifeAnalysis>, Response> {
    let internal = |e: anyhow::Error| {
        (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
    };

    let previous = state
        .life_analyses
        .latest_for_user(auth.user_id)
        .await
        .map_err(internal)?;

    if let Some(previous) = previous {
        let retry_after = previous.generated_at + COOLDOWN;
        if retry_after > Utc::now() {
            let body = CooldownError {
                error: "Yaşam analizi haftada bir oluşturulabilir.",
                retry_after,
            };
            return Err((axum::http::StatusCode::TOO_MANY_REQUESTS, Json(body)).into_response());
        }
    }

    let moods = state.moods.list_all(auth.user_id).await.map_err(internal)?;
    let journal_entries = state.journals.list_all(auth.user_id).await.map_err(internal)?;
    let chat_messages = state
        .chats
        .history_for_user(auth.user_id, MAX_CHAT_MESSAGES)
        .await
        .map_err(internal)?;
    let reports = state
        .reports
        .list_recent(auth.user_id, MAX_REPORTS)
        .await
        .map_err(internal)?;
    let diagnoses = diagnoses_for(&state, auth.user_id).await;

    let analysis = generate_life_analysis(
        auth.user_id,
        &moods,
        &journal_entries,
        &chat_messages,
        &reports,
        &diagnoses,
        state.llm.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()).into_response())?;

    state.life_analyses.save(&analysis).await.map_err(internal)?;

    Ok(Json(analysis))
}
