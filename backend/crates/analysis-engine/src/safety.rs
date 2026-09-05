/// Lightweight keyword-based crisis screen, run over every journal entry
/// and chat message *before* it reaches the LLM. This is intentionally
/// simple and high-recall (a wordlist, not a classifier): false positives
/// just mean the crisis-resources message is shown once when it wasn't
/// strictly needed, which is an acceptable cost; false negatives are the
/// failure mode that actually matters, so keep this list broad and revisit
/// it with real product/clinical review before shipping, per
/// `docs/PRIVACY.md`'s safety-review note.
const CRISIS_KEYWORDS: &[&str] = &[
    "kill myself",
    "suicide",
    "end my life",
    "want to die",
    "hurt myself",
    "self harm",
    "self-harm",
    "no reason to live",
];

#[derive(Debug, Clone)]
pub struct CrisisScreenResult {
    pub flagged: bool,
    pub matched_terms: Vec<String>,
}

pub fn screen_for_crisis_language(text: &str) -> CrisisScreenResult {
    let lowered = text.to_lowercase();
    let matched: Vec<String> = CRISIS_KEYWORDS
        .iter()
        .filter(|kw| lowered.contains(*kw))
        .map(|kw| kw.to_string())
        .collect();

    CrisisScreenResult {
        flagged: !matched.is_empty(),
        matched_terms: matched,
    }
}
