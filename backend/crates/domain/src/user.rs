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
    pub created_at: DateTime<Utc>,
}
