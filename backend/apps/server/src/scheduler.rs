use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use chrono::{Duration as ChronoDuration, Timelike, Utc};

use mental_analysis_engine::{generate_disorder_explainer, synthesize_insights};
use mental_common::config::ResearchIngestConfig;
use mental_domain::catalog;
use mental_domain::repository::{
    ExplainerRepository, InsightRepository, MoodRepository, PushTokenRepository, UserRepository,
};
use mental_push::PushRequest;
use mental_research_ingest::sources::{PubMedSource, WhoRssSource};
use mental_research_ingest::{run_ingest_cycle, ResearchSource};
use tokio_cron_scheduler::{Job, JobScheduler};

use crate::routes::user_for;
use crate::state::AppState;

/// Caps how many newly-ingested articles get turned into insight cards
/// per cycle — each one costs an LLM call, so this bounds both API spend
/// and how fast the insight feed grows relative to the raw corpus.
const MAX_INSIGHTS_PER_CYCLE: usize = 5;

/// Pause between explainer generations. Generation is one LLM call that
/// takes ~30s on its own, so this isn't about rate limits — it's about
/// leaving the API free for requests a person is actually waiting on.
const EXPLAINER_GAP: Duration = Duration::from_secs(20);

/// How old a card has to be before it's rewritten. The research corpus grows
/// underneath these cards, so one written months ago rests on a smaller
/// evidence base than one written today.
const EXPLAINER_MAX_AGE_DAYS: i64 = 30;

/// How many stale cards to rewrite per run, so refreshing never crowds out
/// filling in the ones that are still missing.
const EXPLAINER_REFRESH_PER_RUN: u32 = 10;

/// The one language the warm-up pre-builds; every other language is filled
/// in lazily on first request.
const EXPLAINER_WARMUP_LANGUAGE: &str = "tr";

/// Fills in the disorder-explainer cache in the background, one condition at
/// a time, so that opening a card is a database read rather than a ~30s LLM
/// call. That wait was the real bug behind the timeouts on the guide screen:
/// over a tunnel, a cold card could outlive the client's patience entirely.
///
/// Missing slugs are generated first, so a restart resumes where the last run
/// stopped instead of paying for the whole catalog again; a handful of the
/// oldest cards are then rewritten per run so the guide keeps up with the
/// research that has been ingested since they were written.
pub fn spawn_explainer_warmup_job(state: AppState) {
    tokio::spawn(async move {
        // Only Turkish is pre-warmed: it's what almost every account reads,
        // and warming a second language would double a job that already
        // spends ~150 LLM calls. English cards generate on first request
        // and are cached from then on (see `routes::catalog::explainer`).
        let cached = match state
            .explainers
            .cached_slugs(EXPLAINER_WARMUP_LANGUAGE)
            .await
        {
            Ok(slugs) => slugs,
            Err(err) => {
                tracing::warn!(error = %err, "explainer warm-up: could not read cache, skipping");
                return;
            }
        };

        let missing: Vec<String> = catalog::CATEGORIES
            .iter()
            .flat_map(|category| category.disorders.iter())
            .map(|disorder| disorder.slug.to_string())
            .filter(|slug| !cached.contains(slug))
            .collect();

        // Missing cards first — someone opening one of those waits ~30s
        // today. Stale cards are only a freshness problem, so they come
        // after, and only a few per run.
        let cutoff = Utc::now() - ChronoDuration::days(EXPLAINER_MAX_AGE_DAYS);
        let stale = state
            .explainers
            .stale_slugs(cutoff, EXPLAINER_REFRESH_PER_RUN, EXPLAINER_WARMUP_LANGUAGE)
            .await
            .unwrap_or_default();

        if missing.is_empty() && stale.is_empty() {
            tracing::info!("explainer warm-up: cache complete and current");
            return;
        }

        tracing::info!(
            missing = missing.len(),
            stale = stale.len(),
            "explainer warm-up starting"
        );

        for slug in missing.into_iter().chain(stale) {
            match generate_disorder_explainer(
                &slug,
                EXPLAINER_WARMUP_LANGUAGE,
                state.llm.as_ref(),
                state.research.as_ref(),
                state.vector_store.as_ref(),
                state.embedder.as_ref(),
            )
            .await
            {
                Ok(explainer) => {
                    if let Err(err) = state.explainers.save(&explainer).await {
                        tracing::warn!(error = %err, slug, "explainer warm-up: save failed");
                    }
                }
                // One condition failing (bad JSON, a transient API error)
                // shouldn't stop the other hundred-odd from being filled in.
                Err(err) => {
                    tracing::warn!(error = %err, slug, "explainer warm-up: generation failed")
                }
            }

            tokio::time::sleep(EXPLAINER_GAP).await;
        }

        tracing::info!("explainer warm-up complete");
    });
}

