use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A short, user-facing educational card distilled from one or more
/// `ResearchArticle`s by the analysis engine. Always carries a citation
/// back to its source so the app can show "based on: <source>" in the UI.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Insight {
    pub id: Uuid,
    pub title: String,
    pub body: String,
    pub source_article_ids: Vec<Uuid>,
    pub tags: Vec<String>,
    pub created_at: DateTime<Utc>,
}
