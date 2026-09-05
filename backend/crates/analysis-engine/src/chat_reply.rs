use mental_domain::{JournalEntry, MoodEntry};
use mental_knowledge_base::{Embedder, VectorStore};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};

use crate::safety::screen_for_crisis_language;

pub struct ChatReplyResult {
    pub reply: String,
    pub crisis_flag: bool,
}

/// Answers one chat turn, personalized with the user's recent mood/
/// journal history and grounded with research snippets relevant to
/// *this* message — the "nabza göre şerbet" (tailored, not generic)
/// behavior: two people sending the same words get different replies if
/// their recent context differs. `recent_moods`/`recent_journal_entries`
/// are expected to already be scoped to a short window (a few days) by
/// the caller so the prompt doesn't grow unbounded over a long-lived
/// account.
pub async fn generate_chat_reply(
    user_message: &str,
    recent_moods: &[MoodEntry],
    recent_journal_entries: &[JournalEntry],
    llm: &dyn LlmProvider,
    vector_store: &dyn VectorStore,
    embedder: &Embedder,
) -> anyhow::Result<ChatReplyResult> {
    let crisis = screen_for_crisis_language(user_message);

    let query_embedding = embedder.embed_one(user_message).await.unwrap_or_default();
    let related = if query_embedding.is_empty() {
        vec![]
    } else {
        vector_store.search(&query_embedding, 3).await.unwrap_or_default()
    };

    let mood_summary = if recent_moods.is_empty() {
        "No recent mood check-ins.".to_string()
    } else {
        let avg_valence: f32 = recent_moods.iter().map(|m| m.valence).sum::<f32>() / recent_moods.len() as f32;
        let avg_arousal: f32 = recent_moods.iter().map(|m| m.arousal).sum::<f32>() / recent_moods.len() as f32;
        format!(
            "{} recent check-ins, average valence {:.2}, average arousal {:.2}",
            recent_moods.len(),
            avg_valence,
            avg_arousal
        )
    };

    let journal_excerpts = recent_journal_entries
        .iter()
        .rev()
        .take(3)
        .map(|j| format!("- {}", j.body.chars().take(200).collect::<String>()))
        .collect::<Vec<_>>()
        .join("\n");

    let context = format!(
        "Recent mood: {mood_summary}\n\nRecent journal excerpts:\n{}\n\nRelated research snippets: {} found\n{}",
        if journal_excerpts.is_empty() { "(none)".to_string() } else { journal_excerpts },
        related.len(),
        related
            .iter()
            .map(|r| format!("- article {} (relevance {:.2})", r.article_id, r.score))
            .collect::<Vec<_>>()
            .join("\n"),
    );

    let messages = vec![
        ChatMessage { role: Role::System, content: prompts::SAFETY_SYSTEM_PROMPT.to_string() },
        ChatMessage { role: Role::System, content: prompts::chat_instruction().to_string() },
        ChatMessage { role: Role::System, content: format!("User context:\n{context}") },
        ChatMessage { role: Role::User, content: user_message.to_string() },
    ];

    let response = llm.chat(ChatRequest { messages, tools: vec![], temperature: None }).await?;

    Ok(ChatReplyResult { reply: response.message.content, crisis_flag: crisis.flagged })
}
