CREATE TABLE IF NOT EXISTS life_analyses (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    period_start TEXT NOT NULL,
    period_end TEXT NOT NULL,
    narrative TEXT NOT NULL,
    key_patterns TEXT NOT NULL DEFAULT '[]',
    generated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_life_analyses_user_date ON life_analyses(user_id, generated_at);
