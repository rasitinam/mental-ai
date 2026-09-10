use mental_domain::{User, WellbeingAssessment};

/// The screening-battery half of [`PersonContext`], reduced to what a
/// prompt actually needs — scores and bands, not the raw item answers.
/// Owned rather than borrowed so it can be built from a repository call
/// (`Option<WellbeingAssessment>`) independently of `User`, which doesn't
/// carry it.
#[derive(Debug, Clone, Copy)]
pub struct AssessmentSummary {
    pub phq9_score: u8,
    pub depression_band: &'static str,
    pub gad7_score: u8,
    pub anxiety_band: &'static str,
    pub who5_score: u8,
    pub wellbeing_band: &'static str,
    pub phq15_score: u8,
    pub somatic_band: &'static str,
    pub ptsd5_score: u8,
    pub ptsd_band: &'static str,
    pub auditc_score: u8,
    pub alcohol_band: &'static str,
    pub cageaid_score: u8,
    pub substance_band: &'static str,
    pub days_ago: i64,
}

impl AssessmentSummary {
    pub fn from_assessment(a: &WellbeingAssessment) -> Self {
        Self {
            phq9_score: a.phq9_score,
            depression_band: a.depression_band(),
            gad7_score: a.gad7_score,
            anxiety_band: a.anxiety_band(),
            who5_score: a.who5_score,
            wellbeing_band: a.wellbeing_band(),
            phq15_score: a.phq15_score,
            somatic_band: a.somatic_band(),
            ptsd5_score: a.ptsd5_score,
            ptsd_band: a.ptsd_band(),
            auditc_score: a.auditc_score,
            alcohol_band: a.alcohol_band(),
            cageaid_score: a.cageaid_score,
            substance_band: a.substance_band(),
            days_ago: (chrono::Utc::now() - a.created_at).num_days(),
        }
    }
}

/// The "who am I writing for" half of every prompt in this crate.
///
/// Diagnoses, age and language used to be threaded through as three loose
/// parameters (or not at all); bundling them means a new piece of profile
/// context gets added in one place instead of in every generator's
/// signature. Age matters more than it looks: the same diagnosis label
/// describes a very different life at 16 than at 45, and without it the
/// model defaults to generic adult advice.
/// The registration default (`routes/auth.rs`) for an account that never
/// gave a name — treated as "no name", not as a name to address anyone by.
const UNNAMED_PLACEHOLDER: &str = "Kullanıcı";

#[derive(Debug, Clone, Copy)]
pub struct PersonContext<'a> {
    pub display_name: Option<&'a str>,
    pub diagnoses: &'a [String],
    pub age: Option<i32>,
    /// ISO-639-1 code the generated text must come back in.
    pub language: &'a str,
    pub assessment: Option<AssessmentSummary>,
}

impl<'a> PersonContext<'a> {
    pub fn from_user(user: &'a User) -> Self {
        Self {
            display_name: (user.display_name != UNNAMED_PLACEHOLDER)
                .then_some(user.display_name.as_str()),
            diagnoses: &user.diagnoses,
            age: user.age(),
            language: &user.language,
            assessment: None,
        }
    }

    /// Fallback for the paths where the account couldn't be loaded — better
    /// a less tailored answer than a failed request.
    pub fn unknown() -> Self {
        Self {
            display_name: None,
            diagnoses: &[],
            age: None,
            language: "tr",
            assessment: None,
        }
    }

    /// Attaches the latest PHQ-9/GAD-7 reading, if there is one. A
    /// separate step rather than a `from_user` parameter because the
    /// assessment comes from its own repository call, not from `User`.
    pub fn with_assessment(mut self, assessment: Option<AssessmentSummary>) -> Self {
        self.assessment = assessment;
        self
    }

    /// A short block prepended to the user-role context message. Returns an
    /// empty string when nothing is known, so prompts don't carry a
    /// paragraph of "unknown" fields.
    pub fn prompt_block(&self) -> String {
        let mut lines = Vec::new();

        if let Some(name) = self.display_name {
            lines.push(format!(
                "Their name: {name}. Use it naturally when it fits — a greeting, a moment that \
                 calls for it — not forced into every reply."
            ));
        }
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
        if let Some(a) = self.assessment {
            // PHQ-9/GAD-7 are the headline pair, always included. The rest
            // of the battery (well-being, somatic, PTSD, alcohol,
            // substance) only earns a line when it's outside its safest
            // band — otherwise seven scores on every single prompt would
            // bury the two that matter most under five that don't.
            let mut extra = Vec::new();
            if a.wellbeing_band != "good" {
                extra.push(format!("WHO-5 well-being {}/25 ({})", a.who5_score, a.wellbeing_band));
            }
            if a.somatic_band != "minimal" {
                extra.push(format!("PHQ-15 somatic symptoms {}/30 ({})", a.phq15_score, a.somatic_band));
            }
            if a.ptsd_band == "positive screen" {
                extra.push(format!("PC-PTSD-5 {}/5 (positive screen)", a.ptsd5_score));
            }
            if a.alcohol_band != "minimal" {
                extra.push(format!("AUDIT-C alcohol use {}/12 ({})", a.auditc_score, a.alcohol_band));
            }
            if a.substance_band == "positive screen" {
                extra.push(format!("CAGE-AID {}/4 (positive screen)", a.cageaid_score));
            }
            let extra_line = if extra.is_empty() {
                String::new()
            } else {
                format!(" Also notable: {}.", extra.join("; "))
            };

            lines.push(format!(
                "Self-report screening from {} day(s) ago — PHQ-9 (depression): {}/27 ({}); \
                 GAD-7 (anxiety): {}/21 ({}).{extra_line} This is a screening signal, not a \
                 diagnosis: read it the same way as their self-reported conditions, one more \
                 data point about where they currently are, never something to name or quote \
                 back at them like a lab result.",
                a.days_ago, a.phq9_score, a.depression_band, a.gad7_score, a.anxiety_band
            ));
        }

        if lines.is_empty() {
            String::new()
        } else {
            format!("{}\n\n", lines.join("\n"))
        }
    }
}
