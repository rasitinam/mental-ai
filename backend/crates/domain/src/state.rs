use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Where a person is *right now*, assessed from every recent signal at once
/// rather than from the last mood slider alone.
///
/// This exists because the mood check-in is capped at once per day, so on
/// its own it goes stale the moment anything happens — someone can spend an
/// evening describing a crisis in chat and the home screen would still be
/// showing yesterday's cheerful slider reading. Chat, the latest daily
/// report, the latest life analysis, recent journal entries and the mood
/// history all feed this instead, and [`UserState::basis`] records which of
/// them actually contributed so the app can show its work.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserState {
    pub user_id: Uuid,
    /// Unpleasant..pleasant, -1.0..=1.0 — same axis as `MoodEntry::valence`
    /// so the two are directly comparable.
    pub valence: f32,
    /// Drained..energized, -1.0..=1.0 — the `MoodEntry::arousal` axis.
    pub energy: f32,
    /// One short line naming the state, shown under the face.
    pub headline: String,
    /// A sentence of context: what moved, compared to what.
    pub note: String,
    /// Human-readable labels for the sources that fed this assessment.
    #[serde(default)]
    pub basis: Vec<String>,
    pub generated_at: DateTime<Utc>,
}

impl UserState {
    /// Both axes mapped from -1.0..=1.0 onto a 1..=5 star rating, which is
    /// what the home screen shows instead of raw decimals.
    pub fn stars(value: f32) -> u8 {
        let normalized = (value.clamp(-1.0, 1.0) + 1.0) / 2.0;
        (normalized * 4.0).round() as u8 + 1
    }
}
