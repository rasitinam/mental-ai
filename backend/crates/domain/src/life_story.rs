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
    /// The catalog condition this story is about — required at
    /// submission, so the guide can filter the feed by diagnosis instead
    /// of it being one undifferentiated wall of text.
    pub diagnosis_slug: String,
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
    /// Whether the feed hides who wrote this. Chosen per story rather
    /// than per account: the same person can want their name on one
    /// account of their life and not on another.
    #[serde(default = "default_anonymous")]
    pub anonymous: bool,
    /// ISO-639-1-ish code detected from the body at submission time (see
    /// [`detect_language`]). Drives the feed's auto-translate: a reader
    /// whose own account language differs from this gets a translated
    /// copy with a toggle back to the original — see
    /// `routes::stories::translate`.
    #[serde(default = "default_language")]
    pub language: String,
    pub reviewed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

fn default_anonymous() -> bool {
    true
}

fn default_language() -> String {
    "tr".to_string()
}

/// A deliberately small heuristic, not a statistical language-id model:
/// Turkish-specific letters (ç ğ ı ö ş ü, any case) are a strong enough
/// signal on their own, and their absence from text of any real length
/// is a strong enough signal the other way. Good enough to route
/// "should this be offered a translation", not meant as a general-purpose
/// classifier — a misdetected story just means one unnecessary (or one
/// skipped) translate button, never a wrong score or a lost submission.
/// Returns a free-form language code rather than an enum so adding a
/// third app language later is a matter of teaching this function one
/// more signal, not a schema change.
pub fn detect_language(text: &str) -> String {
    const TURKISH_CHARS: &[char] = &['ç', 'ğ', 'ı', 'ö', 'ş', 'ü', 'Ç', 'Ğ', 'İ', 'Ö', 'Ş', 'Ü'];
    if text.chars().any(|c| TURKISH_CHARS.contains(&c)) {
        return "tr".to_string();
    }

    // No Turkish-specific letters. Short text (a few words) is too little
    // signal either way, so default to Turkish — the app's primary
    // language — rather than guess. Longer plain-ASCII text with common
    // English function words is treated as English.
    let lower = text.to_lowercase();
    let word_count = lower.split_whitespace().count();
    let is_ascii_ish = text.chars().all(|c| c.is_ascii() || c.is_whitespace());
    const ENGLISH_MARKERS: &[&str] =
        &[" the ", " and ", " that ", " with ", " have ", " this ", " because ", " my "];
    let padded = format!(" {lower} ");
    let english_hits = ENGLISH_MARKERS.iter().filter(|m| padded.contains(*m)).count();

    if word_count >= 6 && is_ascii_ish && english_hits >= 1 {
        "en".to_string()
    } else {
        "tr".to_string()
    }
}

/// A feed row: the story plus everything the reader's copy of it needs —
/// vote tally, whether *they* voted, and the author's identity when the
/// story isn't anonymous. Assembled in one query rather than a lookup
/// per story.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoryFeedItem {
    pub story: LifeStory,
    pub upvotes: u32,
    pub viewer_upvoted: bool,
    pub author_display_name: String,
    pub author_has_avatar: bool,
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
