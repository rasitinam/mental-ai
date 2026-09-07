//! Repository ports (hexagonal-architecture "driven" side). Every crate
//! that needs persistence depends on these traits, not on `mental-storage`
//! directly — `mental-storage` is wired in only at the composition root
//! (`apps/server/src/state.rs`). This keeps `analysis-engine` and
//! `research-ingest` unit-testable with in-memory fakes.

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::report::LifeAnalysis;
use crate::{
    ChatMessageRecord, Credentials, DailyMentalReport, DisorderExplainer, Insight, JournalEntry,
    MoodEntry, ResearchArticle, Session, User,
};

#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn get(&self, id: Uuid) -> anyhow::Result<Option<User>>;
    async fn upsert(&self, user: &User) -> anyhow::Result<()>;
    /// Replaces the whole self-reported diagnosis list — the profile screen
    /// edits it as a set, so a partial update would just be a second way to
    /// get the same result wrong.
    async fn set_diagnoses(&self, user_id: Uuid, diagnoses: &[String]) -> anyhow::Result<()>;
}

#[async_trait]
pub trait AuthRepository: Send + Sync {
    async fn create_credentials(&self, credentials: &Credentials) -> anyhow::Result<()>;
    async fn find_credentials_by_email(&self, email: &str) -> anyhow::Result<Option<Credentials>>;
    async fn create_session(&self, session: &Session) -> anyhow::Result<()>;
    async fn find_session(&self, token: &str) -> anyhow::Result<Option<Session>>;
    async fn delete_session(&self, token: &str) -> anyhow::Result<()>;
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
    /// Most recent check-in regardless of window — used to enforce the
    /// once-per-24h cooldown (see `apps/server/src/routes/mood.rs`)
    /// without needing the caller to guess a `list_between` range.
    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<MoodEntry>>;
    /// Every check-in ever, oldest first — the life analysis covers the whole
    /// history rather than a rolling window.
    async fn list_all(&self, user_id: Uuid) -> anyhow::Result<Vec<MoodEntry>>;
}

#[async_trait]
pub trait ChatRepository: Send + Sync {
    async fn add(&self, message: &ChatMessageRecord) -> anyhow::Result<()>;
    /// The full durable transcript for a user, oldest first — used to
    /// rehydrate the chat screen on login/app restart so the conversation
    /// reads as one continuous thread instead of resetting every session.
    async fn history_for_user(&self, user_id: Uuid, limit: u32) -> anyhow::Result<Vec<ChatMessageRecord>>;
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
    /// Most recent entry, for the once-per-day cooldown.
    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<JournalEntry>>;
    /// Whole history, newest first — backs the date-by-date archive screen
    /// and the life analysis.
    async fn list_all(&self, user_id: Uuid) -> anyhow::Result<Vec<JournalEntry>>;
}

#[async_trait]
pub trait ReportRepository: Send + Sync {
    async fn save(&self, report: &DailyMentalReport) -> anyhow::Result<()>;
    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<DailyMentalReport>>;
    /// Past reports, newest first. Feeds two things: the "compared to previous
    /// days" line in a new daily report, and the life analysis.
    async fn list_recent(&self, user_id: Uuid, limit: u32) -> anyhow::Result<Vec<DailyMentalReport>>;
}

#[async_trait]
pub trait ResearchRepository: Send + Sync {
    async fn upsert_many(&self, articles: &[ResearchArticle]) -> anyhow::Result<()>;
    async fn exists(&self, source: &str, external_id: &str) -> anyhow::Result<bool>;
    /// Most recently ingested articles regardless of when — used to
    /// manually (re)synthesize insights from what's already in the
    /// knowledge base, for when a scheduled ingest cycle finds nothing
    /// "new" (everything was already fetched once) but the insight feed
    /// is still empty.
    async fn recent(&self, limit: u32) -> anyhow::Result<Vec<ResearchArticle>>;
    /// Resolves vector-search hits back to their text. `VectorStore::search`
    /// only returns ids and scores, so without this the "retrieval" half of
    /// RAG hands the model bare UUIDs it can't read anything out of.
    async fn get_many(&self, ids: &[Uuid]) -> anyhow::Result<Vec<ResearchArticle>>;
}

#[async_trait]
pub trait InsightRepository: Send + Sync {
    async fn save(&self, insight: &Insight) -> anyhow::Result<()>;
    async fn recent(&self, limit: u32) -> anyhow::Result<Vec<Insight>>;
    /// The feed filtered to one `catalog` category.
    async fn recent_in_category(&self, category: &str, limit: u32) -> anyhow::Result<Vec<Insight>>;
}

#[async_trait]
pub trait ExplainerRepository: Send + Sync {
    async fn get(&self, slug: &str) -> anyhow::Result<Option<DisorderExplainer>>;
    async fn save(&self, explainer: &DisorderExplainer) -> anyhow::Result<()>;
}

#[async_trait]
pub trait LifeAnalysisRepository: Send + Sync {
    async fn save(&self, analysis: &LifeAnalysis) -> anyhow::Result<()>;
    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<LifeAnalysis>>;
}
