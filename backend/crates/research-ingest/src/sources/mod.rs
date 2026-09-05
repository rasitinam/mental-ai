pub mod pubmed;
pub mod who;

use async_trait::async_trait;
use chrono::{DateTime, Utc};

pub use pubmed::PubMedSource;
pub use who::WhoRssSource;

/// A not-yet-persisted article as returned by a source fetcher, before
/// `pipeline` assigns it a domain `Uuid` and hands it to storage.
#[derive(Debug, Clone)]
pub struct RawArticle {
    pub source: String,
    pub external_id: String,
    pub title: String,
    pub abstract_text: String,
    pub url: String,
    pub published_at: Option<DateTime<Utc>>,
    pub tags: Vec<String>,
}

#[async_trait]
pub trait ResearchSource: Send + Sync {
    fn name(&self) -> &'static str;
    async fn fetch_recent(&self) -> anyhow::Result<Vec<RawArticle>>;
}
