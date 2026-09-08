use mental_domain::repository::ResearchRepository;
use mental_domain::{JournalEntry, MoodEntry};
use mental_knowledge_base::{Embedder, VectorStore};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};

use crate::retrieval::{format_context, retrieve_context};
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
///
/// `conversation_history` is the visible transcript so far (oldest
/// first, not including `user_message`), as kept by the Flutter client.
/// Without it every turn would be answered with no memory of what was
/// just said — a real conversation ("tell me more about that") is
/// impossible if the model can't see what "that" refers to. There is no
/// server-side session store on purpose: the client already holds the
/// transcript for display, so resending it is simpler than adding
/// stateful sessions, at the cost of the caller needing to cap its
/// length (see `ChatApi` on the Flutter side).
#[allow(clippy::too_many_arguments)]
pub async fn generate_chat_reply(
    user_message: &str,
    conversation_history: &[ChatMessage],
    recent_moods: &[MoodEntry],
    recent_journal_entries: &[JournalEntry],
    person: &crate::person::PersonContext<'_>,
    llm: &dyn LlmProvider,
    research: &dyn ResearchRepository,
    vector_store: &dyn VectorStore,
    embedder: &Embedder,
) -> anyhow::Result<ChatReplyResult> {
    let crisis = screen_for_crisis_language(user_message);

    let related = retrieve_context(user_message, 3, research, vector_store, embedder).await;

    let mood_summary = if recent_moods.is_empty() {
        "No recent check-ins.".to_string()
    } else {
        let avg_valence: f32 = recent_moods.iter().map(|m| m.valence).sum::<f32>() / recent_moods.len() as f32;
        let avg_arousal: f32 = recent_moods.iter().map(|m| m.arousal).sum::<f32>() / recent_moods.len() as f32;
        format!(
            "{} check-ins, average valence {:.2}, average energy {:.2}",
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
        "{}Recent mood: {mood_summary}\n\n\
         Recent journal excerpts:\n{}\n\n\
         Related research:\n{}",
        person.prompt_block(),
        if journal_excerpts.is_empty() { "(none)".to_string() } else { journal_excerpts },
        format_context(&related),
    );

    let mut messages = vec![
        ChatMessage { role: Role::System, content: prompts::SAFETY_SYSTEM_PROMPT.to_string() },
        ChatMessage { role: Role::System, content: prompts::chat_instruction(person.language) },
        ChatMessage { role: Role::System, content: format!("User context:\n{context}") },
    ];
    messages.extend(conversation_history.iter().cloned());
    messages.push(ChatMessage { role: Role::User, content: user_message.to_string() });

    let response = llm.chat(ChatRequest { messages, tools: vec![], temperature: None }).await?;

    Ok(ChatReplyResult { reply: response.message.content, crisis_flag: crisis.flagged })
}
