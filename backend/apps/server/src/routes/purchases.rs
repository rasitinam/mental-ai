//! App Store subscription verification. The client never gets to say
//! "I'm premium" on its own — every entitlement in [`Subscription`] is
//! derived from a receipt Apple itself has vouched for, validated here via
//! the (legacy but still functional) `verifyReceipt` endpoint. Google Play
//! would be a second `platform` value and its own verify call, added the
//! same way once Android sells the same subscription.

use axum::{extract::State, http::StatusCode, routing::get, Json, Router};
use chrono::{DateTime, Utc};
use mental_domain::repository::SubscriptionRepository;
use mental_domain::Subscription;
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/purchases/verify-apple", axum::routing::post(verify_apple))
        .route("/purchases/subscription", get(subscription))
}

const PRODUCTION_VERIFY_URL: &str = "https://buy.itunes.apple.com/verifyReceipt";
const SANDBOX_VERIFY_URL: &str = "https://sandbox.itunes.apple.com/verifyReceipt";
/// Apple's code for "this is a sandbox receipt, sent to the production
/// endpoint" — the documented signal to retry against sandbox instead of
/// treating it as a rejection. A real device running a TestFlight or
/// App-Store build can still hand back a sandbox receipt while the app is
/// in review, so production has to try first and fall back, never the
/// other way round.
const SANDBOX_RECEIPT_ON_PRODUCTION: i64 = 21007;

#[derive(Debug, Deserialize)]
struct VerifyReceiptRequest {
    /// Base64 App Store receipt, exactly as `InAppPurchase`/StoreKit hands
    /// it to the client.
    receipt_data: String,
}

#[derive(Debug, Serialize)]
struct EntitlementResponse {
    is_premium: bool,
    expires_at: Option<DateTime<Utc>>,
    product_id: Option<String>,
}

impl From<Subscription> for EntitlementResponse {
    fn from(sub: Subscription) -> Self {
        Self { is_premium: sub.is_active(), expires_at: Some(sub.expires_at), product_id: Some(sub.product_id) }
    }
}

#[derive(Debug, Serialize)]
struct AppleVerifyRequest<'a> {
    #[serde(rename = "receipt-data")]
    receipt_data: &'a str,
    password: &'a str,
    #[serde(rename = "exclude-old-transactions")]
    exclude_old_transactions: bool,
}

#[derive(Debug, Deserialize)]
struct AppleVerifyResponse {
    status: i64,
    receipt: Option<AppleReceipt>,
    #[serde(default)]
    latest_receipt_info: Vec<AppleLatestReceiptInfo>,
}

#[derive(Debug, Deserialize)]
struct AppleReceipt {
    bundle_id: String,
}

#[derive(Debug, Deserialize)]
struct AppleLatestReceiptInfo {
    product_id: String,
    original_transaction_id: String,
    /// Apple sends this as a numeric string, not a number.
    expires_date_ms: String,
}

async fn call_apple(url: &str, receipt_data: &str, shared_secret: &str) -> anyhow::Result<AppleVerifyResponse> {
    let body = AppleVerifyRequest { receipt_data, password: shared_secret, exclude_old_transactions: true };
    let response = reqwest::Client::new().post(url).json(&body).send().await?;
    Ok(response.json::<AppleVerifyResponse>().await?)
}

/// Validates a receipt with Apple, records the resulting entitlement, and
/// returns it. Idempotent — replaying the same receipt just re-confirms the
/// same expiry, which is exactly what happens when a client re-syncs after
/// a reinstall or a device switch.
async fn verify_apple(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<VerifyReceiptRequest>,
) -> Result<Json<EntitlementResponse>, (StatusCode, String)> {
    if state.apple_iap.shared_secret.is_empty() {
        return Err((StatusCode::SERVICE_UNAVAILABLE, "Apple IAP is not configured on this server".to_string()));
    }

    let mut apple = call_apple(PRODUCTION_VERIFY_URL, &req.receipt_data, &state.apple_iap.shared_secret)
        .await
        .map_err(|e| (StatusCode::BAD_GATEWAY, format!("could not reach Apple: {e}")))?;

    if apple.status == SANDBOX_RECEIPT_ON_PRODUCTION {
        apple = call_apple(SANDBOX_VERIFY_URL, &req.receipt_data, &state.apple_iap.shared_secret)
            .await
            .map_err(|e| (StatusCode::BAD_GATEWAY, format!("could not reach Apple sandbox: {e}")))?;
    }

    if apple.status != 0 {
        return Err((StatusCode::BAD_REQUEST, format!("Apple rejected the receipt (status {})", apple.status)));
    }

    let receipt = apple
        .receipt
        .ok_or((StatusCode::BAD_REQUEST, "receipt response had no bundle info".to_string()))?;
    if receipt.bundle_id != state.apple_iap.bundle_id {
        return Err((StatusCode::BAD_REQUEST, "receipt belongs to a different app".to_string()));
    }

    // The most recent transaction by expiry — there's only one subscription
    // tier today, so this doesn't need to filter by product id. Adding a
    // second tier later means picking the right one here instead of
    // whichever expires furthest out.
    let latest = apple
        .latest_receipt_info
        .into_iter()
        .max_by_key(|info| info.expires_date_ms.parse::<i64>().unwrap_or(0));

    let Some(latest) = latest else {
        return Ok(Json(EntitlementResponse { is_premium: false, expires_at: None, product_id: None }));
    };

    let expires_at = latest
        .expires_date_ms
        .parse::<i64>()
        .ok()
        .and_then(DateTime::<Utc>::from_timestamp_millis)
        .ok_or((StatusCode::BAD_GATEWAY, "Apple returned an unparseable expiry".to_string()))?;

    let subscription = Subscription {
        user_id: auth.user_id,
        platform: "apple".to_string(),
        product_id: latest.product_id,
        original_transaction_id: latest.original_transaction_id,
        expires_at,
        updated_at: Utc::now(),
    };

    state
        .subscriptions
        .upsert(&subscription)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(subscription.into()))
}

/// The signed-in account's current entitlement, from the last receipt this
/// server validated — read on app launch to gate premium features without
/// re-validating a receipt on every check.
async fn subscription(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<EntitlementResponse>, (StatusCode, String)> {
    let subscription = state
        .subscriptions
        .for_user(auth.user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(match subscription {
        Some(sub) => sub.into(),
        None => EntitlementResponse { is_premium: false, expires_at: None, product_id: None },
    }))
}
