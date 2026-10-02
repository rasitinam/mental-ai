-- Reports about a person rather than a story: their profile (name, photo)
-- or what they wrote in a private conversation. App Store guideline 1.2
-- asks for a way to report objectionable content wherever people can reach
-- each other; stories already had one (`life_story_reports`).
--
-- `content` is a copy of what was reported, taken by the server at report
-- time, so the moderator sees exactly that even if it is edited or deleted
-- later. Removed with either account (see `SqliteAuthRepository::delete_account`).
CREATE TABLE IF NOT EXISTS user_reports (
    id TEXT PRIMARY KEY,
    reporter_id TEXT NOT NULL,
    reported_user_id TEXT NOT NULL,
    kind TEXT NOT NULL,            -- 'profile' | 'dm'
    content TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL,
    resolved_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_user_reports_open ON user_reports(resolved_at, created_at);
