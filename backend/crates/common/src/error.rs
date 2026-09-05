use thiserror::Error;

/// Shared application error type. Individual crates define their own
/// domain-specific errors and convert into this at module boundaries
/// (API handlers, job runners) so callers get one consistent shape.
#[derive(Debug, Error)]
pub enum AppError {
    #[error("not found: {0}")]
    NotFound(String),

    #[error("invalid input: {0}")]
    InvalidInput(String),

    #[error("upstream service error: {0}")]
    Upstream(String),

    #[error("storage error: {0}")]
    Storage(#[from] anyhow::Error),
}

pub type AppResult<T> = Result<T, AppError>;
