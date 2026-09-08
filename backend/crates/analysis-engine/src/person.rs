use mental_domain::User;

/// The "who am I writing for" half of every prompt in this crate.
///
/// Diagnoses, age and language used to be threaded through as three loose
/// parameters (or not at all); bundling them means a new piece of profile
/// context gets added in one place instead of in every generator's
/// signature. Age matters more than it looks: the same diagnosis label
/// describes a very different life at 16 than at 45, and without it the
/// model defaults to generic adult advice.
#[derive(Debug, Clone, Copy)]
pub struct PersonContext<'a> {
    pub diagnoses: &'a [String],
    pub age: Option<i32>,
    /// ISO-639-1 code the generated text must come back in.
    pub language: &'a str,
}

impl<'a> PersonContext<'a> {
    pub fn from_user(user: &'a User) -> Self {
        Self {
            diagnoses: &user.diagnoses,
            age: user.age(),
            language: &user.language,
        }
    }

    /// Fallback for the paths where the account couldn't be loaded — better
    /// a less tailored answer than a failed request.
    pub fn unknown() -> Self {
        Self {
            diagnoses: &[],
            age: None,
            language: "tr",
        }
    }

    /// A short block prepended to the user-role context message. Returns an
    /// empty string when nothing is known, so prompts don't carry a
    /// paragraph of "unknown" fields.
    pub fn prompt_block(&self) -> String {
        let mut lines = Vec::new();

        if !self.diagnoses.is_empty() {
            lines.push(format!(
                "Self-reported conditions (their own words, not established fact): {}",
                self.diagnoses.join(", ")
            ));
        }
        if let Some(age) = self.age {
            lines.push(format!(
                "Age: {age}. Frame everything for this life stage — the pressures, \
                 relationships and options of someone this age, not a generic adult."
            ));
        }

        if lines.is_empty() {
            String::new()
        } else {
            format!("{}\n\n", lines.join("\n"))
        }
    }
}
