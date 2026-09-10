use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// PHQ-9 item 9 ("thoughts that you'd be better off dead, or of hurting
/// yourself") — the one item across the whole battery that gets a person
/// routed to the same crisis handling as a flagged journal entry or chat
/// message, regardless of any score. Standard clinical practice: any
/// nonzero answer here warrants follow-up on its own.
const PHQ9_SELF_HARM_ITEM: usize = 8;

/// A self-report screening battery — seven public-domain instruments
/// covering the areas primary care actually screens for, not just mood
/// and anxiety: PHQ-9 (depression) and GAD-7 (anxiety) as before, plus
/// WHO-5 (general well-being), PHQ-15 (somatic symptoms), PC-PTSD-5
/// (post-traumatic stress), AUDIT-C (alcohol use) and CAGE-AID (other
/// substance use). All seven are free to use clinically and in research
/// without a license, the same basis PHQ-9/GAD-7 were chosen on. This is
/// a screening signal like a self-reported diagnosis, not something the
/// app diagnoses from.
///
/// Item scales differ by instrument (0-3 for PHQ-9/GAD-7, 0-5 for WHO-5,
/// 0-2 for PHQ-15, 0-1 yes/no for PC-PTSD-5 and CAGE-AID, 0-4 for
/// AUDIT-C) — each `*_answers` vector is validated against its own
/// instrument's length and per-item ceiling in [`WellbeingAssessment::new`].
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WellbeingAssessment {
    pub id: Uuid,
    pub user_id: Uuid,
    pub phq9_answers: Vec<u8>,
    pub phq9_score: u8,
    pub gad7_answers: Vec<u8>,
    pub gad7_score: u8,
    pub who5_answers: Vec<u8>,
    pub who5_score: u8,
    pub phq15_answers: Vec<u8>,
    pub phq15_score: u8,
    pub ptsd5_answers: Vec<u8>,
    pub ptsd5_score: u8,
    pub auditc_answers: Vec<u8>,
    pub auditc_score: u8,
    pub cageaid_answers: Vec<u8>,
    pub cageaid_score: u8,
    pub crisis_flag: bool,
    pub created_at: DateTime<Utc>,
}

/// One instrument's validation rule: exactly this many items, each
/// 0..=this per-item ceiling.
struct InstrumentShape {
    name: &'static str,
    len: usize,
    max: u8,
}

fn check(answers: &[u8], shape: InstrumentShape) -> anyhow::Result<()> {
    if answers.len() != shape.len {
        anyhow::bail!("{} needs exactly {} answers", shape.name, shape.len);
    }
    if answers.iter().any(|a| *a > shape.max) {
        anyhow::bail!("{} answers must be 0-{}", shape.name, shape.max);
    }
    Ok(())
}

impl WellbeingAssessment {
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        user_id: Uuid,
        phq9_answers: Vec<u8>,
        gad7_answers: Vec<u8>,
        who5_answers: Vec<u8>,
        phq15_answers: Vec<u8>,
        ptsd5_answers: Vec<u8>,
        auditc_answers: Vec<u8>,
        cageaid_answers: Vec<u8>,
    ) -> anyhow::Result<Self> {
        check(&phq9_answers, InstrumentShape { name: "PHQ-9", len: 9, max: 3 })?;
        check(&gad7_answers, InstrumentShape { name: "GAD-7", len: 7, max: 3 })?;
        check(&who5_answers, InstrumentShape { name: "WHO-5", len: 5, max: 5 })?;
        check(&phq15_answers, InstrumentShape { name: "PHQ-15", len: 15, max: 2 })?;
        check(&ptsd5_answers, InstrumentShape { name: "PC-PTSD-5", len: 5, max: 1 })?;
        check(&auditc_answers, InstrumentShape { name: "AUDIT-C", len: 3, max: 4 })?;
        check(&cageaid_answers, InstrumentShape { name: "CAGE-AID", len: 4, max: 1 })?;

        let crisis_flag = phq9_answers[PHQ9_SELF_HARM_ITEM] > 0;
        Ok(Self {
            id: Uuid::new_v4(),
            user_id,
            phq9_score: phq9_answers.iter().sum(),
            gad7_score: gad7_answers.iter().sum(),
            who5_score: who5_answers.iter().sum(),
            phq15_score: phq15_answers.iter().sum(),
            ptsd5_score: ptsd5_answers.iter().sum(),
            auditc_score: auditc_answers.iter().sum(),
            cageaid_score: cageaid_answers.iter().sum(),
            phq9_answers,
            gad7_answers,
            who5_answers,
            phq15_answers,
            ptsd5_answers,
            auditc_answers,
            cageaid_answers,
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

    /// WHO-5 raw score out of 25 (the published instrument reports this
    /// as a 0-100 percentage — raw * 4 — but the bands below work the
    /// same either way). A conventional ≤13 cutoff is where WHO
    /// guidance suggests screening further for depression.
    pub fn wellbeing_band(&self) -> &'static str {
        match self.who5_score {
            0..=6 => "very low",
            7..=12 => "low",
            13..=18 => "moderate",
            _ => "good",
        }
    }

    /// Standard PHQ-15 severity bands (Kroenke et al. 2002).
    pub fn somatic_band(&self) -> &'static str {
        match self.phq15_score {
            0..=4 => "minimal",
            5..=9 => "low",
            10..=14 => "medium",
            _ => "high",
        }
    }

    /// PC-PTSD-5's published cutoff: 3 or more "yes" answers is a
    /// positive screen (U.S. Dept. of Veterans Affairs).
    pub fn ptsd_band(&self) -> &'static str {
        if self.ptsd5_score >= 3 {
            "positive screen"
        } else {
            "below threshold"
        }
    }

    /// AUDIT-C: scores climb with drinking frequency/quantity/binge rate.
    pub fn alcohol_band(&self) -> &'static str {
        match self.auditc_score {
            0..=2 => "minimal",
            3..=4 => "caution",
            _ => "high",
        }
    }

    /// CAGE-AID: 2 or more "yes" answers is the conventional threshold
    /// for a clinically significant screen.
    pub fn substance_band(&self) -> &'static str {
        if self.cageaid_score >= 2 {
            "positive screen"
        } else {
            "minimal"
        }
    }
}
