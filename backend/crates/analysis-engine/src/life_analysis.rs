use chrono::{DateTime, Utc};
use mental_domain::report::LifeAnalysis;
use mental_domain::{JournalEntry, MoodEntry};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use uuid::Uuid;

/// Longer-horizon pattern summary (weekly/monthly) over mood and journal
/// history. Shares the same safety system prompt as the daily report;
/// unlike the daily report this does not run RAG retrieval per call since
/// it summarizes the user's own history rather than answering a specific
/// question.
pub async fn generate_life_analysis(
    user_id: Uuid,
    period_start: DateTime<Utc>,
    period_end: DateTime<Utc>,
    moods: &[MoodEntry],
    journal_entries: &[JournalEntry],
    llm: &dyn LlmProvider,
) -> anyhow::Result<LifeAnalysis> {
    let mood_series = moods
        .iter()
        .map(|m| format!("{}: valence={:.2} arousal={:.2}", m.recorded_at, m.valence, m.arousal))
        .collect::<Vec<_>>()
        .join("\n");

    let journal_titles = journal_entries
        .iter()
        .map(|j| format!("- {}", j.body.chars().take(120).collect::<String>()))
        .collect::<Vec<_>>()
        .join("\n");

    let user_content = format!(
        "Mood series for the period:\n{mood_series}\n\nJournal entries (truncated):\n{journal_titles}"
    );

    let messages = vec![
        ChatMessage {
            role: Role::System,
            content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
        },
        ChatMessage {
            role: Role::System,
            content: "Write a compassionate narrative (5-8 sentences) describing the \
                      patterns you notice across this period. Do not diagnose. \
                      Separately, list 3-5 short bullet points naming the key \
                      recurring patterns.\n\n\
                      Respond as JSON: {\"narrative\": \"...\", \"key_patterns\": \
                      [\"...\", \"...\"]}. Both the narrative and every pattern must \
                      be written in Turkish."
                .to_string(),
        },
        ChatMessage {
            role: Role::User,
            content: user_content,
        },
    ];

    let response = llm
        .chat(ChatRequest {
            messages,
            tools: vec![],
            // Left unset: some chat models reject a non-default
            // temperature outright (see llm-connector's OpenAI-compatible
            // provider for details).
            temperature: None,
        })
        .await?;

    let (narrative, key_patterns) = parse_analysis_json(&response.message.content)
        .unwrap_or_else(|| (response.message.content.clone(), vec![]));

    Ok(LifeAnalysis {
        id: Uuid::new_v4(),
        user_id,
        period_start,
        period_end,
        narrative,
        key_patterns,
        generated_at: Utc::now(),
    })
}

/// Mirrors `insight_synthesis::parse_insight_json` - the model is asked
/// for strict JSON but occasionally wraps it in a markdown fence anyway,
/// so that's stripped defensively before parsing.
fn parse_analysis_json(raw: &str) -> Option<(String, Vec<String>)> {
    let cleaned = raw.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();

    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    let narrative = value.get("narrative")?.as_str()?.to_string();
    let key_patterns = value
        .get("key_patterns")
        .and_then(|r| r.as_array())
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
        .unwrap_or_default();

    Some((narrative, key_patterns))
}
