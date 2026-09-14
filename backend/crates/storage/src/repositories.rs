use async_trait::async_trait;
use chrono::{DateTime, NaiveDate, Utc};
use mental_domain::repository::{
    ActivityRepository, AssessmentRepository, AuthRepository, ChatRepository, ChatUsageRepository,
    ContentTranslationRepository, DmRepository, ExplainerRepository, InsightRepository,
    JournalRepository, LifeAnalysisRepository, LifeStoryRepository, MoodRepository,
    PushTokenRepository, ReportRepository, ResearchRepository, SocialRepository,
    SubscriptionRepository, UserRepository, UserStateRepository,
};
use mental_domain::life_story::REACTIONS;
use mental_domain::report::LifeAnalysis;
use mental_domain::{
    ChatMessageRecord, ChatRole, Credentials, DailyMentalReport, DisorderExplainer, DmMessage,
    DmPolicy, DmStatus, DmThread, Insight, JournalEntry, LifeStory, LifeStoryReport, MoodEntry,
    PushToken, ResearchArticle, Session, StoryFeedItem, StoryStatus, Subscription, User, UserState,
    WellbeingAssessment,
};
use sqlx::SqlitePool;
use uuid::Uuid;

fn tags_to_json(tags: &[String]) -> String {
    serde_json::to_string(tags).unwrap_or_else(|_| "[]".to_string())
}

fn tags_from_json(raw: &str) -> Vec<String> {
    serde_json::from_str(raw).unwrap_or_default()
}

/// Unpacks the `"destek:2,anliyorum:1"`-shaped string `feed_for`'s
/// `group_concat` produces back into counts ordered like [`REACTIONS`].
/// An unrecognized name (there shouldn't be one — `react` validates against
/// the same constant) is silently dropped rather than failing the whole
/// feed row over one bad count.
fn parse_reaction_counts(summary: Option<String>) -> [u32; 3] {
    let mut counts = [0u32; REACTIONS.len()];
    let Some(summary) = summary else { return counts };

    for part in summary.split(',') {
        let Some((name, count)) = part.split_once(':') else { continue };
        if let Some(idx) = REACTIONS.iter().position(|r| *r == name) {
            counts[idx] = count.parse().unwrap_or(0);
        }
    }

    counts
}

pub struct SqliteUserRepository {
    pool: SqlitePool,
}

