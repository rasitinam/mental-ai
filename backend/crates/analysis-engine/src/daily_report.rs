use chrono::Utc;
use mental_domain::repository::ResearchRepository;
use mental_domain::{ChatMessageRecord, ChatRole, DailyMentalReport, JournalEntry, MoodEntry};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use mental_knowledge_base::{Embedder, VectorStore};
use uuid::Uuid;

use crate::person::PersonContext;
use crate::retrieval::{format_context, retrieve_context};
use crate::safety::screen_for_crisis_language;

/// How many past reports to show the model. Enough to say "compared to the
/// last few days" without turning today's report into a history essay — the
/// long view is the life analysis's job.
const MAX_PREVIOUS_REPORTS: usize = 7;

/// How many of the day's chat turns go into the report. The conversation is
/// often the richest thing that happened in a day — leaving it out was why a
/// report could describe a calm day the person had spent describing a crisis.
const MAX_CHAT_TURNS: usize = 24;

/// Builds the RAG context (mood summary + journal excerpts + top-k
/// research snippets) and asks the LLM for today's report. The crisis
/// screen runs on the raw journal text first: if it trips, the report is
/// still generated (so the user isn't left with nothing) but
/// `crisis_flag` is set so the app can surface crisis resources
/// alongside it — see `SAFETY_SYSTEM_PROMPT` for the model-side half of
/// this behavior.
///
/// The report covers today, but `mood_history` and `previous_reports` are
/// passed in so it can place today against the days before it ("better than
/// yesterday", "third quiet day in a row") instead of describing a single
/// data point in isolation.
#[allow(clippy::too_many_arguments)]
pub async fn generate_daily_report(
    user_id: Uuid,
    moods: &[MoodEntry],
    journal_entries: &[JournalEntry],
    chat_messages: &[ChatMessageRecord],
    mood_history: &[MoodEntry],
    previous_reports: &[DailyMentalReport],
    person: &PersonContext<'_>,
    llm: &dyn LlmProvider,
    research: &dyn ResearchRepository,
    vector_store: &dyn VectorStore,
    embedder: &Embedder,
) -> anyhow::Result<DailyMentalReport> {
    let journal_text = journal_entries
        .iter()
        .map(|j| j.body.as_str())
        .collect::<Vec<_>>()
        .join("\n---\n");

    let chat_text = summarize_chat(chat_messages);

    // The crisis screen reads the conversation too: someone is far more
    // likely to say the alarming thing to the chat than to write it in a
    // journal entry they know they're composing.
    let crisis = screen_for_crisis_language(&format!("{journal_text}\n{chat_text}"));

    let mood_summary = summarize_moods(moods);
    let baseline = summarize_baseline(moods, mood_history);

    let previous_summaries = previous_reports
        .iter()
        .take(MAX_PREVIOUS_REPORTS)
        .map(|r| format!("{}: {}", r.report_date.format("%Y-%m-%d"), r.summary))
        .collect::<Vec<_>>()
        .join("\n");

    // Retrieval is seeded with the conversation as well, so grounding
    // follows what the person actually talked about today.
    let related = retrieve_context(
        &format!("{journal_text}\n{chat_text}"),
        3,
        research,
        vector_store,
        embedder,
    )
    .await;

    let context = format!(
        "{}Today's mood: {mood_summary}\n\n\
         Position against history: {baseline}\n\n\
         Today's journal entries:\n{journal_text}\n\n\
         Today's conversation with the app:\n{chat_text}\n\n\
         Previous days' reports (newest first):\n{previous_summaries}\n\n\
         Related research:\n{}",
        person.prompt_block(),
        format_context(&related)
    );

    let messages = vec![
        ChatMessage {
            role: Role::System,
            content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
        },
        ChatMessage {
            role: Role::System,
            content: prompts::daily_report_instruction(person.language),
        },
        ChatMessage {
            role: Role::User,
            content: context,
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

    let (summary, recommendations) = parse_report_json(&response.message.content)
        .unwrap_or_else(|| (response.message.content.clone(), vec![]));

    Ok(DailyMentalReport {
        id: Uuid::new_v4(),
        user_id,
        report_date: Utc::now(),
        summary,
        mood_trend_note: mood_summary,
        recommendations,
        cited_insight_ids: vec![],
        crisis_flag: crisis.flagged,
        generated_at: Utc::now(),
        language: person.language.to_string(),
    })
}

fn summarize_chat(messages: &[ChatMessageRecord]) -> String {
    if messages.is_empty() {
        return "No conversation today.".to_string();
    }

    let start = messages.len().saturating_sub(MAX_CHAT_TURNS);
    messages[start..]
        .iter()
        .map(|m| {
            let speaker = match m.role {
                ChatRole::User => "Person",
                ChatRole::Assistant => "App",
            };
            format!("{speaker}: {}", m.content)
        })
        .collect::<Vec<_>>()
        .join("\n")
}

/// Rounds a -1.0..1.0 (or wider, for a today-vs-baseline delta) value to
/// the nearest half point. The report should read "one and a half points
/// lower", not "1.22 points lower" — a two-decimal average is precision
/// the underlying check-ins never had, and it reads as noise, not signal.
fn round_to_half(value: f32) -> f32 {
    (value * 2.0).round() / 2.0
}

/// Turkish word for a magnitude already rounded to the nearest half point,
/// never a digit — the daily report is meant to be read, not audited.
fn magnitude_word(rounded_magnitude: f32) -> &'static str {
    let steps = (rounded_magnitude / 0.5).round().abs() as i32;
    match steps {
        0 => "aynı düzeyde",
        1 => "yarım puan",
        2 => "bir puan",
        3 => "bir buçuk puan",
        4 => "iki puan",
        _ => "iki buçuk puandan fazla",
    }
}

/// A -1.0..1.0 axis value described in words, rounded to the nearest half
/// point — same "no raw decimals" rule as [`magnitude_word`].
fn level_phrase(value: f32) -> &'static str {
    let steps = (round_to_half(value.clamp(-1.0, 1.0)) / 0.5).round() as i32;
    match steps {
        i32::MIN..=-2 => "çok düşük",
        -1 => "düşük",
        0 => "orta",
        1 => "yüksek",
        _ => "çok yüksek",
    }
}

