//! What a person has asked the app *not* to do in conversation.
//!
//! Asked as the first thing in onboarding ("what don't you want from
//! these conversations?") and editable from the profile afterwards. Kept
//! as a closed set of slugs rather than free text alone for one reason:
//! each slug carries a precise prompt directive written here, so the
//! model receives an unambiguous instruction instead of a Turkish UI
//! label it has to interpret. Anything the list doesn't cover goes in the
//! free-text note that rides alongside it.

/// One selectable boundary: the stored slug and the directive that slug
/// turns into inside a prompt.
pub struct ChatBoundary {
    pub slug: &'static str,
    /// Written as an instruction to the model, in English like every
    /// other prompt in this codebase — the reply language is decided
    /// separately (see `prompts::language_name`).
    pub directive: &'static str,
}

/// The full set, in the order the onboarding step lists them.
pub const CHAT_BOUNDARIES: &[ChatBoundary] = &[
    ChatBoundary {
        slug: "no_advice",
        directive: "Do not offer advice, tips, exercises or action steps unless they explicitly \
                    ask for them. Listen, reflect back what you heard, and let that be enough.",
    },
    ChatBoundary {
        slug: "no_referrals",
        directive: "Do not suggest seeing a therapist, psychiatrist or other professional. They \
                    already know that option exists and have asked not to hear it. (This does not \
                    apply to a real safety risk — see the safety rules, which always win.)",
    },
    ChatBoundary {
        slug: "no_toxic_positivity",
        directive: "No cheerful, motivational or silver-lining framing, and no reaching for a \
                    bright side. Stay plain, grounded and honest about how hard something is.",
    },
    ChatBoundary {
        slug: "no_questions",
        directive: "Keep questions to an absolute minimum — at most one, only when the \
                    conversation genuinely cannot continue without it. Prefer statements.",
    },
    ChatBoundary {
        slug: "no_clinical_terms",
        directive: "Avoid clinical, diagnostic or therapy-jargon vocabulary entirely. Use the \
                    same everyday words they would use themselves.",
    },
    ChatBoundary {
        slug: "no_religious",
        directive: "Never use religious, spiritual or faith-based framing, imagery or comfort.",
    },
    ChatBoundary {
        slug: "no_tough_love",
        directive: "Never take a challenging, confronting or 'tough love' tone, and don't push \
                    back on how they see their own situation.",
    },
    ChatBoundary {
        slug: "no_history_callbacks",
        directive: "Don't bring up their earlier entries, check-ins or past conversations on your \
                    own. Use that context silently to understand them; only name it if they \
                    raise it first.",
    },
];

/// Longest free-text note accepted — enough for a sentence or two of
/// "here's the thing the list didn't cover", short enough that it can't
/// become a second prompt smuggled into every request.
pub const MAX_BOUNDARY_NOTE_LEN: usize = 280;

pub fn boundary(slug: &str) -> Option<&'static ChatBoundary> {
    CHAT_BOUNDARIES.iter().find(|b| b.slug == slug)
}

/// Renders the person's selections (and their own note) as the prompt
/// section every generator prepends via
/// [`crate::user::User`]-backed `PersonContext`. Empty when they asked
/// for nothing in particular, so the prompt doesn't carry a heading with
/// nothing under it.
pub fn directives_block(slugs: &[String], note: Option<&str>) -> String {
    let directives: Vec<&str> =
        slugs.iter().filter_map(|slug| boundary(slug)).map(|b| b.directive).collect();
    let note = note.map(str::trim).filter(|n| !n.is_empty());

    if directives.is_empty() && note.is_none() {
        return String::new();
    }

    let mut block = String::from(
        "THIS PERSON'S OWN GROUND RULES FOR THESE CONVERSATIONS — they were asked what they did \
         not want, and this is their answer. Follow it exactly; it outranks your default style. \
         The one thing it never overrides is the safety rule about real risk to their life: if \
         that comes up, respond to it regardless of what follows.",
    );
    for directive in directives {
        block.push_str("\n- ");
        block.push_str(directive);
    }
    if let Some(note) = note {
        block.push_str("\n- In their own words: \"");
        block.push_str(note);
        block.push_str("\" — honor this the same way as the rules above.");
    }

    block
}
