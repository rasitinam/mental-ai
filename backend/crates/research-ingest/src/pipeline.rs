use std::sync::Arc;

use chrono::Utc;
use mental_domain::repository::ResearchRepository;
use mental_domain::ResearchArticle;
use mental_knowledge_base::{Embedder, VectorStore};
use uuid::Uuid;

use crate::sources::ResearchSource;

#[derive(Debug, Default)]
pub struct IngestSummary {
    pub fetched: usize,
    pub new_articles: usize,
    pub errors: Vec<String>,
}

/// Runs one ingestion pass across all configured sources: fetch, dedup
/// against `ResearchRepository`, embed new articles, upsert into both the
/// relational store and the vector store. Called on a timer from
/// `apps/server`; a single failing source is logged and skipped rather
/// than aborting the whole cycle.
pub async fn run_ingest_cycle(
    sources: &[Arc<dyn ResearchSource>],
    repository: &dyn ResearchRepository,
    vector_store: &dyn VectorStore,
    embedder: &Embedder,
) -> IngestSummary {
    let mut summary = IngestSummary::default();

    for source in sources {
        let raw_articles = match source.fetch_recent().await {
            Ok(articles) => articles,
            Err(err) => {
                summary.errors.push(format!("{}: {err}", source.name()));
                continue;
            }
        };
        summary.fetched += raw_articles.len();

        let mut fresh = Vec::new();
        for raw in raw_articles {
            let already_have = repository
                .exists(&raw.source, &raw.external_id)
                .await
                .unwrap_or(false);
            if !already_have {
                fresh.push(ResearchArticle {
                    id: Uuid::new_v4(),
                    source: raw.source,
                    external_id: raw.external_id,
                    title: raw.title,
                    abstract_text: raw.abstract_text,
                    url: raw.url,
                    published_at: raw.published_at,
                    tags: raw.tags,
                    ingested_at: Utc::now(),
                });
            }
        }

        if fresh.is_empty() {
            continue;
        }

        if let Err(err) = repository.upsert_many(&fresh).await {
            summary.errors.push(format!("{}: storage error: {err}", source.name()));
            continue;
        }

        for article in &fresh {
            let text = format!("{}\n\n{}", article.title, article.abstract_text);
            match embedder.embed_one(&text).await {
                Ok(embedding) => {
                    if let Err(err) = vector_store.upsert(article.id, &embedding).await {
                        summary.errors.push(format!("embedding store error: {err}"));
                    }
                }
                Err(err) => summary.errors.push(format!("embedding error: {err}")),
            }
        }

        summary.new_articles += fresh.len();
    }

    summary
}