fn comparison_phrase(label: &str, diff: f32) -> String {
    let rounded = round_to_half(diff);
    if rounded == 0.0 {
        return format!("{label} ortalamayla aynı düzeyde");
    }
    let direction = if rounded > 0.0 { "yüksek" } else { "düşük" };
    format!("{label} ortalamadan {} {direction}", magnitude_word(rounded))
}

/// Computed directly from the actual mood entries rather than asked of
/// the LLM - the numbers should reflect real data, not a model's
/// restatement of data it was already given. Described in words (see
/// [`level_phrase`]) rather than raw decimals, since this text is handed
/// to the model as context and it otherwise tends to copy the digits
/// straight into the report it writes for the person to read.
fn summarize_moods(moods: &[MoodEntry]) -> String {
    if moods.is_empty() {
        return "Bugün için kaydedilmiş bir ruh hali yok.".to_string();
    }
    let (avg_valence, avg_arousal) = averages(moods);
    format!(
        "{} kayıt, ortalama keyif düzeyi {}, ortalama enerji düzeyi {}",
        moods.len(),
        level_phrase(avg_valence),
        level_phrase(avg_arousal),
    )
}

/// Today against everything before it. Also computed rather than inferred,
/// so the "better/worse than usual" framing in the report rests on real
/// arithmetic instead of the model's impression of a list — expressed in
/// words (see [`comparison_phrase`]) so that arithmetic never surfaces to
/// the person as a raw decimal.
fn summarize_baseline(today: &[MoodEntry], history: &[MoodEntry]) -> String {
    let today_ids: Vec<Uuid> = today.iter().map(|m| m.id).collect();
    let earlier: Vec<&MoodEntry> = history
        .iter()
        .filter(|m| !today_ids.contains(&m.id))
        .collect();

    if today.is_empty() || earlier.is_empty() {
        return "Karşılaştırma için yeterli geçmiş kayıt yok.".to_string();
    }

    let (today_valence, today_arousal) = averages(today);
    let (base_valence, base_arousal) = averages(earlier.iter().copied());

    format!(
        "Önceki {} kaydın ortalamasına göre bugün: {}, {}.",
        earlier.len(),
        comparison_phrase("keyif", today_valence - base_valence),
        comparison_phrase("enerji", today_arousal - base_arousal),
    )
}

fn averages<'a>(moods: impl IntoIterator<Item = &'a MoodEntry>) -> (f32, f32) {
    let (mut count, mut valence, mut arousal) = (0f32, 0f32, 0f32);
    for entry in moods {
        count += 1.0;
        valence += entry.valence;
        arousal += entry.arousal;
    }
    if count == 0.0 {
        return (0.0, 0.0);
    }
    (valence / count, arousal / count)
}

/// Mirrors `insight_synthesis::parse_insight_json` - the model is asked
/// for strict JSON but occasionally wraps it in a markdown fence anyway,
/// so that's stripped defensively before parsing.
fn parse_report_json(raw: &str) -> Option<(String, Vec<String>)> {
    let cleaned = raw.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();

    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    let summary = value.get("summary")?.as_str()?.to_string();
    let recommendations = value
        .get("recommendations")
        .and_then(|r| r.as_array())
        .map(|arr| arr.iter().filter_map(|v| v.as_str().map(str::to_string)).collect())
        .unwrap_or_default();

    Some((summary, recommendations))
}
