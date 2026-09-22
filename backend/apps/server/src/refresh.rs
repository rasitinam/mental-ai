//! Keeps two things current without anyone having to ask: the "how are they
//! right now" reading (`UserState`) and the person's long-term memory. Both
//! used to only update when something read them fresh (a pull-to-refresh, a
//! `life-analysis/generate` call) — someone could describe a crisis in chat
//! at 11pm and the home screen would keep showing that morning's cheerful
//! reading until they happened to pull to refresh it. Now every chat turn,
//! journal entry and mood check-in fires a background reassessment.
//!
//! Throttled by [`RefreshGuard`] so a busy evening of chatting triggers this
//! at most once per state reading and, far less often, once per memory
//! rewrite — not once per message.

use std::collections::HashMap;
use std::sync::Mutex;

use chrono::{DateTime, Duration as ChronoDuration, Utc};
use mental_analysis_engine::{generate_person_memory, MemoryInputs, PersonContext};
use mental_domain::repository::{
    AssessmentRepository, ChatRepository, JournalRepository, LifeStoryRepository, MoodRepository,
    PersonMemoryRepository, UserStateRepository,
};
use mental_domain::PersonMemory;
use uuid::Uuid;

use crate::routes::user_for;
use crate::state::AppState;

/// Minimum time between automatic state reassessments triggered by new
/// activity. An explicit pull-to-refresh (`POST /state/refresh`) ignores
/// this — it exists only so a back-and-forth conversation doesn't recompute
/// (and bill) the reading on every single message.
const STATE_MIN_INTERVAL: ChronoDuration = ChronoDuration::minutes(30);

/// Minimum time between automatic long-term-memory rewrites. Memory reads
/// much more per call (the recent history, not just what changed), so it is
/// rewritten far less often than the state reading.
const MEMORY_MIN_INTERVAL: ChronoDuration = ChronoDuration::hours(24);

/// How many recent chat turns the memory rewrite reads. Generous compared to
/// what a single chat reply sees (see `chat_reply::generate_chat_reply`)
/// since this runs far less often and is meant to catch what a short window
/// would miss.
const MEMORY_CHAT_MESSAGES: u32 = 300;

/// Throttles the background refreshes that follow ordinary activity. In-
/// process only: a restart clears it, which just means the next activity
/// after a restart is allowed to refresh again — never a correctness issue,
/// only a cost one.
pub struct RefreshGuard {
    state_next: Mutex<HashMap<Uuid, DateTime<Utc>>>,
    memory_next: Mutex<HashMap<Uuid, DateTime<Utc>>>,
}

impl RefreshGuard {
    pub fn new() -> Self {
        Self { state_next: Mutex::new(HashMap::new()), memory_next: Mutex::new(HashMap::new()) }
    }

    fn try_begin_state(&self, user_id: Uuid) -> bool {
        Self::try_begin(&self.state_next, user_id, STATE_MIN_INTERVAL)
    }

    fn try_begin_memory(&self, user_id: Uuid) -> bool {
        Self::try_begin(&self.memory_next, user_id, MEMORY_MIN_INTERVAL)
    }

    /// True at most once per `interval` for one user. Checking and reserving
    /// the next slot happen under the same lock, so two triggers arriving at
    /// once for the same person cannot both pass.
    fn try_begin(map: &Mutex<HashMap<Uuid, DateTime<Utc>>>, user_id: Uuid, interval: ChronoDuration) -> bool {
        let mut map = map.lock().unwrap_or_else(|e| e.into_inner());
        let now = Utc::now();
        let allowed = map.get(&user_id).map_or(true, |next| now >= *next);
        if allowed {
            map.insert(user_id, now + interval);
        }
        allowed
    }
}

impl Default for RefreshGuard {
    fn default() -> Self {
        Self::new()
    }
}

