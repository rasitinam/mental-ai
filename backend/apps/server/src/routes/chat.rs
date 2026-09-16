use axum::{
    extract::State,
    http::{header, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::{Duration, Utc};
use mental_analysis_engine::{generate_chat_reply, translate::translate_batch, PersonContext};
use mental_domain::repository::{
    ChatRepository, ChatUsageRepository, ContentTranslationRepository, JournalRepository, MoodRepository,
    SubscriptionRepository,
};
use mental_domain::{ChatMessageRecord, ChatRole};
use mental_llm_connector::ChatMessage;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::routes::{assessment_for, user_for};
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/chat", post(send_message))
        .route("/chat/history", get(chat_history))
        .route("/chat/speech", post(synthesize_speech))
}

/// How much of the durable transcript to hand back when the client
/// rehydrates on login/app start. Generous compared to the 16-message
/// window sent to the LLM per turn — this is just for rendering the
/// scrollback, not prompt cost.
const HISTORY_LIMIT: u32 = 500;

/// `content_translations` type for an assistant turn translated into the
/// reader's language; the content id is the message id.
const CHAT_TRANSLATION_CONTENT_TYPE: &str = "chat_message";
/// Assistant turns per translation call. Batches run concurrently, so a
/// long transcript's first load after a language switch stays a matter of
/// seconds.
const TRANSLATION_BATCH_SIZE: usize = 25;

#[derive(Debug, Deserialize)]
struct ChatTurnRequest {
    message: String,
    /// The visible transcript so far, oldest first, NOT including
    /// `message`. `mental_llm_connector::Role` deserializes from
    /// "user"/"assistant" (matches `ChatSender` on the Flutter side), so
    /// the client can send its own message list close to as-is — see
    /// `ChatApi.sendMessage` in the app. Capped server-side so a
    /// long-running conversation can't grow the prompt unbounded.
    #[serde(default)]
    history: Vec<ChatMessage>,
}

#[derive(Debug, Serialize)]
struct ChatTurnResponse {
    reply: String,
    crisis_flag: bool,
}

#[derive(Debug, Deserialize)]
struct SpeechRequest {
    text: String,
}

/// A single chat reply is never going to run past this; it's just a
/// backstop against an accidental/abusive giant payload driving up the
/// per-character cost of the TTS call.
const MAX_SPEECH_CHARS: usize = 4000;

/// Only the most recent turns are kept: early rapport-building context
/// matters less than what was just said, and this bounds token cost on
/// long-lived conversations.
const MAX_HISTORY_MESSAGES: usize = 16;

/// Free-tier daily chat budget, in tokens. Rough estimate, not a measured
/// figure yet: a turn's prompt (safety + instruction system messages, the
/// person's mood/journal/research context, and the growing history window)
/// plus a warm, non-terse reply tends to run ~1.5-2k tokens once a
/// conversation has some back-and-forth, and someone actively chatting
/// sends roughly a message a minute or two — so ~10 turns, i.e. about 15
/// minutes of real conversation, lands around 20k tokens. Tune this once
/// real usage data says otherwise; it only needs to be in the right
/// neighborhood, since going over it just means an upsell, not an outage.
const FREE_DAILY_CHAT_TOKEN_BUDGET: i64 = 20_000;

/// The client (`ChatApi.sendMessage`) matches on this exact status code to
/// route to the paywall instead of showing a generic error — see
/// `PremiumRequiredException` on the Flutter side.
const QUOTA_EXCEEDED_STATUS: StatusCode = StatusCode::PAYMENT_REQUIRED;

/// Chat with the wellness companion, personalized with the last few days
/// of the user's own mood/journal history, grounded with research
/// relevant to their message, and now with real conversational memory —
/// see `mental_analysis_engine::generate_chat_reply`. There is still no
/// server-side *live* session store (the client resends the tail of its
/// transcript each turn, as above) — but every turn is now durably
/// persisted to `chat_messages` regardless, so a conversation survives
/// an app reinstall/restart even though it isn't replayed automatically
/// yet. A failure to persist is logged and swallowed rather than failing
/// the request: losing the durable copy of a message the user already
/// received is much better than losing the reply itself over a DB hiccup.
async fn send_message(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<ChatTurnRequest>,
) -> Result<Json<ChatTurnResponse>, (axum::http::StatusCode, String)> {
    let now = Utc::now();
    let today = now.date_naive();

    // Hearth Plus subscribers chat without a cap; everyone else draws down
    // a daily token budget (see `FREE_DAILY_CHAT_TOKEN_BUDGET`) and gets
    // sent to the paywall once it's gone for the day.
    let is_premium = state
        .subscriptions
        .for_user(auth.user_id)
        .await
        .ok()
        .flatten()
        .is_some_and(|sub| sub.is_active());

    if !is_premium {
        let used_today = state.chat_usage.tokens_used(auth.user_id, today).await.unwrap_or(0);
        if used_today >= FREE_DAILY_CHAT_TOKEN_BUDGET {
            return Err((QUOTA_EXCEEDED_STATUS, "daily chat limit reached".to_string()));
        }
    }

    let since = now - Duration::days(3);

    let recent_moods = state
        .moods
        .list_between(auth.user_id, since, now)
        .await
        .unwrap_or_default();
    let recent_journal_entries = state
        .journals
        .list_between(auth.user_id, since, now)
        .await
        .unwrap_or_default();

    let history_start = req.history.len().saturating_sub(MAX_HISTORY_MESSAGES);
    let history = &req.history[history_start..];

    let user = user_for(&state, auth.user_id).await;
    let person = user
        .as_ref()
        .map(PersonContext::from_user)
        .unwrap_or_else(PersonContext::unknown)
        .with_assessment(assessment_for(&state, auth.user_id).await);

    let result = generate_chat_reply(
        &req.message,
        history,
        &recent_moods,
        &recent_journal_entries,
        &person,
        state.llm.as_ref(),
        state.research.as_ref(),
        state.vector_store.as_ref(),
        state.embedder.as_ref(),
    )
    .await
    .map_err(|e| (axum::http::StatusCode::BAD_GATEWAY, e.to_string()))?;

    persist_turn(&state, auth.user_id, ChatRole::User, &req.message, false).await;
    persist_turn(&state, auth.user_id, ChatRole::Assistant, &result.reply, result.crisis_flag).await;

    // Recorded regardless of `is_premium`, so the counter is already
    // accurate if a subscription lapses mid-day instead of undercounting
    // the day it expires.
    if let Some(tokens) = result.usage_tokens {
        if let Err(err) = state.chat_usage.add_tokens(auth.user_id, today, tokens as i64).await {
            tracing::warn!(error = %err, "failed to record chat token usage");
        }
    }

    Ok(Json(ChatTurnResponse { reply: result.reply, crisis_flag: result.crisis_flag }))
}

/// Full persisted transcript for the signed-in user, oldest first — the
/// chat screen loads this once on start so a conversation reads as one
/// continuous thread across logins/app restarts instead of resetting.
async fn chat_history(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Vec<ChatMessageRecord>>, (axum::http::StatusCode, String)> {
    let mut history = state
        .chats
        .history_for_user(auth.user_id, HISTORY_LIMIT)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if let Some(user) = user_for(&state, auth.user_id).await {
        translate_assistant_turns(&state, &mut history, &user.language).await;
    }

    Ok(Json(history))
}

/// Puts the AI's side of the transcript into the reader's current language,
/// leaving the person's own messages exactly as they wrote them. Each
/// assistant turn is translated once per language and cached — a turn
/// already in that language comes back from the model unchanged and is
/// cached the same way, so it is never sent again. A batch that fails keeps
/// its original text rather than failing the whole history.
async fn translate_assistant_turns(state: &AppState, history: &mut [ChatMessageRecord], language: &str) {
    let mut missing = Vec::new();
    for (index, record) in history.iter_mut().enumerate() {
        if record.role != ChatRole::Assistant {
            continue;
        }
        match state.content_translations.get(CHAT_TRANSLATION_CONTENT_TYPE, &record.id.to_string(), language).await {
            Ok(Some(cached)) => record.content = cached,
            Ok(None) => missing.push(index),
            Err(err) => tracing::warn!(error = %err, "failed to read a cached chat translation"),
        }
    }
    if missing.is_empty() {
        return;
    }

    let mut batches = tokio::task::JoinSet::new();
    for chunk in missing.chunks(TRANSLATION_BATCH_SIZE) {
        let indices = chunk.to_vec();
        let texts: Vec<String> = indices.iter().map(|&index| history[index].content.clone()).collect();
        let llm = state.llm.clone();
        let language = language.to_string();
        batches.spawn(async move {
            let translated = translate_batch(&texts, &language, llm.as_ref()).await;
            (indices, translated)
        });
    }

    while let Some(joined) = batches.join_next().await {
        let Ok((indices, translated)) = joined else { continue };
        match translated {
            Ok(texts) => {
                for (index, text) in indices.into_iter().zip(texts) {
                    let record = &mut history[index];
                    if let Err(err) = state
                        .content_translations
                        .save(CHAT_TRANSLATION_CONTENT_TYPE, &record.id.to_string(), language, &text)
                        .await
                    {
                        tracing::warn!(error = %err, "failed to cache a chat translation");
                    }
                    record.content = text;
                }
            }
            Err(err) => tracing::warn!(error = %err, "failed to translate a chat history batch"),
        }
    }
}

/// Reads a chat message aloud with a natural, warm TTS voice — the
/// "Sesli oku" button. Auth-gated (not a free-standing TTS proxy) and
/// length-capped; every other failure mode (empty text, provider error)
/// just fails the one request, nothing durable to clean up.
async fn synthesize_speech(
    State(state): State<AppState>,
    _auth: AuthUser,
    Json(req): Json<SpeechRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    if req.text.trim().is_empty() {
        return Err((StatusCode::BAD_REQUEST, "text must not be empty".to_string()));
    }
    if req.text.len() > MAX_SPEECH_CHARS {
        return Err((StatusCode::BAD_REQUEST, format!("text must be at most {MAX_SPEECH_CHARS} characters")));
    }

    let audio = state
        .llm
        .synthesize_speech(&req.text)
        .await
        .map_err(|e| (StatusCode::BAD_GATEWAY, e.to_string()))?;

    Ok(([(header::CONTENT_TYPE, "audio/mpeg")], audio))
}

async fn persist_turn(state: &AppState, user_id: Uuid, role: ChatRole, content: &str, crisis_flag: bool) {
    let record = ChatMessageRecord {
        id: Uuid::new_v4(),
        user_id,
        role,
        content: content.to_string(),
        crisis_flag,
        created_at: Utc::now(),
    };
    if let Err(err) = state.chats.add(&record).await {
        tracing::warn!(error = %err, "failed to persist chat message");
        return;
    }

    // A reply is written in the account's current language, so it is
    // already its own translation into that language. Recording it as one
    // means reading the history back in the same language never sends it
    // to the model.
    if role == ChatRole::Assistant {
        if let Some(user) = user_for(state, user_id).await {
            if let Err(err) = state
                .content_translations
                .save(CHAT_TRANSLATION_CONTENT_TYPE, &record.id.to_string(), &user.language, content)
                .await
            {
                tracing::warn!(error = %err, "failed to cache a chat reply in its own language");
            }
        }
    }
}