impl SqliteUserRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl UserRepository for SqliteUserRepository {
    async fn get(&self, id: Uuid) -> anyhow::Result<Option<User>> {
        let row = sqlx::query_as::<_, (String, String, String, String, String, Option<i32>, bool, Option<String>, String, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, display_name, timezone, diagnoses, language, birth_year, is_admin, avatar_content_type, dm_policy, chat_boundaries, chat_boundary_note, created_at
             FROM users WHERE id = ?1",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, display_name, timezone, diagnoses, language, birth_year, is_admin, avatar_content_type, dm_policy, chat_boundaries, chat_boundary_note, created_at)| User {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                display_name,
                timezone,
                diagnoses: tags_from_json(&diagnoses),
                language,
                birth_year,
                is_admin,
                avatar_content_type,
                dm_policy: DmPolicy::parse(&dm_policy),
                chat_boundaries: tags_from_json(&chat_boundaries),
                chat_boundary_note,
                created_at,
            },
        ))
    }

    async fn upsert(&self, user: &User) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO users (id, display_name, timezone, diagnoses, language, birth_year, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(id) DO UPDATE SET display_name = excluded.display_name, timezone = excluded.timezone",
        )
        .bind(user.id.to_string())
        .bind(&user.display_name)
        .bind(&user.timezone)
        .bind(tags_to_json(&user.diagnoses))
        .bind(&user.language)
        .bind(user.birth_year)
        .bind(user.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn set_avatar(&self, user_id: Uuid, content_type: Option<&str>) -> anyhow::Result<()> {
        sqlx::query("UPDATE users SET avatar_content_type = ?1 WHERE id = ?2")
            .bind(content_type)
            .bind(user_id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn set_diagnoses(&self, user_id: Uuid, diagnoses: &[String]) -> anyhow::Result<()> {
        sqlx::query("UPDATE users SET diagnoses = ?1 WHERE id = ?2")
            .bind(tags_to_json(diagnoses))
            .bind(user_id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn set_chat_boundaries(
        &self,
        user_id: Uuid,
        boundaries: &[String],
        note: Option<&str>,
    ) -> anyhow::Result<()> {
        sqlx::query("UPDATE users SET chat_boundaries = ?1, chat_boundary_note = ?2 WHERE id = ?3")
            .bind(tags_to_json(boundaries))
            .bind(note)
            .bind(user_id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn set_preferences(
        &self,
        user_id: Uuid,
        display_name: Option<&str>,
        language: Option<&str>,
        birth_year: Option<i32>,
        dm_policy: Option<DmPolicy>,
    ) -> anyhow::Result<()> {
        // COALESCE so an omitted field keeps its stored value: the profile
        // screen can save just the language without also having to resend a
        // birth year — or a name — the person didn't touch.
        sqlx::query(
            "UPDATE users SET display_name = COALESCE(?1, display_name),
             language = COALESCE(?2, language), birth_year = COALESCE(?3, birth_year),
             dm_policy = COALESCE(?4, dm_policy)
             WHERE id = ?5",
        )
        .bind(display_name)
        .bind(language)
        .bind(birth_year)
        .bind(dm_policy.map(|p| p.as_str()))
        .bind(user_id.to_string())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn delete_account(&self, user_id: Uuid) -> anyhow::Result<()> {
        let id = user_id.to_string();
        let mut tx = self.pool.begin().await?;

        // Dependents of this user's own stories first — SQLite doesn't
        // cascade (none of these were declared `ON DELETE CASCADE`), the
        // same reason `LifeStoryRepository::delete` does its own cascade.
        sqlx::query(
            "DELETE FROM story_reactions WHERE story_id IN (SELECT id FROM life_stories WHERE user_id = ?1)",
        )
        .bind(&id)
        .execute(&mut *tx)
        .await?;
        sqlx::query(
            "DELETE FROM story_upvotes WHERE story_id IN (SELECT id FROM life_stories WHERE user_id = ?1)",
        )
        .bind(&id)
        .execute(&mut *tx)
        .await?;
        sqlx::query(
            "DELETE FROM life_story_reports WHERE story_id IN (SELECT id FROM life_stories WHERE user_id = ?1)",
        )
        .bind(&id)
        .execute(&mut *tx)
        .await?;
        sqlx::query(
            "DELETE FROM story_translations WHERE story_id IN (SELECT id FROM life_stories WHERE user_id = ?1)",
        )
        .bind(&id)
        .execute(&mut *tx)
        .await?;
        sqlx::query("DELETE FROM life_stories WHERE user_id = ?1").bind(&id).execute(&mut *tx).await?;

        // This account's own activity elsewhere in the feed — a reaction or
        // report it made on someone else's story, not its own.
        sqlx::query("DELETE FROM story_reactions WHERE user_id = ?1").bind(&id).execute(&mut *tx).await?;
        sqlx::query("DELETE FROM story_upvotes WHERE user_id = ?1").bind(&id).execute(&mut *tx).await?;
        sqlx::query("DELETE FROM life_story_reports WHERE reporter_user_id = ?1")
            .bind(&id)
            .execute(&mut *tx)
            .await?;

        // Cached translations of this account's own private content —
        // `content_translations` has no user_id column, so each content
        // type is matched back to its owning row a different way. See
        // `routes::reports`/`routes::life_analysis`/`routes::state` for
        // where these content ids and types come from.
        sqlx::query(
            "DELETE FROM content_translations WHERE content_type = 'daily_report'
             AND content_id IN (SELECT id FROM daily_reports WHERE user_id = ?1)",
        )
        .bind(&id)
        .execute(&mut *tx)
        .await?;
        sqlx::query(
            "DELETE FROM content_translations WHERE content_type = 'life_analysis'
             AND content_id IN (SELECT id FROM life_analyses WHERE user_id = ?1)",
        )
        .bind(&id)
        .execute(&mut *tx)
        .await?;
        sqlx::query("DELETE FROM content_translations WHERE content_type = 'current_state' AND content_id LIKE ?1")
            .bind(format!("{id}:%"))
            .execute(&mut *tx)
            .await?;

        // Direct messages this account is part of, either side.
        sqlx::query(
            "DELETE FROM dm_messages WHERE thread_id IN
             (SELECT id FROM dm_threads WHERE user_low = ?1 OR user_high = ?1)",
        )
        .bind(&id)
        .execute(&mut *tx)
        .await?;
        sqlx::query("DELETE FROM dm_threads WHERE user_low = ?1 OR user_high = ?1")
            .bind(&id)
            .execute(&mut *tx)
            .await?;

        sqlx::query("DELETE FROM follows WHERE follower_id = ?1 OR followee_id = ?1")
            .bind(&id)
            .execute(&mut *tx)
            .await?;

        // The account's own history and settings.
        for table in [
            "mood_entries",
            "journal_entries",
            "daily_reports",
            "life_analyses",
            "chat_messages",
            // The free-tier quota counter (see `routes::chat`). It has a
            // foreign key to `users` like everything else here, so an
            // account that had ever sent one chat message could not be
            // deleted at all while this was missing from the list.
            "chat_token_usage",
            "wellbeing_assessments",
            "user_states",
            "subscriptions",
            "device_push_tokens",
            "sessions",
            "credentials",
        ] {
            sqlx::query(&format!("DELETE FROM {table} WHERE user_id = ?1")).bind(&id).execute(&mut *tx).await?;
        }

        sqlx::query("DELETE FROM users WHERE id = ?1").bind(&id).execute(&mut *tx).await?;

        tx.commit().await?;
        Ok(())
    }
}

pub struct SqliteMoodRepository {
    pool: SqlitePool,
}

impl SqliteMoodRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl MoodRepository for SqliteMoodRepository {
    async fn add(&self, entry: &MoodEntry) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO mood_entries (id, user_id, valence, arousal, tags, note, recorded_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        )
        .bind(entry.id.to_string())
        .bind(entry.user_id.to_string())
        .bind(entry.valence)
        .bind(entry.arousal)
        .bind(tags_to_json(&entry.tags))
        .bind(&entry.note)
        .bind(entry.recorded_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn list_between(
        &self,
        user_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> anyhow::Result<Vec<MoodEntry>> {
        let rows = sqlx::query_as::<_, (String, String, f32, f32, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, user_id, valence, arousal, tags, note, recorded_at FROM mood_entries
             WHERE user_id = ?1 AND recorded_at BETWEEN ?2 AND ?3 ORDER BY recorded_at ASC",
        )
        .bind(user_id.to_string())
        .bind(from)
        .bind(to)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, user_id, valence, arousal, tags, note, recorded_at)| MoodEntry {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                valence,
                arousal,
                tags: tags_from_json(&tags),
                note,
                recorded_at,
            })
            .collect())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<MoodEntry>> {
        let row = sqlx::query_as::<_, (String, String, f32, f32, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, user_id, valence, arousal, tags, note, recorded_at FROM mood_entries
             WHERE user_id = ?1 ORDER BY recorded_at DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(id, user_id, valence, arousal, tags, note, recorded_at)| MoodEntry {
            id: Uuid::parse_str(&id).unwrap_or_default(),
            user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
            valence,
            arousal,
            tags: tags_from_json(&tags),
            note,
            recorded_at,
        }))
    }

    async fn list_all(&self, user_id: Uuid) -> anyhow::Result<Vec<MoodEntry>> {
        let rows = sqlx::query_as::<_, (String, String, f32, f32, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, user_id, valence, arousal, tags, note, recorded_at FROM mood_entries
             WHERE user_id = ?1 ORDER BY recorded_at ASC",
        )
        .bind(user_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, user_id, valence, arousal, tags, note, recorded_at)| MoodEntry {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                valence,
                arousal,
                tags: tags_from_json(&tags),
                note,
                recorded_at,
            })
            .collect())
    }
}

pub struct SqliteJournalRepository {
    pool: SqlitePool,
}

impl SqliteJournalRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl JournalRepository for SqliteJournalRepository {
    async fn add(&self, entry: &JournalEntry) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO journal_entries (id, user_id, body, detected_themes, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5)",
        )
        .bind(entry.id.to_string())
        .bind(entry.user_id.to_string())
        .bind(&entry.body)
        .bind(entry.detected_themes.as_ref().map(|t| tags_to_json(t)))
        .bind(entry.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn update_themes(&self, id: Uuid, themes: Vec<String>) -> anyhow::Result<()> {
        sqlx::query("UPDATE journal_entries SET detected_themes = ?1 WHERE id = ?2")
            .bind(tags_to_json(&themes))
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn list_between(
        &self,
        user_id: Uuid,
        from: DateTime<Utc>,
        to: DateTime<Utc>,
    ) -> anyhow::Result<Vec<JournalEntry>> {
        let rows = sqlx::query_as::<_, (String, String, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, user_id, body, detected_themes, created_at FROM journal_entries
             WHERE user_id = ?1 AND created_at BETWEEN ?2 AND ?3 ORDER BY created_at ASC",
        )
        .bind(user_id.to_string())
        .bind(from)
        .bind(to)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, user_id, body, themes, created_at)| JournalEntry {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                body,
                detected_themes: themes.map(|t| tags_from_json(&t)),
                created_at,
            })
            .collect())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<JournalEntry>> {
        let row = sqlx::query_as::<_, (String, String, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, user_id, body, detected_themes, created_at FROM journal_entries
             WHERE user_id = ?1 ORDER BY created_at DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(id, user_id, body, themes, created_at)| JournalEntry {
            id: Uuid::parse_str(&id).unwrap_or_default(),
            user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
            body,
            detected_themes: themes.map(|t| tags_from_json(&t)),
            created_at,
        }))
    }

    async fn list_all(&self, user_id: Uuid) -> anyhow::Result<Vec<JournalEntry>> {
        let rows = sqlx::query_as::<_, (String, String, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, user_id, body, detected_themes, created_at FROM journal_entries
             WHERE user_id = ?1 ORDER BY created_at DESC",
        )
        .bind(user_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, user_id, body, themes, created_at)| JournalEntry {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                body,
                detected_themes: themes.map(|t| tags_from_json(&t)),
                created_at,
            })
            .collect())
    }
}

pub struct SqliteReportRepository {
    pool: SqlitePool,
}

