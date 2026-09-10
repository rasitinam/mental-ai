-- Lets the story feed auto-translate a submission into whatever language
-- the reader's own account uses. `language` is a free ISO-639-1-ish
-- string rather than an enum, detected once at submission time, so
-- adding a third (fourth, ...) app language later never touches this
-- schema. `story_translations` is a cache keyed by (story, target
-- language) — the LLM call happens at most once per language a story is
-- ever actually read in, not once per reader.
ALTER TABLE life_stories ADD COLUMN language TEXT NOT NULL DEFAULT 'tr';

CREATE TABLE IF NOT EXISTS story_translations (
    story_id TEXT NOT NULL REFERENCES life_stories(id),
    target_language TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (story_id, target_language)
);
