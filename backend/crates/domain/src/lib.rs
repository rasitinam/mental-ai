//! Core domain models and repository ports. This crate has no dependency
//! on any framework (no axum, no sqlx) so it can be shared by the API
//! layer, background jobs, and tests without pulling in I/O concerns.
//! Concrete implementations of the repository traits live in `mental-storage`.

pub mod insight;
pub mod journal;
pub mod mood;
pub mod repository;
pub mod report;
pub mod research;
pub mod user;

pub use insight::Insight;
pub use journal::JournalEntry;
pub use mood::MoodEntry;
pub use report::DailyMentalReport;
pub use research::ResearchArticle;
pub use user::User;
