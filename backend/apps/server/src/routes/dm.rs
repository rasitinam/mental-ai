use std::collections::HashMap;

use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::routing::{get, post};
use axum::{Json, Router};
use chrono::{DateTime, Utc};
use mental_domain::repository::{DmRepository, PushTokenRepository};
use mental_domain::{DmMessage, DmStatus, DmThread};
use mental_push::PushRequest;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::routes::social::{internal, may_open_dm};
use crate::routes::user_for;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/dm/threads", get(threads))
        .route("/dm/requests", get(requests))
        .route("/dm/with/:user_id", post(open))
        .route("/dm/threads/:id/messages", get(messages).post(send))
        .route("/dm/threads/:id/accept", post(accept))
        .route("/dm/threads/:id", axum::routing::delete(decline))
}

/// How many messages a conversation hands back at once. Generous enough
/// that scrolling up rarely hits the edge, bounded so a long-running
/// thread can't turn one request into a megabyte of JSON.
const MESSAGE_LIMIT: u32 = 300;

/// A row in the inbox (or the request list). Carries the other person,
/// not both sides — the viewer already knows who they are.
///
/// Deliberately no unread count and no "seen" timestamp: there is no
/// read state anywhere in this feature.
#[derive(Debug, Serialize)]
struct ThreadView {
    id: String,
    other_user_id: String,
    other_display_name: String,
    other_has_avatar: bool,
    status: DmStatus,
    /// True when the *viewer* opened this thread, so a pending one can
    /// read "waiting for them" instead of asking the sender to accept
    /// their own request.
    started_by_me: bool,
    last_message_at: DateTime<Utc>,
    last_message: Option<String>,
}

#[derive(Debug, Serialize)]
struct MessageView {
    id: String,
    sender_id: String,
    mine: bool,
    body: String,
    created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
struct SendRequest {
    body: String,
}

#[derive(Debug, Serialize)]
struct OpenedThread {
    thread_id: String,
    status: DmStatus,
}

async fn views_for(state: &AppState, viewer: Uuid, threads: Vec<DmThread>) -> Vec<ThreadView> {
    let ids: Vec<Uuid> = threads.iter().map(|t| t.id).collect();
    let latest = state.dms.latest_messages(&ids).await.unwrap_or_default();

    let hidden = crate::routes::social::hidden_ids(state, viewer).await;
    let mut views = Vec::with_capacity(threads.len());
    for thread in threads {
        let other = thread.other(viewer);
        if hidden.contains(&other) {
            continue;
        }
        let Some(user) = user_for(state, other).await else { continue };
        views.push(ThreadView {
            id: thread.id.to_string(),
            other_user_id: other.to_string(),
            other_display_name: user.display_name,
            other_has_avatar: user.avatar_content_type.is_some(),
            status: thread.status,
            started_by_me: thread.started_by == viewer,
            last_message_at: thread.last_message_at,
            last_message: latest
                .iter()
                .find(|m| m.thread_id == thread.id)
                .map(|m| m.body.clone()),
        });
    }
    views
}

/// The inbox: accepted conversations only.
async fn threads(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<ThreadView>>, (StatusCode, String)> {
    let threads = state
        .dms
        .threads_for(auth.user_id, DmStatus::Accepted)
        .await
        .map_err(internal)?;

    Ok(Json(views_for(&state, auth.user_id, threads).await))
}

/// Pending threads — both the requests waiting on the viewer and the ones
/// they sent that haven't been accepted yet, told apart by
/// `started_by_me`.
async fn requests(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<ThreadView>>, (StatusCode, String)> {
    let threads = state
        .dms
        .threads_for(auth.user_id, DmStatus::Pending)
        .await
        .map_err(internal)?;

    Ok(Json(views_for(&state, auth.user_id, threads).await))
}

/// Opens a conversation with someone, carrying its first message. This is
/// the request: the thread exists immediately but stays `pending`, and
/// the sender cannot add a second message until the other side accepts —
/// which is the whole point of the gate.
async fn open(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(user_id): Path<Uuid>,
    Json(req): Json<SendRequest>,
) -> Result<Json<OpenedThread>, (StatusCode, String)> {
    if user_id == auth.user_id {
        return Err((StatusCode::BAD_REQUEST, "cannot message yourself".to_string()));
    }
    crate::routes::social::ensure_not_blocked(&state, auth.user_id, user_id).await?;

    let body = req.body.trim().to_string();
    if body.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "message cannot be empty".to_string()));
    }