impl SqliteReportRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ReportRepository for SqliteReportRepository {
    async fn save(&self, report: &DailyMentalReport) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO daily_reports
             (id, user_id, report_date, summary, mood_trend_note, recommendations, cited_insight_ids, crisis_flag, generated_at, language)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
        )
        .bind(report.id.to_string())
        .bind(report.user_id.to_string())
        .bind(report.report_date)
        .bind(&report.summary)
        .bind(&report.mood_trend_note)
        .bind(tags_to_json(&report.recommendations))
        .bind(serde_json::to_string(&report.cited_insight_ids).unwrap_or_default())
        .bind(report.crisis_flag)
        .bind(report.generated_at)
        .bind(&report.language)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<DailyMentalReport>> {
        let row = sqlx::query_as::<_, (String, String, DateTime<Utc>, String, String, String, String, bool, DateTime<Utc>, String)>(
            "SELECT id, user_id, report_date, summary, mood_trend_note, recommendations, cited_insight_ids, crisis_flag, generated_at, language
             FROM daily_reports WHERE user_id = ?1 ORDER BY report_date DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, user_id, report_date, summary, mood_trend_note, recommendations, cited, crisis_flag, generated_at, language)| {
                DailyMentalReport {
                    id: Uuid::parse_str(&id).unwrap_or_default(),
                    user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                    report_date,
                    summary,
                    mood_trend_note,
                    recommendations: tags_from_json(&recommendations),
                    cited_insight_ids: serde_json::from_str(&cited).unwrap_or_default(),
                    crisis_flag,
                    generated_at,
                    language,
                }
            },
        ))
    }

    async fn list_recent(&self, user_id: Uuid, limit: u32) -> anyhow::Result<Vec<DailyMentalReport>> {
        let rows = sqlx::query_as::<_, (String, String, DateTime<Utc>, String, String, String, String, bool, DateTime<Utc>, String)>(
            "SELECT id, user_id, report_date, summary, mood_trend_note, recommendations, cited_insight_ids, crisis_flag, generated_at, language
             FROM daily_reports WHERE user_id = ?1 ORDER BY report_date DESC LIMIT ?2",
        )
        .bind(user_id.to_string())
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(
                |(id, user_id, report_date, summary, mood_trend_note, recommendations, cited, crisis_flag, generated_at, language)| {
                    DailyMentalReport {
                        id: Uuid::parse_str(&id).unwrap_or_default(),
                        user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                        report_date,
                        summary,
                        mood_trend_note,
                        recommendations: tags_from_json(&recommendations),
                        cited_insight_ids: serde_json::from_str(&cited).unwrap_or_default(),
                        crisis_flag,
                        generated_at,
                        language,
                    }
                },
            )
            .collect())
    }
}

pub struct SqliteResearchRepository {
    pool: SqlitePool,
}

impl SqliteResearchRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ResearchRepository for SqliteResearchRepository {
    async fn upsert_many(&self, articles: &[ResearchArticle]) -> anyhow::Result<()> {
        let mut tx = self.pool.begin().await?;

        for article in articles {
            sqlx::query(
                "INSERT INTO research_articles
                 (id, source, external_id, title, abstract_text, url, published_at, tags, ingested_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
                 ON CONFLICT(source, external_id) DO NOTHING",
            )
            .bind(article.id.to_string())
            .bind(&article.source)
            .bind(&article.external_id)
            .bind(&article.title)
            .bind(&article.abstract_text)
            .bind(&article.url)
            .bind(article.published_at)
            .bind(tags_to_json(&article.tags))
            .bind(article.ingested_at)
            .execute(&mut *tx)
            .await?;
        }

        tx.commit().await?;
        Ok(())
    }

    async fn exists(&self, source: &str, external_id: &str) -> anyhow::Result<bool> {
        let row: Option<(i64,)> = sqlx::query_as(
            "SELECT 1 FROM research_articles WHERE source = ?1 AND external_id = ?2",
        )
        .bind(source)
        .bind(external_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.is_some())
    }

    async fn recent(&self, limit: u32) -> anyhow::Result<Vec<ResearchArticle>> {
        let rows = sqlx::query_as::<_, ArticleRow>(
            "SELECT id, source, external_id, title, abstract_text, url, published_at, tags, ingested_at
             FROM research_articles ORDER BY ingested_at DESC LIMIT ?1",
        )
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(article_from_row).collect())
    }

    async fn get_many(&self, ids: &[Uuid]) -> anyhow::Result<Vec<ResearchArticle>> {
        if ids.is_empty() {
            return Ok(vec![]);
        }

        // SQLite has no array binding, so the placeholder list is built to
        // match the id count; the ids themselves are still bound as
        // parameters rather than interpolated.
        let placeholders = std::iter::repeat("?").take(ids.len()).collect::<Vec<_>>().join(",");
        let sql = format!(
            "SELECT id, source, external_id, title, abstract_text, url, published_at, tags, ingested_at
             FROM research_articles WHERE id IN ({placeholders})"
        );

        let mut query = sqlx::query_as::<_, ArticleRow>(&sql);
        for id in ids {
            query = query.bind(id.to_string());
        }

        Ok(query.fetch_all(&self.pool).await?.into_iter().map(article_from_row).collect())
    }
}

type ArticleRow = (
    String,
    String,
    String,
    String,
    String,
    String,
    Option<DateTime<Utc>>,
    String,
    DateTime<Utc>,
);

fn article_from_row(
    (id, source, external_id, title, abstract_text, url, published_at, tags, ingested_at): ArticleRow,
) -> ResearchArticle {
    ResearchArticle {
        id: Uuid::parse_str(&id).unwrap_or_default(),
        source,
        external_id,
        title,
        abstract_text,
        url,
        published_at,
        tags: tags_from_json(&tags),
        ingested_at,
    }
}

pub struct SqliteInsightRepository {
    pool: SqlitePool,
}

impl SqliteInsightRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl InsightRepository for SqliteInsightRepository {
    async fn save(&self, insight: &Insight) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO insights (id, title, body, source_article_ids, tags, category, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        )
        .bind(insight.id.to_string())
        .bind(&insight.title)
        .bind(&insight.body)
        .bind(serde_json::to_string(&insight.source_article_ids).unwrap_or_default())
        .bind(tags_to_json(&insight.tags))
        .bind(&insight.category)
        .bind(insight.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn recent(&self, limit: u32) -> anyhow::Result<Vec<Insight>> {
        let rows = sqlx::query_as::<_, InsightRow>(
            "SELECT id, title, body, source_article_ids, tags, category, created_at FROM insights
             ORDER BY created_at DESC LIMIT ?1",
        )
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(insight_from_row).collect())
    }

    async fn recent_in_category(&self, category: &str, limit: u32) -> anyhow::Result<Vec<Insight>> {
        let rows = sqlx::query_as::<_, InsightRow>(
            "SELECT id, title, body, source_article_ids, tags, category, created_at FROM insights
             WHERE category = ?1 ORDER BY created_at DESC LIMIT ?2",
        )
        .bind(category)
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(insight_from_row).collect())
    }

    async fn get(&self, id: Uuid) -> anyhow::Result<Option<Insight>> {
        let row = sqlx::query_as::<_, InsightRow>(
            "SELECT id, title, body, source_article_ids, tags, category, created_at
             FROM insights WHERE id = ?1",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(insight_from_row))
    }

    async fn get_translation(
        &self,
        insight_id: Uuid,
        target_language: &str,
    ) -> anyhow::Result<Option<(String, String)>> {
        let row: Option<(String, String)> = sqlx::query_as(
            "SELECT title, body FROM insight_translations
             WHERE insight_id = ?1 AND target_language = ?2",
        )
        .bind(insight_id.to_string())
        .bind(target_language)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row)
    }

    async fn save_translation(
        &self,
        insight_id: Uuid,
        target_language: &str,
        title: &str,
        body: &str,
    ) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO insight_translations (insight_id, target_language, title, body, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5)
             ON CONFLICT (insight_id, target_language) DO UPDATE SET
                title = excluded.title,
                body = excluded.body,
                created_at = excluded.created_at",
        )
        .bind(insight_id.to_string())
        .bind(target_language)
        .bind(title)
        .bind(body)
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}

