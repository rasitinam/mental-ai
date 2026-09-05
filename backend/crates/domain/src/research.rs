use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A normalized record from one research source (PubMed, WHO, APA, ...),
/// as ingested by `mental-research-ingest` and embedded/indexed by
/// `mental-knowledge-base`. Only open-access abstracts/metadata are
/// stored — never full copyrighted article text.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResearchArticle {
    pub id: Uuid,
    pub source: String,
    pub external_id: String,
    pub title: String,
    pub abstract_text: String,
    pub url: String,
    pub published_at: Option<DateTime<Utc>>,
    pub tags: Vec<String>,
    pub ingested_at: DateTime<Utc>,
}
