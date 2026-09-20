-- Sign in with Apple. Apple identifies a person to this app by a stable,
-- app-scoped `sub` claim (the email can be a private relay address and is
-- not guaranteed to be present after the first sign-in), so that `sub` is
-- the link key. The account itself is still an ordinary `users` row with a
-- `credentials` row whose password hash is the "!apple" sentinel (never
-- verifies), which keeps every "look the account up by email / user id"
-- path working without a second account model.
CREATE TABLE IF NOT EXISTS apple_identities (
    apple_sub TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
    created_at TEXT NOT NULL
);
