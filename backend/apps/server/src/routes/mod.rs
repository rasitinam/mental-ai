mod assessment;
mod auth;
mod catalog;
mod chat;
mod dm;
mod health;
mod insights;
mod journal;
mod life_analysis;
mod mood;
pub(crate) mod profile;
mod reports;
pub(crate) mod social;
mod state;
mod stories;
mod streak;

use axum::http::StatusCode;
use axum::Router;
use mental_domain::repository::{AssessmentRepository, UserRepository};
use mental_domain::User;
use mental_analysis_engine::AssessmentSummary;
use uuid::Uuid;

use crate::state::AppState;

pub fn build_router(app_state: AppState) -> Router {
    Router::new()
        .merge(health::router())
        .merge(assessment::router())
        .merge(auth::router())
        .merge(profile::router())
        .merge(catalog::router())
        .merge(chat::router())
        .merge(mood::router())
        .merge(journal::router())
        .merge(reports::router())
        .merge(insights::router())
        .merge(life_analysis::router())
        .merge(state::router())
        .merge(stories::router())
        .merge(social::router())
        .merge(dm::router())
        .merge(streak::router())
        .with_state(app_state)
}

/// The account behind a request, for prompt context (diagnoses, age,
/// language). Returns `None` rather than an error when the lookup fails:
/// missing context should make an answer less tailored, never fail the
/// request — callers fall back to `PersonContext::unknown()`.
pub(crate) async fn user_for(state: &AppState, user_id: Uuid) -> Option<User> {
    state.users.get(user_id).await.ok().flatten()
}

/// The other half of prompt context: the latest PHQ-9/GAD-7 reading, if
/// there is one. Same "missing just means less tailored" fallback as
/// [`user_for`] — a failed lookup returns `None` rather than failing
/// whatever generation call is asking for it.
pub(crate) async fn assessment_for(state: &AppState, user_id: Uuid) -> Option<AssessmentSummary> {
    state
        .assessments
        .latest_for_user(user_id)
        .await
        .ok()
        .flatten()
        .as_ref()
        .map(AssessmentSummary::from_assessment)
}

/// Gate for the life-story moderation routes. `is_admin` is granted by
/// hand against the database (see `migrations/0007_life_stories.sql`) —
/// there is no endpoint that can set it, so this check can't be defeated
/// by anything a request supplies.
pub(crate) async fn require_admin(state: &AppState, user_id: Uuid) -> Result<(), (StatusCode, String)> {
    match user_for(state, user_id).await {
        Some(user) if user.is_admin => Ok(()),
        _ => Err((StatusCode::FORBIDDEN, "admin only".to_string())),
    }
}