type InsightRow = (String, String, String, String, String, Option<String>, DateTime<Utc>);

fn insight_from_row(
    (id, title, body, source_ids, tags, category, created_at): InsightRow,
) -> Insight {
    Insight {
        id: Uuid::parse_str(&id).unwrap_or_default(),
        title,
        body,
        source_article_ids: serde_json::from_str(&source_ids).unwrap_or_default(),
        tags: tags_from_json(&tags),
        category,
        created_at,
    }
}

pub struct SqliteLifeAnalysisRepository {
    pool: SqlitePool,
}

impl SqliteLifeAnalysisRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl LifeAnalysisRepository for SqliteLifeAnalysisRepository {
    async fn save(&self, analysis: &LifeAnalysis) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO life_analyses (id, user_id, period_start, period_end, narrative, key_patterns, do_list, dont_list, generated_at, language)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
        )
        .bind(analysis.id.to_string())
        .bind(analysis.user_id.to_string())
        .bind(analysis.period_start)
        .bind(analysis.period_end)
        .bind(&analysis.narrative)
        .bind(tags_to_json(&analysis.key_patterns))
        .bind(tags_to_json(&analysis.do_list))
        .bind(tags_to_json(&analysis.dont_list))
        .bind(analysis.generated_at)
        .bind(&analysis.language)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<LifeAnalysis>> {
        let row = sqlx::query_as::<_, (String, String, DateTime<Utc>, DateTime<Utc>, String, String, String, String, DateTime<Utc>, String)>(
            "SELECT id, user_id, period_start, period_end, narrative, key_patterns, do_list, dont_list, generated_at, language
             FROM life_analyses WHERE user_id = ?1 ORDER BY generated_at DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, user_id, period_start, period_end, narrative, key_patterns, do_list, dont_list, generated_at, language)| {
                LifeAnalysis {
                    id: Uuid::parse_str(&id).unwrap_or_default(),
                    user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                    period_start,
                    period_end,
                    narrative,
                    key_patterns: tags_from_json(&key_patterns),
                    do_list: tags_from_json(&do_list),
                    dont_list: tags_from_json(&dont_list),
                    generated_at,
                    language,
                }
            },
        ))
    }
}

pub struct SqliteExplainerRepository {
    pool: SqlitePool,
}

impl SqliteExplainerRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ExplainerRepository for SqliteExplainerRepository {
    async fn get(&self, slug: &str, language: &str) -> anyhow::Result<Option<DisorderExplainer>> {
        let row = sqlx::query_as::<_, (String, String, String, String, String, String, String, String, DateTime<Utc>)>(
            "SELECT slug, language, category, name, what_it_is, how_it_develops, coping_paths, treatment_paths, generated_at
             FROM disorder_explainers WHERE slug = ?1 AND language = ?2",
        )
        .bind(slug)
        .bind(language)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(slug, language, category, name, what_it_is, how_it_develops, coping, treatment, generated_at)| {
                DisorderExplainer {
                    slug,
                    language,
                    category,
                    name,
                    what_it_is,
                    how_it_develops,
                    coping_paths: tags_from_json(&coping),
                    treatment_paths: tags_from_json(&treatment),
                    generated_at,
                }
            },
        ))
    }

    async fn save(&self, explainer: &DisorderExplainer) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO disorder_explainers (slug, language, category, name, what_it_is, how_it_develops, coping_paths, treatment_paths, generated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
             ON CONFLICT(slug, language) DO UPDATE SET
                name = excluded.name,
                what_it_is = excluded.what_it_is,
                how_it_develops = excluded.how_it_develops,
                coping_paths = excluded.coping_paths,
                treatment_paths = excluded.treatment_paths,
                generated_at = excluded.generated_at",
        )
        .bind(&explainer.slug)
        .bind(&explainer.language)
        .bind(&explainer.category)
        .bind(&explainer.name)
        .bind(&explainer.what_it_is)
        .bind(&explainer.how_it_develops)
        .bind(tags_to_json(&explainer.coping_paths))
        .bind(tags_to_json(&explainer.treatment_paths))
        .bind(explainer.generated_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn cached_slugs(&self, language: &str) -> anyhow::Result<Vec<String>> {
        let rows =
            sqlx::query_as::<_, (String,)>("SELECT slug FROM disorder_explainers WHERE language = ?1")
                .bind(language)
                .fetch_all(&self.pool)
                .await?;

        Ok(rows.into_iter().map(|(slug,)| slug).collect())
    }

    async fn stale_slugs(
        &self,
        cutoff: DateTime<Utc>,
        limit: u32,
        language: &str,
    ) -> anyhow::Result<Vec<String>> {
        let rows = sqlx::query_as::<_, (String,)>(
            "SELECT slug FROM disorder_explainers
             WHERE generated_at < ?1 AND language = ?2
             ORDER BY generated_at ASC
             LIMIT ?3",
        )
        .bind(cutoff)
        .bind(language)
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|(slug,)| slug).collect())
    }
}

pub struct SqliteUserStateRepository {
    pool: SqlitePool,
}

impl SqliteUserStateRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl UserStateRepository for SqliteUserStateRepository {
    async fn get(&self, user_id: Uuid) -> anyhow::Result<Option<UserState>> {
        let row = sqlx::query_as::<_, (String, f32, f32, String, String, String, DateTime<Utc>, String)>(
            "SELECT user_id, valence, energy, headline, note, basis, generated_at, language
             FROM user_states WHERE user_id = ?1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(user_id, valence, energy, headline, note, basis, generated_at, language)| UserState {
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                valence,
                energy,
                headline,
                note,
                basis: tags_from_json(&basis),
                generated_at,
                language,
            },
        ))
    }

    async fn save(&self, state: &UserState) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO user_states (user_id, valence, energy, headline, note, basis, generated_at, language)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
             ON CONFLICT(user_id) DO UPDATE SET
                valence = excluded.valence,
                energy = excluded.energy,
                headline = excluded.headline,
                note = excluded.note,
                basis = excluded.basis,
                generated_at = excluded.generated_at,
                language = excluded.language",
        )
        .bind(state.user_id.to_string())
        .bind(state.valence)
        .bind(state.energy)
        .bind(&state.headline)
        .bind(&state.note)
        .bind(tags_to_json(&state.basis))
        .bind(state.generated_at)
        .bind(&state.language)
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}

pub struct SqliteActivityRepository {
    pool: SqlitePool,
}

impl SqliteActivityRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ActivityRepository for SqliteActivityRepository {
    async fn daily_counts(
        &self,
        user_id: Uuid,
        since: DateTime<Utc>,
    ) -> anyhow::Result<Vec<(String, u32)>> {
        // `date()` parses the RFC3339 text these columns are stored as and
        // truncates to the UTC day — see `StreakSummary` on why UTC is
        // good enough here. Assistant chat messages are excluded: a
        // streak should count what the person did, not what was said back.
        let rows = sqlx::query_as::<_, (String, i64)>(
            "SELECT day, SUM(n) AS total FROM (
                 SELECT date(recorded_at) AS day, COUNT(*) AS n FROM mood_entries
                 WHERE user_id = ?1 AND recorded_at >= ?2 GROUP BY day
                 UNION ALL
                 SELECT date(created_at) AS day, COUNT(*) AS n FROM journal_entries
                 WHERE user_id = ?1 AND created_at >= ?2 GROUP BY day
                 UNION ALL
                 SELECT date(created_at) AS day, COUNT(*) AS n FROM chat_messages
                 WHERE user_id = ?1 AND role = 'user' AND created_at >= ?2 GROUP BY day
             )
             GROUP BY day ORDER BY day ASC",
        )
        .bind(user_id.to_string())
        .bind(since)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|(day, total)| (day, total.max(0) as u32)).collect())
    }
}

