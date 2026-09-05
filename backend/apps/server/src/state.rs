use std::sync::Arc;

use mental_knowledge_base::{Embedder, SqliteVectorStore};
use mental_llm_connector::LlmProvider;
use mental_storage::{
    SqliteInsightRepository, SqliteJournalRepository, SqliteLifeAnalysisRepository,
    SqliteMoodRepository, SqliteReportRepository, SqliteResearchRepository, SqliteUserRepository,
};

/// Composition root: the one place that knows every concrete
/// implementation. Every axum handler and background job receives this
/// (or a field of it) instead of constructing dependencies itself, so
/// swapping an implementation (e.g. a different `LlmProvider`) means
/// changing `build()`, not every call site.
#[derive(Clone)]
pub struct AppState {
    pub users: Arc<SqliteUserRepository>,
    pub moods: Arc<SqliteMoodRepository>,
    pub journals: Arc<SqliteJournalRepository>,
    pub reports: Arc<SqliteReportRepository>,
    pub research: Arc<SqliteResearchRepository>,
    pub insights: Arc<SqliteInsightRepository>,
    pub life_analyses: Arc<SqliteLifeAnalysisRepository>,
    pub vector_store: Arc<SqliteVectorStore>,
    pub llm: Arc<dyn LlmProvider>,
    pub embedder: Arc<Embedder>,
}
