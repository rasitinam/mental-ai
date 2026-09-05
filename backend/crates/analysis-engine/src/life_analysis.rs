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
                      patterns you notice across this period, followed by 3-5 short \
                      bullet points naming the key recurring patterns. Do not diagnose."
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
            temperature: Some(0.6),
        })
        .await?;

    Ok(LifeAnalysis {
        id: Uuid::new_v4(),
        user_id,
        period_start,
        period_end,
        narrative: response.message.content,
        key_patterns: vec![],
        generated_at: Utc::now(),
    })
}
