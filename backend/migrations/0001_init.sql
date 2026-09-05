CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    timezone TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS mood_entries (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    valence REAL NOT NULL,
    arousal REAL NOT NULL,
    tags TEXT NOT NULL DEFAULT '[]',
    note TEXT,
    recorded_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_mood_entries_user_time ON mood_entries(user_id, recorded_at);

CREATE TABLE IF NOT EXISTS journal_entries (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    body TEXT NOT NULL,
    detected_themes TEXT,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_time ON journal_entries(user_id, created_at);

CREATE TABLE IF NOT EXISTS daily_reports (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    report_date TEXT NOT NULL,
    summary TEXT NOT NULL,
    mood_trend_note TEXT NOT NULL,
    recommendations TEXT NOT NULL DEFAULT '[]',
    cited_insight_ids TEXT NOT NULL DEFAULT '[]',
    crisis_flag INTEGER NOT NULL DEFAULT 0,
    generated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_daily_reports_user_date ON daily_reports(user_id, report_date);

CREATE TABLE IF NOT EXISTS research_articles (
    id TEXT PRIMARY KEY,
    source TEXT NOT NULL,
    external_id TEXT NOT NULL,
    title TEXT NOT NULL,
    abstract_text TEXT NOT NULL,
    url TEXT NOT NULL,
    published_at TEXT,
    tags TEXT NOT NULL DEFAULT '[]',
    ingested_at TEXT NOT NULL,
    UNIQUE(source, external_id)
);

CREATE TABLE IF NOT EXISTS research_embeddings (
    article_id TEXT PRIMARY KEY REFERENCES research_articles(id),
    embedding BLOB NOT NULL,
    dims INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS insights (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    source_article_ids TEXT NOT NULL DEFAULT '[]',
    tags TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL
);
