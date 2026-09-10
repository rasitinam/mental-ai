use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// PHQ-9 item 9 ("thoughts that you'd be better off dead, or of hurting
/// yourself") — the one item on either scale that gets a person routed to
/// the same crisis handling as a flagged journal entry or chat message,
/// regardless of the rest of their score. Standard clinical practice: any
/// nonzero answer here warrants follow-up on its own.
const PHQ9_SELF_HARM_ITEM: usize = 8;

/// A PHQ-9 + GAD-7 self-report screening — the same two public-domain,
/// Turkish-validated instruments used in primary care worldwide. Answers
/// are 0–3 per item ("Hiç" .. "Neredeyse her gün"); this is a screening
/// signal like a self-reported diagnosis, not something the app
/// diagnoses from.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WellbeingAssessment {
    pub id: Uuid,
    pub user_id: Uuid,
    pub phq9_answers: Vec<u8>,
    pub phq9_score: u8,
    pub gad7_answers: Vec<u8>,
    pub gad7_score: u8,
    pub crisis_flag: bool,
    pub created_at: DateTime<Utc>,
}

impl WellbeingAssessment {
    pub fn new(user_id: Uuid, phq9_answers: Vec<u8>, gad7_answers: Vec<u8>) -> anyhow::Result<Self> {
        if phq9_answers.len() != 9 {
            anyhow::bail!("PHQ-9 needs exactly 9 answers");
        }
        if gad7_answers.len() != 7 {
            anyhow::bail!("GAD-7 needs exactly 7 answers");
        }
        if phq9_answers.iter().chain(gad7_answers.iter()).any(|a| *a > 3) {
            anyhow::bail!("each answer must be 0-3");
        }

        let crisis_flag = phq9_answers[PHQ9_SELF_HARM_ITEM] > 0;
        Ok(Self {
            id: Uuid::new_v4(),
            user_id,
            phq9_score: phq9_answers.iter().sum(),
            gad7_score: gad7_answers.iter().sum(),
            phq9_answers,
            gad7_answers,
            crisis_flag,
            created_at: Utc::now(),
        })
    }

    /// Standard PHQ-9 severity bands (Kroenke et al. 2001).
    pub fn depression_band(&self) -> &'static str {
        match self.phq9_score {
            0..=4 => "minimal",
            5..=9 => "mild",
            10..=14 => "moderate",
            15..=19 => "moderately severe",
            _ => "severe",
        }
    }

    /// Standard GAD-7 severity bands (Spitzer et al. 2006).
    pub fn anxiety_band(&self) -> &'static str {
        match self.gad7_score {
            0..=4 => "minimal",
            5..=9 => "mild",
            10..=14 => "moderate",
            _ => "severe",
        }
    }
}
