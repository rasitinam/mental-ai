-- What Hearth has learned about a person from their own entries, kept as a
-- few short lines (JSON array of {kind, text}) that every generated answer
-- carries. One row per person. It is theirs to read, clear and switch off:
-- `enabled = 0` means nothing is remembered or used for them.
CREATE TABLE IF NOT EXISTS person_memory (
    user_id TEXT PRIMARY KEY REFERENCES users(id),
    enabled INTEGER NOT NULL DEFAULT 1,
    items TEXT NOT NULL DEFAULT '[]',
    language TEXT NOT NULL DEFAULT 'tr',
    generated_at TEXT
);
