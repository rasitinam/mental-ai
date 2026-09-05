mod chat;
mod health;
mod insights;
mod journal;
mod life_analysis;
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
        .merge(insights::router())
        .merge(life_analysis::router())
        .with_state(state)
}
