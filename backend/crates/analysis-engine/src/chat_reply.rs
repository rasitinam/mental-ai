use chrono::{DateTime, Utc};
use mental_domain::repository::ResearchRepository;
use mental_domain::report::LifeAnalysis;
use mental_domain::{DailyMentalReport, JournalEntry, MoodEntry, UserState};
use mental_knowledge_base::{Embedder, VectorStore};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};

use crate::person_memory::age_label;
use crate::retrieval::{format_context, retrieve_context};
use crate::safety::screen_for_crisis_language;

pub struct ChatReplyResult {
    pub reply: String,
    pub crisis_flag: bool,
    pub usage_tokens: Option<u32>,
}

/// What the app has already worked out about the person, beyond the last few
/// days of raw entries: the reading of how they are right now, today's
/// report and the patterns found across their whole history. All computed
/// earlier (never on the chat path) so it costs nothing to include, and
/// each part is labelled with how old it is so a stale reading can lose to
/// what they are saying now.
#[derive(Default)]
pub struct ChatBackground<'a> {
    /// The person's own local time and weekday, e.g. "Tuesday 02:10" — a
    /// message at 2 a.m. is not the same message at 2 p.m.
    pub local_time: Option<String>,
    pub state: Option<&'a UserState>,
    pub report: Option<&'a DailyMentalReport>,
    pub life_analysis: Option<&'a LifeAnalysis>,
}

const REPORT_CHARS: usize = 320;
const STATE_NOTE_CHARS: usize = 200;
const MAX_PATTERNS: usize = 4;
const MAX_HELPS: usize = 3;

fn shorten(text: &str, max: usize) -> String {
    let flat = text.trim().replace('\n', " ");
    if flat.chars().count() <= max {
        return flat;
    }
    flat.chars().take(max).collect::<String>() + "..."
}

/// The "what the app already noticed" section of the chat context. Empty
/// when there is nothing yet.
pub fn background_block(background: &ChatBackground<'_>, now: DateTime<Utc>) -> String {
    let mut lines = Vec::new();

    if let Some(time) = &background.local_time {
        lines.push(format!("Their local time right now: {time}."));
    }
    if let Some(state) = background.state {
        lines.push(format!(
            "How they were reading (assessed {}): {} — {}",
            age_label(state.generated_at, now),
            state.headline.trim(),
            shorten(&state.note, STATE_NOTE_CHARS)
        ));
    }
    if let Some(report) = background.report {
        lines.push(format!(
            "Their latest daily report ({}): {}",
            age_label(report.generated_at, now),
            shorten(&report.summary, REPORT_CHARS)
        ));
    }
    if let Some(analysis) = background.life_analysis {
        if !analysis.key_patterns.is_empty() {
            let patterns = analysis.key_patterns.iter().take(MAX_PATTERNS).cloned().collect::<Vec<_>>().join("; ");
            lines.push(format!(
                "Patterns noticed across their history ({}): {patterns}",
                age_label(analysis.generated_at, now)
            ));
        }
        if !analysis.do_list.is_empty() {
            let helps = analysis.do_list.iter().take(MAX_HELPS).cloned().collect::<Vec<_>>().join("; ");
            lines.push(format!("What has visibly helped them: {helps}"));
        }
    }

    lines.join("\n")
}

/// The recent-mood paragraph: how many check-ins and their average, plus
/// the feeling words and notes they attached — the part of a check-in that
/// says what a number was about.
pub fn mood_summary(recent_moods: &[MoodEntry]) -> String {
    if recent_moods.is_empty() {
        return "No recent check-ins.".to_string();
    }

    let avg_valence: f32 = recent_moods.iter().map(|m| m.valence).sum::<f32>() / recent_moods.len() as f32;
    let avg_arousal: f32 = recent_moods.iter().map(|m| m.arousal).sum::<f32>() / recent_moods.len() as f32;
    let mut summary = format!(
        "{} check-ins, average valence {:.2}, average energy {:.2}",
        recent_moods.len(),
        avg_valence,
        avg_arousal
    );

    let mut tags: Vec<&str> = Vec::new();
    for tag in recent_moods.iter().flat_map(|m| m.tags.iter()) {
        if !tags.contains(&tag.as_str()) {
            tags.push(tag);
        }
    }
    if !tags.is_empty() {
        summary.push_str(&format!("; feelings they named: {}", tags.join(", ")));
    }

    let notes = recent_moods
        .iter()
        .filter_map(|m| m.note.as_deref().map(str::trim).filter(|n| !n.is_empty()))
        .take(3)
        .map(|n| format!("\"{}\"", shorten(n, 140)))
        .collect::<Vec<_>>();
    if !notes.is_empty() {
        summary.push_str(&format!("; their notes: {}", notes.join(" / ")));
    }

    summary
}

