use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A durable record of one chat turn. Persisted purely so the
/// conversation isn't lost the moment the Flutter app's in-memory state
/// disappears (app restart, reinstall) — the live conversational memory
/// used to generate replies still comes from the client resending its
/// visible transcript (see `mental_analysis_engine::generate_chat_reply`),
/// this is the durable copy on the "everything real gets saved to the
/// database" side of things.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessageRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub role: ChatRole,
    pub content: String,
    pub crisis_flag: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum ChatRole {
    User,
    Assistant,
}

impl ChatRole {
    pub fn as_str(self) -> &'static str {
        match self {
            ChatRole::User => "user",
            ChatRole::Assistant => "assistant",
        }
    }
}
