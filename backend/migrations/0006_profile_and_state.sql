-- Interface language, so the backend can answer in the same language the
-- app is showing. Defaults to Turkish: that is what every existing account
-- has been using.
ALTER TABLE users ADD COLUMN language TEXT NOT NULL DEFAULT 'tr';

-- Birth year rather than age, so the number doesn't silently go stale.
-- Nullable: nobody is forced to give it, and the prompts fall back to
-- age-neutral wording when it is missing. It matters because what a
-- teenager is going through and what a middle-aged person is going through
-- are different problems even under the same diagnosis label.
ALTER TABLE users ADD COLUMN birth_year INTEGER;

-- A single rolling "where is this person right now" snapshot, assessed from
-- every recent signal at once (chat, daily report, life analysis, mood
-- check-ins, journal) rather than from the mood slider alone. One row per
-- user: this is current state, not history — the history already lives in
-- its own tables.
CREATE TABLE IF NOT EXISTS user_states (
    user_id TEXT PRIMARY KEY REFERENCES users(id),
    valence REAL NOT NULL,
    energy REAL NOT NULL,
    headline TEXT NOT NULL,
    note TEXT NOT NULL,
    basis TEXT NOT NULL DEFAULT '[]',
    generated_at TEXT NOT NULL
);
