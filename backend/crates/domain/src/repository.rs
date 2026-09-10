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
    ChatMessageRecord, Credentials, DailyMentalReport, DisorderExplainer, DmMessage, DmPolicy,
    DmStatus, DmThread, Insight, JournalEntry, LifeStory, LifeStoryReport, MoodEntry,
    ResearchArticle, Session, StoryFeedItem, StoryStatus, User, UserState, WellbeingAssessment,
};

#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn get(&self, id: Uuid) -> anyhow::Result<Option<User>>;
    async fn upsert(&self, user: &User) -> anyhow::Result<()>;
    /// Replaces the whole self-reported diagnosis list — the profile screen
    /// edits it as a set, so a partial update would just be a second way to
    /// get the same result wrong.
    async fn set_diagnoses(&self, user_id: Uuid, diagnoses: &[String]) -> anyhow::Result<()>;
    /// Display name, language, birth year and DM policy, each optional to
    /// change independently: `None` leaves that field as it is rather
    /// than clearing it.
    async fn set_preferences(
        &self,
        user_id: Uuid,
        display_name: Option<&str>,
        language: Option<&str>,
        birth_year: Option<i32>,
        dm_policy: Option<DmPolicy>,
    ) -> anyhow::Result<()>;
    /// Records which Content-Type the just-uploaded avatar file was saved
    /// with, or clears it (`None`) — the image bytes themselves are written
    /// straight to disk by the route handler, not through this trait.
    async fn set_avatar(&self, user_id: Uuid, content_type: Option<&str>) -> anyhow::Result<()>;
}

#[async_trait]
pub trait AuthRepository: Send + Sync {
    async fn create_credentials(&self, credentials: &Credentials) -> anyhow::Result<()>;
    async fn find_credentials_by_email(&self, email: &str) -> anyhow::Result<Option<Credentials>>;
    /// The address an account signs in with, for showing it back on the
    /// profile screen. Sign-in itself always goes the other way round.
    async fn find_email_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<String>>;
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
    /// Slugs that already have a cached card. The warm-up job walks the
    /// catalog against this so it only spends LLM calls on what's missing
    /// instead of regenerating the whole list on every boot.
    async fn cached_slugs(&self) -> anyhow::Result<Vec<String>>;
    /// Cards generated before `cutoff`, oldest first. The research corpus
    /// keeps growing underneath these, so a card written months ago is
    /// grounded in a smaller evidence base than one written today.
    async fn stale_slugs(&self, cutoff: DateTime<Utc>, limit: u32) -> anyhow::Result<Vec<String>>;
}

#[async_trait]
pub trait UserStateRepository: Send + Sync {
    async fn get(&self, user_id: Uuid) -> anyhow::Result<Option<UserState>>;
    /// One row per user, replaced wholesale — this is the current snapshot,
    /// not an append-only log.
    async fn save(&self, state: &UserState) -> anyhow::Result<()>;
}

#[async_trait]
pub trait LifeAnalysisRepository: Send + Sync {
    async fn save(&self, analysis: &LifeAnalysis) -> anyhow::Result<()>;
    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<LifeAnalysis>>;
}

#[async_trait]
pub trait AssessmentRepository: Send + Sync {
    async fn save(&self, assessment: &WellbeingAssessment) -> anyhow::Result<()>;
    /// Most recent screening on file, for both showing "you last checked
    /// in N days ago" and for feeding `PersonContext`.
    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<WellbeingAssessment>>;
}

#[async_trait]
pub trait ActivityRepository: Send + Sync {
    /// Per-day counts of everything someone did from `since` onward —
    /// mood check-ins, journal entries and their own chat messages
    /// together — as `(yyyy-mm-dd, count)` in ascending date order.
    /// One query across the three tables rather than three round trips
    /// the caller then has to merge.
    async fn daily_counts(
        &self,
        user_id: Uuid,
        since: DateTime<Utc>,
    ) -> anyhow::Result<Vec<(String, u32)>>;
}

