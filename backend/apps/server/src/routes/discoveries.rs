use axum::{extract::State, http::StatusCode, routing::get, Json, Router};
use chrono::{DateTime, Duration, Utc};
use mental_analysis_engine::{distinct_mood_days, generate_discoveries, PersonContext};
use mental_domain::discovery::{
    CachedDiscoveries, Discovery, DISCOVERY_WINDOW_DAYS, MIN_DAYS_FOR_DISCOVERIES,
};
use mental_domain::repository::{DiscoveryRepository, JournalRepository, MoodRepository};
use serde::Serialize;

use crate::auth::AuthUser;
use crate::routes::user_for;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/discoveries", get(discoveries))
}

/// Cards are rebuilt at most once a day per account. Reading the home
/// screen ten times a day shouldn't cost ten LLM calls, and a pattern
/// across weeks of history doesn't change between breakfast and lunch.
const REFRESH_AFTER_HOURS: i64 = 24;

#[derive(Debug, Serialize)]
#[serde(tag = "status", rename_all = "snake_case")]
enum DiscoveriesResponse {
    /// Not enough history yet — the client shows how far along they are
    /// instead of an empty section.
    Locked { days_logged: usize, days_needed: usize },
    /// `cards` can be empty: enough days, but nothing the model could
    /// honestly call a pattern. That's a different message from "locked".
    Ready { cards: Vec<Discovery>, generated_at: DateTime<Utc> },
}

async fn discoveries(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<DiscoveriesResponse>, (StatusCode, String)> {
    let now = Utc::now();
    let since = now - Duration::days(DISCOVERY_WINDOW_DAYS);

    let moods = state
        .moods
        .list_between(auth.user_id, since, now)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let days_logged = distinct_mood_days(&moods);
    if days_logged < MIN_DAYS_FOR_DISCOVERIES {
        return Ok(Json(DiscoveriesResponse::Locked {
            days_logged,
            days_needed: MIN_DAYS_FOR_DISCOVERIES,
        }));
    }

    let user = user_for(&state, auth.user_id).await;
    let language = user.as_ref().map(|u| u.language.clone()).unwrap_or_else(|| "tr".to_string());

    let cached = state.discoveries.get(auth.user_id).await.ok().flatten();
    if let Some(cached) = &cached {
        let fresh = now - cached.generated_at < Duration::hours(REFRESH_AFTER_HOURS);
        if fresh && cached.language == language {
            return Ok(Json(DiscoveriesResponse::Ready {
                cards: cached.cards.clone(),
                generated_at: cached.generated_at,
            }));
        }
    }

    let journals = state.journals.list_between(auth.user_id, since, now).await.unwrap_or_default();
    let person = user.as_ref().map(PersonContext::from_user).unwrap_or_else(PersonContext::unknown);

    match generate_discoveries(&moods, &journals, &person, state.llm.as_ref()).await {
        Ok(result) => {
            let fresh = CachedDiscoveries { language, cards: result.cards, generated_at: now };
            if let Err(err) = state.discoveries.save(auth.user_id, &fresh).await {
                tracing::warn!(error = %err, "failed to cache discoveries");
            }
            Ok(Json(DiscoveriesResponse::Ready { cards: fresh.cards, generated_at: now }))
        }
        // A stale set of cards is still true about the person; showing it
        // beats an error on the home screen because one refresh failed.
        Err(err) => match cached {
            Some(cached) => {
                tracing::warn!(error = %err, "discoveries refresh failed; serving cached cards");
                Ok(Json(DiscoveriesResponse::Ready {
                    cards: cached.cards,
                    generated_at: cached.generated_at,
                }))
            }
            None => Err((StatusCode::BAD_GATEWAY, err.to_string())),
        },
    }
}
