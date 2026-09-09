use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum StoryStatus {
    Pending,
    Approved,
    Rejected,
}

impl StoryStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            StoryStatus::Pending => "pending",
            StoryStatus::Approved => "approved",
            StoryStatus::Rejected => "rejected",
        }
    }

    pub fn parse(raw: &str) -> Self {
        match raw {
            "approved" => StoryStatus::Approved,
            "rejected" => StoryStatus::Rejected,
            _ => StoryStatus::Pending,
        }
    }
}

/// A first-person account of someone's own mental-health journey —
/// submitted for the public guide rather than kept private like a
/// journal entry. Every submission starts `Pending`; only an admin's
/// approve/reject moves it, and the author can withdraw it at any status.
///
/// Deliberately free text with no structured "medication name" field: a
/// searchable directory of who recommends which drug reads as promoting
/// a specific product, which is what Turkey's regulation on advertising
/// medicinal products to the public restricts. A personal narrative that
/// happens to mention a medication in passing is a different thing.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LifeStory {
    pub id: Uuid,
    pub user_id: Uuid,
    pub body: String,
    pub status: StoryStatus,
    /// Same keyword screen used for journal/chat, run at submission time
    /// so a crisis-flagged story gets extra scrutiny in the approval
    /// queue instead of blending in with the rest.
    pub crisis_flag: bool,
    /// When the author checked the "this will be shown to other users"
    /// box — a separate consent from account signup, since "visible to
    /// other users" is a materially different use of the data than a
    /// private journal entry.
    pub consented_at: DateTime<Utc>,
    pub reviewed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

/// A reader flagging an already-approved story back for re-review.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LifeStoryReport {
    pub id: Uuid,
    pub story_id: Uuid,
    pub reporter_user_id: Uuid,
    pub note: Option<String>,
    pub created_at: DateTime<Utc>,
}