pub struct SqliteAssessmentRepository {
    pool: SqlitePool,
}

impl SqliteAssessmentRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl AssessmentRepository for SqliteAssessmentRepository {
    async fn save(&self, assessment: &WellbeingAssessment) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO wellbeing_assessments
             (id, user_id, phq9_answers, phq9_score, gad7_answers, gad7_score,
              who5_answers, who5_score, phq15_answers, phq15_score,
              ptsd5_answers, ptsd5_score, auditc_answers, auditc_score,
              cageaid_answers, cageaid_score, crisis_flag, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18)",
        )
        .bind(assessment.id.to_string())
        .bind(assessment.user_id.to_string())
        .bind(serde_json::to_string(&assessment.phq9_answers).unwrap_or_default())
        .bind(assessment.phq9_score as i32)
        .bind(serde_json::to_string(&assessment.gad7_answers).unwrap_or_default())
        .bind(assessment.gad7_score as i32)
        .bind(serde_json::to_string(&assessment.who5_answers).unwrap_or_default())
        .bind(assessment.who5_score as i32)
        .bind(serde_json::to_string(&assessment.phq15_answers).unwrap_or_default())
        .bind(assessment.phq15_score as i32)
        .bind(serde_json::to_string(&assessment.ptsd5_answers).unwrap_or_default())
        .bind(assessment.ptsd5_score as i32)
        .bind(serde_json::to_string(&assessment.auditc_answers).unwrap_or_default())
        .bind(assessment.auditc_score as i32)
        .bind(serde_json::to_string(&assessment.cageaid_answers).unwrap_or_default())
        .bind(assessment.cageaid_score as i32)
        .bind(assessment.crisis_flag)
        .bind(assessment.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<WellbeingAssessment>> {
        // A derive-based row rather than a raw tuple: eighteen columns is
        // past where hand-matching positional tuple fields stays safe to
        // read, and sqlx's tuple `FromRow` impls don't reach this arity
        // anyway.
        #[derive(sqlx::FromRow)]
        struct Row {
            id: String,
            user_id: String,
            phq9_answers: String,
            phq9_score: i32,
            gad7_answers: String,
            gad7_score: i32,
            who5_answers: String,
            who5_score: i32,
            phq15_answers: String,
            phq15_score: i32,
            ptsd5_answers: String,
            ptsd5_score: i32,
            auditc_answers: String,
            auditc_score: i32,
            cageaid_answers: String,
            cageaid_score: i32,
            crisis_flag: bool,
            created_at: DateTime<Utc>,
        }

        let row = sqlx::query_as::<_, Row>(
            "SELECT id, user_id, phq9_answers, phq9_score, gad7_answers, gad7_score,
                    who5_answers, who5_score, phq15_answers, phq15_score,
                    ptsd5_answers, ptsd5_score, auditc_answers, auditc_score,
                    cageaid_answers, cageaid_score, crisis_flag, created_at
             FROM wellbeing_assessments WHERE user_id = ?1 ORDER BY created_at DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| WellbeingAssessment {
            id: Uuid::parse_str(&r.id).unwrap_or_default(),
            user_id: Uuid::parse_str(&r.user_id).unwrap_or_default(),
            phq9_answers: serde_json::from_str(&r.phq9_answers).unwrap_or_default(),
            phq9_score: r.phq9_score as u8,
            gad7_answers: serde_json::from_str(&r.gad7_answers).unwrap_or_default(),
            gad7_score: r.gad7_score as u8,
            who5_answers: serde_json::from_str(&r.who5_answers).unwrap_or_default(),
            who5_score: r.who5_score as u8,
            phq15_answers: serde_json::from_str(&r.phq15_answers).unwrap_or_default(),
            phq15_score: r.phq15_score as u8,
            ptsd5_answers: serde_json::from_str(&r.ptsd5_answers).unwrap_or_default(),
            ptsd5_score: r.ptsd5_score as u8,
            auditc_answers: serde_json::from_str(&r.auditc_answers).unwrap_or_default(),
            auditc_score: r.auditc_score as u8,
            cageaid_answers: serde_json::from_str(&r.cageaid_answers).unwrap_or_default(),
            cageaid_score: r.cageaid_score as u8,
            crisis_flag: r.crisis_flag,
            created_at: r.created_at,
        }))
    }
}

pub struct SqliteLifeStoryRepository {
    pool: SqlitePool,
}

impl SqliteLifeStoryRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

type StoryRow = (String, String, String, String, String, bool, DateTime<Utc>, bool, Option<DateTime<Utc>>, DateTime<Utc>, String);

fn story_from_row(
    (id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at, language): StoryRow,
) -> LifeStory {
    LifeStory {
        id: Uuid::parse_str(&id).unwrap_or_default(),
        user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
        body,
        diagnosis_slug,
        status: StoryStatus::parse(&status),
        crisis_flag,
        consented_at,
        anonymous,
        language,
        reviewed_at,
        created_at,
    }
}

