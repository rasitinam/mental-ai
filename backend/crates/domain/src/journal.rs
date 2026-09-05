use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct JournalEntry {
    pub id: Uuid,
    pub user_id: Uuid,
    pub body: String,
    /// Populated asynchronously by the analysis engine after the entry is
    /// saved; `None` until the sentiment/theme pass has run.
    pub detected_themes: Option<Vec<String>>,
    pub created_at: DateTime<Utc>,
}
