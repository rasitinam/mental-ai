mod chat;
mod health;
mod journal;
mod mood;
mod reports;

use axum::Router;

use crate::state::AppState;

pub fn build_router(state: AppState) -> Router {
    Router::new()
        .merge(health::router())
        .merge(chat::router())
        .merge(mood::router())
        .merge(journal::router())
        .merge(reports::router())
        .with_state(state)
}
