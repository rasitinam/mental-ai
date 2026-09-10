-- Research insight cards are synthesized once, in the app's primary
-- language, and shared by every account — so an English-speaking reader
-- was getting Turkish cards in the guide feed. Same approach as
-- `story_translations`: translate on first read into whatever language
-- asked for it, then cache, so the LLM is called at most once per
-- (card, language) rather than once per reader.
CREATE TABLE IF NOT EXISTS insight_translations (
    insight_id TEXT NOT NULL REFERENCES insights(id),
    target_language TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (insight_id, target_language)
);