/// Wires up the recurring research-ingest job described in
/// `research-ingest`'s crate docs: every `interval_hours`, pull from each
/// configured source, feed new articles into the knowledge base, then
/// synthesize a handful of them into user-facing insight cards. This is
/// the one background loop the whole system runs continuously; a panic
/// inside a single cycle is caught by `run_ingest_cycle`'s per-source
/// error handling so the scheduler itself never dies.
pub async fn spawn_research_ingest_job(
    state: AppState,
    config: ResearchIngestConfig,
) -> anyhow::Result<()> {
    let sources = build_sources(&config.sources);
    let schedule = format!("0 0 */{} * * *", config.interval_hours.max(1));

    // Run one cycle immediately on startup instead of waiting for the next
    // cron tick (up to `interval_hours` away) — otherwise the insight feed
    // would sit empty for hours after every fresh install/restart.
    {
        let state = state.clone();
        let sources = sources.clone();
        tokio::spawn(async move {
            run_cycle(&state, &sources).await;
        });
    }

    let scheduler = JobScheduler::new().await?;
    let job = Job::new_async(schedule.as_str(), move |_uuid, _lock| {
        let state = state.clone();
        let sources = sources.clone();
        Box::pin(async move { run_cycle(&state, &sources).await })
    })?;

    scheduler.add(job).await?;
    scheduler.start().await?;

    Ok(())
}

async fn run_cycle(state: &AppState, sources: &[Arc<dyn ResearchSource>]) {
    let summary = run_ingest_cycle(
        sources,
        state.research.as_ref(),
        state.vector_store.as_ref(),
        state.embedder.as_ref(),
    )
    .await;

    tracing::info!(
        fetched = summary.fetched,
        new_articles = summary.new_articles,
        errors = ?summary.errors,
        "research ingest cycle complete"
    );

    if !summary.added_articles.is_empty() {
        let insights = synthesize_insights(
            &summary.added_articles,
            MAX_INSIGHTS_PER_CYCLE,
            state.llm.as_ref(),
        )
        .await;

        for insight in &insights {
            if let Err(err) = state.insights.save(insight).await {
                tracing::warn!(error = %err, "failed to save synthesized insight");
            }
        }

        tracing::info!(generated = insights.len(), "insight synthesis complete");
    }
}

