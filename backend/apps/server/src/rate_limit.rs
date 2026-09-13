use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{Duration, Instant};

/// A blunt, in-process defense against automated password guessing on
/// `/auth/login`: once an email has racked up too many wrong passwords
/// inside the window, further attempts for that email are rejected
/// without even touching Argon2, until the oldest of them ages out.
///
/// Deliberately simple — an in-memory map, not an external store — so it
/// resets on restart and doesn't coordinate across multiple server
/// processes. That's the right tradeoff for this app's current
/// single-process deployment; a horizontally-scaled deployment would need
/// this backed by something shared (Redis, the database itself) instead.
pub struct LoginRateLimiter {
    attempts: Mutex<HashMap<String, Vec<Instant>>>,
}

const MAX_ATTEMPTS: usize = 8;
const WINDOW: Duration = Duration::from_secs(15 * 60);

impl LoginRateLimiter {
    pub fn new() -> Self {
        Self { attempts: Mutex::new(HashMap::new()) }
    }

    /// Whether `key` (a normalized email) has room for another attempt
    /// right now. Also prunes attempts outside the window for `key`, so a
    /// key that's gone quiet doesn't hold a stale entry forever.
    pub fn allow(&self, key: &str) -> bool {
        let mut attempts = self.attempts.lock().unwrap_or_else(|e| e.into_inner());
        let now = Instant::now();
        let entry = attempts.entry(key.to_string()).or_default();
        entry.retain(|t| now.duration_since(*t) < WINDOW);
        entry.len() < MAX_ATTEMPTS
    }

    pub fn record_failure(&self, key: &str) {
        let mut attempts = self.attempts.lock().unwrap_or_else(|e| e.into_inner());
        attempts.entry(key.to_string()).or_default().push(Instant::now());
    }

    /// Clears `key`'s record on a correct password — a person who
    /// mistypes a few times and then gets it right shouldn't stay
    /// partway toward a lockout for the next fifteen minutes.
    pub fn record_success(&self, key: &str) {
        let mut attempts = self.attempts.lock().unwrap_or_else(|e| e.into_inner());
        attempts.remove(key);
    }
}

impl Default for LoginRateLimiter {
    fn default() -> Self {
        Self::new()
    }
}
