//! Reporting a person: their profile, or what they wrote to you in a
//! private conversation. Stories have their own report path
//! (`routes::stories`); together they cover every place one member can
//! reach another (App Store guideline 1.2).
//!
//! The server takes the copy of what is reported, not the client, so a
//! report can't put words in someone's mouth, and the moderator sees the
//! content as it was even after it is edited or deleted.

use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use mental_domain::repository::{DmRepository, UserRepository};
use mental_storage::UserReport;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::routes::{require_admin, user_for};
use crate::state::AppState;

/// How many of their latest messages in the conversation the report keeps.
const DM_MESSAGES_KEPT: usize = 20;
/// Enough to cover any real conversation; `messages` returns oldest first.
const DM_SCAN_LIMIT: u32 = 2000;
const MAX_NOTE_CHARS: usize = 500;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/users/:id/report", post(report_user))
        .route("/moderation/user-reports", get(open_reports))
        .route("/moderation/user-reports/:id/resolve", post(resolve))
}

#[derive(Debug, Deserialize)]
struct ReportUserRequest {
    /// "profile" or "dm".
    kind: String,
    /// For "dm": the conversation the reporter is part of.
    #[serde(default)]
    thread_id: Option<Uuid>,
    /// Why, in their own words. Optional.
    #[serde(default)]
    note: Option<String>,
}

fn internal(e: anyhow::Error) -> (StatusCode, String) {
    (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
}

async fn report_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(reported): Path<Uuid>,
    Json(req): Json<ReportUserRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    if reported == auth.user_id {
        return Err((StatusCode::BAD_REQUEST, "you can't report yourself".to_string()));
    }
    let user = state
        .users
        .get(reported)
        .await
        .map_err(internal)?
        .ok_or((StatusCode::NOT_FOUND, "user not found".to_string()))?;

    let content = match req.kind.as_str() {
        "profile" => format!(
            "Name: {}\nProfile photo: {}",
            user.display_name,
            if user.avatar_content_type.is_some() { "yes" } else { "no" }
        ),
        "dm" => {
            let thread_id = req.thread_id.ok_or((StatusCode::BAD_REQUEST, "thread_id is required".to_string()))?;
            let thread = state
                .dms
                .get_thread(thread_id)
                .await
                .map_err(internal)?
                .ok_or((StatusCode::NOT_FOUND, "conversation not found".to_string()))?;
            // Only someone in the conversation can report it, and only the
            // other person in it.
            let members = [thread.user_low, thread.user_high];
            if !members.contains(&auth.user_id) || !members.contains(&reported) {
                return Err((StatusCode::NOT_FOUND, "conversation not found".to_string()));
            }
            let messages = state.dms.messages(thread_id, DM_SCAN_LIMIT).await.map_err(internal)?;
            let theirs: Vec<_> = messages.iter().filter(|m| m.sender_id == reported).collect();
            let kept = &theirs[theirs.len().saturating_sub(DM_MESSAGES_KEPT)..];
            if kept.is_empty() {
                "(no messages from them in this conversation)".to_string()
            } else {
                kept.iter()
                    .map(|m| format!("{}: {}", m.created_at.format("%Y-%m-%d %H:%M"), m.body))
                    .collect::<Vec<_>>()
                    .join("\n")
            }
        }
        _ => return Err((StatusCode::BAD_REQUEST, "kind must be profile or dm".to_string())),
    };

    let note = req
        .note
        .map(|n| n.trim().chars().take(MAX_NOTE_CHARS).collect::<String>())
        .filter(|n| !n.is_empty());

    state
        .user_reports
        .add(&UserReport {
            id: Uuid::new_v4(),
            reporter_id: auth.user_id,
            reported_user_id: reported,
            kind: req.kind,
            content,
            note,
            created_at: Utc::now(),
        })
        .await
        .map_err(internal)?;

    Ok(StatusCode::NO_CONTENT)
}

/// What the moderator sees: who was reported and by whom (names, so they
/// can act), what kind, the copy and the reporter's note.
#[derive(Debug, Serialize)]
struct UserReportView {
    id: String,
    kind: String,
    reported_user_id: String,
    reported_name: String,
    reporter_name: String,
    content: String,
    note: Option<String>,
    created_at: DateTime<Utc>,
}

async fn open_reports(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<UserReportView>>, (StatusCode, String)> {
    require_admin(&state, auth.user_id).await?;
    let reports = state.user_reports.list_open().await.map_err(internal)?;

    let mut views = Vec::with_capacity(reports.len());
    for report in reports {
        let name = |user: Option<mental_domain::User>| user.map(|u| u.display_name).unwrap_or_else(|| "(deleted)".to_string());
        views.push(UserReportView {
            id: report.id.to_string(),
            kind: report.kind,
            reported_user_id: report.reported_user_id.to_string(),
            reported_name: name(user_for(&state, report.reported_user_id).await),
            reporter_name: name(user_for(&state, report.reporter_id).await),
            content: report.content,
            note: report.note,
            created_at: report.created_at,
        });
    }
    Ok(Json(views))
}

async fn resolve(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    require_admin(&state, auth.user_id).await?;
    if state.user_reports.resolve(id).await.map_err(internal)? {
        Ok(StatusCode::NO_CONTENT)
    } else {
        Err((StatusCode::NOT_FOUND, "report not found".to_string()))
    }
}
