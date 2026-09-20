//! Blocking other people (App Store Guideline 1.2: an app with user-generated
//! content and messaging must let people block abusive users).
//!
//! A block is recorded one way but enforced both ways — see
//! `social::hidden_ids` / `social::ensure_not_blocked` for where it bites
//! (story feed, DM lists and sending, follows, profiles).
//!
//! Blocking from an *anonymous* story never tells the blocker who wrote it:
//! the row is flagged `anonymous`, and the blocked-people list shows it as
//! "anonymous author", unblocked by the row's own id.

use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{delete, get, post},
    Json, Router,
};
use mental_domain::repository::{BlockRepository, LifeStoryRepository};
use mental_domain::StoryStatus;
use serde::Serialize;
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::routes::social::internal;
use crate::routes::user_for;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/blocks", get(list))
        .route("/blocks/:id", delete(unblock))
        .route("/users/:id/block", post(block_user))
        .route("/stories/:id/block-author", post(block_story_author))
}

#[derive(Debug, Serialize)]
struct BlockView {
    /// The block's own id — what "unblock" takes.
    id: String,
    /// `None` for a block made from an anonymous story.
    display_name: Option<String>,
    /// Only meaningful when `display_name` is present.
    user_id: Option<String>,
    has_avatar: bool,
    anonymous: bool,
}

async fn list(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<BlockView>>, (StatusCode, String)> {
    let records = state.blocks.list_for(auth.user_id).await.map_err(internal)?;

    let mut views = Vec::with_capacity(records.len());
    for record in records {
        if record.anonymous {
            views.push(BlockView {
                id: record.id.to_string(),
                display_name: None,
                user_id: None,
                has_avatar: false,
                anonymous: true,
            });
            continue;
        }
        // A deleted account just drops off the list.
        let Some(user) = user_for(&state, record.blocked_id).await else { continue };
        views.push(BlockView {
            id: record.id.to_string(),
            display_name: Some(user.display_name),
            user_id: Some(record.blocked_id.to_string()),
            has_avatar: user.avatar_content_type.is_some(),
            anonymous: false,
        });
    }
    Ok(Json(views))
}

async fn block_user(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    if id == auth.user_id {
        return Err((StatusCode::BAD_REQUEST, "cannot block yourself".to_string()));
    }
    user_for(&state, id)
        .await
        .ok_or((StatusCode::NOT_FOUND, "user not found".to_string()))?;

    state.blocks.block(auth.user_id, id, false).await.map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

/// Blocks whoever wrote a published story, without revealing them when the
/// story is anonymous. Only stories the reader could actually see (approved)
/// count, so this can't be used to probe who wrote something pending.
async fn block_story_author(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    let story = state
        .life_stories
        .get(id)
        .await
        .map_err(internal)?
        .filter(|story| story.status == StoryStatus::Approved)
        .ok_or((StatusCode::NOT_FOUND, "story not found".to_string()))?;

    if story.user_id == auth.user_id {
        return Err((StatusCode::BAD_REQUEST, "cannot block yourself".to_string()));
    }

    state.blocks.block(auth.user_id, story.user_id, story.anonymous).await.map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

async fn unblock(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.blocks.unblock(auth.user_id, id).await.map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}
