use chrono::Utc;
use mental_domain::repository::UserRepository;
use mental_domain::User;
use uuid::Uuid;

use crate::state::AppState;

/// The app is local-first with no separate sign-up step — the Flutter
/// client generates a random id on first launch and just starts sending
/// it. `ensure_user` is called at the top of every handler that touches
/// user-scoped data so a `users` row always exists before anything
/// references it as a foreign key, without requiring a dedicated
/// "register" call the client would have to remember to make first.
/// Cheap: `UserRepository::upsert` is a single `INSERT ... ON CONFLICT`
/// that leaves `created_at` untouched on repeat calls.
pub async fn ensure_user(state: &AppState, user_id: Uuid) -> anyhow::Result<()> {
    state
        .users
        .upsert(&User {
            id: user_id,
            display_name: "Kullanıcı".to_string(),
            timezone: "UTC".to_string(),
            created_at: Utc::now(),
        })
        .await
}
