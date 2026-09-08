//! Orchestrates the LLM + knowledge base to turn raw mood/journal data
//! into user-facing artifacts (daily report, life analysis, chat turns).
//! This crate owns the RAG prompt-assembly logic and the safety pass;
//! it is the only place that decides *what* gets sent to the LLM, while
//! `llm-connector` only knows *how* to send it.

pub mod chat_reply;
pub mod current_state;
pub mod daily_report;
pub mod explainer;
pub mod insight_synthesis;
pub mod life_analysis;
pub mod person;
pub mod retrieval;
pub mod safety;

pub use chat_reply::generate_chat_reply;
pub use current_state::{assess_current_state, StateInputs};
pub use daily_report::generate_daily_report;
pub use person::PersonContext;
pub use explainer::generate_disorder_explainer;
pub use insight_synthesis::synthesize_insights;
pub use life_analysis::generate_life_analysis;
pub use retrieval::retrieve_context;
pub use safety::{screen_for_crisis_language, CrisisScreenResult};
