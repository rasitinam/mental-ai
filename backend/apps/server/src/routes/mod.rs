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

use axum::Router;
use mental_domain::repository::UserRepository;
use uuid::Uuid;

use crate::state::AppState;

pub fn build_router(state: AppState) -> Router {
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
        .with_state(state)
}

/// The account's self-reported conditions, for prompt context. Returns an
/// empty list rather than an error when the lookup fails: missing context
/// should make an answer less tailored, never fail the request.
pub(crate) async fn diagnoses_for(state: &AppState, user_id: Uuid) -> Vec<String> {
    state
        .users
        .get(user_id)
        .await
        .ok()
        .flatten()
        .map(|user| user.diagnoses)
        .unwrap_or_default()
}