    // An existing thread short-circuits the policy check: once a
    // conversation exists, `send` owns the rules for it.
    if let Some(existing) = state.dms.thread_between(auth.user_id, user_id).await.map_err(internal)? {
        return send_into(&state, auth.user_id, existing, body).await;
    }

    if !may_open_dm(&state, auth.user_id, user_id).await? {
        return Err((
            StatusCode::FORBIDDEN,
            "this person only accepts messages from people they follow".to_string(),
        ));
    }

    let now = Utc::now();
    let (low, high) = DmThread::pair(auth.user_id, user_id);
    let thread = DmThread {
        id: Uuid::new_v4(),
        user_low: low,
        user_high: high,
        started_by: auth.user_id,
        status: DmStatus::Pending,
        created_at: now,
        last_message_at: now,
    };
    state.dms.create_thread(&thread).await.map_err(internal)?;

    send_into(&state, auth.user_id, thread, body).await
}

/// Adds a message to an existing thread, enforcing the one rule that
/// makes a request a request: while it's pending, only the person who
/// *received* it may reply. The opener already had their one message.
async fn send_into(
    state: &AppState,
    sender: Uuid,
    thread: DmThread,
    body: String,
) -> Result<Json<OpenedThread>, (StatusCode, String)> {
    let already_has_messages = !state
        .dms
        .messages(thread.id, 1)
        .await
        .map_err(internal)?
        .is_empty();

    if thread.status == DmStatus::Pending && thread.started_by == sender && already_has_messages {
        return Err((
            StatusCode::FORBIDDEN,
            "wait for them to accept before sending more".to_string(),
        ));
    }

    // The recipient answering a pending request accepts it by doing so —
    // making someone tap "accept" and then type is a step for its own sake.
    let mut status = thread.status;
    if thread.status == DmStatus::Pending && thread.started_by != sender {
        state.dms.accept_thread(thread.id).await.map_err(internal)?;
        status = DmStatus::Accepted;
    }

    let now = Utc::now();
    let message = DmMessage {
        id: Uuid::new_v4(),
        thread_id: thread.id,
        sender_id: sender,
        body,
        created_at: now,
    };
    state.dms.add_message(&message, now).await.map_err(internal)?;

    // A message that leaves the thread `Pending` can only be the opener's
    // first one — the guard above already refuses a second one from them
    // — so that's exactly the "new request" case; anything else (a reply
    // that just accepted it, or an ongoing conversation) is a regular
    // message. Never blocks the response on delivery: a push failing
    // (no token, FCM down, ...) is not a reason to fail the send itself.
    let is_new_request = status == DmStatus::Pending;
    notify_new_message(state, sender, &thread, is_new_request, &message.body).await;

    Ok(Json(OpenedThread { thread_id: thread.id.to_string(), status }))
}

