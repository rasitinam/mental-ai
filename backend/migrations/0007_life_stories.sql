-- Admin flag for the moderation queue below. Not exposed through any
-- route — granted by hand against the database, the same way a
-- superuser account is on any small system, since a self-serve
-- "make me admin" endpoint would just be a privilege-escalation bug
-- waiting to happen.
ALTER TABLE users ADD COLUMN is_admin INTEGER NOT NULL DEFAULT 0;

-- First-person accounts of someone's own mental-health journey, submitted
-- for the public guide rather than kept private like a journal entry.
-- Every submission starts `pending`; only an admin's approve/reject moves
-- it out of that state, and it stays out of `list_approved` (the public
-- feed) until then. Deliberately no structured medication field — see
-- `mental_domain::life_story` for why.
CREATE TABLE IF NOT EXISTS life_stories (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    body TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    crisis_flag INTEGER NOT NULL DEFAULT 0,
    consented_at TEXT NOT NULL,
    reviewed_at TEXT,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_life_stories_status ON life_stories(status, created_at);
CREATE INDEX IF NOT EXISTS idx_life_stories_user ON life_stories(user_id, created_at);

-- A reader flagging an already-published story — the admin's own
-- approval isn't the only safety net; anyone can send a story back for
-- re-review after the fact.
CREATE TABLE IF NOT EXISTS life_story_reports (
    id TEXT PRIMARY KEY,
    story_id TEXT NOT NULL REFERENCES life_stories(id),
    reporter_user_id TEXT NOT NULL REFERENCES users(id),
    note TEXT,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_life_story_reports_story ON life_story_reports(story_id);
