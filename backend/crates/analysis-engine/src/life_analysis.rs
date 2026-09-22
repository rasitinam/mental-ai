use chrono::{DateTime, Utc};
use mental_domain::report::LifeAnalysis;
use mental_domain::{
    ChatMessageRecord, DailyMentalReport, JournalEntry, LifeStory, MoodEntry, UserState, WellbeingAssessment,
};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use uuid::Uuid;

use crate::person_memory::age_label;

/// Whole-history pattern summary. Unlike the daily report (today, with a
/// glance backwards) this looks at everything the account has recorded:
/// mood check-ins with the tags and notes attached to them, journal entries,
/// chat turns, past daily reports, the run of screening results, the last
/// reading of how they are, and what they wrote as their own stories. It is
/// generated at most once a week (enforced in
/// `apps/server/src/routes/life_analysis.rs`), which is also what makes the
/// wider input affordable.
///
/// The per-source caps below exist so the prompt stays bounded as an account
/// ages — a year of daily use is ~365 of each, and sending all of it forever
/// would eventually blow past the context window. What falls outside them is
/// still carried by the long-term memory in the person block.
const MAX_MOODS: usize = 180;
const MAX_JOURNAL_ENTRIES: usize = 60;
const MAX_CHAT_MESSAGES: usize = 80;
const MAX_REPORTS: usize = 30;
const MAX_ASSESSMENTS: usize = 12;
const MAX_STORIES: usize = 3;
const EXCERPT_CHARS: usize = 220;
const STORY_CHARS: usize = 500;
const NOTE_CHARS: usize = 120;

/// Everything the analysis reads, oldest first, gathered by the caller.
pub struct LifeAnalysisInputs<'a> {
    pub moods: &'a [MoodEntry],
    pub journal_entries: &'a [JournalEntry],
    pub chat_messages: &'a [ChatMessageRecord],
    pub reports: &'a [DailyMentalReport],
    /// Every screening on file (oldest first), so a change over time shows.
    pub assessments: &'a [WellbeingAssessment],
    /// How they were reading at the last refresh.
    pub state: Option<&'a UserState>,
    /// Stories they wrote themselves.
    pub stories: &'a [LifeStory],
}

