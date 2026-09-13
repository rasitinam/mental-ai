-- One active entitlement per account: whichever platform's receipt was
-- last successfully verified wins. A single row per user (rather than a
-- history table) is enough because the App Store is the source of truth
-- for the actual subscription history — this just caches "what does this
-- account currently get", refreshed on every verify call and re-derivable
-- at any time by re-validating the stored receipt.
CREATE TABLE IF NOT EXISTS subscriptions (
    user_id TEXT PRIMARY KEY REFERENCES users(id),
    platform TEXT NOT NULL,
    product_id TEXT NOT NULL,
    -- Apple's stable id for a subscription across renewals, price changes
    -- and even product-id changes within the same subscription group —
    -- the right key to reconcile against if a future webhook (App Store
    -- Server Notifications) needs to find "this account's subscription"
    -- rather than "this specific receipt".
    original_transaction_id TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
