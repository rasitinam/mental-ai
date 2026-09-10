use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::{assess_current_state, PersonContext, StateInputs};
use mental_domain::repository::{
    ChatRepository, JournalRepository, LifeAnalysisRepository, MoodRepository, ReportRepository,
    UserRepository, UserStateRepository,
};
use mental_domain::{User, UserState};

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/state", get(current_state))
        .route("/state/refresh", post(refresh_state))
}

/// How much conversation to look back over. Long enough to cover an evening,
/// short enough that a months-old exchange can't colour "right now".
const CHAT_WINDOW_HOURS: i64 = 72;
const CHAT_MESSAGES: u32 = 40;

async fn current_state(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<UserState>>, (axum::http::StatusCode, String)> {
    let stored = state
        .user_states
        .get(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(stored))
}

/// Recomputes the home screen's reading from every current signal — this is
/// what pull-to-refresh calls. Deliberately a full reassessment rather than a
/// cache read: the whole point is that a conversation the person just had
/// should move the number, and the cached row can't know that happened.
async fn refresh_state(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<UserState>, (axum::http::StatusCode, String)> {
    let now = Utc::now();
    let since = now - Duration::hours(CHAT_WINDOW_HOURS);

    let user: Option<User> = state.users.get(auth.user_id).await.ok().flatten();
    let person = user
        .as_ref()
        .map(PersonContext::from_user)
        .unwrap_or_else(PersonContext::unknown)
        .with_assessment(crate::routes::assessment_for(&state, auth.user_id).await);

    let chat = state
        .chats
        .history_for_user(auth.user_id, CHAT_MESSAGES)
        .await
        .unwrap_or_default();
    let moods = state
        .moods
        .list_between(auth.user_id, since, now)
        .await
        .unwrap_or_default();
    let journal = state.journals.list_all(auth.user_id).await.unwrap_or_default();
    let report = state.reports.latest_for_user(auth.user_id).await.unwrap_or_default();
    let life_analysis = state
        .life_analyses
        .latest_for_user(auth.user_id)
        .await
        .unwrap_or_default();

    let assessed = assess_current_state(
        auth.user_id,
        StateInputs {
            chat: &chat,
            moods: &moods,
            journal: &journal,
            report: report.as_ref(),
            life_analysis: life_analysis.as_ref(),
        },
        &person,
        state.llm.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()))?;

    // A failed write costs the cache, not the answer the caller is waiting on.
    if let Err(err) = state.user_states.save(&assessed).await {
        tracing::warn!(error = %err, "failed to persist user state");
    }

    Ok(Json(assessed))
}
