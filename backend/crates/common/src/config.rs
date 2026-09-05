use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub llm: LlmConfig,
    pub research_ingest: ResearchIngestConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Clone, Deserialize)]
pub struct DatabaseConfig {
    /// e.g. "sqlite://data/mental_ai.db"
    pub url: String,
}

/// Configuration for the pluggable LLM backend. `provider` selects the
/// implementation in `mental-llm-connector` (currently "openai-compatible",
/// which works for OpenAI, Azure OpenAI, and any OpenAI-schema-compatible
/// endpoint). Secrets (`api_key`) are read from the environment, never
/// committed to config files.
#[derive(Debug, Clone, Deserialize)]
pub struct LlmConfig {
    pub provider: String,
    pub base_url: String,
    pub chat_model: String,
    pub embedding_model: String,
    #[serde(default)]
    pub api_key_env: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ResearchIngestConfig {
    pub enabled: bool,
    pub interval_hours: u64,
    pub sources: Vec<String>,
}

impl AppConfig {
    /// Loads config by layering `config/default.toml`, an optional
    /// `config/local.toml` (git-ignored, for machine-specific overrides),
    /// and `MENTAL_AI__*` environment variables (double underscore as the
    /// nested-key separator, e.g. `MENTAL_AI__SERVER__PORT=9090`).
    pub fn load() -> anyhow::Result<Self> {
        let cfg = config::Config::builder()
            .add_source(config::File::with_name("config/default"))
            .add_source(config::File::with_name("config/local").required(false))
            .add_source(config::Environment::with_prefix("MENTAL_AI").separator("__"))
            .build()?;

        Ok(cfg.try_deserialize()?)
    }
}
