-- Generalizes the single up/down "upvote" into a small set of named
-- reactions (see `mental_domain::life_story::REACTIONS`) — one active
-- reaction per (story, user), so picking a new one replaces the old
-- rather than stacking. Existing upvotes carry real signal from real
-- readers, so they're migrated forward as the "destek" reaction rather
-- than discarded; `story_upvotes` itself is left in place (unused from
-- here on) rather than dropped, since SQLite's `DROP TABLE` inside a
-- migration that might run on an older SQLite build is more risk than
-- reclaiming a few empty pages is worth.
CREATE TABLE IF NOT EXISTS story_reactions (
    story_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    reaction TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (story_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_story_reactions_story ON story_reactions(story_id);

INSERT INTO story_reactions (story_id, user_id, reaction, created_at)
SELECT story_id, user_id, 'destek', created_at FROM story_upvotes;