/// The user-role message: the person block, then every source under a label.
/// Split out so it can be tested without a model.
pub fn build_user_content(
    inputs: &LifeAnalysisInputs<'_>,
    person: &crate::person::PersonContext<'_>,
    period_start: DateTime<Utc>,
    period_end: DateTime<Utc>,
) -> String {
    let mood_series = tail(inputs.moods, MAX_MOODS)
        .iter()
        .map(|m| {
            let mut line = format!(
                "{}: keyif={:.2} enerji={:.2}",
                m.recorded_at.format("%Y-%m-%d"),
                m.valence,
                m.arousal
            );
            // What the person said the number was about.
            if !m.tags.is_empty() {
                line.push_str(&format!(" [{}]", m.tags.join(", ")));
            }
            if let Some(note) = m.note.as_deref().map(str::trim).filter(|n| !n.is_empty()) {
                line.push_str(&format!(" \"{}\"", clip(note, NOTE_CHARS)));
            }
            line
        })
        .collect::<Vec<_>>()
        .join("\n");

    let journal_excerpts = tail(inputs.journal_entries, MAX_JOURNAL_ENTRIES)
        .iter()
        .map(|j| format!("{}: {}", j.created_at.format("%Y-%m-%d"), excerpt(&j.body)))
        .collect::<Vec<_>>()
        .join("\n");

    let chat_excerpts = tail(inputs.chat_messages, MAX_CHAT_MESSAGES)
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
    let mut recent_reports = inputs.reports.iter().take(MAX_REPORTS).collect::<Vec<_>>();
    recent_reports.reverse();
    let report_excerpts = recent_reports
        .iter()
        .map(|r| format!("{}: {}", r.report_date.format("%Y-%m-%d"), excerpt(&r.summary)))
        .collect::<Vec<_>>()
        .join("\n");

    // Every reading in the window, not only the newest: one score says where
    // someone is, the run of them says which way they are going.
    let screening = tail(inputs.assessments, MAX_ASSESSMENTS)
        .iter()
        .map(|a| {
            format!(
                "{}: PHQ-9 (depression) {}/27 ({}); GAD-7 (anxiety) {}/21 ({}); WHO-5 (well-being) {}/25 ({})",
                a.created_at.format("%Y-%m-%d"),
                a.phq9_score,
                a.depression_band(),
                a.gad7_score,
                a.anxiety_band(),
                a.who5_score,
                a.wellbeing_band()
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    let reading = inputs
        .state
        .map(|s| {
            format!(
                "assessed {}: {} — {}",
                age_label(s.generated_at, period_end),
                s.headline.trim(),
                clip(&s.note, NOTE_CHARS * 2)
            )
        })
        .unwrap_or_default();

    let stories = tail(inputs.stories, MAX_STORIES)
        .iter()
        .map(|s| format!("{}: {}", s.created_at.format("%Y-%m-%d"), clip(&s.body, STORY_CHARS)))
        .collect::<Vec<_>>()
        .join("\n");

    let or_none = |s: String| if s.is_empty() { "(none)".to_string() } else { s };

    format!(
        "{}Period covered: {} - {}\n\n\
         MOOD CHECK-INS (with feeling tags and notes):\n{}\n\n\
         SELF-REPORT SCREENING HISTORY (oldest first):\n{}\n\n\
         JOURNAL ENTRIES:\n{}\n\n\
         CHAT HISTORY:\n{}\n\n\
         PAST DAILY REPORTS:\n{}\n\n\
         HOW THEY WERE READING AT THE LAST REFRESH:\n{}\n\n\
         WHAT THEY WROTE AS THEIR OWN STORIES:\n{}",
        person.prompt_block(),
        period_start.format("%Y-%m-%d"),
        period_end.format("%Y-%m-%d"),
        or_none(mood_series),
        or_none(screening),
        or_none(journal_excerpts),
        or_none(chat_excerpts),
        or_none(report_excerpts),
        or_none(reading),
        or_none(stories),
    )
}

pub async fn generate_life_analysis(
    user_id: Uuid,
    inputs: &LifeAnalysisInputs<'_>,
    person: &crate::person::PersonContext<'_>,
    llm: &dyn LlmProvider,
) -> anyhow::Result<LifeAnalysis> {
    let period_start =
        earliest_timestamp(inputs.moods, inputs.journal_entries, inputs.chat_messages).unwrap_or_else(Utc::now);
    let period_end = Utc::now();

    let user_content = build_user_content(inputs, person, period_start, period_end);

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
    clip(text, EXCERPT_CHARS)
}

fn clip(text: &str, max: usize) -> String {
    let flat = text.trim().replace('\n', " ");
    if flat.chars().count() <= max {
        return flat;
    }
    flat.chars().take(max).collect::<String>() + "..."
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::person::PersonContext;
    use chrono::Duration;

    fn mood(days_ago: i64, valence: f32, tags: &[&str], note: Option<&str>) -> MoodEntry {
        MoodEntry {
            id: Uuid::new_v4(),
            user_id: Uuid::nil(),
            valence,
            arousal: 0.1,
            tags: tags.iter().map(|t| t.to_string()).collect(),
            note: note.map(str::to_string),
            recorded_at: Utc::now() - Duration::days(days_ago),
        }
    }

    fn empty<'a>() -> LifeAnalysisInputs<'a> {
        LifeAnalysisInputs {
            moods: &[],
            journal_entries: &[],
            chat_messages: &[],
            reports: &[],
            assessments: &[],
            state: None,
            stories: &[],
        }
    }

    #[test]
    fn mood_lines_carry_the_tags_and_notes_the_person_added() {
        let moods = vec![mood(3, -0.4, &["gergin", "yorgun"], Some("sunum yüzünden")), mood(1, 0.3, &[], None)];
        let mut inputs = empty();
        inputs.moods = &moods;
        let content = build_user_content(&inputs, &PersonContext::unknown(), Utc::now(), Utc::now());
        assert!(content.contains("[gergin, yorgun] \"sunum yüzünden\""));
        assert!(content.contains("keyif=0.30 enerji=0.10"));
    }

    #[test]
    fn missing_sources_read_as_none_not_as_empty_sections() {
        let content = build_user_content(&empty(), &PersonContext::unknown(), Utc::now(), Utc::now());
        for label in [
            "SELF-REPORT SCREENING HISTORY (oldest first):\n(none)",
            "HOW THEY WERE READING AT THE LAST REFRESH:\n(none)",
            "WHAT THEY WROTE AS THEIR OWN STORIES:\n(none)",
        ] {
            assert!(content.contains(label), "missing: {label}");
        }
    }

    #[test]
    fn the_reading_is_included_with_its_age() {
        let now = Utc::now();
        let state = UserState {
            user_id: Uuid::nil(),
            valence: -0.3,
            energy: -0.1,
            headline: "Yorgun ve gergin".into(),
            note: "Son konuşma seni zorlamış.".into(),
            basis: vec![],
            generated_at: now - Duration::hours(5),
            language: "tr".into(),
        };
        let mut inputs = empty();
        inputs.state = Some(&state);
        let content = build_user_content(&inputs, &PersonContext::unknown(), now, now);
        assert!(content.contains("assessed 5 hours ago: Yorgun ve gergin — Son konuşma seni zorlamış."));
    }
}
