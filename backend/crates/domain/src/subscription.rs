use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// The account's current entitlement, as last confirmed by validating a
/// store receipt. Deliberately carries no separate "active"/"expired"
/// flag — [`Subscription::is_active`] derives it from `expires_at`, the
/// same "don't store what you can compute" choice the mood/journal
/// cooldowns make, so there's no stale-flag bug to worry about.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Subscription {
    pub user_id: Uuid,
    /// "apple" today; "google" once Android sells the same subscription.
    pub platform: String,
    pub product_id: String,
    /// Apple's stable id for a subscription across renewals and price
    /// changes — see `migrations/0019_subscriptions.sql`.
    pub original_transaction_id: String,
    pub expires_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Subscription {
    pub fn is_active(&self) -> bool {
        self.expires_at > Utc::now()
    }
}
