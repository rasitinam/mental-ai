-- Every story is tagged with exactly one catalog diagnosis at submission
-- time (enforced in `routes/stories.rs`, not here) — this is what lets
-- the guide filter the feed by condition instead of it being one
-- undifferentiated wall of text. Existing rows (all test data, pre-launch)
-- get an empty tag rather than a guess; nothing has been approved for
-- real users to see yet.
ALTER TABLE life_stories ADD COLUMN diagnosis_slug TEXT NOT NULL DEFAULT '';
