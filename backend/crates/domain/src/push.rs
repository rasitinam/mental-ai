use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// One device's FCM registration token. `platform` is informational only
/// today (nothing branches on it yet) but costs nothing to keep, and
/// matters the day APNs needs different handling than FCM.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PushToken {
    pub token: String,
    pub user_id: Uuid,
    pub platform: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
