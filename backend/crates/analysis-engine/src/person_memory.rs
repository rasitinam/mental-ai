use chrono::{DateTime, Utc};
use mental_domain::memory::sanitize_items;
use mental_domain::{ChatMessageRecord, ChatRole, JournalEntry, LifeStory, MemoryItem, MoodEntry, WellbeingAssessment};
use mental_llm_connector::{prompts, ChatMessage, ChatRequest, LlmProvider, Role};

use crate::person::PersonContext;

/// How much of each source is read. Bounded so the prompt does not grow
/// with the age of the account: the memory is rewritten from the recent past
/// plus the lines it already holds, not from everything ever recorded.
const MAX_JOURNAL: usize = 40;
const MAX_CHAT: usize = 60;
const MAX_MOODS: usize = 60;
const MAX_ASSESSMENTS: usize = 6;
const MAX_STORIES: usize = 3;
const EXCERPT_CHARS: usize = 300;
const STORY_CHARS: usize = 500;

/// Fewer signals than this and there is nothing solid to remember yet: a
/// memory built from one sentence would only be a guess.
const MIN_SIGNALS: usize = 3;

/// Everything the memory is written from, gathered by the caller (oldest
/// first) so this stays a prompt-assembly function like the other generators.
pub struct MemoryInputs<'a> {
    pub journal: &'a [JournalEntry],
    /// Every chat message; only the person's own are used.
    pub chat: &'a [ChatMessageRecord],
    pub moods: &'a [MoodEntry],
    pub assessments: &'a [WellbeingAssessment],
    /// Stories this person wrote themselves.
    pub stories: &'a [LifeStory],
    /// The lines kept last time, so they are updated rather than rewritten.
    pub previous: &'a [MemoryItem],
}

fn has_tags_or_note(m: &MoodEntry) -> bool {
    !m.tags.is_empty() || m.note.as_deref().is_some_and(|n| !n.trim().is_empty())
}

impl MemoryInputs<'_> {
    /// Whether there is enough of the person's own words to write a memory.
    pub fn has_enough_material(&self) -> bool {
        let own_chat = self.chat.iter().filter(|m| m.role == ChatRole::User).count();
        let mood_notes = self.moods.iter().filter(|m| has_tags_or_note(m)).count();
        self.journal.len() + own_chat + mood_notes + self.stories.len() >= MIN_SIGNALS
    }
}

fn excerpt(text: &str, max: usize) -> String {
    let flat = text.trim().replace('\n', " ");
    if flat.chars().count() <= max {
        return flat;
    }
    flat.chars().take(max).collect::<String>() + "..."
}

fn tail<T>(items: &[T], max: usize) -> &[T] {
    &items[items.len().saturating_sub(max)..]
}

