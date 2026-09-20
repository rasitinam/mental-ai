use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Who may open a DM request. Not who may *send* — an accepted thread
/// stays open regardless of this setting, so tightening it later doesn't
/// silently cut off conversations already underway.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DmPolicy {
    Everyone,
    Following,
}

impl DmPolicy {
    pub fn as_str(&self) -> &'static str {
        match self {
            DmPolicy::Everyone => "everyone",
            DmPolicy::Following => "following",
        }
    }

    pub fn parse(raw: &str) -> Self {
        match raw {
            "following" => DmPolicy::Following,
            _ => DmPolicy::Everyone,
        }
    }
}

/// A thread is `Pending` from its first message until the person who
/// didn't start it accepts. Declining removes the thread outright rather
/// than keeping a rejected row around — there's nothing useful to show
/// on either side afterwards.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DmStatus {
    Pending,
    Accepted,
}

impl DmStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            DmStatus::Pending => "pending",
            DmStatus::Accepted => "accepted",
        }
    }

    pub fn parse(raw: &str) -> Self {
        match raw {
            "accepted" => DmStatus::Accepted,
            _ => DmStatus::Pending,
        }
    }
}

/// The pair row. Ids are stored sorted (`user_low` < `user_high`) so a
/// conversation can only ever have one thread no matter who writes first.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DmThread {
    pub id: Uuid,
    pub user_low: Uuid,
    pub user_high: Uuid,
    pub started_by: Uuid,
    pub status: DmStatus,
    pub created_at: DateTime<Utc>,
    pub last_message_at: DateTime<Utc>,
}

impl DmThread {
    /// Sorted pair for `user_low`/`user_high`, so callers don't have to
    /// remember the ordering rule at every query site.
    pub fn pair(a: Uuid, b: Uuid) -> (Uuid, Uuid) {
        if a <= b {
            (a, b)
        } else {
            (b, a)
        }
    }

    pub fn other(&self, viewer: Uuid) -> Uuid {
        if self.user_low == viewer {
            self.user_high
        } else {
            self.user_low
        }
    }

    pub fn involves(&self, user: Uuid) -> bool {
        self.user_low == user || self.user_high == user
    }
}

/// Deliberately carries no read/seen state — see `migrations/0011_social.sql`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DmMessage {
    pub id: Uuid,
    pub thread_id: Uuid,
    pub sender_id: Uuid,
    pub body: String,
    pub created_at: DateTime<Utc>,
}

/// What one account looks like to someone else: enough to decide whether
/// to follow or write to them, and nothing from the clinical side of the
/// app (no diagnoses, no assessment scores, no mood history).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublicProfile {
    pub user_id: Uuid,
    pub display_name: String,
    pub has_avatar: bool,
    pub story_count: u32,
    pub follower_count: u32,
    pub following_count: u32,
    pub viewer_follows: bool,
    pub accepts_dm: bool,
}

/// One block the viewer has made, as listed on their "Blocked people"
/// screen. `blocked_id` is only ever shown to the viewer when the block did
/// not come from an anonymous story (see `anonymous`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockRecord {
    pub id: Uuid,
    pub blocked_id: Uuid,
    pub anonymous: bool,
    pub created_at: DateTime<Utc>,
}
