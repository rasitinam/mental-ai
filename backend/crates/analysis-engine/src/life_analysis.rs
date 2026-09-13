use chrono::{DateTime, Utc};
use mental_domain::report::LifeAnalysis;
use mental_domain::{ChatMessageRecord, DailyMentalReport, JournalEntry, MoodEntry};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use uuid::Uuid;

/// Whole-history pattern summary. Unlike the daily report (today, with a
/// glance backwards) this looks at everything the account has ever recorded:
/// mood check-ins, journal entries, chat turns and past daily reports. It is
/// generated at most once a week (enforced in
/// `apps/server/src/routes/life_analysis.rs`), which is also what makes the
/// wider input affordable.
///
/// The per-source caps below exist so the prompt stays bounded as an account
/// ages — a year of daily use is ~365 of each, and sending all of it forever
/// would eventually blow past the context window.
const MAX_MOODS: usize = 180;
const MAX_JOURNAL_ENTRIES: usize = 60;
const MAX_CHAT_MESSAGES: usize = 80;
const MAX_REPORTS: usize = 30;
const EXCERPT_CHARS: usize = 220;

pub async fn generate_life_analysis(
    user_id: Uuid,
    moods: &[MoodEntry],
    journal_entries: &[JournalEntry],
    chat_messages: &[ChatMessageRecord],
    reports: &[DailyMentalReport],
    person: &crate::person::PersonContext<'_>,
    llm: &dyn LlmProvider,
) -> anyhow::Result<LifeAnalysis> {
    let period_start = earliest_timestamp(moods, journal_entries, chat_messages).unwrap_or_else(Utc::now);
    let period_end = Utc::now();

    let mood_series = tail(moods, MAX_MOODS)
        .iter()
        .map(|m| {
            format!(
                "{}: keyif={:.2} enerji={:.2}",
                m.recorded_at.format("%Y-%m-%d"),
                m.valence,
                m.arousal
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    let journal_excerpts = tail(journal_entries, MAX_JOURNAL_ENTRIES)
        .iter()
        .map(|j| format!("{}: {}", j.created_at.format("%Y-%m-%d"), excerpt(&j.body)))
        .collect::<Vec<_>>()
        .join("\n");

    let chat_excerpts = tail(chat_messages, MAX_CHAT_MESSAGES)
        .iter()
        .map(|m| {
            format!(
                "{} [{}]: {}",
                m.created_at.format("%Y-%m-%d"),
                m.role.as_str(),
                excerpt(&m.content)
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    // Reports arrive newest-first from the repository; the model reads the
    // history more naturally oldest-first, like the other sections.
    let mut recent_reports = reports.iter().take(MAX_REPORTS).collect::<Vec<_>>();
    recent_reports.reverse();
    let report_excerpts = recent_reports
        .iter()
        .map(|r| format!("{}: {}", r.report_date.format("%Y-%m-%d"), excerpt(&r.summary)))
        .collect::<Vec<_>>()
        .join("\n");

    let user_content = format!(
        "{}Period covered: {} - {}\n\n\
         MOOD CHECK-INS:\n{mood_series}\n\n\
         JOURNAL ENTRIES:\n{journal_excerpts}\n\n\
         CHAT HISTORY:\n{chat_excerpts}\n\n\
         PAST DAILY REPORTS:\n{report_excerpts}",
        person.prompt_block(),
        period_start.format("%Y-%m-%d"),
        period_end.format("%Y-%m-%d"),
    );

    let messages = vec![
        ChatMessage {
            role: Role::System,
            content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
        },
        ChatMessage {
            role: Role::System,
            content: prompts::life_analysis_instruction(person.language),
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

    let parsed = parse_analysis_json(&response.message.content);
    let (narrative, key_patterns, do_list, dont_list) = parsed
        .unwrap_or_else(|| (response.message.content.clone(), vec![], vec![], vec![]));

    Ok(LifeAnalysis {
        id: Uuid::new_v4(),
        user_id,
        period_start,
        period_end,
        narrative,
        key_patterns,
        do_list,
        dont_list,
        generated_at: Utc::now(),
        language: person.language.to_string(),
    })
}

fn tail<T>(items: &[T], max: usize) -> &[T] {
    &items[items.len().saturating_sub(max)..]
}

fn excerpt(text: &str) -> String {
    let trimmed = text.trim().replace('\n', " ");
    if trimmed.chars().count() <= EXCERPT_CHARS {
        return trimmed;
    }
    trimmed.chars().take(EXCERPT_CHARS).collect::<String>() + "..."
}

fn earliest_timestamp(
    moods: &[MoodEntry],
    journal_entries: &[JournalEntry],
    chat_messages: &[ChatMessageRecord],
) -> Option<DateTime<Utc>> {
    [
        moods.iter().map(|m| m.recorded_at).min(),
        journal_entries.iter().map(|j| j.created_at).min(),
        chat_messages.iter().map(|m| m.created_at).min(),
    ]
    .into_iter()
    .flatten()
    .min()
}

/// Mirrors `insight_synthesis::parse_insight_json` - the model is asked
/// for strict JSON but occasionally wraps it in a markdown fence anyway,
/// so that's stripped defensively before parsing.
fn parse_analysis_json(raw: &str) -> Option<(String, Vec<String>, Vec<String>, Vec<String>)> {
    let cleaned = raw.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();

    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    let narrative = value.get("narrative")?.as_str()?.to_string();

    Some((
        narrative,
        string_list(&value, "key_patterns"),
        string_list(&value, "do_list"),
        string_list(&value, "dont_list"),
    ))
}

fn string_list(value: &serde_json::Value, key: &str) -> Vec<String> {
    value
        .get(key)
        .and_then(|v| v.as_array())
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
        .unwrap_or_default()
}
