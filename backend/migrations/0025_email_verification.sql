-- The 6-digit code emailed to someone who is registering, before the account
-- exists. One row per address: asking for another code replaces the row.
--
-- Only a hash of the code is stored (see `email_verify::hash_code`), and the
-- row is deleted the moment the code is used or has been guessed wrong too
-- often. `sends_in_window` / `window_started_at` back the hourly cap on how
-- many codes one address can be sent, so the endpoint cannot be used to
-- flood someone's inbox.
CREATE TABLE IF NOT EXISTS email_verifications (
    email TEXT PRIMARY KEY,
    code_hash TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_sent_at TEXT NOT NULL,
    window_started_at TEXT NOT NULL,
    sends_in_window INTEGER NOT NULL DEFAULT 1
);
