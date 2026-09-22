//! Regression tests for the read paths whose *order* the AI features depend
//! on. They run against a real SQLite file (the migrations included), since
//! the order lives in the SQL.

use chrono::{Duration, Utc};
use mental_domain::repository::{ChatRepository, UserRepository};
use mental_domain::{ChatMessageRecord, ChatRole, DmPolicy, User};
use uuid::Uuid;

use crate::{init_pool, SqliteChatRepository, SqliteUserRepository};

fn user(id: Uuid) -> User {
    User {
        id,
        display_name: "Test".to_string(),
        timezone: "UTC".to_string(),
        diagnoses: vec![],
        language: "tr".to_string(),
        birth_year: None,
        is_admin: false,
        avatar_content_type: None,
        dm_policy: DmPolicy::Everyone,
        chat_boundaries: vec![],
        chat_boundary_note: None,
        checkin_reminder_enabled: true,
        checkin_reminder_hour: 21,
        utc_offset_minutes: 180,
        created_at: Utc::now(),
    }
}

#[tokio::test]
async fn chat_history_is_the_newest_messages_oldest_first() {
    let path = std::env::temp_dir().join(format!("hearth-history-{}.db", Uuid::new_v4()));
    let url = format!("sqlite://{}?mode=rwc", path.display().to_string().replace('\\', "/"));
    let pool = init_pool(&url).await.expect("pool");

    let user_id = Uuid::new_v4();
    SqliteUserRepository::new(pool.clone()).upsert(&user(user_id)).await.expect("user");

    let chats = SqliteChatRepository::new(pool.clone());
    let start = Utc::now() - Duration::hours(1);
    for i in 0..10 {
        chats
            .add(&ChatMessageRecord {
                id: Uuid::new_v4(),
                user_id,
                role: if i % 2 == 0 { ChatRole::User } else { ChatRole::Assistant },
                content: format!("m{i}"),
                crisis_flag: false,
                created_at: start + Duration::minutes(i),
            })
            .await
            .expect("add");
    }

    // The newest three, in reading order — not the oldest three.
    let latest: Vec<String> = chats.history_for_user(user_id, 3).await.expect("history").into_iter().map(|m| m.content).collect();
    assert_eq!(latest, ["m7", "m8", "m9"]);

    // A limit above the count returns everything, still oldest first.
    let all: Vec<String> = chats.history_for_user(user_id, 500).await.expect("history").into_iter().map(|m| m.content).collect();
    assert_eq!(all.len(), 10);
    assert_eq!(all.first().map(String::as_str), Some("m0"));
    assert_eq!(all.last().map(String::as_str), Some("m9"));

    pool.close().await;
    let _ = std::fs::remove_file(&path);
}