#[async_trait]
impl LifeStoryRepository for SqliteLifeStoryRepository {
    async fn create(&self, story: &LifeStory) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO life_stories (id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at, language)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
        )
        .bind(story.id.to_string())
        .bind(story.user_id.to_string())
        .bind(&story.body)
        .bind(&story.diagnosis_slug)
        .bind(story.status.as_str())
        .bind(story.crisis_flag)
        .bind(story.consented_at)
        .bind(story.anonymous)
        .bind(story.reviewed_at)
        .bind(story.created_at)
        .bind(&story.language)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn get(&self, id: Uuid) -> anyhow::Result<Option<LifeStory>> {
        let row = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at, language
             FROM life_stories WHERE id = ?1",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(story_from_row))
    }

    async fn list_approved(&self, limit: u32) -> anyhow::Result<Vec<LifeStory>> {
        let rows = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at, language
             FROM life_stories WHERE status = 'approved' ORDER BY created_at DESC LIMIT ?1",
        )
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(story_from_row).collect())
    }

    async fn list_for_user(&self, user_id: Uuid) -> anyhow::Result<Vec<LifeStory>> {
        let rows = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at, language
             FROM life_stories WHERE user_id = ?1 ORDER BY created_at DESC",
        )
        .bind(user_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(story_from_row).collect())
    }

    async fn list_pending(&self) -> anyhow::Result<Vec<LifeStory>> {
        let rows = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at, language
             FROM life_stories WHERE status = 'pending' ORDER BY created_at ASC",
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(story_from_row).collect())
    }

    async fn set_status(
        &self,
        id: Uuid,
        status: StoryStatus,
        reviewed_at: DateTime<Utc>,
    ) -> anyhow::Result<()> {
        sqlx::query("UPDATE life_stories SET status = ?1, reviewed_at = ?2 WHERE id = ?3")
            .bind(status.as_str())
            .bind(reviewed_at)
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn delete(&self, id: Uuid, user_id: Uuid) -> anyhow::Result<()> {
        // None of `story_reactions`, `life_story_reports` or
        // `story_translations` cascade on delete (SQLite foreign keys
        // don't unless declared `ON DELETE CASCADE`, and these weren't),
        // so a story with any of the three attached would otherwise fail
        // to delete with a foreign-key-constraint error. One transaction
        // so a withdrawal is still all-or-nothing.
        let mut tx = self.pool.begin().await?;

        sqlx::query("DELETE FROM story_reactions WHERE story_id = ?1")
            .bind(id.to_string())
            .execute(&mut *tx)
            .await?;
        sqlx::query("DELETE FROM life_story_reports WHERE story_id = ?1")
            .bind(id.to_string())
            .execute(&mut *tx)
            .await?;
        sqlx::query("DELETE FROM story_translations WHERE story_id = ?1")
            .bind(id.to_string())
            .execute(&mut *tx)
            .await?;
        sqlx::query("DELETE FROM life_stories WHERE id = ?1 AND user_id = ?2")
            .bind(id.to_string())
            .bind(user_id.to_string())
            .execute(&mut *tx)
            .await?;

        tx.commit().await?;
        Ok(())
    }

    async fn update(&self, story: &LifeStory) -> anyhow::Result<()> {
        // A translation cached against the old body would now be wrong —
        // dropped rather than left to be served as if it still matched.
        let mut tx = self.pool.begin().await?;

        sqlx::query("DELETE FROM story_translations WHERE story_id = ?1")
            .bind(story.id.to_string())
            .execute(&mut *tx)
            .await?;
        sqlx::query(
            "UPDATE life_stories SET
                body = ?1, diagnosis_slug = ?2, status = ?3, crisis_flag = ?4,
                anonymous = ?5, language = ?6, reviewed_at = ?7
             WHERE id = ?8 AND user_id = ?9",
        )
        .bind(&story.body)
        .bind(&story.diagnosis_slug)
        .bind(story.status.as_str())
        .bind(story.crisis_flag)
        .bind(story.anonymous)
        .bind(&story.language)
        .bind(story.reviewed_at)
        .bind(story.id.to_string())
        .bind(story.user_id.to_string())
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(())
    }

    async fn add_report(&self, report: &LifeStoryReport) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO life_story_reports (id, story_id, reporter_user_id, note, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5)",
        )
        .bind(report.id.to_string())
        .bind(report.story_id.to_string())
        .bind(report.reporter_user_id.to_string())
        .bind(&report.note)
        .bind(report.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn list_reports(&self) -> anyhow::Result<Vec<LifeStoryReport>> {
        let rows = sqlx::query_as::<_, (String, String, String, Option<String>, DateTime<Utc>)>(
            "SELECT id, story_id, reporter_user_id, note, created_at
             FROM life_story_reports ORDER BY created_at DESC",
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, story_id, reporter_user_id, note, created_at)| LifeStoryReport {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                story_id: Uuid::parse_str(&story_id).unwrap_or_default(),
                reporter_user_id: Uuid::parse_str(&reporter_user_id).unwrap_or_default(),
                note,
                created_at,
            })
            .collect())
    }

    async fn feed_for(&self, viewer: Uuid, limit: u32) -> anyhow::Result<Vec<StoryFeedItem>> {
        // The author join is unconditional here and stripped in the route
        // layer for anonymous rows — keeping the "don't leak the name"
        // decision in one place (`routes/stories.rs`) rather than half in
        // SQL and half in Rust.
        // Reaction counts come back as one `name:count,name:count` string
        // rather than a column per reaction type — sqlx's tuple `FromRow`
        // only goes up to 16 columns, and three more scalar subqueries
        // would have pushed this past that. Parsed by
        // `parse_reaction_counts` below.
        let rows = sqlx::query_as::<
            _,
            (
                String, String, String, String, String, bool, DateTime<Utc>, bool,
                Option<DateTime<Utc>>, DateTime<Utc>, String, Option<String>, Option<String>, String,
                Option<String>,
            ),
        >(
            "SELECT s.id, s.user_id, s.body, s.diagnosis_slug, s.status, s.crisis_flag,
                    s.consented_at, s.anonymous, s.reviewed_at, s.created_at, s.language,
                    (SELECT group_concat(reaction || ':' || cnt) FROM (
                        SELECT reaction, COUNT(*) AS cnt FROM story_reactions
                        WHERE story_id = s.id GROUP BY reaction
                    )) AS reaction_summary,
                    (SELECT r.reaction FROM story_reactions r WHERE r.story_id = s.id AND r.user_id = ?1) AS mine,
                    u.display_name, u.avatar_content_type
             FROM life_stories s JOIN users u ON u.id = s.user_id
             WHERE s.status = 'approved'
             ORDER BY s.created_at DESC LIMIT ?2",
        )
        .bind(viewer.to_string())
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at,
                   anonymous, reviewed_at, created_at, language, reaction_summary, mine,
                   display_name, avatar)| {
                StoryFeedItem {
                    story: story_from_row((
                        id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at,
                        anonymous, reviewed_at, created_at, language,
                    )),
                    reaction_counts: parse_reaction_counts(reaction_summary),
                    viewer_reaction: mine,
                    author_display_name: display_name,
                    author_has_avatar: avatar.is_some(),
                }
            })
            .collect())
    }

    async fn approved_count_for(&self, user_id: Uuid) -> anyhow::Result<u32> {
        let (count,): (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM life_stories WHERE user_id = ?1 AND status = 'approved'",
        )
        .bind(user_id.to_string())
        .fetch_one(&self.pool)
        .await?;

        Ok(count.max(0) as u32)
    }

    async fn get_translation(
        &self,
        story_id: Uuid,
        target_language: &str,
    ) -> anyhow::Result<Option<String>> {
        let row: Option<(String,)> = sqlx::query_as(
            "SELECT body FROM story_translations WHERE story_id = ?1 AND target_language = ?2",
        )
        .bind(story_id.to_string())
        .bind(target_language)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(body,)| body))
    }

    async fn save_translation(
        &self,
        story_id: Uuid,
        target_language: &str,
        body: &str,
    ) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO story_translations (story_id, target_language, body, created_at)
             VALUES (?1, ?2, ?3, ?4)
             ON CONFLICT (story_id, target_language) DO UPDATE SET body = excluded.body, created_at = excluded.created_at",
        )
        .bind(story_id.to_string())
        .bind(target_language)
        .bind(body)
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}

pub struct SqliteSocialRepository {
    pool: SqlitePool,
}

