mod auth;
mod catalog;
mod chat;
mod health;
mod insights;
mod journal;
mod life_analysis;
mod mood;
mod profile;
mod reports;
mod state;
mod stories;

use axum::http::StatusCode;
use axum::Router;
use mental_domain::repository::UserRepository;
use mental_domain::User;
use uuid::Uuid;

use crate::state::AppState;

pub fn build_router(app_state: AppState) -> Router {
    Router::new()
        .merge(health::router())
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
        .with_state(app_state)
}

/// The account behind a request, for prompt context (diagnoses, age,
/// language). Returns `None` rather than an error when the lookup fails:
/// missing context should make an answer less tailored, never fail the
/// request — callers fall back to `PersonContext::unknown()`.
pub(crate) async fn user_for(state: &AppState, user_id: Uuid) -> Option<User> {
    state.users.get(user_id).await.ok().flatten()
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
