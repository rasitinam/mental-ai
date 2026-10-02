-- The person's explicit permission to send their own content to the
-- third-party AI service (OpenAI) that writes replies, reports and
-- readings. Asked separately from the Privacy Policy, in the app, before
-- anything is sent (App Store guideline 5.1.2(i)). No row means no
-- permission: every generator that reads the person's data refuses, and
-- background refreshes skip them. Withdrawing deletes the row.
CREATE TABLE IF NOT EXISTS ai_consent (
    user_id TEXT PRIMARY KEY REFERENCES users(id),
    granted_at TEXT NOT NULL
);