/// Each topic below runs as its own PubMed query so a person struggling
/// with e.g. bipolar disorder specifically gets a knowledge base that
/// actually covers it, rather than diluting everything into one generic
/// "mental health" search. `recovery` deliberately queries for published,
/// peer-reviewed qualitative research about lived experience and recovery
/// pathways — real accounts of how people got better — sourced the same
/// vetted way as the clinical topics, instead of scraping personal
/// stories from social media (which would be a privacy and
/// misinformation risk; see docs/DATA_SOURCES.md).
fn build_sources(names: &[String]) -> Vec<Arc<dyn ResearchSource>> {
    names
        .iter()
        .filter_map(|name| match name.as_str() {
            "pubmed_general" => Some(pubmed(
                "pubmed:general",
                "(psychology OR psychiatry OR mental health)[Title] AND (\"last 30 days\"[PDat])",
                vec!["mental-health"],
            )),
            "pubmed_ptsd" => Some(pubmed(
                "pubmed:ptsd",
                "(PTSD OR \"posttraumatic stress\")[Title/Abstract] AND (treatment OR therapy OR recovery)[Title/Abstract]",
                vec!["ptsd", "trauma"],
            )),
            "pubmed_bipolar" => Some(pubmed(
                "pubmed:bipolar",
                "\"bipolar disorder\"[Title/Abstract] AND (treatment OR management OR recovery)[Title/Abstract]",
                vec!["bipolar"],
            )),
            "pubmed_anxiety_depression" => Some(pubmed(
                "pubmed:anxiety_depression",
                "(anxiety OR depression)[Title] AND (coping OR treatment OR \"cognitive behavioral\")[Title/Abstract]",
                vec!["anxiety", "depression"],
            )),
            "pubmed_recovery" => Some(pubmed(
                "pubmed:recovery",
                "(\"lived experience\" OR \"recovery narrative\" OR \"qualitative study\") AND (PTSD OR bipolar OR \"mental illness\")",
                vec!["recovery-story", "lived-experience"],
            )),
            "pubmed_borderline" => Some(pubmed(
                "pubmed:borderline",
                "\"borderline personality disorder\"[Title/Abstract] AND (treatment OR therapy OR management OR recovery)[Title/Abstract]",
                vec!["borderline", "personality-disorder"],
            )),
            "pubmed_ocd" => Some(pubmed(
                "pubmed:ocd",
                "(\"obsessive-compulsive disorder\" OR OCD)[Title/Abstract] AND (treatment OR therapy OR management)[Title/Abstract]",
                vec!["ocd"],
            )),
            "pubmed_schizophrenia" => Some(pubmed(
                "pubmed:schizophrenia",
                "schizophrenia[Title/Abstract] AND (treatment OR therapy OR management OR recovery)[Title/Abstract]",
                vec!["schizophrenia", "psychosis"],
            )),
            // Kept available but not in the default source list: WHO's
            // general news feed covers all of global health (outbreaks,
            // vaccines, policy...), not specifically mental illness, so it
            // was diluting the insight feed with content unrelated to any
            // named condition. Re-add "who" to config/default.toml if a
            // general-health-news card type is wanted again later.
            "who" => Some(Arc::new(WhoRssSource::new(
                "https://www.who.int/rss-feeds/news-english.xml",
            )) as Arc<dyn ResearchSource>),
            other => {
                tracing::warn!("unknown research source in config: {other}");
                None
            }
        })
        .collect()
}

fn pubmed(label: &'static str, query: &str, tags: Vec<&str>) -> Arc<dyn ResearchSource> {
    Arc::new(PubMedSource::new(
        label,
        query,
        15,
        tags.into_iter().map(str::to_string).collect(),
    ))
}

/// Daily check-in reminders at 09:00, 14:00 and the evening hour each person picked
/// (Ayarlar → Bildirimler; 21:00 unless they changed it).
///
/// Runs every minute so users in half-hour and quarter-hour time zones
/// still receive reminders exactly on the hour in their local time. For
/// each account with a registered device it checks that the reminder is
/// on, that the local time matches one of the three slots, and that they
/// haven't logged a mood yet that local day.
/// `claim_checkin_reminder` claims that date+slot atomically, so a restart
/// or a second server process can't send the same slot twice.
///
/// The morning and afternoon slots are fixed; the evening slot is
/// configurable and all three are controlled by the same setting.
pub fn spawn_checkin_nudge_job(state: AppState) {
    tokio::spawn(async move {
        let scheduler = match JobScheduler::new().await {
            Ok(scheduler) => scheduler,
            Err(err) => {
                tracing::warn!(error = %err, "check-in nudge: failed to create scheduler");
                return;
            }
        };

        let job = match Job::new_async("0 * * * * *", move |_uuid, _lock| {
            let state = state.clone();
            Box::pin(async move { run_checkin_nudge(&state).await })
        }) {
            Ok(job) => job,
            Err(err) => {
                tracing::warn!(error = %err, "check-in nudge: failed to build job");
                return;
            }
        };

        if let Err(err) = scheduler.add(job).await {
            tracing::warn!(error = %err, "check-in nudge: failed to schedule job");
            return;
        }
        if let Err(err) = scheduler.start().await {
            tracing::warn!(error = %err, "check-in nudge: failed to start scheduler");
        }
    });
}

