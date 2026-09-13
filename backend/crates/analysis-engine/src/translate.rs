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

/// Translates a daily report's user-facing text — `summary` and each
/// `recommendations` line — in one call. `mood_trend_note` is left out: it
/// is computed, not shown anywhere in the app, so translating it would
/// just be a wasted round of tokens.
pub async fn translate_daily_report(
    summary: &str,
    recommendations: &[String],
    target_language: &str,
    llm: &dyn LlmProvider,
) -> anyhow::Result<(String, Vec<String>)> {
    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: format!(
                        "You are a translation engine. Translate the summary and the \
                         recommendation list into {}. Preserve tone, meaning and the number of \
                         recommendations. Reply with JSON only, exactly: \
                         {{\"summary\": \"...\", \"recommendations\": [\"...\"]}}",
                        language_name(target_language)
                    ),
                },
                ChatMessage {
                    role: Role::User,
                    content: format!(
                        "Summary: {summary}\n\nRecommendations:\n{}",
                        recommendations.join("\n")
                    ),
                },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    let cleaned = clean_json(&response.message.content);
    if let Ok(value) = serde_json::from_str::<serde_json::Value>(cleaned) {
        if let Some(translated_summary) = value.get("summary").and_then(|v| v.as_str()) {
            let translated_recommendations = value
                .get("recommendations")
                .and_then(|v| v.as_array())
                .map(|arr| arr.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
                .unwrap_or_default();
            return Ok((translated_summary.to_string(), translated_recommendations));
        }
    }

    let translated_summary = translate_text(summary, target_language, llm).await?;
    let mut translated_recommendations = Vec::with_capacity(recommendations.len());
    for item in recommendations {
        translated_recommendations.push(translate_text(item, target_language, llm).await?);
    }
    Ok((translated_summary, translated_recommendations))
}

/// Translates a life analysis's user-facing text — `narrative`,
/// `key_patterns`, `do_list` and `dont_list` — in one call.
pub async fn translate_life_analysis(
    narrative: &str,
    key_patterns: &[String],
    do_list: &[String],
    dont_list: &[String],
    target_language: &str,
    llm: &dyn LlmProvider,
) -> anyhow::Result<(String, Vec<String>, Vec<String>, Vec<String>)> {
    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: format!(
                        "You are a translation engine. Translate the narrative and the three \
                         lists into {}. Preserve tone, meaning and each list's item count. \
                         Reply with JSON only, exactly: {{\"narrative\": \"...\", \
                         \"key_patterns\": [\"...\"], \"do_list\": [\"...\"], \"dont_list\": \
                         [\"...\"]}}",
                        language_name(target_language)
                    ),
                },
                ChatMessage {
                    role: Role::User,
                    content: format!(
                        "Narrative: {narrative}\n\nKey patterns:\n{}\n\nDo:\n{}\n\nDon't:\n{}",
                        key_patterns.join("\n"),
                        do_list.join("\n"),
                        dont_list.join("\n"),
                    ),
                },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    let cleaned = clean_json(&response.message.content);
    if let Ok(value) = serde_json::from_str::<serde_json::Value>(cleaned) {
        if let Some(translated_narrative) = value.get("narrative").and_then(|v| v.as_str()) {
            return Ok((
                translated_narrative.to_string(),
                string_array(&value, "key_patterns"),
                string_array(&value, "do_list"),
                string_array(&value, "dont_list"),
            ));
        }
    }

    let translated_narrative = translate_text(narrative, target_language, llm).await?;
    Ok((
        translated_narrative,
        translate_each(key_patterns, target_language, llm).await?,
        translate_each(do_list, target_language, llm).await?,
        translate_each(dont_list, target_language, llm).await?,
    ))
}

/// Translates the current-state snapshot's `headline` and `note`. `basis`
/// is not included — those are fixed labels the app itself picks by
/// language, not model output (see `current_state::basis_label`).
pub async fn translate_current_state(
    headline: &str,
    note: &str,
    target_language: &str,
    llm: &dyn LlmProvider,
) -> anyhow::Result<(String, String)> {
    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: format!(
                        "You are a translation engine. Translate the headline and note into \
                         {}. Preserve tone and meaning. Reply with JSON only, exactly: \
                         {{\"headline\": \"...\", \"note\": \"...\"}}",
                        language_name(target_language)
                    ),
                },
                ChatMessage {
                    role: Role::User,
                    content: format!("Headline: {headline}\n\nNote: {note}"),
                },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    let cleaned = clean_json(&response.message.content);
    if let Ok(value) = serde_json::from_str::<serde_json::Value>(cleaned) {
        if let (Some(h), Some(n)) =
            (value.get("headline").and_then(|v| v.as_str()), value.get("note").and_then(|v| v.as_str()))
        {
            return Ok((h.to_string(), n.to_string()));
        }
    }

    Ok((
        translate_text(headline, target_language, llm).await?,
        translate_text(note, target_language, llm).await?,
    ))
}

fn clean_json(raw: &str) -> &str {
    raw.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim()
}

fn string_array(value: &serde_json::Value, key: &str) -> Vec<String> {
    value
        .get(key)
        .and_then(|v| v.as_array())
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
        .unwrap_or_default()
}

async fn translate_each(
    items: &[String],
    target_language: &str,
    llm: &dyn LlmProvider,
) -> anyhow::Result<Vec<String>> {
    let mut out = Vec::with_capacity(items.len());
    for item in items {
        out.push(translate_text(item, target_language, llm).await?);
    }
    Ok(out)
}
