use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// One user's login credentials. Kept as its own table (not folded into
/// `User`) so a future "sign in with Apple/Google, no password" path
/// doesn't need a schema change — it would just be a row with no
/// `password_hash` and a different credential kind.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Credentials {
    pub user_id: Uuid,
    pub email: String,
    pub password_hash: String,
    pub created_at: DateTime<Utc>,
}

/// A pending sign-up verification: the hash of the code emailed to `email`
/// and the bookkeeping that limits how often it can be requested or guessed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EmailCodeRecord {
    pub email: String,
    pub code_hash: String,
    pub expires_at: DateTime<Utc>,
    /// Wrong guesses since this code was issued.
    pub attempts: u32,
    pub last_sent_at: DateTime<Utc>,
    /// Start of the current hourly window for counting sends to this address.
    pub window_started_at: DateTime<Utc>,
    pub sends_in_window: u32,
}

/// An opaque bearer token issued on register/login. There is no refresh
/// flow yet — a session is valid until `expires_at` and the client just
/// has to log in again after that. Deliberately simple (a random token
/// in a table) rather than a signed JWT: it means a session can be
/// revoked server-side just by deleting the row, which a stateless JWT
/// can't do without an extra denylist anyway.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
    pub token: String,
    pub user_id: Uuid,
    pub created_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
}