impl SqliteSocialRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl SocialRepository for SqliteSocialRepository {
    async fn follow(&self, follower: Uuid, followee: Uuid) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO follows (follower_id, followee_id, created_at) VALUES (?1, ?2, ?3)
             ON CONFLICT(follower_id, followee_id) DO NOTHING",
        )
        .bind(follower.to_string())
        .bind(followee.to_string())
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn unfollow(&self, follower: Uuid, followee: Uuid) -> anyhow::Result<()> {
        sqlx::query("DELETE FROM follows WHERE follower_id = ?1 AND followee_id = ?2")
            .bind(follower.to_string())
            .bind(followee.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn is_following(&self, follower: Uuid, followee: Uuid) -> anyhow::Result<bool> {
        let (count,): (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM follows WHERE follower_id = ?1 AND followee_id = ?2",
        )
        .bind(follower.to_string())
        .bind(followee.to_string())
        .fetch_one(&self.pool)
        .await?;

        Ok(count > 0)
    }

    async fn follower_count(&self, user_id: Uuid) -> anyhow::Result<u32> {
        let (count,): (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM follows WHERE followee_id = ?1")
                .bind(user_id.to_string())
                .fetch_one(&self.pool)
                .await?;

        Ok(count.max(0) as u32)
    }

    async fn following_count(&self, user_id: Uuid) -> anyhow::Result<u32> {
        let (count,): (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM follows WHERE follower_id = ?1")
                .bind(user_id.to_string())
                .fetch_one(&self.pool)
                .await?;

        Ok(count.max(0) as u32)
    }

    async fn followers(&self, user_id: Uuid) -> anyhow::Result<Vec<Uuid>> {
        let rows = sqlx::query_as::<_, (String,)>(
            "SELECT follower_id FROM follows WHERE followee_id = ?1 ORDER BY created_at DESC",
        )
        .bind(user_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|(id,)| Uuid::parse_str(&id).unwrap_or_default()).collect())
    }

    async fn following(&self, user_id: Uuid) -> anyhow::Result<Vec<Uuid>> {
        let rows = sqlx::query_as::<_, (String,)>(
            "SELECT followee_id FROM follows WHERE follower_id = ?1 ORDER BY created_at DESC",
        )
        .bind(user_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|(id,)| Uuid::parse_str(&id).unwrap_or_default()).collect())
    }

    async fn react(&self, story_id: Uuid, user_id: Uuid, reaction: &str) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO story_reactions (story_id, user_id, reaction, created_at) VALUES (?1, ?2, ?3, ?4)
             ON CONFLICT(story_id, user_id) DO UPDATE SET
                reaction = excluded.reaction, created_at = excluded.created_at",
        )
        .bind(story_id.to_string())
        .bind(user_id.to_string())
        .bind(reaction)
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn remove_reaction(&self, story_id: Uuid, user_id: Uuid) -> anyhow::Result<()> {
        sqlx::query("DELETE FROM story_reactions WHERE story_id = ?1 AND user_id = ?2")
            .bind(story_id.to_string())
            .bind(user_id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }
}

pub struct SqliteDmRepository {
    pool: SqlitePool,
}

impl SqliteDmRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

type DmThreadRow = (String, String, String, String, String, DateTime<Utc>, DateTime<Utc>);

fn thread_from_row(
    (id, user_low, user_high, started_by, status, created_at, last_message_at): DmThreadRow,
) -> DmThread {
    DmThread {
        id: Uuid::parse_str(&id).unwrap_or_default(),
        user_low: Uuid::parse_str(&user_low).unwrap_or_default(),
        user_high: Uuid::parse_str(&user_high).unwrap_or_default(),
        started_by: Uuid::parse_str(&started_by).unwrap_or_default(),
        status: DmStatus::parse(&status),
        created_at,
        last_message_at,
    }
}

const THREAD_COLUMNS: &str =
    "id, user_low, user_high, started_by, status, created_at, last_message_at";

#[async_trait]
impl DmRepository for SqliteDmRepository {
    async fn thread_between(&self, a: Uuid, b: Uuid) -> anyhow::Result<Option<DmThread>> {
        let (low, high) = DmThread::pair(a, b);
        let row = sqlx::query_as::<_, DmThreadRow>(&format!(
            "SELECT {THREAD_COLUMNS} FROM dm_threads WHERE user_low = ?1 AND user_high = ?2"
        ))
        .bind(low.to_string())
        .bind(high.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(thread_from_row))
    }

    async fn get_thread(&self, id: Uuid) -> anyhow::Result<Option<DmThread>> {
        let row = sqlx::query_as::<_, DmThreadRow>(&format!(
            "SELECT {THREAD_COLUMNS} FROM dm_threads WHERE id = ?1"
        ))
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(thread_from_row))
    }

    async fn create_thread(&self, thread: &DmThread) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO dm_threads (id, user_low, user_high, started_by, status, created_at, last_message_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        )
        .bind(thread.id.to_string())
        .bind(thread.user_low.to_string())
        .bind(thread.user_high.to_string())
        .bind(thread.started_by.to_string())
        .bind(thread.status.as_str())
        .bind(thread.created_at)
        .bind(thread.last_message_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn accept_thread(&self, id: Uuid) -> anyhow::Result<()> {
        sqlx::query("UPDATE dm_threads SET status = 'accepted' WHERE id = ?1")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn delete_thread(&self, id: Uuid) -> anyhow::Result<()> {
        sqlx::query("DELETE FROM dm_messages WHERE thread_id = ?1")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;
        sqlx::query("DELETE FROM dm_threads WHERE id = ?1")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn threads_for(&self, user_id: Uuid, status: DmStatus) -> anyhow::Result<Vec<DmThread>> {
        let rows = sqlx::query_as::<_, DmThreadRow>(&format!(
            "SELECT {THREAD_COLUMNS} FROM dm_threads
             WHERE (user_low = ?1 OR user_high = ?1) AND status = ?2
             ORDER BY last_message_at DESC"
        ))
        .bind(user_id.to_string())
        .bind(status.as_str())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(thread_from_row).collect())
    }

    async fn add_message(&self, message: &DmMessage, sent_at: DateTime<Utc>) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO dm_messages (id, thread_id, sender_id, body, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5)",
        )
        .bind(message.id.to_string())
        .bind(message.thread_id.to_string())
        .bind(message.sender_id.to_string())
        .bind(&message.body)
        .bind(message.created_at)
        .execute(&self.pool)
        .await?;

        sqlx::query("UPDATE dm_threads SET last_message_at = ?1 WHERE id = ?2")
            .bind(sent_at)
            .bind(message.thread_id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn messages(&self, thread_id: Uuid, limit: u32) -> anyhow::Result<Vec<DmMessage>> {
        let rows = sqlx::query_as::<_, (String, String, String, String, DateTime<Utc>)>(
            "SELECT id, thread_id, sender_id, body, created_at FROM dm_messages
             WHERE thread_id = ?1 ORDER BY created_at ASC LIMIT ?2",
        )
        .bind(thread_id.to_string())
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(dm_message_from_row).collect())
    }

    async fn latest_messages(&self, thread_ids: &[Uuid]) -> anyhow::Result<Vec<DmMessage>> {
        if thread_ids.is_empty() {
            return Ok(Vec::new());
        }

        // Ids are server-generated UUIDs, never user input, so building
        // the IN list by hand can't carry anything injectable.
        let list = thread_ids
            .iter()
            .map(|id| format!("'{id}'"))
            .collect::<Vec<_>>()
            .join(",");

        let rows = sqlx::query_as::<_, (String, String, String, String, DateTime<Utc>)>(&format!(
            "SELECT m.id, m.thread_id, m.sender_id, m.body, m.created_at FROM dm_messages m
             JOIN (SELECT thread_id, MAX(created_at) AS newest FROM dm_messages
                   WHERE thread_id IN ({list}) GROUP BY thread_id) latest
               ON latest.thread_id = m.thread_id AND latest.newest = m.created_at"
        ))
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(dm_message_from_row).collect())
    }
}

fn dm_message_from_row(
    (id, thread_id, sender_id, body, created_at): (String, String, String, String, DateTime<Utc>),
) -> DmMessage {
    DmMessage {
        id: Uuid::parse_str(&id).unwrap_or_default(),
        thread_id: Uuid::parse_str(&thread_id).unwrap_or_default(),
        sender_id: Uuid::parse_str(&sender_id).unwrap_or_default(),
        body,
        created_at,
    }
}

pub struct SqliteAuthRepository {
    pool: SqlitePool,
}

