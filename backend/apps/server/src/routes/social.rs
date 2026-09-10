use axum::extract::{Path, State};
use axum::http::{header, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use mental_domain::repository::{LifeStoryRepository, SocialRepository};
use mental_domain::{DmPolicy, PublicProfile};
use serde::Serialize;
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::routes::user_for;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/users/:id", get(profile))
        .route("/users/:id/avatar", get(avatar))
        .route("/users/:id/follow", post(follow).delete(unfollow))
        .route("/users/:id/followers", get(followers))
        .route("/users/:id/following", get(following))
}

/// One row in a follower/following list — the same shape the story feed
/// uses for an author, so the app renders both with one widget.
#[derive(Debug, Serialize)]
pub(crate) struct UserCard {
    pub user_id: String,
    pub display_name: String,
    pub has_avatar: bool,
}

/// Someone else's profile as the viewer sees it. Carries nothing from the
/// clinical side of the app — no diagnoses, no scores, no mood history.
async fn profile(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<PublicProfile>, (StatusCode, String)> {
    let user = user_for(&state, id)
        .await
        .ok_or((StatusCode::NOT_FOUND, "user not found".to_string()))?;

    let viewer_follows = state
        .social
        .is_following(auth.user_id, id)
        .await
        .map_err(internal)?;

    // "Can I write to them" is answered here rather than left for the
    // client to infer from a policy string it would have to re-implement
    // the rule for. Writing to yourself is never on offer.
    let accepts_dm = id != auth.user_id
        && match user.dm_policy {
            DmPolicy::Everyone => true,
            DmPolicy::Following => {
                state.social.is_following(id, auth.user_id).await.map_err(internal)?
            }
        };

    Ok(Json(PublicProfile {
        user_id: id,
        display_name: user.display_name,
        has_avatar: user.avatar_content_type.is_some(),
        story_count: state.life_stories.approved_count_for(id).await.map_err(internal)?,
        follower_count: state.social.follower_count(id).await.map_err(internal)?,
        following_count: state.social.following_count(id).await.map_err(internal)?,
        viewer_follows,
        accepts_dm,
    }))
}

/// Anyone signed in can load anyone's avatar — it's the picture attached
/// to a name already visible on a story or a follower list, so gating it
/// further would only break the lists that show it.
async fn avatar(
    State(state): State<AppState>,
    _auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Response, (StatusCode, String)> {
    let user = user_for(&state, id)
        .await
        .ok_or((StatusCode::NOT_FOUND, "user not found".to_string()))?;
    let content_type = user
        .avatar_content_type
        .ok_or((StatusCode::NOT_FOUND, "no avatar set".to_string()))?;

    let bytes = tokio::fs::read(crate::routes::profile::avatar_path(id))
        .await
        .map_err(|_| (StatusCode::NOT_FOUND, "avatar file missing".to_string()))?;

    Ok(([(header::CONTENT_TYPE, content_type)], bytes).into_response())
}

async fn follow(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    if id == auth.user_id {
        return Err((StatusCode::BAD_REQUEST, "cannot follow yourself".to_string()));
    }
    user_for(&state, id)
        .await
        .ok_or((StatusCode::NOT_FOUND, "user not found".to_string()))?;

    state.social.follow(auth.user_id, id).await.map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

async fn unfollow(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, String)> {
    state.social.unfollow(auth.user_id, id).await.map_err(internal)?;
    Ok(StatusCode::NO_CONTENT)
}

async fn followers(
    State(state): State<AppState>,
    _auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<Vec<UserCard>>, (StatusCode, String)> {
    let ids = state.social.followers(id).await.map_err(internal)?;
    Ok(Json(cards_for(&state, &ids).await))
}

async fn following(
    State(state): State<AppState>,
    _auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<Vec<UserCard>>, (StatusCode, String)> {
    let ids = state.social.following(id).await.map_err(internal)?;
    Ok(Json(cards_for(&state, &ids).await))
}

/// Names and avatars for a list of ids, skipping any that no longer
/// resolve — a deleted account shouldn't blank out someone's whole
/// follower list.
pub(crate) async fn cards_for(state: &AppState, ids: &[Uuid]) -> Vec<UserCard> {
    let mut cards = Vec::with_capacity(ids.len());
    for id in ids {
        if let Some(user) = user_for(state, *id).await {
            cards.push(UserCard {
                user_id: id.to_string(),
                display_name: user.display_name,
                has_avatar: user.avatar_content_type.is_some(),
            });
        }
    }
    cards
}

/// Whether `sender` is allowed to *open* a thread with `recipient`.
/// An already-accepted thread isn't subject to this — see [`DmPolicy`].
pub(crate) async fn may_open_dm(
    state: &AppState,
    sender: Uuid,
    recipient: Uuid,
) -> Result<bool, (StatusCode, String)> {
    let user = user_for(state, recipient)
        .await
        .ok_or((StatusCode::NOT_FOUND, "user not found".to_string()))?;

    Ok(match user.dm_policy {
        DmPolicy::Everyone => true,
        // "Only people I follow": the recipient must follow the sender.
        DmPolicy::Following => {
            state.social.is_following(recipient, sender).await.map_err(internal)?
        }
    })
}

pub(crate) fn internal(e: impl std::fmt::Display) -> (StatusCode, String) {
    (StatusCode::INTERNAL_SERVER_ERROR, e.to_string())
}
