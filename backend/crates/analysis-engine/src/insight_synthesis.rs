use chrono::Utc;
use mental_domain::catalog;
use mental_domain::{Insight, ResearchArticle};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use uuid::Uuid;

/// Turns freshly-ingested research articles into short, user-facing
/// insight cards — the step that makes the research-ingest background
/// job actually visible to the user instead of just growing a database
/// silently. Capped at `max_articles` per call since each card costs one
/// LLM round-trip; the scheduler passes a small slice of a cycle's new
/// articles rather than the whole batch.
pub async fn synthesize_insights(
    articles: &[ResearchArticle],
    max_articles: usize,
    llm: &dyn LlmProvider,
) -> Vec<Insight> {
    let mut insights = Vec::new();

    for article in articles.iter().take(max_articles) {
        let user_content = format!(
            "Title: {}\n\nAbstract: {}\n\nSource tags: {}",
            article.title,
            article.abstract_text,
            article.tags.join(", ")
        );

        let messages = vec![
            ChatMessage {
                role: Role::System,
                content: prompts::insight_synthesis_instruction(&catalog::category_menu()),
            },
            ChatMessage {
                role: Role::User,
                content: user_content,
            },
        ];

        let response = match llm
            .chat(ChatRequest { messages, tools: vec![], temperature: None })
            .await
        {
            Ok(r) => r,
            Err(err) => {
                tracing::warn!(article_id = %article.id, error = %err, "insight synthesis failed");
                continue;
            }
        };

        match parse_insight_json(&response.message.content) {
            Some((title, body, tags, category)) => insights.push(Insight {
                id: Uuid::new_v4(),
                title,
                body,
                source_article_ids: vec![article.id],
                tags,
                category,
                created_at: Utc::now(),
            }),
            None => {
                tracing::warn!(article_id = %article.id, "could not parse insight synthesis response as JSON");
            }
        }
    }

    insights
}

fn parse_insight_json(raw: &str) -> Option<(String, String, Vec<String>, Option<String>)> {
    // Models occasionally wrap JSON in a markdown fence despite the
    // instruction not to; strip it defensively rather than failing the
    // whole insight.
    let cleaned = raw.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();

    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    let title = value.get("title")?.as_str()?.to_string();
    let body = value.get("body")?.as_str()?.to_string();
    let tags = value
        .get("tags")
        .and_then(|t| t.as_array())
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
        .unwrap_or_default();

    // Validated against the catalog rather than trusted: an invented slug
    // would create a category filter that matches nothing and silently hide
    // the card. Unrecognized means "uncategorized", which still shows in the
    // unfiltered feed.
    let category = value
        .get("category")
        .and_then(|c| c.as_str())
        .filter(|slug| catalog::is_category(slug))
        .map(str::to_string);

    Some((title, body, tags, category))
}
