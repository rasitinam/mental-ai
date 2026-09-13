use chrono::{DateTime, Duration, Utc};
use mental_domain::report::LifeAnalysis;
use mental_domain::{ChatMessageRecord, ChatRole, DailyMentalReport, JournalEntry, MoodEntry, UserState};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use uuid::Uuid;

use crate::person::PersonContext;

/// How many of the most recent chat turns feed the assessment. Enough to
/// carry the shape of the current conversation, few enough that a long
/// history doesn't drown the last few minutes.
const CHAT_TURNS: usize = 20;
/// How many recent journal entries and mood check-ins to include.
const RECENT_ENTRIES: usize = 5;

/// Everything the assessment reads, gathered by the caller so this stays a
/// pure prompt-assembly function (same shape as the other generators here).
pub struct StateInputs<'a> {
    pub chat: &'a [ChatMessageRecord],
    pub moods: &'a [MoodEntry],
    pub journal: &'a [JournalEntry],
    pub report: Option<&'a DailyMentalReport>,
    pub life_analysis: Option<&'a LifeAnalysis>,
}

/// Reads where someone is *right now* from every recent signal at once.
///
/// The mood check-in alone can't answer this: it is capped at once per day,
/// so someone can spend an evening describing a crisis in chat while the
/// home screen still shows yesterday's cheerful slider. Each section below
/// is labelled with its age and the model is told to weigh recency heavily,
/// so the newest signal wins when they disagree.
pub async fn assess_current_state(
    user_id: Uuid,
    inputs: StateInputs<'_>,
    person: &PersonContext<'_>,
    llm: &dyn LlmProvider,
) -> anyhow::Result<UserState> {
    let now = Utc::now();
    let mut sections = Vec::new();
    let mut basis = Vec::new();

    if !inputs.chat.is_empty() {
        let transcript = inputs
            .chat
            .iter()
            .rev()
            .take(CHAT_TURNS)
            .collect::<Vec<_>>()
            .into_iter()
            .rev()
            .map(|m| {
                let speaker = match m.role {
                    ChatRole::User => "Person",
                    ChatRole::Assistant => "App",
                };
                format!("[{}] {speaker}: {}", age_label(m.created_at, now), m.content)
            })
            .collect::<Vec<_>>()
            .join("\n");
        sections.push(format!("RECENT CONVERSATION (newest last):\n{transcript}"));
        basis.push(basis_label("chat", person.language));
    }

    if !inputs.moods.is_empty() {
        let moods = inputs
            .moods
            .iter()
            .rev()
            .take(RECENT_ENTRIES)
            .map(|m| {
                format!(
                    "[{}] valence {:.2}, energy {:.2}{}",
                    age_label(m.recorded_at, now),
                    m.valence,
                    m.arousal,
                    m.note.as_deref().map(|n| format!(" — \"{n}\"")).unwrap_or_default()
                )
            })
            .collect::<Vec<_>>()
            .join("\n");
        sections.push(format!("MOOD CHECK-INS (newest first):\n{moods}"));
        basis.push(basis_label("mood", person.language));
    }

    if !inputs.journal.is_empty() {
        let entries = inputs
            .journal
            .iter()
            .take(RECENT_ENTRIES)
            .map(|j| format!("[{}] {}", age_label(j.created_at, now), j.body))
            .collect::<Vec<_>>()
            .join("\n---\n");
        sections.push(format!("JOURNAL ENTRIES (newest first):\n{entries}"));
        basis.push(basis_label("journal", person.language));
    }

    if let Some(report) = inputs.report {
        sections.push(format!(
            "LATEST DAILY REPORT [{}]:\n{}\nMood trend: {}",
            age_label(report.generated_at, now),
            report.summary,
            report.mood_trend_note
        ));
        basis.push(basis_label("daily_report", person.language));
    }

    if let Some(analysis) = inputs.life_analysis {
        sections.push(format!(
            "LATEST LIFE ANALYSIS [{}]:\n{}\nPatterns: {}",
            age_label(analysis.generated_at, now),
            analysis.narrative,
            analysis.key_patterns.join("; ")
        ));
        basis.push(basis_label("life_analysis", person.language));
    }

    if sections.is_empty() {
        anyhow::bail!("no signals to assess state from");
    }

    let context = format!("{}{}", person.prompt_block(), sections.join("\n\n"));

    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage {
                    role: Role::System,
                    content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
                },
                ChatMessage {
                    role: Role::System,
                    content: prompts::current_state_instruction(person.language),
                },
                ChatMessage {
                    role: Role::User,
                    content: context,
                },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    let (valence, energy, headline, note) = parse_state_json(&response.message.content)
        .ok_or_else(|| anyhow::anyhow!("state assessment was not valid JSON"))?;

    Ok(UserState {
        user_id,
        valence: valence.clamp(-1.0, 1.0),
        energy: energy.clamp(-1.0, 1.0),
        headline,
        note,
        basis: basis.into_iter().map(str::to_string).collect(),
        generated_at: now,
        language: person.language.to_string(),
    })
}

