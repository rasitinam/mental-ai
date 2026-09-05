use thiserror::Error;

#[derive(Debug, Error)]
pub enum LlmError {
    #[error("missing API key: set the {0} environment variable")]
    MissingApiKey(String),

    #[error("request to LLM provider failed: {0}")]
    Request(#[from] reqwest::Error),

    #[error("LLM provider returned an error: {0}")]
    Provider(String),

    #[error("failed to parse LLM response: {0}")]
    Parse(String),
}
