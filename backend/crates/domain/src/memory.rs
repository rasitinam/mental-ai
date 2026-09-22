use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// What kind of thing a remembered line is. Kept to a short fixed list so the
/// app can group and label them, and so the model is asked for structure
/// rather than free-form notes.
pub const MEMORY_KINDS: [&str; 5] = ["theme", "trigger", "helps", "context", "goal"];

/// Most lines kept per person, and the longest one. Together they bound how
/// much every later prompt grows, and keep the "what Hearth remembers" screen
/// readable at a glance.
pub const MAX_MEMORY_ITEMS: usize = 10;
pub const MAX_MEMORY_ITEM_CHARS: usize = 180;

/// One short thing Hearth has learned about a person from their own entries.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MemoryItem {
    /// One of [`MEMORY_KINDS`].
    pub kind: String,
    pub text: String,
}

/// The person's long-term memory: a few distilled lines, rewritten from
/// their recent entries now and then, that every generated answer carries so
/// it can be specific instead of asking the same things again.
///
/// The person can read it, clear it and switch it off (`enabled`); nothing is
/// remembered about someone who has switched it off.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PersonMemory {
    pub user_id: Uuid,
    pub enabled: bool,
    pub items: Vec<MemoryItem>,
    /// Language the lines are written in (the account's language when they
    /// were generated).
    pub language: String,
    pub generated_at: Option<DateTime<Utc>>,
}

impl PersonMemory {
    /// A new, empty, switched-on memory.
    pub fn empty(user_id: Uuid, language: &str) -> Self {
        Self { user_id, enabled: true, items: Vec::new(), language: language.to_string(), generated_at: None }
    }
}

/// Keeps only well-formed lines: a known kind, non-empty text, trimmed and
/// cut to the length limit, at most [`MAX_MEMORY_ITEMS`] of them. Whatever the
/// model returned, this is what gets stored and shown.
pub fn sanitize_items(items: Vec<MemoryItem>) -> Vec<MemoryItem> {
    items
        .into_iter()
        .filter_map(|item| {
            let kind = item.kind.trim().to_lowercase();
            let text = item.text.trim().replace('\n', " ");
            if !MEMORY_KINDS.contains(&kind.as_str()) || text.is_empty() {
                return None;
            }
            Some(MemoryItem { kind, text: text.chars().take(MAX_MEMORY_ITEM_CHARS).collect() })
        })
        .take(MAX_MEMORY_ITEMS)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn item(kind: &str, text: &str) -> MemoryItem {
        MemoryItem { kind: kind.to_string(), text: text.to_string() }
    }

    #[test]
    fn unknown_kinds_and_empty_lines_are_dropped() {
        let cleaned = sanitize_items(vec![
            item("theme", "  sınav kaygısı  "),
            item("diagnosis", "bipolar"),
            item("helps", "   "),
            item("HELPS", "akşam yürüyüşü"),
        ]);
        assert_eq!(cleaned, vec![item("theme", "sınav kaygısı"), item("helps", "akşam yürüyüşü")]);
    }

    #[test]
    fn lines_are_cut_and_capped() {
        let long = "a".repeat(MAX_MEMORY_ITEM_CHARS + 50);
        let many: Vec<_> = (0..MAX_MEMORY_ITEMS + 5).map(|_| item("context", &long)).collect();
        let cleaned = sanitize_items(many);
        assert_eq!(cleaned.len(), MAX_MEMORY_ITEMS);
        assert!(cleaned.iter().all(|i| i.text.chars().count() == MAX_MEMORY_ITEM_CHARS));
    }
}