/// `basis` names which signals fed the assessment (shown under the
/// headline as "based on: ...") — these are fixed labels the app defines,
/// not model output, so they're picked directly by language rather than
/// routed through the LLM like `headline`/`note` are.
pub fn basis_label(key: &str, language: &str) -> &'static str {
    let english = language == "en";
    match key {
        "chat" => {
            if english {
                "conversation"
            } else {
                "sohbet"
            }
        }
        "mood" => {
            if english {
                "mood"
            } else {
                "ruh hali"
            }
        }
        "journal" => {
            if english {
                "journal"
            } else {
                "günlük"
            }
        }
        "daily_report" => {
            if english {
                "daily report"
            } else {
                "günlük rapor"
            }
        }
        _ => {
            if english {
                "life analysis"
            } else {
                "yaşam analizi"
            }
        }
    }
}

/// Re-derives a stored `basis` list in `target_language` — a pure lookup,
/// not an LLM call, so unlike `headline`/`note` this can just be redone on
/// every read instead of translated-and-cached. Handles a snapshot stored
/// in either supported language; anything unrecognized (there shouldn't be
/// any) passes through unchanged rather than disappearing.
pub fn relabel_basis(basis: &[String], target_language: &str) -> Vec<String> {
    basis
        .iter()
        .map(|label| match basis_key(label) {
            Some(key) => basis_label(key, target_language).to_string(),
            None => label.clone(),
        })
        .collect()
}

fn basis_key(label: &str) -> Option<&'static str> {
    match label {
        "sohbet" | "conversation" => Some("chat"),
        "ruh hali" | "mood" => Some("mood"),
        "günlük" | "journal" => Some("journal"),
        "günlük rapor" | "daily report" => Some("daily_report"),
        "yaşam analizi" | "life analysis" => Some("life_analysis"),
        _ => None,
    }
}

/// Recency is the whole point of this assessment, so every signal carries how
/// old it is rather than a bare timestamp the model has to do arithmetic on.
fn age_label(at: DateTime<Utc>, now: DateTime<Utc>) -> String {
    let elapsed = now - at;
    if elapsed < Duration::minutes(60) {
        format!("{} min ago", elapsed.num_minutes().max(0))
    } else if elapsed < Duration::hours(48) {
        format!("{}h ago", elapsed.num_hours())
    } else {
        format!("{}d ago", elapsed.num_days())
    }
}

/// Mirrors the defensive parsing in the other generators: strict JSON is
/// asked for, a markdown fence sometimes arrives anyway.
fn parse_state_json(raw: &str) -> Option<(f32, f32, String, String)> {
    let cleaned = raw
        .trim()
        .trim_start_matches("```json")
        .trim_start_matches("```")
        .trim_end_matches("```")
        .trim();

    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    Some((
        value.get("valence")?.as_f64()? as f32,
        value.get("energy")?.as_f64()? as f32,
        value.get("headline")?.as_str()?.to_string(),
        value.get("note")?.as_str()?.to_string(),
    ))
}
