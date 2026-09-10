-- Explainer cards were cached by slug alone but generated in one fixed
-- language, so an English-speaking reader got the Turkish card back from
-- the cache. The cache key is now (slug, language).
--
-- SQLite can't alter a primary key in place, so the table is rebuilt and
-- the existing rows are carried over as Turkish — which is what they are.
-- Nothing here is user data: worst case a card regenerates.
CREATE TABLE IF NOT EXISTS disorder_explainers_v2 (
    slug TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'tr',
    category TEXT NOT NULL,
    name TEXT NOT NULL,
    what_it_is TEXT NOT NULL,
    how_it_develops TEXT NOT NULL,
    coping_paths TEXT NOT NULL DEFAULT '[]',
    treatment_paths TEXT NOT NULL DEFAULT '[]',
    generated_at TEXT NOT NULL,
    PRIMARY KEY (slug, language)
);

INSERT OR IGNORE INTO disorder_explainers_v2
    (slug, language, category, name, what_it_is, how_it_develops, coping_paths, treatment_paths, generated_at)
SELECT slug, 'tr', category, name, what_it_is, how_it_develops, coping_paths, treatment_paths, generated_at
FROM disorder_explainers;

DROP TABLE disorder_explainers;
ALTER TABLE disorder_explainers_v2 RENAME TO disorder_explainers;
