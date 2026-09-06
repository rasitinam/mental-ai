use std::sync::Arc;

use mental_analysis_engine::synthesize_insights;
use mental_common::config::ResearchIngestConfig;
use mental_domain::repository::InsightRepository;
use mental_research_ingest::sources::{PubMedSource, WhoRssSource};
use mental_research_ingest::{run_ingest_cycle, ResearchSource};
use tokio_cron_scheduler::{Job, JobScheduler};

use crate::state::AppState;

/// Caps how many newly-ingested articles get turned into insight cards
/// per cycle — each one costs an LLM call, so this bounds both API spend
/// and how fast the insight feed grows relative to the raw corpus.
const MAX_INSIGHTS_PER_CYCLE: usize = 5;

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
        let insights = synthesize_insights(&summary.added_articles, MAX_INSIGHTS_PER_CYCLE, state.llm.as_ref()).await;

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
