use chrono::{DateTime, Datelike, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: Uuid,
    pub display_name: String,
    /// IANA timezone (e.g. "Europe/Istanbul"), used to schedule the daily
    /// report at a sensible local time rather than a fixed UTC hour.
    pub timezone: String,
    /// Self-reported conditions, as `catalog` slugs. The app never assigns
    /// these — they exist so someone can tell it what they already know, and
    /// so reports/chat can be framed with that context instead of guessing.
    #[serde(default)]
    pub diagnoses: Vec<String>,
    /// Interface language as a plain ISO-639-1 code ("tr"/"en"). The model is
    /// told to answer in it, so a language switch changes generated content
    /// too, not just the labels around it.
    #[serde(default = "default_language")]
    pub language: String,
    /// Birth year, not age, so it can't go stale. Optional — [`User::age`]
    /// returns `None` and the prompts stay age-neutral when it's unset.
    #[serde(default)]
    pub birth_year: Option<i32>,
    /// Grants access to the life-story moderation queue. Set by hand
    /// against the database — see `migrations/0007_life_stories.sql`.
    #[serde(default)]
    pub is_admin: bool,
    /// MIME type of the uploaded profile photo, if any — the image bytes
    /// live on disk (`data/avatars/<user_id>`), keyed by this record's
    /// `id`; this field alone is what tells `GET /profile/avatar` whether
    /// there's a file to read and what Content-Type to serve it with.
    #[serde(default)]
    pub avatar_content_type: Option<String>,
    pub created_at: DateTime<Utc>,
}

fn default_language() -> String {
    "tr".to_string()
}

impl User {
    /// Age in whole years, or `None` when no birth year was given. Ignores a
    /// birth year that can't be true (future, or absurdly long ago) rather
    /// than feeding the model a nonsense number.
    pub fn age(&self) -> Option<i32> {
        let birth_year = self.birth_year?;
        let this_year = Utc::now().year();
        let age = this_year - birth_year;
        (0..=120).contains(&age).then_some(age)
    }
}
