use axum::{
    extract::State,
    routing::post,
    Json, Router,
};
use mental_domain::repository::AssessmentRepository;
use mental_domain::WellbeingAssessment;
use serde::{Deserialize, Serialize};

use crate::auth::AuthUser;
use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/assessment", post(submit).get(latest))
}

#[derive(Debug, Deserialize)]
struct SubmitRequest {
    phq9_answers: Vec<u8>,
    gad7_answers: Vec<u8>,
    who5_answers: Vec<u8>,
    phq15_answers: Vec<u8>,
    ptsd5_answers: Vec<u8>,
    auditc_answers: Vec<u8>,
    cageaid_answers: Vec<u8>,
}

/// Trimmed down from the full record for the client: the raw per-item
/// answers stay in the database, but the app only ever needs to show
/// scores/bands back to the person who just answered.
#[derive(Debug, Serialize)]
struct AssessmentResponse {
    phq9_score: u8,
    depression_band: String,
    gad7_score: u8,
    anxiety_band: String,
    who5_score: u8,
    wellbeing_band: String,
    phq15_score: u8,
    somatic_band: String,
    ptsd5_score: u8,
    ptsd_band: String,
    auditc_score: u8,
    alcohol_band: String,
    cageaid_score: u8,
    substance_band: String,
    crisis_flag: bool,
    created_at: chrono::DateTime<chrono::Utc>,
}

impl From<&WellbeingAssessment> for AssessmentResponse {
    fn from(a: &WellbeingAssessment) -> Self {
        Self {
            phq9_score: a.phq9_score,
            depression_band: a.depression_band().to_string(),
            gad7_score: a.gad7_score,
            anxiety_band: a.anxiety_band().to_string(),
            who5_score: a.who5_score,
            wellbeing_band: a.wellbeing_band().to_string(),
            phq15_score: a.phq15_score,
            somatic_band: a.somatic_band().to_string(),
            ptsd5_score: a.ptsd5_score,
            ptsd_band: a.ptsd_band().to_string(),
            auditc_score: a.auditc_score,
            alcohol_band: a.alcohol_band().to_string(),
            cageaid_score: a.cageaid_score,
            substance_band: a.substance_band().to_string(),
            crisis_flag: a.crisis_flag,
            created_at: a.created_at,
        }
    }
}

/// Submits the full screening battery (PHQ-9, GAD-7, WHO-5, PHQ-15,
/// PC-PTSD-5, AUDIT-C, CAGE-AID). Always optional on the client side
/// (onboarding can be skipped, and this can be retaken later from
/// Settings) — nothing here blocks any other part of the app from
/// working without one on file.
async fn submit(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(req): Json<SubmitRequest>,
) -> Result<Json<AssessmentResponse>, (axum::http::StatusCode, String)> {
    let assessment = WellbeingAssessment::new(
        auth.user_id,
        req.phq9_answers,
        req.gad7_answers,
        req.who5_answers,
        req.phq15_answers,
        req.ptsd5_answers,
        req.auditc_answers,
        req.cageaid_answers,
    )
    .map_err(|e| (axum::http::StatusCode::BAD_REQUEST, e.to_string()))?;

    state
        .assessments
        .save(&assessment)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(AssessmentResponse::from(&assessment)))
}

async fn latest(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<Option<AssessmentResponse>>, (axum::http::StatusCode, String)> {
    let assessment = state
        .assessments
        .latest_for_user(auth.user_id)
        .await
        .map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(assessment.as_ref().map(AssessmentResponse::from)))
}
