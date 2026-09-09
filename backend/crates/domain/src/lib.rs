//! Core domain models and repository ports. This crate has no dependency
//! on any framework (no axum, no sqlx) so it can be shared by the API
//! layer, background jobs, and tests without pulling in I/O concerns.
//! Concrete implementations of the repository traits live in `mental-storage`.

pub mod auth;
pub mod catalog;
pub mod chat;
pub mod explainer;
pub mod insight;
pub mod journal;
pub mod life_story;
pub mod mood;
pub mod repository;
pub mod report;
pub mod research;
pub mod state;
pub mod streak;
pub mod user;

pub use auth::{Credentials, Session};
pub use catalog::{Disorder, DisorderCategory};
pub use chat::{ChatMessageRecord, ChatRole};
pub use explainer::DisorderExplainer;
pub use insight::Insight;
pub use journal::JournalEntry;
pub use life_story::{LifeStory, LifeStoryReport, StoryStatus};
pub use mood::MoodEntry;
pub use report::DailyMentalReport;
pub use research::ResearchArticle;
pub use state::UserState;
pub use streak::StreakSummary;
pub use user::User;
