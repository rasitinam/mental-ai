//! SQLite-backed implementations of the `mental_domain::repository` ports.
//! SQLite (not Postgres) is the default because the product runs
//! local-first on the user's own machine/device — no server-side database
//! to provision. Swapping in another backend later only means adding a
//! new module here; nothing outside this crate references SQLx directly.

pub mod pool;
pub mod repositories;

pub use pool::init_pool;
pub use repositories::{
    SqliteActivityRepository, SqliteAssessmentRepository, SqliteAuthRepository, SqliteChatRepository,
    SqliteChatUsageRepository, SqliteContentTranslationRepository, SqliteDiscoveryRepository,
    SqliteDmRepository,
    SqliteExplainerRepository, SqliteInsightRepository, SqliteJournalRepository,
    SqliteLifeAnalysisRepository, SqliteLifeStoryRepository, SqliteMoodRepository,
    SqlitePushTokenRepository, SqliteReportRepository, SqliteResearchRepository,
    SqliteSocialRepository, SqliteSubscriptionRepository, SqliteUserRepository,
    SqliteUserStateRepository,
};
