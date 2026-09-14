//! "Seni iyi hissettirenler" — a handful of cards naming what, in one
//! person's own log, tends to come with their better and harder days.
//!
//! The model never sees a mood score. Each check-in is handed over as a
//! word ("low", "high"), for the same reason `daily_report` stopped
//! passing decimals: a model copies whatever figures it's given, and these
//! cards are meant to read as an observation, not a statistic. The digit
//! guard in [`parse_cards`] backs that up — a card that still contains a
//! number is dropped rather than shown.

use std::collections::{BTreeMap, HashSet};

use chrono::NaiveDate;
use mental_domain::discovery::{Discovery, DiscoveryKind};
use mental_domain::{JournalEntry, MoodEntry};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};

use crate::person::PersonContext;

/// A card has to rest on at least this many separate days of the log.
/// The prompt asks for the same threshold; this is the check that doesn't
/// depend on the model listening.
const MIN_EVIDENCE_DAYS: u64 = 3;
const MAX_CARDS: usize = 4;
const JOURNAL_EXCERPT_CHARS: usize = 260;
const NOTE_EXCERPT_CHARS: usize = 120;
const MAX_TITLE_CHARS: usize = 60;
const MAX_BODY_CHARS: usize = 260;

pub struct DiscoveryResult {
    pub cards: Vec<Discovery>,
    pub usage_tokens: Option<u32>,
}

/// How many separate calendar days have at least one mood check-in — the
/// gate for whether there's enough history to say anything yet.
pub fn distinct_mood_days(moods: &[MoodEntry]) -> usize {
    moods.iter().map(|m| m.recorded_at.date_naive()).collect::<HashSet<_>>().len()
}

/// A `[-1, 1]` valence/arousal reading as the word the model is given in
/// place of the number. Five bands, matching how the home screen's own
/// state card talks about levels.
pub(crate) fn level_word(value: f32) -> &'static str {
    match value {
        v if v < -0.6 => "very low",
        v if v < -0.2 => "low",
        v if v <= 0.2 => "middle",
        v if v <= 0.6 => "high",
        _ => "very high",
    }
}

pub(crate) fn excerpt(text: &str, max_chars: usize) -> String {
    let flat = text.split_whitespace().collect::<Vec<_>>().join(" ");
    if flat.chars().count() <= max_chars {
        flat
    } else {
        format!("{}…", flat.chars().take(max_chars).collect::<String>())
    }
}

#[derive(Default)]
struct DayLog {
    moods: Vec<String>,
    journal: Option<String>,
}

pub async fn generate_discoveries(
    moods: &[MoodEntry],
    journals: &[JournalEntry],
    person: &PersonContext<'_>,
    llm: &dyn LlmProvider,
) -> anyhow::Result<DiscoveryResult> {
    let mut days: BTreeMap<NaiveDate, DayLog> = BTreeMap::new();

    for mood in moods {
        let mut line =
            format!("mood {}, energy {}", level_word(mood.valence), level_word(mood.arousal));
        if !mood.tags.is_empty() {
            line.push_str(&format!("; felt: {}", mood.tags.join(", ")));
        }
        if let Some(note) = mood.note.as_deref().map(str::trim).filter(|n| !n.is_empty()) {
            line.push_str(&format!("; note: \"{}\"", excerpt(note, NOTE_EXCERPT_CHARS)));
        }
        days.entry(mood.recorded_at.date_naive()).or_default().moods.push(line);
    }

    for entry in journals {
        let day = days.entry(entry.created_at.date_naive()).or_default();
        if day.journal.is_none() {
            day.journal = Some(excerpt(&entry.body, JOURNAL_EXCERPT_CHARS));
        }
    }

    // The weekday is spelled out on every line: "Sundays are heavier" is
    // one of the most useful things this can notice, and it can't if the
    // model has to work out what day a date was.
    let log = days
        .iter()
        .map(|(date, day)| {
            let mut line = format!("{} ({})", date.format("%Y-%m-%d"), date.format("%A"));
            if !day.moods.is_empty() {
                line.push_str(&format!(" — {}", day.moods.join(" / ")));
            }
            if let Some(journal) = &day.journal {
                line.push_str(&format!(" — journal: \"{journal}\""));
            }
            line
        })
        .collect::<Vec<_>>()
        .join("\n");

    let response = llm
        .chat(ChatRequest {
            messages: vec![
                ChatMessage { role: Role::System, content: prompts::SAFETY_SYSTEM_PROMPT.to_string() },
                ChatMessage {
                    role: Role::System,
                    content: prompts::discoveries_instruction(person.language),
                },
                ChatMessage {
                    role: Role::User,
                    content: format!("{}DAY-BY-DAY LOG (oldest first):\n{log}", person.prompt_block()),
                },
            ],
            tools: vec![],
            temperature: None,
        })
        .await?;

    Ok(DiscoveryResult {
        cards: parse_cards(&response.message.content),
        usage_tokens: response.usage_tokens,
    })
}

