use axum::{extract::State, http::StatusCode, routing::post, Json, Router};
use chrono::{DateTime, Duration, Utc};
use mental_analysis_engine::{generate_session_summary, PersonContext};
use mental_domain::repository::{ChatRepository, JournalRepository, MoodRepository};
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::routes::{assessment_for, user_for};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/session-summary", post(session_summary))
}

/// The periods the screen offers. Fixed rather than free-form: "since my
/// last appointment" is almost always one of these, and a closed set keeps
/// the prompt size predictable.
const ALLOWED_DAYS: [i64; 3] = [7, 14, 30];

/// Enough for a few sentences of "things I want to bring up", not a
/// second journal.
const MAX_NOTE_CHARS: usize = 600;

/// How far back to read chat history before filtering it to the period.
const MAX_CHAT_MESSAGES: u32 = 400;

/// A screening older than this says little about the period being
/// summarized, so it's left out rather than presented as current.
const MAX_ASSESSMENT_AGE_DAYS: i64 = 90;

#[derive(Debug, Deserialize)]
struct SessionSummaryRequest {
    days: i64,
    #[serde(default)]
    note: Option<String>,
}

#[derive(Debug, Serialize)]
struct ScreeningView {
    days_ago: i64,
    phq9_score: u8,
    depression_band: &'static str,
    gad7_score: u8,
    anxiety_band: &'static str,
    who5_score: u8,
    wellbeing_band: &'static str,
}

#[derive(Debug, Serialize)]
struct SessionSummaryResponse {
    period_start: DateTime<Utc>,
    period_end: DateTime<Utc>,
    mood_days: usize,
    journal_entries: usize,
    overview: String,
    mood_course: String,
    themes: Vec<String>,
    hard_moments: Vec<String>,
    what_helped: Vec<String>,
    questions_to_bring: Vec<String>,
    screening: Option<ScreeningView>,
}

async fn session_summary(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SessionSummaryRequest>,
) -> Result<Json<SessionSummaryResponse>, (StatusCode, String)> {
    if !ALLOWED_DAYS.contains(&req.days) {
        return Err((StatusCode::BAD_REQUEST, format!("unsupported period: {} days", req.days)));
    }
    let note = req.note.as_deref().map(str::trim).filter(|n| !n.is_empty());
    if note.is_some_and(|n| n.chars().count() > MAX_NOTE_CHARS) {
        return Err((StatusCode::BAD_REQUEST, format!("note is longer than {MAX_NOTE_CHARS} characters")));
    }

    let period_end = Utc::now();
    let period_start = period_end - Duration::days(req.days);

    let moods = state
        .moods
        .list_between(auth.user_id, period_start, period_end)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    let journals = state
        .journals
        .list_between(auth.user_id, period_start, period_end)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    // Nothing to summarize: say so plainly rather than let the model write
    // a confident page about an empty fortnight.
    if moods.is_empty() && journals.is_empty() {
        return Err((StatusCode::UNPROCESSABLE_ENTITY, "not enough records in this period".to_string()));
    }

    let own_messages = state
        .chats
        .history_for_user(auth.user_id, MAX_CHAT_MESSAGES)
        .await
        .unwrap_or_default()
        .into_iter()
        .filter(|m| m.role.as_str() == "user" && m.created_at >= period_start)
        .collect::<Vec<_>>();

    let assessment = assessment_for(&state, auth.user_id)
        .await
        .filter(|a| a.days_ago <= MAX_ASSESSMENT_AGE_DAYS);

    let user = user_for(&state, auth.user_id).await;
    let person = user.as_ref().map(PersonContext::from_user).unwrap_or_else(PersonContext::unknown);

    let summary = generate_session_summary(
        period_start,
        period_end,
        &moods,
        &journals,
        &own_messages,
        assessment.as_ref(),
        note,
        &person,
        state.llm.as_ref(),
    )
    .await
    .map_err(|e| (StatusCode::BAD_GATEWAY, e.to_string()))?;

    let mood_days = moods
        .iter()
        .map(|m| m.recorded_at.date_naive())
        .collect::<std::collections::HashSet<_>>()
        .len();

    Ok(Json(SessionSummaryResponse {
        period_start,
        period_end,
        mood_days,
        journal_entries: journals.len(),
        overview: summary.overview,
        mood_course: summary.mood_course,
        themes: summary.themes,
        hard_moments: summary.hard_moments,
        what_helped: summary.what_helped,
        questions_to_bring: summary.questions_to_bring,
        screening: assessment.map(|a| ScreeningView {
            days_ago: a.days_ago,
            phq9_score: a.phq9_score,
            depression_band: a.depression_band,
            gad7_score: a.gad7_score,
            anxiety_band: a.anxiety_band,
            who5_score: a.who5_score,
            wellbeing_band: a.wellbeing_band,
        }),
    }))
}
