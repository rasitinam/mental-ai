use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Educational material for one condition in `catalog`: what it is, how it
/// tends to develop, and what actually helps. Generated once from the
/// research corpus and cached (see `disorder_explainers`), because browsing
/// the catalog would otherwise cost an LLM call per tap.
///
/// Deliberately split into fields rather than one blob: the UI shows them as
/// separate sections, and separating "what helps day to day" from "what
/// treatment looks like" keeps the self-help half from reading like a
/// prescription.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DisorderExplainer {
    pub slug: String,
    pub category: String,
    pub name: String,
    pub what_it_is: String,
    pub how_it_develops: String,
    /// Things a person can try themselves.
    pub coping_paths: Vec<String>,
    /// What professional treatment for this typically involves — described,
    /// never prescribed.
    pub treatment_paths: Vec<String>,
    pub generated_at: DateTime<Utc>,
}
