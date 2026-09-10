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

/// Translates a titled card (a research insight) in one call rather than
/// two. Falls back to translating the body alone if the model doesn't come
/// back with parseable JSON — a card with an untranslated title still reads
/// better than no translation at all.
pub async fn translate_card(
    title: &str,
    body: &str,
    target_language: &str,
    llm: &dyn LlmProvider,
) -> anyhow::Result<(String, String)> {
    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: format!(
                        "You are a translation engine. Translate the title and body into {}. \
                         Preserve tone and meaning. Reply with JSON only, exactly: \
                         {{\"title\": \"...\", \"body\": \"...\"}}",
                        language_name(target_language)
                    ),
                },
                ChatMessage {
                    role: Role::User,
                    content: format!("Title: {title}\n\nBody: {body}"),
                },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    let raw = response.message.content.trim();
    let cleaned = raw
        .trim_start_matches("```json")
        .trim_start_matches("```")
        .trim_end_matches("```")
        .trim();

    if let Ok(value) = serde_json::from_str::<serde_json::Value>(cleaned) {
        if let (Some(t), Some(b)) = (
            value.get("title").and_then(|v| v.as_str()),
            value.get("body").and_then(|v| v.as_str()),
        ) {
            return Ok((t.to_string(), b.to_string()));
        }
    }

    let translated_body = translate_text(body, target_language, llm).await?;
    Ok((title.to_string(), translated_body))
}
