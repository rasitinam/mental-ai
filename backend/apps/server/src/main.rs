mod auth;
mod routes;
mod scheduler;
mod state;

use std::sync::Arc;

use mental_common::AppConfig;
use mental_knowledge_base::{Embedder, SqliteVectorStore};
use mental_llm_connector::openai_compatible::OpenAiCompatibleProvider;
use mental_llm_connector::LlmProvider;
use mental_storage::{
    init_pool, SqliteActivityRepository, SqliteAssessmentRepository, SqliteAuthRepository,
    SqliteChatRepository, SqliteContentTranslationRepository, SqliteDmRepository,
    SqliteExplainerRepository, SqliteInsightRepository, SqliteJournalRepository,
    SqliteLifeAnalysisRepository, SqliteLifeStoryRepository, SqliteMoodRepository,
    SqlitePushTokenRepository, SqliteReportRepository, SqliteResearchRepository,
    SqliteSocialRepository, SqliteSubscriptionRepository, SqliteUserRepository,
    SqliteUserStateRepository,
};
use tower_http::{
    cors::CorsLayer,
    services::{ServeDir, ServeFile},
    trace::TraceLayer,
};

use state::{AppState, AppleIapState};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    mental_common::telemetry::init_tracing();

    let config = AppConfig::load()?;
    tracing::info!("configuration loaded, starting mental-ai-server");

    let pool = init_pool(&config.database.url).await?;

    let api_key = std::env::var(&config.llm.api_key_env).unwrap_or_default();
    if api_key.is_empty() {
        tracing::warn!(
            "no API key found in ${}; LLM-backed endpoints will fail until it is set",
            config.llm.api_key_env
        );
    }

    let llm: Arc<dyn LlmProvider> = Arc::new(OpenAiCompatibleProvider::new(
        config.llm.base_url.clone(),
        api_key,
        config.llm.chat_model.clone(),
        config.llm.embedding_model.clone(),
    ));

    let apple_shared_secret = std::env::var(&config.apple_iap.shared_secret_env).unwrap_or_default();
    if apple_shared_secret.is_empty() {
        tracing::warn!(
            "no Apple shared secret found in ${}; receipt verification will fail until it is set",
            config.apple_iap.shared_secret_env
        );
    }

    let state = AppState {
        users: Arc::new(SqliteUserRepository::new(pool.clone())),
        auth: Arc::new(SqliteAuthRepository::new(pool.clone())),
        moods: Arc::new(SqliteMoodRepository::new(pool.clone())),
        journals: Arc::new(SqliteJournalRepository::new(pool.clone())),
        reports: Arc::new(SqliteReportRepository::new(pool.clone())),
        research: Arc::new(SqliteResearchRepository::new(pool.clone())),
        insights: Arc::new(SqliteInsightRepository::new(pool.clone())),
        life_analyses: Arc::new(SqliteLifeAnalysisRepository::new(pool.clone())),
        chats: Arc::new(SqliteChatRepository::new(pool.clone())),
        explainers: Arc::new(SqliteExplainerRepository::new(pool.clone())),
        user_states: Arc::new(SqliteUserStateRepository::new(pool.clone())),
        life_stories: Arc::new(SqliteLifeStoryRepository::new(pool.clone())),
        social: Arc::new(SqliteSocialRepository::new(pool.clone())),
        dms: Arc::new(SqliteDmRepository::new(pool.clone())),
        activity: Arc::new(SqliteActivityRepository::new(pool.clone())),
        assessments: Arc::new(SqliteAssessmentRepository::new(pool.clone())),
        vector_store: Arc::new(SqliteVectorStore::new(pool.clone())),
        embedder: Arc::new(Embedder::new(llm.clone())),
        llm,
        push_tokens: Arc::new(SqlitePushTokenRepository::new(pool.clone())),
        // The path a `firebase-service-account.json` dropped in the
        // backend's working directory ends up at — see `.gitignore`.
        // Missing file means push notifications are silently disabled
        // rather than the server failing to start over an optional
        // feature.
        push: mental_push::build_provider("firebase-service-account.json"),
        content_translations: Arc::new(SqliteContentTranslationRepository::new(pool.clone())),
        subscriptions: Arc::new(SqliteSubscriptionRepository::new(pool.clone())),
        apple_iap: AppleIapState {
            shared_secret: apple_shared_secret,
            bundle_id: config.apple_iap.bundle_id.clone(),
        },
    };

    if config.research_ingest.enabled {
        scheduler::spawn_research_ingest_job(state.clone(), config.research_ingest.clone()).await?;
    }

    scheduler::spawn_explainer_warmup_job(state.clone());
    scheduler::spawn_checkin_nudge_job(state.clone());

    let mut app = routes::build_router(state);

    // Optional: serve a `flutter build web` output for any request that
    // isn't one of the API routes above, so the web app and its API share
    // one origin — one dev tunnel (see codemagic.yaml's sibling, the
    // ngrok setup this is meant for) instead of needing two, and no
    // separate static host for a real deployment either. Falls back to
    // `index.html` for any unmatched path so Flutter's own client-side
    // routing (e.g. a direct link to `/stories`) still resolves.
    if let Some(web_root) = &config.server.web_root {
        let index = format!("{web_root}/index.html");
        app = app.fallback_service(ServeDir::new(web_root).not_found_service(ServeFile::new(index)));
    }

    let app = app.layer(CorsLayer::permissive()).layer(TraceLayer::new_for_http());

    let addr = format!("{}:{}", config.server.host, config.server.port);
    tracing::info!("listening on {addr}");
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