/// Keeps only cards that pass every guard: a known kind, enough days of
/// evidence, non-empty text, and no digits anywhere a person will read.
/// Anything that fails is dropped silently — showing two honest cards is
/// better than four where one quotes a number or rests on a single day.
fn parse_cards(raw: &str) -> Vec<Discovery> {
    let cleaned = raw
        .trim()
        .trim_start_matches("```json")
        .trim_start_matches("```")
        .trim_end_matches("```")
        .trim();

    let Ok(value) = serde_json::from_str::<serde_json::Value>(cleaned) else {
        return vec![];
    };
    let Some(items) = value.get("cards").and_then(|v| v.as_array()) else {
        return vec![];
    };

    items
        .iter()
        .filter_map(|item| {
            let kind = match item.get("kind")?.as_str()? {
                "lifts" => DiscoveryKind::Lifts,
                "drains" => DiscoveryKind::Drains,
                "rhythm" => DiscoveryKind::Rhythm,
                _ => return None,
            };

            let evidence = item.get("evidence_days").and_then(|v| v.as_u64()).unwrap_or(0);
            if evidence < MIN_EVIDENCE_DAYS {
                return None;
            }

            let title = item.get("title")?.as_str()?.trim();
            let body = item.get("body")?.as_str()?.trim();
            if title.is_empty() || body.is_empty() {
                return None;
            }
            if title.chars().chain(body.chars()).any(|c| c.is_ascii_digit()) {
                return None;
            }

            let fallback_emoji = match kind {
                DiscoveryKind::Lifts => "🌿",
                DiscoveryKind::Drains => "🌧️",
                DiscoveryKind::Rhythm => "🗓️",
            };
            let emoji = item
                .get("emoji")
                .and_then(|v| v.as_str())
                .map(str::trim)
                .filter(|e| !e.is_empty() && e.chars().count() <= 4)
                .unwrap_or(fallback_emoji);

            Some(Discovery {
                kind,
                emoji: emoji.to_string(),
                title: excerpt(title, MAX_TITLE_CHARS),
                body: excerpt(body, MAX_BODY_CHARS),
            })
        })
        .take(MAX_CARDS)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn drops_cards_with_digits_thin_evidence_or_unknown_kind() {
        let raw = r#"{"cards": [
            {"kind": "lifts", "emoji": "🚶", "title": "Yürüyüşler iyi geliyor", "body": "Dışarı çıktığın günler çoğu zaman daha hafif geçiyor.", "evidence_days": 5},
            {"kind": "drains", "emoji": "💼", "title": "Uzun mesailer", "body": "Haftada 3 kez ağırlaşıyor.", "evidence_days": 6},
            {"kind": "rhythm", "emoji": "🗓️", "title": "Pazarlar", "body": "Pazar günleri düşüyor.", "evidence_days": 2},
            {"kind": "mystery", "emoji": "❓", "title": "x", "body": "y", "evidence_days": 9}
        ]}"#;

        let cards = parse_cards(raw);
        assert_eq!(cards.len(), 1);
        assert_eq!(cards[0].kind, DiscoveryKind::Lifts);
    }

    #[test]
    fn level_words_cover_the_whole_scale() {
        assert_eq!(level_word(-1.0), "very low");
        assert_eq!(level_word(0.0), "middle");
        assert_eq!(level_word(1.0), "very high");
    }
}
