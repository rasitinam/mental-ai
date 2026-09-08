use chrono::Utc;
use mental_domain::catalog;
use mental_domain::repository::ResearchRepository;
use mental_domain::DisorderExplainer;
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use mental_knowledge_base::{Embedder, VectorStore};

use crate::retrieval::{format_context, retrieve_context};

/// Builds the educational card for one condition in the catalog: what it is,
/// how it tends to develop, what helps day to day, and what professional
/// treatment looks like.
///
/// Grounded in the ingested research corpus rather than the model's memory
/// alone — this is the part of the app that makes claims about clinical
/// conditions, so it should rest on the same vetted PubMed/WHO material the
/// rest of the feed does. Callers cache the result (`disorder_explainers`);
/// nothing here writes to the database.
pub async fn generate_disorder_explainer(
    slug: &str,
    language: &str,
    llm: &dyn LlmProvider,
    research: &dyn ResearchRepository,
    vector_store: &dyn VectorStore,
    embedder: &Embedder,
) -> anyhow::Result<DisorderExplainer> {
    let (category, disorder) = catalog::disorder(slug)
        .ok_or_else(|| anyhow::anyhow!("unknown disorder slug: {slug}"))?;

    let query = format!("{} {} nedir, nedenleri ve tedavisi", disorder.name, category.name);
    let articles = retrieve_context(&query, 5, research, vector_store, embedder).await;

    let user_content = format!(
        "Condition: {} (category: {})\n\n\
         Related research abstracts:\n{}",
        disorder.name,
        category.name,
        format_context(&articles)
    );

    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
                },
                ChatMessage {
                    role: Role::System,
                    content: prompts::disorder_explainer_instruction(language),
                },
                ChatMessage {
                    role: Role::User,
                    content: user_content,
                },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    let parsed = parse_explainer_json(&response.message.content)
        .ok_or_else(|| anyhow::anyhow!("could not parse explainer response as JSON"))?;

    Ok(DisorderExplainer {
        slug: disorder.slug.to_string(),
        category: category.slug.to_string(),
        name: disorder.name.to_string(),
        what_it_is: parsed.0,
        how_it_develops: parsed.1,
        coping_paths: parsed.2,
        treatment_paths: parsed.3,
        generated_at: Utc::now(),
    })
}

fn parse_explainer_json(raw: &str) -> Option<(String, String, Vec<String>, Vec<String>)> {
    let cleaned = raw.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();

    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    let what_it_is = value.get("what_it_is")?.as_str()?.to_string();
    let how_it_develops = value.get("how_it_develops")?.as_str()?.to_string();

    Some((
        what_it_is,
        how_it_develops,
        string_list(&value, "coping_paths"),
        string_list(&value, "treatment_paths"),
    ))
}

fn string_list(value: &serde_json::Value, key: &str) -> Vec<String> {
    value
        .get(key)
        .and_then(|v| v.as_array())
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
        .unwrap_or_default()
}