async fn run_checkin_nudge(state: &AppState) {
    let user_ids = match state.push_tokens.all_user_ids().await {
        Ok(ids) => ids,
        Err(err) => {
            tracing::warn!(error = %err, "check-in nudge: failed to list candidates");
            return;
        }
    };

    let now = Utc::now();
    let mut nudged = 0u32;

    for user_id in user_ids {
        let Some(user) = user_for(state, user_id).await else {
            continue;
        };
        if !user.checkin_reminder_enabled {
            continue;
        }

        let offset = ChronoDuration::minutes(i64::from(user.utc_offset_minutes));
        let local_now = now + offset;
        let Some(slot) = checkin_reminder_slot(
            local_now.hour(),
            local_now.minute(),
            user.checkin_reminder_hour,
        ) else {
            continue;
        };

        let local_date = local_now.date_naive();
        let Some(local_midnight) = local_date.and_hms_opt(0, 0, 0) else {
            continue;
        };
        let day_start =
            chrono::DateTime::<Utc>::from_naive_utc_and_offset(local_midnight, Utc) - offset;

        // "Couldn't tell" counts as "already logged": a failed lookup must
        // never turn into a reminder someone didn't need.
        let logged_today = state
            .moods
            .list_between(user_id, day_start, now)
            .await
            .map(|entries| !entries.is_empty())
            .unwrap_or(true);
        if logged_today {
            continue;
        }

        let tokens = state
            .push_tokens
            .tokens_for_user(user_id)
            .await
            .unwrap_or_default();
        if tokens.is_empty() {
            continue;
        }

        match state
            .users
            .claim_checkin_reminder(user_id, local_date, slot)
            .await
        {
            Ok(true) => {}
            Ok(false) => continue,
            Err(err) => {
                tracing::warn!(error = %err, "check-in nudge: failed to claim today's reminder");
                continue;
            }
        }

        let (title, body) = checkin_nudge_text(&user.language, slot);
        let mut data = HashMap::new();
        data.insert("type".to_string(), "checkin_nudge".to_string());
        data.insert("slot".to_string(), slot.to_string());

        for token in tokens {
            let request = PushRequest {
                token,
                title: title.clone(),
                body: body.clone(),
                data: data.clone(),
            };
            if let Err(err) = state.push.send(request).await {
                tracing::warn!(error = %err, "check-in nudge: send failed");
            }
        }
        nudged += 1;
    }

    if nudged > 0 {
        tracing::info!(nudged, "check-in nudge cycle complete");
    }
}

fn checkin_nudge_text(language: &str, slot: &str) -> (String, String) {
    match (language, slot) {
        ("en", "morning") => (
            "Good morning".to_string(),
            "Take a moment to notice how you are feeling as the day begins.".to_string(),
        ),
        ("en", "afternoon") => (
            "Midday check-in".to_string(),
            "How has your day been going so far?".to_string(),
        ),
        ("en", _) => (
            "How was today?".to_string(),
            "A short check-in can help you reflect on your day.".to_string(),
        ),
        (_, "morning") => (
            "Günaydın".to_string(),
            "Güne nasıl başladığını fark etmek için kendine kısa bir mola ver.".to_string(),
        ),
        (_, "afternoon") => (
            "Günün nasıl gidiyor?".to_string(),
            "Şu ana kadar nasıl hissettiğini fark etmek için kendine zaman ayır.".to_string(),
        ),
        _ => (
            "Bugün nasıldı?".to_string(),
            "Bugünü değerlendirmek için kendine kısa bir zaman ayır.".to_string(),
        ),
    }
}


/// Returns a reminder slot only at the exact local minute, not merely
/// somewhere within the hour. This matters for UTC offsets such as +05:30.
fn checkin_reminder_slot(hour: u32, minute: u32, evening_hour: u8) -> Option<&'static str> {
    if minute != 0 {
        return None;
    }
    match hour {
        9 => Some("morning"),
        14 => Some("afternoon"),
        h if h == u32::from(evening_hour) => Some("evening"),
        _ => None,
    }
}

#[cfg(test)]
mod checkin_reminder_tests {
    use super::checkin_reminder_slot;

    #[test]
    fn reminder_slots_match_exact_local_hours() {
        assert_eq!(checkin_reminder_slot(9, 0, 21), Some("morning"));
        assert_eq!(checkin_reminder_slot(14, 0, 21), Some("afternoon"));
        assert_eq!(checkin_reminder_slot(21, 0, 21), Some("evening"));
        assert_eq!(checkin_reminder_slot(19, 0, 19), Some("evening"));
    }

    #[test]
    fn reminder_slots_do_not_match_other_minutes_or_hours() {
        assert_eq!(checkin_reminder_slot(9, 30, 21), None);
        assert_eq!(checkin_reminder_slot(14, 1, 21), None);
        assert_eq!(checkin_reminder_slot(20, 0, 21), None);
    }
}
