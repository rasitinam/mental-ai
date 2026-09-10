-- The image bytes themselves live on disk (data/avatars/<user_id>), not in
-- SQLite — this column only remembers whether one was uploaded and what
-- Content-Type to serve it back with.
ALTER TABLE users ADD COLUMN avatar_content_type TEXT;
