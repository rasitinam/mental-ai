//! "Seni iyi hissettirenler" — a few cards naming what, in one person's
//! own log, tends to come with their lighter and heavier days.
//!
//! Observations, never advice or diagnosis, and never a number: see
//! `mental_analysis_engine::discoveries` for how they're produced and the
//! guards that keep them that way.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// A card needs at least this many separate days with a mood check-in
/// behind it before anything is said at all. Below that the app shows a
/// "keep logging" state instead of guessing from a handful of days.
pub const MIN_DAYS_FOR_DISCOVERIES: usize = 7;

/// How far back the cards look. Long enough for weekly rhythms to show
/// up more than once, short enough that last spring doesn't outvote how
/// someone's life looks now.
pub const DISCOVERY_WINDOW_DAYS: i64 = 60;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum DiscoveryKind {
    /// Seems to help.
    Lifts,
    /// Seems to weigh on them.
    Drains,
    /// A pattern in time — a weekday, before or after something.
    Rhythm,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Discovery {
    pub kind: DiscoveryKind,
    pub emoji: String,
    pub title: String,
    pub body: String,
}

/// One account's cards as last generated, in the language they were
/// written in — a language switch regenerates rather than serving the
/// old copy.
#[derive(Debug, Clone)]
pub struct CachedDiscoveries {
    pub language: String,
    pub cards: Vec<Discovery>,
    pub generated_at: DateTime<Utc>,
}
