use axum::{extract::State, routing::get, Json, Router};
use chrono::{Duration, NaiveDate, Utc};
use mental_domain::repository::ActivityRepository;
use mental_domain::StreakSummary;
use std::collections::HashMap;

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/streak", get(streak))
}

/// The window the life-analysis view reports its "N / M gün" over. Two
/// weeks because that's the same span the analysis itself covers.
const PERIOD_DAYS: i64 = 14;
const SPARKLINE_DAYS: i64 = 7;

async fn streak(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<StreakSummary>, (axum::http::StatusCode, String)> {
    // Enough history to answer both questions, plus room for a streak
    // that runs longer than the reporting period.
    let since = Utc::now() - Duration::days(365);
    let counts = state
        .activity
        .daily_counts(auth.user_id, since)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let by_day: HashMap<String, u32> = counts.into_iter().collect();
    let today = Utc::now().date_naive();
    let count_on = |day: NaiveDate| by_day.get(&day.to_string()).copied().unwrap_or(0);

    // Yesterday is allowed to anchor the run so the number doesn't read
    // as 0 every morning before the day's first entry.
    let mut cursor = if count_on(today) > 0 { today } else { today - Duration::days(1) };
    let mut current = 0;
    while count_on(cursor) > 0 {
        current += 1;
        cursor -= Duration::days(1);
    }

    let last_seven = (0..SPARKLINE_DAYS)
        .rev()
        .map(|back| count_on(today - Duration::days(back)))
        .collect();

    let period_active = (0..PERIOD_DAYS)
        .filter(|back| count_on(today - Duration::days(*back)) > 0)
        .count() as u32;

    Ok(Json(StreakSummary {
        current,
        last_seven,
        period_active,
        period_days: PERIOD_DAYS as u32,
    }))
}