/// Best-effort push notification to the other side of the thread. Silent
/// no-op if they have no registered device, if the account lookup fails,
/// or if sending itself fails — see `mental_push::NoopPushProvider` for
/// what happens when push isn't configured at all.
async fn notify_new_message(
    state: &AppState,
    sender: Uuid,
    thread: &DmThread,
    is_new_request: bool,
    body: &str,
) {
    let recipient = thread.other(sender);
    let tokens = state.push_tokens.tokens_for_user(recipient).await.unwrap_or_default();
    if tokens.is_empty() {
        return;
    }

    let Some(sender_user) = user_for(state, sender).await else { return };
    let Some(recipient_user) = user_for(state, recipient).await else { return };

    let preview = truncate_for_notification(body);
    let (title, push_body) = if is_new_request {
        (dm_request_title(&recipient_user.language), format!("{}: {preview}", sender_user.display_name))
    } else {
        (sender_user.display_name.clone(), preview)
    };

    let mut data = HashMap::new();
    data.insert("type".to_string(), if is_new_request { "dm_request" } else { "dm_message" }.to_string());
    data.insert("thread_id".to_string(), thread.id.to_string());

    for token in tokens {
        let request = PushRequest { token, title: title.clone(), body: push_body.clone(), data: data.clone() };
        if let Err(err) = state.push.send(request).await {
            tracing::warn!(error = %err, "failed to send DM push notification");
        }
    }
}

fn dm_request_title(language: &str) -> String {
    match language {
        "en" => "New message request".to_string(),
        _ => "Yeni mesaj isteği".to_string(),
    }
}

/// Notification bodies are short by nature (a phone's notification shade
/// clips long text anyway), but this keeps a very long message from
/// bloating the FCM payload.
fn truncate_for_notification(body: &str) -> String {
    const MAX_CHARS: usize = 140;
    if body.chars().count() <= MAX_CHARS {
        return body.to_string();
    }
    let truncated: String = body.chars().take(MAX_CHARS).collect();
    format!("{}…", truncated.trim_end())
}

async fn send(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(req): Json<SendRequest>,
) -> Result<Json<OpenedThread>, (StatusCode, String)> {
    let body = req.body.trim().to_string();
    if body.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "message cannot be empty".to_string()));
    }

    let thread = load_thread(&state, auth.user_id, id).await?;
    crate::routes::social::ensure_not_blocked(&state, auth.user_id, thread.other(auth.user_id)).await?;
    send_into(&state, auth.user_id, thread, body).await
}

async fn messages(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<Vec<MessageView>>, (StatusCode, String)> {
    let thread = load_thread(&state, auth.user_id, id).await?;
    crate::routes::social::ensure_not_blocked(&state, auth.user_id, thread.other(auth.user_id)).await?;

    let messages = state.dms.messages(id, MESSAGE_LIMIT).await.map_err(internal)?;

    Ok(Json(
        messages
            .into_iter()
            .map(|m| MessageView {
                id: m.id.to_string(),
                sender_id: m.sender_id.to_string(),
                mine: m.sender_id == auth.user_id,
                body: m.body,
                created_at: m.created_at,
            })
            .collect(),
    ))
}

async fn accept(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    let thread = load_thread(&state, auth.user_id, id).await?;
    crate::routes::social::ensure_not_blocked(&state, auth.user_id, thread.other(auth.user_id)).await?;
    if thread.started_by == auth.user_id {
        return Err((StatusCode::FORBIDDEN, "you opened this request".to_string()));
    }

    state.dms.accept_thread(id).await.map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

/// Declining (or leaving) removes the thread and its messages. Either
/// side can do it: for a pending request it's a refusal, for an accepted
/// one it's ending the conversation.
async fn decline(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    load_thread(&state, auth.user_id, id).await?;

    state.dms.delete_thread(id).await.map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

/// Loads a thread and checks the caller is actually in it — a 404 rather
/// than a 403 for one they aren't part of, so thread ids can't be probed.
async fn load_thread(
    state: &AppState,
    viewer: Uuid,
    id: Uuid,
) -> Result<DmThread, (StatusCode, String)> {
    let thread = state
        .dms
        .get_thread(id)
        .await
        .map_err(internal)?
        .filter(|t| t.involves(viewer))
        .ok_or((StatusCode::NOT_FOUND, "thread not found".to_string()))?;

    Ok(thread)
}
