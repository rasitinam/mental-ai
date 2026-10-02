mod assessment;
mod auth;
mod blocks;
mod catalog;
mod chat;
mod discoveries;
mod dm;
mod health;
mod insights;
mod journal;
mod life_analysis;
mod memory;
mod mood;
mod onboarding;
pub(crate) mod profile;
mod purchases;
mod reports;
mod session_summary;
pub(crate) mod social;
pub(crate) mod state;
mod stories;
mod streak;
mod user_reports;

use axum::http::StatusCode;
use axum::Router;
use mental_analysis_engine::{AssessmentSummary, PersonContext};
use mental_domain::repository::{AssessmentRepository, PersonMemoryRepository, SubscriptionRepository, UserRepository};
use mental_domain::{MemoryItem, User};
use uuid::Uuid;

use crate::state::AppState;

pub fn build_router(app_state: AppState) -> Router {
    Router::new()
        .merge(health::router())
        .merge(assessment::router())
        .merge(auth::router())
        .merge(profile::router())
        .merge(catalog::router())
        .merge(chat::router())
        .merge(discoveries::router())
        .merge(session_summary::router())
        .merge(mood::router())
        .merge(onboarding::router())
        .merge(journal::router())
        .merge(reports::router())
        .merge(insights::router())
        .merge(life_analysis::router())
        .merge(memory::router())
        .merge(state::router())
        .merge(stories::router())
        .merge(social::router())
        .merge(blocks::router())
        .merge(dm::router())
        .merge(streak::router())
        .merge(purchases::router())
        .merge(user_reports::router())
        .with_state(app_state)
}

/// The status body a generator answers with when the person hasn't allowed
/// their content to go to the AI service. The app recognises it and asks
/// for permission instead of showing a generic error.
pub(crate) const AI_CONSENT_REQUIRED: &str = "ai_consent_required";

/// Whether this person allowed their own content (messages, moods, journal,
/// answers, profile) to be sent to the AI service. Asked in the app before
/// anything is sent — App Store guideline 5.1.2(i). A failed lookup counts
/// as "no": when in doubt, nothing leaves.
pub(crate) async fn has_ai_consent(state: &AppState, user_id: Uuid) -> bool {
    matches!(state.ai_consent.granted_at(user_id).await, Ok(Some(_)))
}

/// Guard for every handler that sends the person's own data to the model.
pub(crate) async fn require_ai_consent(state: &AppState, user_id: Uuid) -> Result<(), (StatusCode, String)> {
    if has_ai_consent(state, user_id).await {
        Ok(())
    } else {
        Err((StatusCode::FORBIDDEN, AI_CONSENT_REQUIRED.to_string()))
    }
}

/// Whether the person has an active Hearth Plus subscription. A failed
/// lookup counts as the free plan.
pub(crate) async fn is_premium(state: &AppState, user_id: Uuid) -> bool {
    state
        .subscriptions
        .for_user(user_id)
        .await
        .ok()
        .flatten()
        .is_some_and(|sub| sub.is_active())
}

/// The account behind a request, for prompt context (diagnoses, age,
/// language). Returns `None` rather than an error when the lookup fails:
/// missing context should make an answer less tailored, never fail the
/// request — callers fall back to `PersonContext::unknown()`.
pub(crate) async fn user_for(state: &AppState, user_id: Uuid) -> Option<User> {
    state.users.get(user_id).await.ok().flatten()
}

/// The other half of prompt context: the latest PHQ-9/GAD-7 reading, if
/// there is one. Same "missing just means less tailored" fallback as
/// [`user_for`] — a failed lookup returns `None` rather than failing
/// whatever generation call is asking for it.
pub(crate) async fn assessment_for(state: &AppState, user_id: Uuid) -> Option<AssessmentSummary> {
    state
        .assessments
        .latest_for_user(user_id)
        .await
        .ok()
        .flatten()
        .as_ref()
        .map(AssessmentSummary::from_assessment)
}

/// Everything about a person that goes into a prompt's "who am I writing
/// for" block, loaded once per request: the account (name, age, conditions,
/// language, their own rules for how to talk to them), the latest screening
/// and their long-term memory lines. Each part is optional — a failed lookup
/// makes an answer less tailored, never fails it.
///
/// Which parts a given generator gets is its call: see [`PersonData::context`].
pub(crate) struct PersonData {
    user: Option<User>,
    assessment: Option<AssessmentSummary>,
    memory: Vec<MemoryItem>,
}

impl PersonData {
    pub(crate) async fn load(state: &AppState, user_id: Uuid) -> Self {
        // A memory the person switched off contributes nothing.
        let memory = match state.person_memory.get(user_id).await {
            Ok(Some(memory)) if memory.enabled => memory.items,
            _ => Vec::new(),
        };
        Self {
            user: user_for(state, user_id).await,
            assessment: assessment_for(state, user_id).await,
            memory,
        }
    }

    pub(crate) fn user(&self) -> Option<&User> {
        self.user.as_ref()
    }

    /// The prompt context. `screening` adds the latest test scores and
    /// `memory` the long-term memory lines; everything else (name, age,
    /// conditions, language, their own rules) is always there.
    ///
    /// The therapist brief asks for neither of the two extras (it is built
    /// strictly from the records, and states its own screening section), the
    /// state reading leaves the memory out (it is a reading of *now*), and
    /// the daily discoveries leave the screening out.
    pub(crate) fn context(&self, screening: bool, memory: bool) -> PersonContext<'_> {
        let mut person = self.user.as_ref().map(PersonContext::from_user).unwrap_or_else(PersonContext::unknown);
        if screening {
            person = person.with_assessment(self.assessment);
        }
        if memory {
            person = person.with_memory(&self.memory);
        }
        person
    }
}

/// Gate for the life-story moderation routes. `is_admin` is granted by
/// hand against the database (see `migrations/0007_life_stories.sql`) —
/// there is no endpoint that can set it, so this check can't be defeated
/// by anything a request supplies.
pub(crate) async fn require_admin(state: &AppState, user_id: Uuid) -> Result<(), (StatusCode, String)> {
    match user_for(state, user_id).await {
        Some(user) if user.is_admin => Ok(()),
        _ => Err((StatusCode::FORBIDDEN, "admin only".to_string())),
    }
}
