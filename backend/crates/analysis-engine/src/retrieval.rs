use mental_domain::repository::ResearchRepository;
use mental_domain::ResearchArticle;
use mental_knowledge_base::{Embedder, VectorStore};

/// One retrieval step: embed the query, find the closest articles, then load
/// their actual text.
///
/// The last part is the point. `VectorStore::search` only returns ids and
/// scores, so passing its output straight into a prompt gives the model a
/// list of UUIDs — retrieval with nothing retrieved. Every caller that wants
/// grounded output should go through here.
///
/// Failures are swallowed into an empty context on purpose: a missing
/// embedding or an unreachable embedding API should degrade the answer to
/// "ungrounded but still useful", not fail the whole request.
pub async fn retrieve_context(
    query: &str,
    top_k: usize,
    research: &dyn ResearchRepository,
    vector_store: &dyn VectorStore,
    embedder: &Embedder,
) -> Vec<ResearchArticle> {
    if query.trim().is_empty() {
        return vec![];
    }

    let Ok(embedding) = embedder.embed_one(query).await else {
        return vec![];
    };
    if embedding.is_empty() {
        return vec![];
    }

    let hits = vector_store.search(&embedding, top_k).await.unwrap_or_default();
    let ids: Vec<_> = hits.iter().map(|hit| hit.article_id).collect();

    research.get_many(&ids).await.unwrap_or_default()
}

/// Formats retrieved articles for a prompt. Abstracts are truncated because a
/// handful of full abstracts can dwarf the actual user context they're
/// supposed to support.
pub fn format_context(articles: &[ResearchArticle]) -> String {
    if articles.is_empty() {
        return "(ilgili araştırma bulunamadı)".to_string();
    }

    articles
        .iter()
        .map(|article| {
            let abstract_text: String = article.abstract_text.chars().take(700).collect();
            format!(
                "- [{}] {}\n  Özet: {}\n  Kaynak: {}",
                article.id, article.title, abstract_text, article.url
            )
        })
        .collect::<Vec<_>>()
        .join("\n")
}
