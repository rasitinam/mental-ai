use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use mental_analysis_engine::screen_for_crisis_language;
use mental_domain::repository::LifeStoryRepository;
use mental_domain::{LifeStory, LifeStoryReport, StoryStatus};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::routes::{require_admin, user_for};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/stories", post(submit).get(public_feed))
        .route("/stories/mine", get(mine))
        .route("/stories/:id", axum::routing::delete(withdraw))
        .route("/stories/:id/report", post(report))
        .route("/stories/pending", get(pending))
        .route("/stories/reports", get(reports))
        .route("/stories/:id/approve", post(approve))
        .route("/stories/:id/reject", post(reject))
}

#[derive(Debug, Deserialize)]
struct SubmitRequest {
    body: String,
    /// Must be explicitly true — this is a separate consent from account
    /// signup, since "shown to other users" is a materially different use
    /// of the text than a private journal entry.
    consent: bool,
}

/// What a reader sees in the public feed — deliberately anonymous. No
/// `user_id` or display name: someone sharing a mental-health history
/// shouldn't have that tied back to their account just by being read.
#[derive(Debug, Serialize)]
struct PublicStory {
    id: String,
    body: String,
    created_at: DateTime<Utc>,
}

impl From<&LifeStory> for PublicStory {
    fn from(s: &LifeStory) -> Self {
        Self { id: s.id.to_string(), body: s.body.clone(), created_at: s.created_at }
    }
}

/// What an admin sees while moderating — identity included on purpose,
/// since approving or rejecting health content without knowing who wrote
/// it (or being able to follow up) isn't real moderation.
#[derive(Debug, Serialize)]
struct AdminStoryView {
    id: String,
    user_id: String,
    display_name: String,
    body: String,
    status: StoryStatus,
    crisis_flag: bool,
    created_at: DateTime<Utc>,
}

async fn admin_view(state: &AppState, story: &LifeStory) -> AdminStoryView {
    let display_name =
        user_for(state, story.user_id).await.map(|u| u.display_name).unwrap_or_else(|| "?".to_string());

    AdminStoryView {
        id: story.id.to_string(),
        user_id: story.user_id.to_string(),
        display_name,
        body: story.body.clone(),
        status: story.status,
        crisis_flag: story.crisis_flag,
        created_at: story.created_at,
    }
}

#[derive(Debug, Serialize)]
struct ReportedStoryView {
    report_id: String,
    note: Option<String>,
    reported_at: DateTime<Utc>,
    story: AdminStoryView,
}

#[derive(Debug, Deserialize)]
struct ReportRequest {
    #[serde(default)]
    note: Option<String>,
}

/// Submits a story for review. Runs the same crisis-language screen used
/// for journal/chat before it ever reaches the moderation queue, so a
/// crisis-flagged submission is visibly marked rather than looking like
/// any other pending item.
async fn submit(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SubmitRequest>,
) -> Result<Json<LifeStory>, (StatusCode, String)> {
    if !req.consent {
        return Err((StatusCode::BAD_REQUEST, "consent to public sharing is required".to_string()));
    }

    let body = req.body.trim().to_string();
    if body.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "story cannot be empty".to_string()));
    }

    let now = Utc::now();
    let crisis = screen_for_crisis_language(&body);
    let story = LifeStory {
        id: Uuid::new_v4(),
        user_id: auth.user_id,
        body,
        status: StoryStatus::Pending,
        crisis_flag: crisis.flagged,
        consented_at: now,
        reviewed_at: None,
        created_at: now,
    };

    state
        .life_stories
        .create(&story)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(story))
}

/// The public guide feed — approved stories only, identity stripped.
async fn public_feed(
    State(state): State<AppState>,
    _auth: AuthUser,
) -> Result<Json<Vec<PublicStory>>, (StatusCode, String)> {
    let stories = state
        .life_stories
        .list_approved(200)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(stories.iter().map(PublicStory::from).collect()))
}

/// The caller's own submissions, whatever their status — so someone can
/// see a pending story is still pending instead of wondering if it was
/// lost.
async fn mine(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<LifeStory>>, (StatusCode, String)> {
    let stories = state
        .life_stories
        .list_for_user(auth.user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(stories))
}

/// Withdraws the caller's own story, at any status. Scoped to the caller
/// in the delete query itself, so this can't be used to remove someone
/// else's submission by guessing an id.
async fn withdraw(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    state
        .life_stories
        .delete(id, auth.user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// Sends an already-published story back for re-review. The admin's
/// approval at submission time isn't the only safety net — anyone
/// reading the feed can flag something that turns out to be a problem
/// after the fact.
async fn report(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(req): Json<ReportRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    state
        .life_stories
        .get(id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "story not found".to_string()))?;

    let record = LifeStoryReport {
        id: Uuid::new_v4(),
        story_id: id,
        reporter_user_id: auth.user_id,
        note: req.note,
        created_at: Utc::now(),
    };

    state
        .life_stories
        .add_report(&record)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// The moderation queue. Admin-only — see `crate::routes::require_admin`.
async fn pending(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<AdminStoryView>>, (StatusCode, String)> {
    require_admin(&state, auth.user_id).await?;

    let stories = state
        .life_stories
        .list_pending()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let mut views = Vec::with_capacity(stories.len());
    for story in &stories {
        views.push(admin_view(&state, story).await);
    }

    Ok(Json(views))
}

/// Already-published stories a reader flagged, with the story attached so
/// the admin doesn't need a second lookup to act on one.
async fn reports(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<ReportedStoryView>>, (StatusCode, String)> {
    require_admin(&state, auth.user_id).await?;

    let reports = state
        .life_stories
        .list_reports()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let mut views = Vec::with_capacity(reports.len());
    for report in reports {
        let Some(story) = state
            .life_stories
            .get(report.story_id)
            .await
            .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        else {
            continue;
        };

        views.push(ReportedStoryView {
            report_id: report.id.to_string(),
            note: report.note,
            reported_at: report.created_at,
            story: admin_view(&state, &story).await,
        });
    }

    Ok(Json(views))
}

async fn approve(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    require_admin(&state, auth.user_id).await?;

    state
        .life_stories
        .set_status(id, StoryStatus::Approved, Utc::now())
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

async fn reject(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    require_admin(&state, auth.user_id).await?;

    state
        .life_stories
        .set_status(id, StoryStatus::Rejected, Utc::now())
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}
