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
    init_pool, SqliteAuthRepository, SqliteChatRepository, SqliteExplainerRepository,
    SqliteInsightRepository, SqliteJournalRepository, SqliteLifeAnalysisRepository,
    SqliteLifeStoryRepository, SqliteMoodRepository, SqliteReportRepository,
    SqliteResearchRepository, SqliteUserRepository, SqliteUserStateRepository,
};
use tower_http::{cors::CorsLayer, trace::TraceLayer};

use state::AppState;

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
        vector_store: Arc::new(SqliteVectorStore::new(pool.clone())),
        embedder: Arc::new(Embedder::new(llm.clone())),
        llm,
    };

    if config.research_ingest.enabled {
        scheduler::spawn_research_ingest_job(state.clone(), config.research_ingest.clone()).await?;
    }

    scheduler::spawn_explainer_warmup_job(state.clone());

    let app = routes::build_router(state)
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http());

    let addr = format!("{}:{}", config.server.host, config.server.port);
    tracing::info!("listening on {addr}");
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
