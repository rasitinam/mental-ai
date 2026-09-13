use axum::{
    extract::State,
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::{
    assess_current_state, relabel_basis, translate::translate_current_state, PersonContext,
    StateInputs,
};
use mental_domain::repository::{
    ChatRepository, ContentTranslationRepository, JournalRepository, LifeAnalysisRepository,
    MoodRepository, ReportRepository, UserRepository, UserStateRepository,
};
use mental_domain::{User, UserState};

use crate::auth::AuthUser;
use crate::routes::user_for;
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

const STATE_CONTENT_TYPE: &str = "current_state";

#[derive(serde::Serialize, serde::Deserialize)]
struct StateTranslationPayload {
    headline: String,
    note: String,
}

/// Same idea as `reports::latest_report`: the current-state snapshot is
/// assessed on demand (pull-to-refresh) and cached as a single row per
/// user in whatever language the account was set to at that moment
/// (`UserState::language`) — switching the interface language without
/// triggering a fresh assessment used to leave the home screen's headline
/// stuck in the old language. Translated on read and cached per (user,
/// language).
async fn current_state(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<UserState>>, (axum::http::StatusCode, String)> {
    let mut stored = state
        .user_states
        .get(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if let Some(stored) = stored.as_mut() {
        let reader_language = user_for(&state, auth.user_id).await.map(|u| u.language);
        if let Some(reader_language) = reader_language {
            // Cheap either way: `basis` is a handful of fixed labels, not
            // model output, so it's re-derived on every read rather than
            // only when a mismatch is detected.
            stored.basis = relabel_basis(&stored.basis, &reader_language);

            if reader_language != stored.language {
                match translated_state(&state, stored, &reader_language).await {
                    Ok(payload) => {
                        stored.headline = payload.headline;
                        stored.note = payload.note;
                    }
                    Err(err) => {
                        tracing::warn!(error = %err, user_id = %auth.user_id, "failed to translate current state");
                    }
                }
            }
        }
    }

    Ok(Json(stored))
}

async fn translated_state(
    state: &AppState,
    stored: &UserState,
    target_language: &str,
) -> anyhow::Result<StateTranslationPayload> {
    // `user_states` is one row per user, replaced wholesale on every
    // reassessment (see `UserStateRepository::save`) rather than a new row
    // per generation — so the user id alone would key a stale translation
    // to a headline that has since changed. `generated_at` changes on every
    // reassessment, so folding it in makes each generation its own cache
    // entry instead of overwriting the previous one's meaning.
    let content_id = format!("{}:{}", stored.user_id, stored.generated_at.timestamp());

    if let Some(cached) =
        state.content_translations.get(STATE_CONTENT_TYPE, &content_id, target_language).await?
    {
        if let Ok(payload) = serde_json::from_str(&cached) {
            return Ok(payload);
        }
    }

    let (headline, note) =
        translate_current_state(&stored.headline, &stored.note, target_language, state.llm.as_ref())
            .await?;
    let payload = StateTranslationPayload { headline, note };

    if let Ok(serialized) = serde_json::to_string(&payload) {
        if let Err(err) = state
            .content_translations
            .save(STATE_CONTENT_TYPE, &content_id, target_language, &serialized)
            .await
        {
            tracing::warn!(error = %err, user_id = %stored.user_id, "failed to cache current state translation");
        }
    }

    Ok(payload)
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
