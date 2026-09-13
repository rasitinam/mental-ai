-- Daily reports, life analyses and the current-state snapshot are each
-- generated once, in whatever language the account was set to at that
-- moment, then just read back on every later view — so switching the
-- interface language afterward left them stuck in the language they were
-- generated in until the next (sometimes cooldown-gated) regeneration.
-- `language` records what they actually came back in; `content_translations`
-- caches an on-demand translation into a reader's current language the same
-- way insight_translations/story_translations already do for shared
-- content, so re-reading the same private content in the same language
-- costs one LLM call, not one per view.
ALTER TABLE daily_reports ADD COLUMN language TEXT NOT NULL DEFAULT 'tr';
ALTER TABLE life_analyses ADD COLUMN language TEXT NOT NULL DEFAULT 'tr';
ALTER TABLE user_states ADD COLUMN language TEXT NOT NULL DEFAULT 'tr';

CREATE TABLE IF NOT EXISTS content_translations (
    content_type TEXT NOT NULL,
    content_id TEXT NOT NULL,
    target_language TEXT NOT NULL,
    payload TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (content_type, content_id, target_language)
);
