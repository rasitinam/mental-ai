use std::sync::Arc;

use mental_knowledge_base::{Embedder, SqliteVectorStore};
use mental_llm_connector::LlmProvider;
use mental_push::PushProvider;

use crate::rate_limit::LoginRateLimiter;
use mental_storage::{
    SqliteActivityRepository, SqliteAssessmentRepository, SqliteAuthRepository,
    SqliteChatRepository, SqliteChatUsageRepository, SqliteContentTranslationRepository,
    SqliteDiscoveryRepository,
    SqliteDmRepository, SqliteExplainerRepository, SqliteInsightRepository, SqliteJournalRepository,
    SqliteLifeAnalysisRepository, SqliteLifeStoryRepository, SqliteMoodRepository,
    SqlitePushTokenRepository, SqliteReportRepository, SqliteResearchRepository,
    SqliteSocialRepository, SqliteSubscriptionRepository, SqliteUserRepository,
    SqliteUserStateRepository,
};

/// Composition root: the one place that knows every concrete
/// implementation. Every axum handler and background job receives this
/// (or a field of it) instead of constructing dependencies itself, so
/// swapping an implementation (e.g. a different `LlmProvider`) means
/// changing `build()`, not every call site.
#[derive(Clone)]
pub struct AppState {
    pub users: Arc<SqliteUserRepository>,
    pub auth: Arc<SqliteAuthRepository>,
    pub moods: Arc<SqliteMoodRepository>,
    pub journals: Arc<SqliteJournalRepository>,
    pub reports: Arc<SqliteReportRepository>,
    pub research: Arc<SqliteResearchRepository>,
    pub insights: Arc<SqliteInsightRepository>,
    pub life_analyses: Arc<SqliteLifeAnalysisRepository>,
    pub chats: Arc<SqliteChatRepository>,
    pub explainers: Arc<SqliteExplainerRepository>,
    pub user_states: Arc<SqliteUserStateRepository>,
    pub life_stories: Arc<SqliteLifeStoryRepository>,
    pub social: Arc<SqliteSocialRepository>,
    pub dms: Arc<SqliteDmRepository>,
    pub activity: Arc<SqliteActivityRepository>,
    pub assessments: Arc<SqliteAssessmentRepository>,
    pub vector_store: Arc<SqliteVectorStore>,
    pub llm: Arc<dyn LlmProvider>,
    pub embedder: Arc<Embedder>,
    pub push_tokens: Arc<SqlitePushTokenRepository>,
    pub push: Arc<dyn PushProvider>,
    pub content_translations: Arc<SqliteContentTranslationRepository>,
    pub subscriptions: Arc<SqliteSubscriptionRepository>,
    /// Free-tier daily chat token budget tracking — see `routes::chat`.
    pub chat_usage: Arc<SqliteChatUsageRepository>,
    /// Cached "Seni iyi hissettirenler" cards — see `routes::discoveries`.
    pub discoveries: Arc<SqliteDiscoveryRepository>,
    /// Login brute-force guard — see `rate_limit::LoginRateLimiter`.
    pub login_rate_limiter: Arc<LoginRateLimiter>,
    /// App Store receipt validation config — the shared secret (empty when
    /// unconfigured, in which case `routes::purchases` rejects verification
    /// attempts outright rather than calling Apple with no password) and
    /// this app's own bundle id, checked against every verified receipt.
    pub apple_iap: AppleIapState,
    /// Apple's identity-token signing keys, for Sign in with Apple — see
    /// `apple_signin`. Verified against the same `apple_iap.bundle_id`.
    pub apple_keys: Arc<crate::apple_signin::AppleKeys>,
}

#[derive(Clone)]
pub struct AppleIapState {
    pub shared_secret: String,
    pub bundle_id: String,
}
