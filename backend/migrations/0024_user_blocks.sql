-- One person blocking another. Directional in storage (who blocked whom) but
-- treated as mutual everywhere it is enforced: neither side sees the other in
-- the story feed or DM lists, and neither can follow or message the other.
--
-- `anonymous` is set when the block was made from an anonymous story: the
-- blocker never learned who the author is, so the blocked-people list must
-- not reveal it either (it shows "anonymous author" and unblocks by this
-- row's id, never by user id).
CREATE TABLE IF NOT EXISTS user_blocks (
    id TEXT PRIMARY KEY,
    blocker_id TEXT NOT NULL REFERENCES users(id),
    blocked_id TEXT NOT NULL REFERENCES users(id),
    anonymous INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    UNIQUE (blocker_id, blocked_id)
);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON user_blocks(blocked_id);
