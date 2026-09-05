use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A single self-reported mood check-in. `valence`/`arousal` follow the
/// circumplex model of affect (both in [-1.0, 1.0]) so the UI can plot mood
/// on a 2D wheel instead of forcing a single "how do you feel" scalar.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MoodEntry {
    pub id: Uuid,
    pub user_id: Uuid,
    pub valence: f32,
    pub arousal: f32,
    pub tags: Vec<String>,
    pub note: Option<String>,
    pub recorded_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MoodTrend {
    pub average_valence: f32,
    pub average_arousal: f32,
    pub sample_count: u32,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
}
