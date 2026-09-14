-- Three of the engagement features land here, each as a few columns or
-- one table. The fourth (the pre-session summary) is generated on demand
-- and stores nothing.
--
-- 1. Evening check-in reminder, chosen per person instead of one fixed
--    UTC hour for everyone. `utc_offset_minutes` starts at Turkey (UTC+3)
--    until the app reports the device's real offset on its next launch.
--    `checkin_reminder_last_sent` is the *local* calendar date of the last
--    reminder, so the hourly job can never send two on the same day.
ALTER TABLE users ADD COLUMN checkin_reminder_enabled INTEGER NOT NULL DEFAULT 1;
ALTER TABLE users ADD COLUMN checkin_reminder_hour INTEGER NOT NULL DEFAULT 21;
ALTER TABLE users ADD COLUMN utc_offset_minutes INTEGER NOT NULL DEFAULT 180;
ALTER TABLE users ADD COLUMN checkin_reminder_last_sent TEXT;

-- 2. "Bende de oldu": a reader saying a story is theirs too, with an
--    optional note picked from a fixed list (`life_story::METOO_NOTES`).
--    Never free text, so it needs no moderation queue of its own. Like
--    `story_reactions`, one row per (story, reader).
CREATE TABLE IF NOT EXISTS story_metoo (
    story_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL,
    PRIMARY KEY (story_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_story_metoo_story ON story_metoo(story_id);

-- 3. "Seni iyi hissettirenler" cards, cached per account: building them
--    reads weeks of history, and the answer barely moves within a day.
CREATE TABLE IF NOT EXISTS discoveries (
    user_id TEXT PRIMARY KEY,
    language TEXT NOT NULL,
    cards TEXT NOT NULL,
    generated_at TEXT NOT NULL
);
