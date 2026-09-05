use chrono::Utc;
use mental_domain::{DailyMentalReport, JournalEntry, MoodEntry};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};
use mental_knowledge_base::{Embedder, VectorStore};
use uuid::Uuid;

use crate::safety::screen_for_crisis_language;

/// Builds the RAG context (mood summary + journal excerpts + top-k
/// research snippets) and asks the LLM for today's report. The crisis
/// screen runs on the raw journal text first: if it trips, the report is
/// still generated (so the user isn't left with nothing) but
/// `crisis_flag` is set so the app can surface crisis resources
/// alongside it — see `SAFETY_SYSTEM_PROMPT` for the model-side half of
/// this behavior.
pub async fn generate_daily_report(
    user_id: Uuid,
    moods: &[MoodEntry],
    journal_entries: &[JournalEntry],
    llm: &dyn LlmProvider,
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

    let query_embedding = embedder.embed_one(&journal_text).await.unwrap_or_default();
    let related = if query_embedding.is_empty() {
        vec![]
    } else {
        vector_store.search(&query_embedding, 3).await.unwrap_or_default()
    };

    let context = format!(
        "Mood summary: {mood_summary}\n\nJournal excerpts:\n{journal_text}\n\n\
         Related research article IDs (already vetted, cite by ID if used): {:?}",
        related.iter().map(|r| r.article_id).collect::<Vec<_>>()
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

    Ok(DailyMentalReport {
        id: Uuid::new_v4(),
        user_id,
        report_date: Utc::now(),
        summary: response.message.content,
        mood_trend_note: mood_summary,
        recommendations: vec![],
        cited_insight_ids: vec![],
        crisis_flag: crisis.flagged,
        generated_at: Utc::now(),
    })
}

fn summarize_moods(moods: &[MoodEntry]) -> String {
    if moods.is_empty() {
        return "No mood check-ins recorded today.".to_string();
    }
    let avg_valence: f32 = moods.iter().map(|m| m.valence).sum::<f32>() / moods.len() as f32;
    let avg_arousal: f32 = moods.iter().map(|m| m.arousal).sum::<f32>() / moods.len() as f32;
    format!(
        "{} check-ins, average valence {:.2}, average arousal {:.2}",
        moods.len(),
        avg_valence,
        avg_arousal
    )
}