/// The user-role message: the person block, then each source under a label,
/// then the previous memory. Split out so it can be tested without a model.
pub fn build_user_content(inputs: &MemoryInputs<'_>, person: &PersonContext<'_>) -> String {
    let journal = tail(inputs.journal, MAX_JOURNAL)
        .iter()
        .map(|j| format!("{}: {}", j.created_at.format("%Y-%m-%d"), excerpt(&j.body, EXCERPT_CHARS)))
        .collect::<Vec<_>>()
        .join("\n");

    let own_chat: Vec<&ChatMessageRecord> = inputs.chat.iter().filter(|m| m.role == ChatRole::User).collect();
    let chat = tail(&own_chat, MAX_CHAT)
        .iter()
        .map(|m| format!("{}: {}", m.created_at.format("%Y-%m-%d"), excerpt(&m.content, EXCERPT_CHARS)))
        .collect::<Vec<_>>()
        .join("\n");

    let moods = tail(inputs.moods, MAX_MOODS)
        .iter()
        .filter(|m| has_tags_or_note(m))
        .map(|m| {
            let mut line = format!("{}:", m.recorded_at.format("%Y-%m-%d"));
            if !m.tags.is_empty() {
                line.push_str(&format!(" felt {}", m.tags.join(", ")));
            }
            if let Some(note) = m.note.as_deref().map(str::trim).filter(|n| !n.is_empty()) {
                line.push_str(&format!(" — \"{}\"", excerpt(note, 160)));
            }
            line
        })
        .collect::<Vec<_>>()
        .join("\n");

    let assessments = tail(inputs.assessments, MAX_ASSESSMENTS)
        .iter()
        .map(|a| {
            format!(
                "{}: PHQ-9 {}/27 ({}), GAD-7 {}/21 ({}), WHO-5 {}/25 ({})",
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

    let stories = tail(inputs.stories, MAX_STORIES)
        .iter()
        .map(|s| format!("{}: {}", s.created_at.format("%Y-%m-%d"), excerpt(&s.body, STORY_CHARS)))
        .collect::<Vec<_>>()
        .join("\n");

    let previous = inputs
        .previous
        .iter()
        .map(|m| format!("- {}: {}", m.kind, m.text))
        .collect::<Vec<_>>()
        .join("\n");

    let or_none = |s: String| if s.is_empty() { "(none)".to_string() } else { s };

    format!(
        "{}JOURNAL ENTRIES:\n{}\n\nTHEIR OWN CHAT MESSAGES:\n{}\n\nMOOD CHECK-INS WITH TAGS OR NOTES:\n{}\n\n\
         SCREENING HISTORY (self-report):\n{}\n\nTHEIR OWN STORIES:\n{}\n\nLINES KEPT LAST TIME:\n{}",
        person.prompt_block(),
        or_none(journal),
        or_none(chat),
        or_none(moods),
        or_none(assessments),
        or_none(stories),
        or_none(previous),
    )
}

/// Reads the model's JSON into clean memory lines; anything that is not the
/// expected shape yields `None` (the old memory is then left as it was).
pub fn parse_items(raw: &str) -> Option<Vec<MemoryItem>> {
    let cleaned = raw.trim().trim_start_matches("```json").trim_start_matches("```").trim_end_matches("```").trim();
    let value: serde_json::Value = serde_json::from_str(cleaned).ok()?;
    let items = value.get("items")?.as_array()?;
    let parsed = items
        .iter()
        .filter_map(|item| {
            Some(MemoryItem { kind: item.get("kind")?.as_str()?.to_string(), text: item.get("text")?.as_str()?.to_string() })
        })
        .collect();
    Some(sanitize_items(parsed))
}

/// Rewrites the person's memory from their recent entries. Returns `Ok(None)`
/// when there is not enough material or the model's answer was unusable, so
/// the caller keeps what it had.
pub async fn generate_person_memory(
    inputs: &MemoryInputs<'_>,
    person: &PersonContext<'_>,
    llm: &dyn LlmProvider,
) -> anyhow::Result<Option<Vec<MemoryItem>>> {
    if !inputs.has_enough_material() {
        return Ok(None);
    }

    let messages = vec![
        ChatMessage { role: Role::System, content: prompts::SAFETY_SYSTEM_PROMPT.to_string() },
        ChatMessage { role: Role::System, content: prompts::person_memory_instruction(person.language) },
        ChatMessage { role: Role::User, content: build_user_content(inputs, person) },
    ];
    let response = llm.chat(ChatRequest { messages, tools: vec![], temperature: None }).await?;

    Ok(parse_items(&response.message.content))
}

/// How old something is, in words the model can weigh ("2 days ago").
pub fn age_label(generated_at: DateTime<Utc>, now: DateTime<Utc>) -> String {
    let hours = (now - generated_at).num_hours();
    if hours < 1 {
        "under an hour ago".to_string()
    } else if hours < 48 {
        format!("{hours} hours ago")
    } else {
        format!("{} days ago", hours / 24)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    fn journal(body: &str) -> JournalEntry {
        JournalEntry { id: Uuid::new_v4(), user_id: Uuid::nil(), body: body.into(), detected_themes: None, created_at: Utc::now() }
    }

    fn chat(role: ChatRole, text: &str) -> ChatMessageRecord {
        ChatMessageRecord {
            id: Uuid::new_v4(),
            user_id: Uuid::nil(),
            role,
            content: text.into(),
            crisis_flag: false,
            created_at: Utc::now(),
        }
    }

    fn inputs<'a>(journal: &'a [JournalEntry], chat: &'a [ChatMessageRecord]) -> MemoryInputs<'a> {
        MemoryInputs { journal, chat, moods: &[], assessments: &[], stories: &[], previous: &[] }
    }

    #[test]
    fn a_couple_of_lines_is_not_enough_to_remember_anything() {
        let j = [journal("bugün yorgunum")];
        assert!(!inputs(&j, &[]).has_enough_material());
    }

    #[test]
    fn only_the_persons_own_chat_messages_count_and_are_sent() {
        let c = vec![
            chat(ChatRole::User, "sınavlar yüzünden uyuyamıyorum"),
            chat(ChatRole::Assistant, "bunu duyduğuma üzüldüm"),
            chat(ChatRole::User, "annemle konuştum, iyi geldi"),
        ];
        let j = [journal("dün kötüydüm")];
        let inputs = inputs(&j, &c);
        assert!(inputs.has_enough_material());

        let content = build_user_content(&inputs, &PersonContext::unknown());
        assert!(content.contains("sınavlar yüzünden uyuyamıyorum"));
        assert!(content.contains("annemle konuştum"));
        assert!(!content.contains("bunu duyduğuma üzüldüm"), "the app's own replies are not their words");
    }

    #[test]
    fn the_previous_lines_are_carried_so_they_are_updated_not_rewritten() {
        let previous = vec![MemoryItem { kind: "helps".into(), text: "akşam yürüyüşü".into() }];
        let mut i = inputs(&[], &[]);
        i.previous = &previous;
        let content = build_user_content(&i, &PersonContext::unknown());
        assert!(content.contains("- helps: akşam yürüyüşü"));
    }

    #[test]
    fn model_output_is_parsed_and_cleaned() {
        let raw = "```json\n{\"items\": [{\"kind\": \"theme\", \"text\": \" sınav kaygısı \"}, {\"kind\": \"diagnosis\", \"text\": \"x\"}]}\n```";
        let items = parse_items(raw).expect("valid");
        assert_eq!(items, vec![MemoryItem { kind: "theme".into(), text: "sınav kaygısı".into() }]);
        assert!(parse_items("not json").is_none());
        assert!(parse_items("{\"other\": []}").is_none());
    }
}
