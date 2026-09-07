use chrono::Utc;
use mental_domain::repository::ResearchRepository;
use mental_domain::{DailyMentalReport, JournalEntry, MoodEntry};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use mental_knowledge_base::{Embedder, VectorStore};
use uuid::Uuid;

use crate::retrieval::{format_context, retrieve_context};
use crate::safety::screen_for_crisis_language;

/// How many past reports to show the model. Enough to say "compared to the
/// last few days" without turning today's report into a history essay — the
/// long view is the life analysis's job.
const MAX_PREVIOUS_REPORTS: usize = 7;

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
    mood_history: &[MoodEntry],
    previous_reports: &[DailyMentalReport],
    diagnoses: &[String],
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

    let crisis = screen_for_crisis_language(&journal_text);

    let mood_summary = summarize_moods(moods);
    let baseline = summarize_baseline(moods, mood_history);

    let previous_summaries = previous_reports
        .iter()
        .take(MAX_PREVIOUS_REPORTS)
        .map(|r| format!("{}: {}", r.report_date.format("%Y-%m-%d"), r.summary))
        .collect::<Vec<_>>()
        .join("\n");

    let diagnosis_line = if diagnoses.is_empty() {
        String::new()
    } else {
        format!(
            "Kullanıcının kendi bildirdiği tanılar: {}\n\n",
            diagnoses.join(", ")
        )
    };

    let related = retrieve_context(&journal_text, 3, research, vector_store, embedder).await;

    let context = format!(
        "{diagnosis_line}Bugünün ruh hali: {mood_summary}\n\n\
         Geçmişe göre konum: {baseline}\n\n\
         Bugünün günlük kayıtları:\n{journal_text}\n\n\
         Önceki günlerin raporları (yeniden eskiye):\n{previous_summaries}\n\n\
         İlgili araştırma:\n{}",
        format_context(&related)
    );

    let messages = vec![
        ChatMessage {
            role: Role::System,
            content: prompts::SAFETY_SYSTEM_PROMPT.to_string(),
        },
        ChatMessage {
            role: Role::System,
            content: prompts::daily_report_instruction().to_string(),
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
    })
}

/// Computed directly from the actual mood entries rather than asked of
/// the LLM - the numbers should reflect real data, not a model's
/// restatement of data it was already given.
fn summarize_moods(moods: &[MoodEntry]) -> String {
    if moods.is_empty() {
        return "Bugün için kaydedilmiş bir ruh hali yok.".to_string();
    }
    let (avg_valence, avg_arousal) = averages(moods);
    format!(
        "{} kayıt, ortalama keyif düzeyi {:.2}, ortalama enerji düzeyi {:.2}",
        moods.len(),
        avg_valence,
        avg_arousal
    )
}

/// Today against everything before it. Also computed rather than inferred,
/// so the "better/worse than usual" framing in the report rests on real
/// arithmetic instead of the model's impression of a list.
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
        "Bugün keyif {:.2} / enerji {:.2}; önceki {} kaydın ortalaması keyif {:.2} / enerji {:.2} \
         (keyif farkı {:+.2}, enerji farkı {:+.2})",
        today_valence,
        today_arousal,
        earlier.len(),
        base_valence,
        base_arousal,
        today_valence - base_valence,
        today_arousal - base_arousal,
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