/// Answers one chat turn, personalized with the user's recent mood/
/// journal history and grounded with research snippets relevant to
/// *this* message — the "nabza göre şerbet" (tailored, not generic)
/// behavior: two people sending the same words get different replies if
/// their recent context differs. `recent_moods`/`recent_journal_entries`
/// are expected to already be scoped to a short window (a few days) by
/// the caller so the prompt doesn't grow unbounded over a long-lived
/// account; the longer view comes in through `person` (what they have told
/// the app before) and `background` (what it has already worked out).
///
/// `conversation_history` is the visible transcript so far (oldest
/// first, not including `user_message`), as kept by the Flutter client.
/// Without it every turn would be answered with no memory of what was
/// just said — a real conversation ("tell me more about that") is
/// impossible if the model can't see what "that" refers to. There is no
/// server-side session store on purpose: the client already holds the
/// transcript for display, so resending it is simpler than adding
/// stateful sessions, at the cost of the caller needing to cap its
/// length (see `ChatApi` on the Flutter side).
#[allow(clippy::too_many_arguments)]
pub async fn generate_chat_reply(
    user_message: &str,
    conversation_history: &[ChatMessage],
    recent_moods: &[MoodEntry],
    recent_journal_entries: &[JournalEntry],
    person: &crate::person::PersonContext<'_>,
    background: &ChatBackground<'_>,
    llm: &dyn LlmProvider,
    research: &dyn ResearchRepository,
    vector_store: &dyn VectorStore,
    embedder: &Embedder,
) -> anyhow::Result<ChatReplyResult> {
    let crisis = screen_for_crisis_language(user_message);

    let related = retrieve_context(user_message, 3, research, vector_store, embedder).await;

    let journal_excerpts = recent_journal_entries
        .iter()
        .rev()
        .take(3)
        .map(|j| format!("- {}", j.body.chars().take(200).collect::<String>()))
        .collect::<Vec<_>>()
        .join("\n");

    let noticed = background_block(background, Utc::now());
    let noticed_section = if noticed.is_empty() {
        String::new()
    } else {
        format!("What the app has already noticed about them (earlier than this conversation):\n{noticed}\n\n")
    };

    let context = format!(
        "{}Recent mood: {}\n\n\
         Recent journal excerpts:\n{}\n\n\
         {noticed_section}\
         Related research:\n{}",
        person.prompt_block(),
        mood_summary(recent_moods),
        if journal_excerpts.is_empty() { "(none)".to_string() } else { journal_excerpts },
        format_context(&related),
    );

    let mut messages = vec![
        ChatMessage { role: Role::System, content: prompts::SAFETY_SYSTEM_PROMPT.to_string() },
        ChatMessage { role: Role::System, content: prompts::chat_instruction(person.language) },
        ChatMessage { role: Role::System, content: format!("User context:\n{context}") },
    ];
    messages.extend(conversation_history.iter().cloned());
    messages.push(ChatMessage { role: Role::User, content: user_message.to_string() });

    let response = llm.chat(ChatRequest { messages, tools: vec![], temperature: None }).await?;

    Ok(ChatReplyResult {
        reply: response.message.content,
        crisis_flag: crisis.flagged,
        usage_tokens: response.usage_tokens,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Duration;
    use uuid::Uuid;

    fn mood(valence: f32, tags: &[&str], note: Option<&str>) -> MoodEntry {
        MoodEntry {
            id: Uuid::new_v4(),
            user_id: Uuid::nil(),
            valence,
            arousal: 0.0,
            tags: tags.iter().map(|t| t.to_string()).collect(),
            note: note.map(str::to_string),
            recorded_at: Utc::now(),
        }
    }

    fn state(now: DateTime<Utc>) -> UserState {
        UserState {
            user_id: Uuid::nil(),
            valence: -0.4,
            energy: -0.2,
            headline: "Yorgun ve gergin".into(),
            note: "Dün geceki konuşma seni zorlamış görünüyor.".into(),
            basis: vec![],
            generated_at: now - Duration::hours(3),
            language: "tr".into(),
        }
    }

    #[test]
    fn nothing_known_gives_an_empty_block() {
        assert_eq!(background_block(&ChatBackground::default(), Utc::now()), "");
    }

    #[test]
    fn the_reading_is_labelled_with_its_age_and_the_local_time_is_included() {
        let now = Utc::now();
        let s = state(now);
        let bg = ChatBackground { local_time: Some("Tuesday 02:10".into()), state: Some(&s), ..Default::default() };
        let block = background_block(&bg, now);
        assert!(block.contains("Their local time right now: Tuesday 02:10."));
        assert!(block.contains("assessed 3 hours ago"));
        assert!(block.contains("Yorgun ve gergin"));
    }

    #[test]
    fn life_analysis_contributes_patterns_and_what_helped() {
        let now = Utc::now();
        let analysis = LifeAnalysis {
            id: Uuid::new_v4(),
            user_id: Uuid::nil(),
            period_start: now - Duration::days(60),
            period_end: now,
            narrative: "uzun bir anlatı".into(),
            key_patterns: vec!["pazar akşamı kaygısı".into(), "uykusuz geceler".into()],
            do_list: vec!["kısa yürüyüş".into()],
            dont_list: vec!["gece geç saate kadar ekran".into()],
            generated_at: now - Duration::days(5),
            language: "tr".into(),
        };
        let bg = ChatBackground { life_analysis: Some(&analysis), ..Default::default() };
        let block = background_block(&bg, now);
        assert!(block.contains("Patterns noticed across their history (5 days ago): pazar akşamı kaygısı; uykusuz geceler"));
        assert!(block.contains("What has visibly helped them: kısa yürüyüş"));
        assert!(!block.contains("uzun bir anlatı"), "the narrative itself is not sent, only its patterns");
        assert!(!block.contains("ekran"), "the do-not list is not sent as background");
    }

    #[test]
    fn mood_summary_carries_the_feelings_and_notes_not_just_numbers() {
        let moods = vec![
            mood(-0.5, &["gergin", "yorgun"], Some("sunum yüzünden")),
            mood(0.2, &["gergin"], None),
        ];
        let summary = mood_summary(&moods);
        assert!(summary.starts_with("2 check-ins"));
        assert!(summary.contains("feelings they named: gergin, yorgun"));
        assert!(summary.contains("\"sunum yüzünden\""));
        assert_eq!(mood_summary(&[]), "No recent check-ins.");
    }
}
