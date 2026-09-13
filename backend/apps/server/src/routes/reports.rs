use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::{generate_daily_report, translate::translate_daily_report, PersonContext};
use mental_domain::repository::{
    ChatRepository, ContentTranslationRepository, JournalRepository, MoodRepository,
    ReportRepository,
};
use mental_domain::DailyMentalReport;

use crate::auth::AuthUser;
use crate::routes::{assessment_for, user_for};
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
/// How much transcript to pull before filtering it down to today's turns.
const CHAT_MESSAGES: u32 = 60;

const REPORT_CONTENT_TYPE: &str = "daily_report";

#[derive(serde::Serialize, serde::Deserialize)]
struct ReportTranslationPayload {
    summary: String,
    recommendations: Vec<String>,
}

/// Reads back whatever was last generated, translated into the reader's
/// *current* account language if that has since changed — a report is
/// generated once, in the language the account was set to at that moment
/// (see `DailyMentalReport::language`), and switching the interface
/// language afterward used to leave it stuck in the old one until the next
/// scheduled regeneration. Cached per (report, language) so a reader
/// revisiting the same report in the same language costs one LLM call, not
/// one per view.
async fn latest_report(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<DailyMentalReport>>, (axum::http::StatusCode, String)> {
    let mut report = state
        .reports
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if let Some(report) = report.as_mut() {
        let reader_language = user_for(&state, auth.user_id).await.map(|u| u.language);
        if let Some(reader_language) = reader_language {
            if reader_language != report.language {
                match translated_report(&state, report, &reader_language).await {
                    Ok(payload) => {
                        report.summary = payload.summary;
                        report.recommendations = payload.recommendations;
                    }
                    Err(err) => {
                        tracing::warn!(error = %err, report_id = %report.id, "failed to translate daily report");
                    }
                }
            }
        }
    }

    Ok(Json(report))
}

async fn translated_report(
    state: &AppState,
    report: &DailyMentalReport,
    target_language: &str,
) -> anyhow::Result<ReportTranslationPayload> {
    let content_id = report.id.to_string();

    if let Some(cached) = state
        .content_translations
        .get(REPORT_CONTENT_TYPE, &content_id, target_language)
        .await?
    {
        if let Ok(payload) = serde_json::from_str(&cached) {
            return Ok(payload);
        }
    }

    let (summary, recommendations) =
        translate_daily_report(&report.summary, &report.recommendations, target_language, state.llm.as_ref())
            .await?;
    let payload = ReportTranslationPayload { summary, recommendations };

    if let Ok(serialized) = serde_json::to_string(&payload) {
        if let Err(err) = state
            .content_translations
            .save(REPORT_CONTENT_TYPE, &content_id, target_language, &serialized)
            .await
        {
            tracing::warn!(error = %err, report_id = %report.id, "failed to cache daily report translation");
        }
    }

    Ok(payload)
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
    // The day's conversation is part of the day: leaving it out was why a
    // report could describe a calm day the person had spent in crisis in chat.
    let chat_messages = state
        .chats
        .history_for_user(auth.user_id, CHAT_MESSAGES)
        .await
        .unwrap_or_default()
        .into_iter()
        .filter(|m| m.created_at >= since)
        .collect::<Vec<_>>();

    let user = user_for(&state, auth.user_id).await;
    let person = user
        .as_ref()
        .map(PersonContext::from_user)
        .unwrap_or_else(PersonContext::unknown)
        .with_assessment(assessment_for(&state, auth.user_id).await);

    let report = generate_daily_report(
        auth.user_id,
        &moods,
        &journal_entries,
        &chat_messages,
        &mood_history,
        &previous_reports,
        &person,
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
