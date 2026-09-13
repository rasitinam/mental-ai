use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// The daily mental-state summary shown to the user. This is a wellness
//// self-reflection artifact, not a clinical diagnosis — copy generated
/// for `summary` and `recommendations` must stay within that framing
/// (see `mental-llm-connector::prompts` for the enforced system prompt).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyMentalReport {
    pub id: Uuid,
    pub user_id: Uuid,
    pub report_date: DateTime<Utc>,
    pub summary: String,
    pub mood_trend_note: String,
    pub recommendations: Vec<String>,
    pub cited_insight_ids: Vec<Uuid>,
    /// Set by the safety pass in `mental-analysis-engine::safety` when
    /// crisis-risk language was detected in the source journal/chat text.
    pub crisis_flag: bool,
    pub generated_at: DateTime<Utc>,
    /// ISO-639-1 code the report text actually came back in — the account's
    /// language at generation time, not necessarily its language now. Lets
    /// a later reader (after switching the interface language) tell that
    /// this stored copy needs translating rather than regenerating.
    #[serde(default = "default_language")]
    pub language: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LifeAnalysis {
    pub id: Uuid,
    pub user_id: Uuid,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
    pub narrative: String,
    pub key_patterns: Vec<String>,
    /// Concrete "keep doing / start doing" guidance.
    pub do_list: Vec<String>,
    /// Concrete "this is working against you" guidance. Separate from
    /// `do_list` because the UI contrasts them, and because a mixed list
    /// reads as a lecture.
    pub dont_list: Vec<String>,
    pub generated_at: DateTime<Utc>,
    /// Same purpose as [`DailyMentalReport::language`].
    #[serde(default = "default_language")]
    pub language: String,
}

fn default_language() -> String {
    "tr".to_string()
}
