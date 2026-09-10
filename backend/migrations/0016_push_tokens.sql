-- One row per device that has granted notification permission and handed
-- the app an FCM registration token. `token` is the primary key rather
-- than `id`: the same physical device re-registering (app restart, token
-- refresh from Firebase) is an upsert, not a new row, and the same token
-- can only ever belong to one account at a time — logging in as someone
-- else on the same device reassigns it rather than doubling it up.
CREATE TABLE IF NOT EXISTS device_push_tokens (
    token TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    platform TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_device_push_tokens_user ON device_push_tokens(user_id);
