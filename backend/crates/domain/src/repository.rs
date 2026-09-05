//! Repository ports (hexagonal-architecture "driven" side). Every crate
//! that needs persistence depends on these traits, not on `mental-storage`
//! directly — `mental-storage` is wired in only at the composition root
//! (`apps/server/src/state.rs`). This keeps `analysis-engine` and
//! `research-ingest` unit-testable with in-memory fakes.

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::{DailyMentalReport, Insight, JournalEntry, MoodEntry, ResearchArticle, User};

#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn get(&self, id: Uuid) -> anyhow::Result<Option<User>>;
    async fn upsert(&self, user: &User) -> anyhow::Result<()>;
}

#[async_trait]
pub trait MoodRepository: Send + Sync {
    async fn add(&self, entry: &MoodEntry) -> anyhow::Result<()>;
    async fn list_between(
        &self,
        user_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> anyhow::Result<Vec<MoodEntry>>;
}

#[async_trait]
pub trait JournalRepository: Send + Sync {
    async fn add(&self, entry: &JournalEntry) -> anyhow::Result<()>;
    async fn update_themes(&self, id: Uuid, themes: Vec<String>) -> anyhow::Result<()>;
    async fn list_between(
        &self,
        user_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> anyhow::Result<Vec<JournalEntry>>;
}

#[async_trait]
pub trait ReportRepository: Send + Sync {
    async fn save(&self, report: &DailyMentalReport) -> anyhow::Result<()>;
    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<DailyMentalReport>>;
}

#[async_trait]
pub trait ResearchRepository: Send + Sync {
    async fn upsert_many(&self, articles: &[ResearchArticle]) -> anyhow::Result<()>;
    async fn exists(&self, source: &str, external_id: &str) -> anyhow::Result<bool>;
}

#[async_trait]
pub trait InsightRepository: Send + Sync {
    async fn save(&self, insight: &Insight) -> anyhow::Result<()>;
    async fn recent(&self, limit: u32) -> anyhow::Result<Vec<Insight>>;
}
