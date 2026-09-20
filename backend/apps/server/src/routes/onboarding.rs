use axum::{extract::State, http::StatusCode, routing::post, Json, Router};
use chrono::Utc;
use mental_analysis_engine::{interpret_intro_answer, MAX_INTRO_ANSWER_LEN};
use mental_domain::repository::{ChatUsageRepository, UserRepository};
use mental_domain::ChatRole;
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::routes::user_for;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/onboarding/intro", post(intro))
}

#[derive(Debug, Deserialize)]
struct IntroRequest {
    /// What they typed into the first-run chat box, in their own words.
    answer: String,
}

#[derive(Debug, Serialize)]
struct IntroResponse {
    /// The assistant's message, ready to render in the bubble.
    reply: String,
    /// What was stored as a result — the client shows these back so the
    /// step ends with something visible, not just a reply.
    boundaries: Vec<String>,
    note: Option<String>,
}

/// The opening exchange of onboarding: the app asks how it should be
/// with this person, they answer in prose, and that answer becomes both
/// a real reply and their standing conversation rules.
///
/// Persisted into `chat_messages` like any other turn, on purpose — this
/// *is* their first conversation, and finding it already there when they
/// open the chat tab is the point. Saving the derived rules is what
/// actually matters here, so a failure to persist the transcript is
/// logged and swallowed the way `routes::chat` does it.
async fn intro(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<IntroRequest>,
) -> Result<Json<IntroResponse>, (StatusCode, String)> {
    let answer = req.answer.trim();
    if answer.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "answer can't be empty".to_string()));
    }
    if answer.chars().count() > MAX_INTRO_ANSWER_LEN {
        return Err((
            StatusCode::BAD_REQUEST,
            format!("answer is longer than {MAX_INTRO_ANSWER_LEN} characters"),
        ));
    }

    let user = user_for(&state, auth.user_id).await;
    let language = user.as_ref().map(|u| u.language.as_str()).unwrap_or("tr");

    let understanding = interpret_intro_answer(answer, language, state.llm.as_ref())
        .await
        .map_err(|e| (StatusCode::BAD_GATEWAY, e.to_string()))?;

    state
        .users
        .set_chat_boundaries(auth.user_id, &understanding.boundaries, understanding.note.as_deref())
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    crate::routes::chat::persist_turn(&state, auth.user_id, ChatRole::User, answer, false).await;
    crate::routes::chat::persist_turn(&state, auth.user_id, ChatRole::Assistant, &understanding.reply, false).await;

    if let Some(tokens) = understanding.usage_tokens {
        if let Err(err) = state
            .chat_usage
            .add_tokens(auth.user_id, Utc::now().date_naive(), tokens as i64)
            .await
        {
            tracing::warn!(error = %err, "failed to record onboarding intro token usage");
        }
    }

    Ok(Json(IntroResponse {
        reply: understanding.reply,
        boundaries: understanding.boundaries,
        note: understanding.note,
    }))
}