/// Fire-and-forget: after activity that could change how someone is doing —
/// a chat turn, a journal entry, a mood check-in — reassess their current
/// state and, far less often, rewrite their long-term memory. Both are
/// throttled by [`RefreshGuard`]; a call outside the allowed window is a
/// silent no-op, not an error. Runs after the response that triggered it has
/// already gone out — a failure here is only logged.
pub fn trigger_background_refresh(state: AppState, user_id: Uuid) {
    tokio::spawn(async move {
        if state.refresh_guard.try_begin_state(user_id) {
            if let Err(err) = refresh_current_state(&state, user_id).await {
                tracing::warn!(error = %err, %user_id, "background state refresh failed");
            }
        }

        if let Err(err) = maybe_refresh_person_memory(&state, user_id).await {
            tracing::warn!(error = %err, %user_id, "background memory refresh failed");
        }
    });
}

/// Recomputes and persists the "how are they right now" reading — the same
/// work `POST /state/refresh` does on request, reused here so the two paths
/// can never drift apart.
async fn refresh_current_state(state: &AppState, user_id: Uuid) -> anyhow::Result<()> {
    let assessed = crate::routes::state::run_state_refresh(state, user_id).await?;
    state.user_states.save(&assessed).await
}

/// Rewrites the person's long-term memory from their recent entries plus
/// what it already held. Leaves the stored memory untouched when they
/// switched it off, or when there isn't yet enough of their own words to
/// distill anything solid from — see
/// [`MemoryInputs::has_enough_material`].
///
/// The 24-hour throttle ([`RefreshGuard::try_begin_memory`]) is deliberately
/// checked *after* that "enough material" check, not before: gathering the
/// inputs is a handful of cheap local reads, but the throttle guards the one
/// expensive part (the LLM call). Consuming it on a message that turns out
/// to have too little to say would lock out every truly-ready trigger for
/// the rest of the day — this way, activity that arrives too early just
/// costs a few DB reads and tries again next time, and the slot is only
/// spent on a call that actually happens.
async fn maybe_refresh_person_memory(state: &AppState, user_id: Uuid) -> anyhow::Result<()> {
    let existing = state.person_memory.get(user_id).await?;
    if let Some(existing) = &existing {
        if !existing.enabled {
            return Ok(());
        }
    }

    let journal = state.journals.list_all(user_id).await.unwrap_or_default();
    let chat = state.chats.history_for_user(user_id, MEMORY_CHAT_MESSAGES).await.unwrap_or_default();
    let moods = state.moods.list_all(user_id).await.unwrap_or_default();
    let assessments = state.assessments.list_for_user(user_id, 12).await.unwrap_or_default();
    let stories = state.life_stories.list_for_user(user_id).await.unwrap_or_default();
    let previous_items = existing.map(|m| m.items).unwrap_or_default();

    let inputs = MemoryInputs {
        journal: &journal,
        chat: &chat,
        moods: &moods,
        assessments: &assessments,
        stories: &stories,
        previous: &previous_items,
    };

    if !inputs.has_enough_material() || !state.refresh_guard.try_begin_memory(user_id) {
        return Ok(());
    }

    let user = user_for(state, user_id).await;
    let person = user.as_ref().map(PersonContext::from_user).unwrap_or_else(PersonContext::unknown);

    let Some(items) = generate_person_memory(&inputs, &person, state.llm.as_ref()).await? else {
        return Ok(());
    };

    let memory = PersonMemory {
        user_id,
        enabled: true,
        items,
        language: person.language.to_string(),
        generated_at: Some(Utc::now()),
    };
    state.person_memory.save(&memory).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_state_slot_is_granted_once_then_withheld_until_the_interval_passes() {
        let guard = RefreshGuard::new();
        let user = Uuid::new_v4();
        assert!(guard.try_begin_state(user));
        assert!(!guard.try_begin_state(user), "a second trigger right after the first must be refused");
        // A different user is unaffected by the first one's slot.
        assert!(guard.try_begin_state(Uuid::new_v4()));
    }

    #[test]
    fn state_and_memory_slots_are_independent() {
        let guard = RefreshGuard::new();
        let user = Uuid::new_v4();
        assert!(guard.try_begin_state(user));
        // Using up the state slot must not also use up the memory slot.
        assert!(guard.try_begin_memory(user));
        assert!(!guard.try_begin_memory(user));
    }
}
