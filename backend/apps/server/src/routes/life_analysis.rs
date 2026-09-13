use axum::response::{IntoResponse, Response};
use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Duration, Utc};
use mental_analysis_engine::{
    generate_life_analysis, translate::translate_life_analysis, PersonContext,
};
use mental_domain::repository::{
    ChatRepository, ContentTranslationRepository, JournalRepository, LifeAnalysisRepository,
    MoodRepository, ReportRepository,
};
use mental_domain::report::LifeAnalysis;
use serde::Serialize;

use crate::auth::AuthUser;
use crate::state::AppState;
use crate::routes::{assessment_for, user_for};

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

const LIFE_ANALYSIS_CONTENT_TYPE: &str = "life_analysis";

#[derive(Debug, Serialize, serde::Deserialize)]
struct LifeAnalysisTranslationPayload {
    narrative: String,
    key_patterns: Vec<String>,
    do_list: Vec<String>,
    dont_list: Vec<String>,
}

/// Same idea as `reports::latest_report`: a life analysis is generated at
/// most once a week, in whatever language the account was set to at that
/// moment (`LifeAnalysis::language`) — switching the interface language in
/// between regenerations used to leave the analysis stuck in the old one
/// for up to a week. Translated on read and cached per (analysis,
/// language) instead.
async fn latest_analysis(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<LifeAnalysis>>, (axum::http::StatusCode, String)> {
    let mut analysis = state
        .life_analyses
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if let Some(analysis) = analysis.as_mut() {
        let reader_language = user_for(&state, auth.user_id).await.map(|u| u.language);
        if let Some(reader_language) = reader_language {
            if reader_language != analysis.language {
                match translated_analysis(&state, analysis, &reader_language).await {
                    Ok(payload) => {
                        analysis.narrative = payload.narrative;
                        analysis.key_patterns = payload.key_patterns;
                        analysis.do_list = payload.do_list;
                        analysis.dont_list = payload.dont_list;
                    }
                    Err(err) => {
                        tracing::warn!(error = %err, analysis_id = %analysis.id, "failed to translate life analysis");
                    }
                }
            }
        }
    }

    Ok(Json(analysis))
}

async fn translated_analysis(
    state: &AppState,
    analysis: &LifeAnalysis,
    target_language: &str,
) -> anyhow::Result<LifeAnalysisTranslationPayload> {
    let content_id = analysis.id.to_string();

    if let Some(cached) = state
        .content_translations
        .get(LIFE_ANALYSIS_CONTENT_TYPE, &content_id, target_language)
        .await?
    {
        if let Ok(payload) = serde_json::from_str(&cached) {
            return Ok(payload);
        }
    }

    let (narrative, key_patterns, do_list, dont_list) = translate_life_analysis(
        &analysis.narrative,
        &analysis.key_patterns,
        &analysis.do_list,
        &analysis.dont_list,
        target_language,
        state.llm.as_ref(),
    )
    .await?;
    let payload = LifeAnalysisTranslationPayload { narrative, key_patterns, do_list, dont_list };

    if let Ok(serialized) = serde_json::to_string(&payload) {
        if let Err(err) = state
            .content_translations
            .save(LIFE_ANALYSIS_CONTENT_TYPE, &content_id, target_language, &serialized)
            .await
        {
            tracing::warn!(error = %err, analysis_id = %analysis.id, "failed to cache life analysis translation");
        }
    }

    Ok(payload)
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
    let user = user_for(&state, auth.user_id).await;
    let person = user
        .as_ref()
        .map(PersonContext::from_user)
        .unwrap_or_else(PersonContext::unknown)
        .with_assessment(assessment_for(&state, auth.user_id).await);

    let analysis = generate_life_analysis(
        auth.user_id,
        &moods,
        &journal_entries,
        &chat_messages,
        &reports,
        &person,
        state.llm.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()).into_response())?;

    state.life_analyses.save(&analysis).await.map_err(internal)?;

    Ok(Json(analysis))
}
