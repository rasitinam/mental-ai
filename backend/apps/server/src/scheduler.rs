use std::sync::Arc;

use mental_common::config::ResearchIngestConfig;
use mental_research_ingest::sources::{PubMedSource, WhoRssSource};
use mental_research_ingest::{run_ingest_cycle, ResearchSource};
use tokio_cron_scheduler::{Job, JobScheduler};

use crate::state::AppState;

/// Wires up the recurring research-ingest job described in
/// `research-ingest`'s crate docs: every `interval_hours`, pull from each
/// configured source and feed new articles into the knowledge base. This
/// is the one background loop the whole system runs continuously; a
/// panic inside a single cycle is caught by `run_ingest_cycle`'s
/// per-source error handling so the scheduler itself never dies.
pub async fn spawn_research_ingest_job(
    state: AppState,
    config: ResearchIngestConfig,
) -> anyhow::Result<()> {
    let sources = build_sources(&config.sources);
    let schedule = format!("0 0 */{} * * *", config.interval_hours.max(1));

    let scheduler = JobScheduler::new().await?;
    let job = Job::new_async(schedule.as_str(), move |_uuid, _lock| {
        let state = state.clone();
        let sources = sources.clone();
        Box::pin(async move {
            let summary = run_ingest_cycle(
                &sources,
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
        })
    })?;

    scheduler.add(job).await?;
    scheduler.start().await?;

    Ok(())
}

fn build_sources(names: &[String]) -> Vec<Arc<dyn ResearchSource>> {
    names
        .iter()
        .filter_map(|name| match name.as_str() {
            "pubmed" => Some(Arc::new(PubMedSource::new(
                "(psychology OR psychiatry OR mental health)[Title] AND (\"last 30 days\"[PDat])",
                20,
            )) as Arc<dyn ResearchSource>),
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
