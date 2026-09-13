use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub llm: LlmConfig,
    pub research_ingest: ResearchIngestConfig,
    pub apple_iap: AppleIapConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    /// Directory holding a built `flutter build web` output (`index.html`
    /// plus its assets), served for any request that isn't one of the API
    /// routes below — so the API and the web app can share one origin
    /// (and, in dev, one ngrok tunnel) instead of needing two. Unset skips
    /// static serving entirely; nothing about the API changes either way.
    #[serde(default)]
    pub web_root: Option<String>,
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

/// Apple App Store receipt validation. `shared_secret_env` names the
/// environment variable holding the app's "App-Specific Shared Secret"
/// (App Store Connect → the app → Subscriptions → App-Specific Shared
/// Secret) — required by `verifyReceipt` for auto-renewable subscriptions,
/// never put in this file directly. `bundle_id` guards against a receipt
/// minted for a different app being replayed against this one.
#[derive(Debug, Clone, Deserialize)]
pub struct AppleIapConfig {
    #[serde(default)]
    pub shared_secret_env: String,
    pub bundle_id: String,
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
