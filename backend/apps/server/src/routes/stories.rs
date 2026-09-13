use std::collections::HashMap;

use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use mental_analysis_engine::{screen_for_crisis_language, translate_text};
use mental_domain::catalog;
use mental_domain::life_story::{detect_language, REACTIONS};
use mental_domain::repository::{LifeStoryRepository, SocialRepository};
use mental_domain::{LifeStory, LifeStoryReport, StoryFeedItem, StoryStatus};
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
        .route("/stories/:id/react", post(react).delete(remove_reaction))
        .route("/stories/:id/translate", get(translate))
        .route("/stories/pending", get(pending))
        .route("/stories/reports", get(reports))
        .route("/stories/:id/approve", post(approve))
        .route("/stories/:id/reject", post(reject))
}

#[derive(Debug, Deserialize)]
struct SubmitRequest {
    body: String,
    /// A catalog slug — required, so the guide can filter the feed by
    /// condition. Validated against the catalog the same way
    /// `/profile/diagnoses` validates a self-reported diagnosis.
    diagnosis_slug: String,
    /// Must be explicitly true — this is a separate consent from account
    /// signup, since "shown to other users" is a materially different use
    /// of the text than a private journal entry.
    consent: bool,
    /// Defaults to anonymous. Sharing under a name has to be an explicit
    /// choice, not something a client gets to leave out and have decided
    /// the permissive way.
    #[serde(default = "yes")]
    anonymous: bool,
}

fn yes() -> bool {
    true
}

/// What a reader sees in the feed. The author's name and avatar are on
/// the row only when they chose to sign the story; for an anonymous one
/// there is no id to click through to, not just no name displayed.
#[derive(Debug, Serialize)]
struct PublicStory {
    id: String,
    body: String,
    /// What the client compares against its own app language to decide
    /// whether to offer a translated copy — see `translate` below.
    language: String,
    diagnosis_slug: String,
    created_at: DateTime<Utc>,
    /// Count per [`REACTIONS`] entry, keyed by name so the client doesn't
    /// need to hardcode the same ordering the backend does.
    reactions: HashMap<String, u32>,
    viewer_reaction: Option<String>,
    anonymous: bool,
    author_user_id: Option<String>,
    author_display_name: Option<String>,
    author_has_avatar: bool,
}

impl From<&StoryFeedItem> for PublicStory {
    fn from(item: &StoryFeedItem) -> Self {
        let signed = !item.story.anonymous;
        let reactions = REACTIONS
            .iter()
            .zip(item.reaction_counts)
            .map(|(name, count)| (name.to_string(), count))
            .collect();
        Self {
            id: item.story.id.to_string(),
            body: item.story.body.clone(),
            language: item.story.language.clone(),
            diagnosis_slug: item.story.diagnosis_slug.clone(),
            created_at: item.story.created_at,
            reactions,
            viewer_reaction: item.viewer_reaction.clone(),
            anonymous: item.story.anonymous,
            author_user_id: signed.then(|| item.story.user_id.to_string()),
            author_display_name: signed.then(|| item.author_display_name.clone()),
            author_has_avatar: signed && item.author_has_avatar,
        }
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
    diagnosis_slug: String,
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
        diagnosis_slug: story.diagnosis_slug.clone(),
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

    if catalog::disorder(&req.diagnosis_slug).is_none() {
        return Err((StatusCode::BAD_REQUEST, format!("unknown diagnosis slug: {}", req.diagnosis_slug)));
    }

    let now = Utc::now();
    let crisis = screen_for_crisis_language(&body);
    let language = detect_language(&body);
    let story = LifeStory {
        id: Uuid::new_v4(),
        user_id: auth.user_id,
        body,
        diagnosis_slug: req.diagnosis_slug,
        status: StoryStatus::Pending,
        crisis_flag: crisis.flagged,
        consented_at: now,
        anonymous: req.anonymous,
        language,
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

/// The feed: approved stories, ordered so the conditions the reader
/// actually lives with come first. Someone who told the app they have
/// PTSD opening a wall of unrelated accounts is the failure mode this
/// avoids — within each group it's still newest-first, so the ordering
/// personalises without freezing older matching stories at the top
/// forever.
async fn public_feed(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<PublicStory>>, (StatusCode, String)> {
    let mut items = state
        .life_stories
        .feed_for(auth.user_id, FEED_LIMIT)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let mine: Vec<String> = user_for(&state, auth.user_id)
        .await
        .map(|u| u.diagnoses)
        .unwrap_or_default();

    if !mine.is_empty() {
        // Stable sort, so the newest-first order the query already
        // produced survives inside each of the two groups.
        items.sort_by_key(|item| !mine.contains(&item.story.diagnosis_slug));
    }

    Ok(Json(items.iter().map(PublicStory::from).collect()))
}

const FEED_LIMIT: u32 = 200;

#[derive(Debug, Deserialize)]
struct ReactRequest {
    reaction: String,
}

async fn react(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(req): Json<ReactRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    if !REACTIONS.contains(&req.reaction.as_str()) {
        return Err((StatusCode::BAD_REQUEST, format!("unknown reaction: {}", req.reaction)));
    }

    state
        .social
        .react(id, auth.user_id, &req.reaction)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

async fn remove_reaction(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    state
        .social
        .remove_reaction(id, auth.user_id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

#[derive(Debug, Serialize)]
struct TranslationResponse {
    body: String,
    source_language: String,
}

/// Translates a story into the caller's own account language — never a
/// language passed by the client, so this can't be used as a free-form
/// translation proxy for arbitrary text. Results are cached per (story,
/// language) in `story_translations`; a story already read by five people
/// in English costs one LLM call, not five.
async fn translate(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<TranslationResponse>, (StatusCode, String)> {
    let story = state
        .life_stories
        .get(id)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
        .ok_or((StatusCode::NOT_FOUND, "story not found".to_string()))?;

    let reader_language =
        user_for(&state, auth.user_id).await.map(|u| u.language).unwrap_or_else(|| "tr".to_string());

    if story.language == reader_language {
        return Ok(Json(TranslationResponse {
            body: story.body,
            source_language: story.language,
        }));
    }

    if let Some(cached) = state
        .life_stories
        .get_translation(id, &reader_language)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?
    {
        return Ok(Json(TranslationResponse { body: cached, source_language: story.language }));
    }

    let translated = translate_text(&story.body, &reader_language, state.llm.as_ref())
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state
        .life_stories
        .save_translation(id, &reader_language, &translated)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(TranslationResponse { body: translated, source_language: story.language }))
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
