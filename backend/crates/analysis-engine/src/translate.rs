use mental_llm_connector::{prompts::language_name, ChatMessage, ChatRequest, LlmProvider, Role};

/// Translates one story's body into `target_language` for a reader whose
/// account language differs from the language it was written in. No
/// safety system prompt here — this is a mechanical translation task, not
/// a conversation, and wrapping it in the product's conversational voice
/// would risk the model "replying to" the story instead of just
/// translating it.
pub async fn translate_text(
    text: &str,
    target_language: &str,
    llm: &dyn LlmProvider,
) -> anyhow::Result<String> {
    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: format!(
                        "You are a translation engine. Translate the user's text into {}. \
                         Preserve tone, meaning and paragraph breaks. Output ONLY the \
                         translated text — no quotes, no commentary, no original text.",
                        language_name(target_language)
                    ),
                },
                ChatMessage { role: Role::User, content: text.to_string() },
            ],
            tools: vec![],
            // Not every configured model accepts a non-default
            // temperature (some reject anything but 1) — same reason
            // every other generator in this crate leaves this `None`.
            temperature: None,
        })
        .await?;

    Ok(response.message.content.trim().to_string())
}