impl SqliteAuthRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl AuthRepository for SqliteAuthRepository {
    async fn create_credentials(&self, credentials: &Credentials) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO credentials (user_id, email, password_hash, created_at) VALUES (?1, ?2, ?3, ?4)",
        )
        .bind(credentials.user_id.to_string())
        .bind(&credentials.email)
        .bind(&credentials.password_hash)
        .bind(credentials.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn find_credentials_by_email(&self, email: &str) -> anyhow::Result<Option<Credentials>> {
        let row = sqlx::query_as::<_, (String, String, String, DateTime<Utc>)>(
            "SELECT user_id, email, password_hash, created_at FROM credentials WHERE email = ?1",
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(user_id, email, password_hash, created_at)| Credentials {
            user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
            email,
            password_hash,
            created_at,
        }))
    }

    async fn find_email_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<String>> {
        let row = sqlx::query_as::<_, (String,)>("SELECT email FROM credentials WHERE user_id = ?1")
            .bind(user_id.to_string())
            .fetch_optional(&self.pool)
            .await?;

        Ok(row.map(|(email,)| email))
    }

    async fn create_session(&self, session: &Session) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO sessions (token, user_id, created_at, expires_at) VALUES (?1, ?2, ?3, ?4)",
        )
        .bind(&session.token)
        .bind(session.user_id.to_string())
        .bind(session.created_at)
        .bind(session.expires_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn find_session(&self, token: &str) -> anyhow::Result<Option<Session>> {
        let row = sqlx::query_as::<_, (String, String, DateTime<Utc>, DateTime<Utc>)>(
            "SELECT token, user_id, created_at, expires_at FROM sessions WHERE token = ?1",
        )
        .bind(token)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(token, user_id, created_at, expires_at)| Session {
            token,
            user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
            created_at,
            expires_at,
        }))
    }

    async fn delete_session(&self, token: &str) -> anyhow::Result<()> {
        sqlx::query("DELETE FROM sessions WHERE token = ?1")
            .bind(token)
            .execute(&self.pool)
            .await?;

        Ok(())
    }
}

pub struct SqliteChatRepository {
    pool: SqlitePool,
}

impl SqliteChatRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ChatRepository for SqliteChatRepository {
    async fn add(&self, message: &ChatMessageRecord) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO chat_messages (id, user_id, role, content, crisis_flag, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        )
        .bind(message.id.to_string())
        .bind(message.user_id.to_string())
        .bind(message.role.as_str())
        .bind(&message.content)
        .bind(message.crisis_flag)
        .bind(message.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn history_for_user(&self, user_id: Uuid, limit: u32) -> anyhow::Result<Vec<ChatMessageRecord>> {
        let rows = sqlx::query_as::<_, (String, String, String, String, bool, DateTime<Utc>)>(
            "SELECT id, user_id, role, content, crisis_flag, created_at FROM chat_messages
             WHERE user_id = ?1 ORDER BY created_at ASC LIMIT ?2",
        )
        .bind(user_id.to_string())
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, user_id, role, content, crisis_flag, created_at)| ChatMessageRecord {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                role: if role == "assistant" { ChatRole::Assistant } else { ChatRole::User },
                content,
                crisis_flag,
                created_at,
            })
            .collect())
    }
}

pub struct SqlitePushTokenRepository {
    pool: SqlitePool,
}

impl SqlitePushTokenRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl PushTokenRepository for SqlitePushTokenRepository {
    async fn register(&self, token: &PushToken) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO device_push_tokens (token, user_id, platform, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5)
             ON CONFLICT(token) DO UPDATE SET
                user_id = excluded.user_id,
                platform = excluded.platform,
                updated_at = excluded.updated_at",
        )
        .bind(&token.token)
        .bind(token.user_id.to_string())
        .bind(&token.platform)
        .bind(token.created_at)
        .bind(token.updated_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn unregister(&self, token: &str) -> anyhow::Result<()> {
        sqlx::query("DELETE FROM device_push_tokens WHERE token = ?1")
            .bind(token)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn tokens_for_user(&self, user_id: Uuid) -> anyhow::Result<Vec<String>> {
        let rows: Vec<(String,)> =
            sqlx::query_as("SELECT token FROM device_push_tokens WHERE user_id = ?1")
                .bind(user_id.to_string())
                .fetch_all(&self.pool)
                .await?;

        Ok(rows.into_iter().map(|(token,)| token).collect())
    }

    async fn all_user_ids(&self) -> anyhow::Result<Vec<Uuid>> {
        let rows: Vec<(String,)> =
            sqlx::query_as("SELECT DISTINCT user_id FROM device_push_tokens")
                .fetch_all(&self.pool)
                .await?;

        Ok(rows.into_iter().filter_map(|(id,)| Uuid::parse_str(&id).ok()).collect())
    }
}

pub struct SqliteContentTranslationRepository {
    pool: SqlitePool,
}

impl SqliteContentTranslationRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ContentTranslationRepository for SqliteContentTranslationRepository {
    async fn get(
        &self,
        content_type: &str,
        content_id: &str,
        target_language: &str,
    ) -> anyhow::Result<Option<String>> {
        let row: Option<(String,)> = sqlx::query_as(
            "SELECT payload FROM content_translations
             WHERE content_type = ?1 AND content_id = ?2 AND target_language = ?3",
        )
        .bind(content_type)
        .bind(content_id)
        .bind(target_language)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(payload,)| payload))
    }

    async fn save(
        &self,
        content_type: &str,
        content_id: &str,
        target_language: &str,
        payload: &str,
    ) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO content_translations (content_type, content_id, target_language, payload, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5)
             ON CONFLICT (content_type, content_id, target_language) DO UPDATE SET
                payload = excluded.payload,
                created_at = excluded.created_at",
        )
        .bind(content_type)
        .bind(content_id)
        .bind(target_language)
        .bind(payload)
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }
}

pub struct SqliteSubscriptionRepository {
    pool: SqlitePool,
}

impl SqliteSubscriptionRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl SubscriptionRepository for SqliteSubscriptionRepository {
    async fn upsert(&self, subscription: &Subscription) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO subscriptions
                (user_id, platform, product_id, original_transaction_id, expires_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(user_id) DO UPDATE SET
                platform = excluded.platform,
                product_id = excluded.product_id,
                original_transaction_id = excluded.original_transaction_id,
                expires_at = excluded.expires_at,
                updated_at = excluded.updated_at",
        )
        .bind(subscription.user_id.to_string())
        .bind(&subscription.platform)
        .bind(&subscription.product_id)
        .bind(&subscription.original_transaction_id)
        .bind(subscription.expires_at)
        .bind(subscription.updated_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn for_user(&self, user_id: Uuid) -> anyhow::Result<Option<Subscription>> {
        let row = sqlx::query_as::<_, (String, String, String, DateTime<Utc>, DateTime<Utc>)>(
            "SELECT platform, product_id, original_transaction_id, expires_at, updated_at
             FROM subscriptions WHERE user_id = ?1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(platform, product_id, original_transaction_id, expires_at, updated_at)| {
            Subscription { user_id, platform, product_id, original_transaction_id, expires_at, updated_at }
        }))
    }
}

pub struct SqliteChatUsageRepository {
    pool: SqlitePool,
}

impl SqliteChatUsageRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ChatUsageRepository for SqliteChatUsageRepository {
    async fn add_tokens(&self, user_id: Uuid, date: NaiveDate, tokens: i64) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO chat_token_usage (user_id, usage_date, tokens_used)
             VALUES (?1, ?2, ?3)
             ON CONFLICT(user_id, usage_date) DO UPDATE SET
                tokens_used = tokens_used + excluded.tokens_used",
        )
        .bind(user_id.to_string())
        .bind(date.to_string())
        .bind(tokens)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn tokens_used(&self, user_id: Uuid, date: NaiveDate) -> anyhow::Result<i64> {
        let used: Option<i64> = sqlx::query_scalar(
            "SELECT tokens_used FROM chat_token_usage WHERE user_id = ?1 AND usage_date = ?2",
        )
        .bind(user_id.to_string())
        .bind(date.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(used.unwrap_or(0))
    }
}
