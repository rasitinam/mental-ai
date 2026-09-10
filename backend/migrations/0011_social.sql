-- Optional anonymity. Existing rows default to 1: anonymous is the only
-- mode they were ever submitted under, so silently attaching names to
-- stories written under the old promise would be the wrong migration.
ALTER TABLE life_stories ADD COLUMN anonymous INTEGER NOT NULL DEFAULT 1;

-- Upvotes only — one per person per story, and no downvote table on
-- purpose. A feed of mental-health accounts is not somewhere a "this was
-- unhelpful" button belongs.
CREATE TABLE IF NOT EXISTS story_upvotes (
    story_id TEXT NOT NULL REFERENCES life_stories(id),
    user_id TEXT NOT NULL REFERENCES users(id),
    created_at TEXT NOT NULL,
    PRIMARY KEY (story_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_story_upvotes_story ON story_upvotes(story_id);

CREATE TABLE IF NOT EXISTS follows (
    follower_id TEXT NOT NULL REFERENCES users(id),
    followee_id TEXT NOT NULL REFERENCES users(id),
    created_at TEXT NOT NULL,
    PRIMARY KEY (follower_id, followee_id)
);
CREATE INDEX IF NOT EXISTS idx_follows_followee ON follows(followee_id);

-- One thread per pair, with the ids stored in sorted order so (A,B) and
-- (B,A) can't become two threads. `status` is the whole request system:
-- a thread opens as 'pending' carrying its first message, and only the
-- recipient can move it to 'accepted'. Declining deletes the row.
--
-- There is deliberately no read/seen column anywhere in here.
CREATE TABLE IF NOT EXISTS dm_threads (
    id TEXT PRIMARY KEY,
    user_low TEXT NOT NULL REFERENCES users(id),
    user_high TEXT NOT NULL REFERENCES users(id),
    started_by TEXT NOT NULL REFERENCES users(id),
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TEXT NOT NULL,
    last_message_at TEXT NOT NULL,
    UNIQUE (user_low, user_high)
);

CREATE TABLE IF NOT EXISTS dm_messages (
    id TEXT PRIMARY KEY,
    thread_id TEXT NOT NULL REFERENCES dm_threads(id),
    sender_id TEXT NOT NULL REFERENCES users(id),
    body TEXT NOT NULL,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_dm_messages_thread ON dm_messages(thread_id, created_at);

-- 'everyone' | 'following' — who is allowed to open a request at all.
ALTER TABLE users ADD COLUMN dm_policy TEXT NOT NULL DEFAULT 'everyone';