#[async_trait]
pub trait LifeStoryRepository: Send + Sync {
    async fn create(&self, story: &LifeStory) -> anyhow::Result<()>;
    async fn get(&self, id: Uuid) -> anyhow::Result<Option<LifeStory>>;
    /// Approved stories only, newest first — the public feed.
    async fn list_approved(&self, limit: u32) -> anyhow::Result<Vec<LifeStory>>;
    /// One author's own submissions regardless of status, newest first.
    async fn list_for_user(&self, user_id: Uuid) -> anyhow::Result<Vec<LifeStory>>;
    /// The moderation queue: everything still pending, oldest first, so
    /// the longest-waiting submission surfaces first.
    async fn list_pending(&self) -> anyhow::Result<Vec<LifeStory>>;
    async fn set_status(
        &self,
        id: Uuid,
        status: StoryStatus,
        reviewed_at: DateTime<Utc>,
    ) -> anyhow::Result<()>;
    /// Scoped to `user_id` in the query itself, so deleting someone
    /// else's story by id is a no-op rather than something the caller
    /// has to check for separately.
    async fn delete(&self, id: Uuid, user_id: Uuid) -> anyhow::Result<()>;
    async fn add_report(&self, report: &LifeStoryReport) -> anyhow::Result<()>;
    /// Every open report, newest first — the admin queue for
    /// already-published stories a reader flagged.
    async fn list_reports(&self) -> anyhow::Result<Vec<LifeStoryReport>>;
    /// The reader's own copy of the feed: approved stories with their
    /// vote tally, whether `viewer` voted, and the author's name where
    /// the story isn't anonymous — one query instead of three per row.
    async fn feed_for(&self, viewer: Uuid, limit: u32) -> anyhow::Result<Vec<StoryFeedItem>>;
    /// How many approved stories one author has in the public feed.
    async fn approved_count_for(&self, user_id: Uuid) -> anyhow::Result<u32>;
    /// A cached translation, if this story has already been translated
    /// into `target_language` for a previous reader.
    async fn get_translation(
        &self,
        story_id: Uuid,
        target_language: &str,
    ) -> anyhow::Result<Option<String>>;
    /// Caches a translation so the LLM is called at most once per
    /// (story, language) pair rather than once per reader.
    async fn save_translation(
        &self,
        story_id: Uuid,
        target_language: &str,
        body: &str,
    ) -> anyhow::Result<()>;
}

/// Follows and upvotes: the two things that make the story feed social
/// rather than a noticeboard. Kept apart from [`LifeStoryRepository`]
/// because a follow isn't about a story at all.
#[async_trait]
pub trait SocialRepository: Send + Sync {
    async fn follow(&self, follower: Uuid, followee: Uuid) -> anyhow::Result<()>;
    async fn unfollow(&self, follower: Uuid, followee: Uuid) -> anyhow::Result<()>;
    async fn is_following(&self, follower: Uuid, followee: Uuid) -> anyhow::Result<bool>;
    async fn follower_count(&self, user_id: Uuid) -> anyhow::Result<u32>;
    async fn following_count(&self, user_id: Uuid) -> anyhow::Result<u32>;
    /// Accounts following `user_id`, newest follow first.
    async fn followers(&self, user_id: Uuid) -> anyhow::Result<Vec<Uuid>>;
    /// Accounts `user_id` follows, newest follow first.
    async fn following(&self, user_id: Uuid) -> anyhow::Result<Vec<Uuid>>;
    /// Idempotent: voting twice is the same as voting once, so a
    /// double-tap can't inflate a tally.
    async fn upvote(&self, story_id: Uuid, user_id: Uuid) -> anyhow::Result<()>;
    async fn remove_upvote(&self, story_id: Uuid, user_id: Uuid) -> anyhow::Result<()>;
}

/// Direct messages, with the request gate built into the thread's own
/// status rather than a separate "requests" table — a request *is* the
/// thread, it just hasn't been accepted yet.
#[async_trait]
pub trait DmRepository: Send + Sync {
    async fn thread_between(&self, a: Uuid, b: Uuid) -> anyhow::Result<Option<DmThread>>;
    async fn get_thread(&self, id: Uuid) -> anyhow::Result<Option<DmThread>>;
    async fn create_thread(&self, thread: &DmThread) -> anyhow::Result<()>;
    async fn accept_thread(&self, id: Uuid) -> anyhow::Result<()>;
    /// Declining removes the thread and its messages outright.
    async fn delete_thread(&self, id: Uuid) -> anyhow::Result<()>;
    /// Threads `user_id` is part of at the given status, most recently
    /// active first.
    async fn threads_for(&self, user_id: Uuid, status: DmStatus) -> anyhow::Result<Vec<DmThread>>;
    async fn add_message(&self, message: &DmMessage, sent_at: DateTime<Utc>) -> anyhow::Result<()>;
    /// A thread's messages, oldest first.
    async fn messages(&self, thread_id: Uuid, limit: u32) -> anyhow::Result<Vec<DmMessage>>;
    /// The most recent message in each of `thread_ids`, for list previews.
    async fn latest_messages(&self, thread_ids: &[Uuid]) -> anyhow::Result<Vec<DmMessage>>;
}
