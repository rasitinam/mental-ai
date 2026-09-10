#[derive(Debug, thiserror::Error)]
pub enum PushError {
    #[error("push credentials not configured: {0}")]
    NotConfigured(String),
    #[error("failed to sign auth token: {0}")]
    Signing(#[from] jsonwebtoken::errors::Error),
    #[error("token exchange failed: {0}")]
    TokenExchange(String),
    #[error("http error: {0}")]
    Http(#[from] reqwest::Error),
    #[error("fcm rejected the message: {0}")]
    Rejected(String),
}
