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
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LifeAnalysis {
    pub id: Uuid,
    pub user_id: Uuid,
    pub period_start: DateTime<Utc>,
    pub period_end: DateTime<Utc>,
    pub narrative: String,
    pub key_patterns: Vec<String>,
    pub generated_at: DateTime<Utc>,
}
