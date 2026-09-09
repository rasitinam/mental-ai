use serde::{Deserialize, Serialize};

/// How many days in a row someone has actually used the app, plus enough
/// recent shape to draw it. A day counts as "active" when it holds at
/// least one mood check-in, journal entry or chat message — three things
/// that already exist, rather than a fourth kind of record whose only
/// purpose is to feed a counter.
///
/// Days are bucketed in UTC. For a Turkish user that shifts a very late
/// entry into the next bucket; the alternative is carrying a timezone
/// database into the backend for a number whose whole job is to be
/// roughly encouraging.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreakSummary {
    /// Consecutive active days ending today — or ending yesterday, if
    /// today is still empty. Without that grace the number someone built
    /// up over two weeks would read as 0 every morning until they opened
    /// the app, which is exactly backwards.
    pub current: u32,
    /// Activity counts for the last seven days, oldest first. Counts
    /// rather than booleans so the sparkline has something to vary.
    pub last_seven: Vec<u32>,
    /// Active days within [`Self::period_days`], for the life-analysis
    /// view, which reports on a period rather than on a run.
    pub period_active: u32,
    pub period_days: u32,
}
