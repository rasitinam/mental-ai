CREATE TABLE IF NOT EXISTS checkin_reminder_claims (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    local_date TEXT NOT NULL,
    slot TEXT NOT NULL CHECK (
        slot IN ('morning', 'afternoon', 'evening')
    ),
    claimed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, local_date, slot)
);

CREATE INDEX IF NOT EXISTS idx_checkin_reminder_claims_date
ON checkin_reminder_claims(local_date);

-- Preserve existing reminders already sent today.
INSERT OR IGNORE INTO checkin_reminder_claims (
    user_id,
    local_date,
    slot
)
SELECT
    id,
    checkin_reminder_last_sent,
    'evening'
FROM users
WHERE checkin_reminder_last_sent IS NOT NULL;