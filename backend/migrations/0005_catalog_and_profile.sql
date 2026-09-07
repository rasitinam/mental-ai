-- Self-reported diagnoses (slugs from mental_domain::catalog), kept on the
-- account so they travel with it. Self-reported on purpose: the app never
-- diagnoses anyone, it just lets someone tell it what they already know.
ALTER TABLE users ADD COLUMN diagnoses TEXT NOT NULL DEFAULT '[]';

-- The insight feed is browsable by category now, so each card records which
-- catalog category it was synthesized under. Nullable: cards created before
-- categorization existed (and any the model couldn't place) stay uncategorized
-- and only show up under "Genel".
ALTER TABLE insights ADD COLUMN category TEXT;
CREATE INDEX IF NOT EXISTS idx_insights_category ON insights(category, created_at);

-- Life analysis now carries explicit "do this / avoid this" guidance
-- alongside the narrative.
ALTER TABLE life_analyses ADD COLUMN do_list TEXT NOT NULL DEFAULT '[]';
ALTER TABLE life_analyses ADD COLUMN dont_list TEXT NOT NULL DEFAULT '[]';

-- Per-condition explainers ("what it is / how it develops / what helps"),
-- generated once from the research corpus and cached. Without the cache,
-- browsing the catalog would cost one LLM call per tap.
CREATE TABLE IF NOT EXISTS disorder_explainers (
    slug TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    name TEXT NOT NULL,
    what_it_is TEXT NOT NULL,
    how_it_develops TEXT NOT NULL,
    coping_paths TEXT NOT NULL DEFAULT '[]',
    treatment_paths TEXT NOT NULL DEFAULT '[]',
    generated_at TEXT NOT NULL
);
