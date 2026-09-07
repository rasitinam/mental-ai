use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: Uuid,
    pub display_name: String,
    /// IANA timezone (e.g. "Europe/Istanbul"), used to schedule the daily
    /// report at a sensible local time rather than a fixed UTC hour.
    pub timezone: String,
    /// Self-reported conditions, as `catalog` slugs. The app never assigns
    /// these — they exist so someone can tell it what they already know, and
    /// so reports/chat can be framed with that context instead of guessing.
    #[serde(default)]
    pub diagnoses: Vec<String>,
    pub created_at: DateTime<Utc>,
}
