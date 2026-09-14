//! The first exchange a new account ever has with the app.
//!
//! Instead of opening with a questionnaire, onboarding opens with one
//! question in plain language — "how do you want me to be with you, and
//! what don't you want?" — answered in a chat box. This module turns
//! that free-text answer into two things at once: a real reply to show
//! them, and the standing instruction every later prompt carries (see
//! `mental_domain::chat_boundary`).
//!
//! Doing both in a single call is deliberate. Two calls would mean the
//! reply and the stored rules could disagree with each other, which is
//! the one failure mode that would actually be noticed: being told
//! "understood, no advice" and then getting advice.

use mental_domain::chat_boundary;
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};

/// What the model made of someone's answer.
pub struct IntroUnderstanding {
    /// Shown to them as the assistant's message, in their own language.
    pub reply: String,
    /// The distilled standing instruction, in English, already trimmed to
    /// `chat_boundary::MAX_BOUNDARY_NOTE_LEN`. `None` when they wrote
    /// nothing the model could turn into a rule.
    pub note: Option<String>,
    /// Slugs from `chat_boundary::CHAT_BOUNDARIES`, filtered to the ones
    /// that actually exist — a hallucinated slug is dropped rather than
    /// stored, since it would silently do nothing in a prompt.
    pub boundaries: Vec<String>,
    pub usage_tokens: Option<u32>,
}

/// Longest answer accepted from the intro box. Far more than anyone
/// types, far less than a document — the raw text goes to the model, and
/// only the distilled instruction is ever stored.
pub const MAX_INTRO_ANSWER_LEN: usize = 1_200;

pub async fn interpret_intro_answer(
    answer: &str,
    language: &str,
    llm: &dyn LlmProvider,
) -> anyhow::Result<IntroUnderstanding> {
    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
                },
                ChatMessage {
                    role: Role::System,
                    content: prompts::onboarding_intro_instruction(
                        language,
                        &chat_boundary::slug_menu(),
                        chat_boundary::MAX_BOUNDARY_NOTE_LEN,
                    ),
                },
                ChatMessage { role: Role::User, content: answer.to_string() },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    let parsed = parse_intro_json(&response.message.content)
        .ok_or_else(|| anyhow::anyhow!("could not parse onboarding intro response as JSON"))?;

    Ok(IntroUnderstanding {
        reply: parsed.reply,
        note: parsed.note,
        boundaries: parsed.boundaries,
        usage_tokens: response.usage_tokens,
    })
}

struct ParsedIntro {
    reply: String,
    note: Option<String>,
    boundaries: Vec<String>,
}

fn parse_intro_json(raw: &str) -> Option<ParsedIntro> {
    let cleaned = raw
        .trim()
        .trim_start_matches("```json")
        .trim_start_matches("```")
        .trim_end_matches("```")
        .trim();

    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    let reply = value.get("reply")?.as_str()?.trim().to_string();
    if reply.is_empty() {
        return None;
    }

    // Truncated on a character boundary, not a byte one: the instruction
    // asks for a short string but nothing enforces it on the model's
    // side, and this value goes into every prompt from here on.
    let note = value
        .get("instruction")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|n| !n.is_empty())
        .map(|n| n.chars().take(chat_boundary::MAX_BOUNDARY_NOTE_LEN).collect::<String>());

    let boundaries = value
        .get("boundaries")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str())
                .filter(|slug| chat_boundary::boundary(slug).is_some())
                .map(str::to_string)
                .collect()
        })
        .unwrap_or_default();

    Some(ParsedIntro { reply, note, boundaries })
}
