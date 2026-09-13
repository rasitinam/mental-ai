-- One row per account per UTC calendar day, incremented after every chat
-- turn with the tokens that turn actually cost (from the LLM response's
-- own `usage.total_tokens`, not an estimate). Backs the free-tier daily
-- chat budget in `apps/server/src/routes/chat.rs` — a day boundary rather
-- than a rolling window, so it's cheap to check (one row lookup) and easy
-- for a person to reason about ("resets tomorrow").
CREATE TABLE IF NOT EXISTS chat_token_usage (
    user_id TEXT NOT NULL REFERENCES users(id),
    usage_date TEXT NOT NULL,
    tokens_used INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, usage_date)
);
