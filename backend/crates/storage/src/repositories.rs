use async_trait::async_trait;
use chrono::{DateTime, Utc};
use mental_domain::repository::{
    ActivityRepository, AssessmentRepository, AuthRepository, ChatRepository, DmRepository,
    ExplainerRepository, InsightRepository, JournalRepository, LifeAnalysisRepository,
    LifeStoryRepository, MoodRepository, ReportRepository, ResearchRepository, SocialRepository,
    UserRepository, UserStateRepository,
};
use mental_domain::report::LifeAnalysis;
use mental_domain::{
    ChatMessageRecord, ChatRole, Credentials, DailyMentalReport, DisorderExplainer, DmMessage,
    DmPolicy, DmStatus, DmThread, Insight, JournalEntry, LifeStory, LifeStoryReport, MoodEntry,
    ResearchArticle, Session, StoryFeedItem, StoryStatus, User, UserState, WellbeingAssessment,
};
use sqlx::SqlitePool;
use uuid::Uuid;

fn tags_to_json(tags: &[String]) -> String {
    serde_json::to_string(tags).unwrap_or_else(|_| "[]".to_string())
}

fn tags_from_json(raw: &str) -> Vec<String> {
    serde_json::from_str(raw).unwrap_or_default()
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
        let row = sqlx::query_as::<_, (String, String, String, String, String, Option<i32>, bool, Option<String>, String, DateTime<Utc>)>(
            "SELECT id, display_name, timezone, diagnoses, language, birth_year, is_admin, avatar_content_type, dm_policy, created_at
             FROM users WHERE id = ?1",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, display_name, timezone, diagnoses, language, birth_year, is_admin, avatar_content_type, dm_policy, created_at)| User {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                display_name,
                timezone,
                diagnoses: tags_from_json(&diagnoses),
                language,
                birth_year,
                is_admin,
                avatar_content_type,
                dm_policy: DmPolicy::parse(&dm_policy),
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
             (id, user_id, report_date, summary, mood_trend_note, recommendations, cited_insight_ids, crisis_flag, generated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
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
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<DailyMentalReport>> {
        let row = sqlx::query_as::<_, (String, String, DateTime<Utc>, String, String, String, String, bool, DateTime<Utc>)>(
            "SELECT id, user_id, report_date, summary, mood_trend_note, recommendations, cited_insight_ids, crisis_flag, generated_at
             FROM daily_reports WHERE user_id = ?1 ORDER BY report_date DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, user_id, report_date, summary, mood_trend_note, recommendations, cited, crisis_flag, generated_at)| {
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
                }
            },
        ))
    }

    async fn list_recent(&self, user_id: Uuid, limit: u32) -> anyhow::Result<Vec<DailyMentalReport>> {
        let rows = sqlx::query_as::<_, (String, String, DateTime<Utc>, String, String, String, String, bool, DateTime<Utc>)>(
            "SELECT id, user_id, report_date, summary, mood_trend_note, recommendations, cited_insight_ids, crisis_flag, generated_at
             FROM daily_reports WHERE user_id = ?1 ORDER BY report_date DESC LIMIT ?2",
        )
        .bind(user_id.to_string())
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(
                |(id, user_id, report_date, summary, mood_trend_note, recommendations, cited, crisis_flag, generated_at)| {
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
            "INSERT INTO life_analyses (id, user_id, period_start, period_end, narrative, key_patterns, do_list, dont_list, generated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
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
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<LifeAnalysis>> {
        let row = sqlx::query_as::<_, (String, String, DateTime<Utc>, DateTime<Utc>, String, String, String, String, DateTime<Utc>)>(
            "SELECT id, user_id, period_start, period_end, narrative, key_patterns, do_list, dont_list, generated_at
             FROM life_analyses WHERE user_id = ?1 ORDER BY generated_at DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, user_id, period_start, period_end, narrative, key_patterns, do_list, dont_list, generated_at)| {
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
    async fn get(&self, slug: &str) -> anyhow::Result<Option<DisorderExplainer>> {
        let row = sqlx::query_as::<_, (String, String, String, String, String, String, String, DateTime<Utc>)>(
            "SELECT slug, category, name, what_it_is, how_it_develops, coping_paths, treatment_paths, generated_at
             FROM disorder_explainers WHERE slug = ?1",
        )
        .bind(slug)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(slug, category, name, what_it_is, how_it_develops, coping, treatment, generated_at)| {
                DisorderExplainer {
                    slug,
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
            "INSERT INTO disorder_explainers (slug, category, name, what_it_is, how_it_develops, coping_paths, treatment_paths, generated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
             ON CONFLICT(slug) DO UPDATE SET
                what_it_is = excluded.what_it_is,
                how_it_develops = excluded.how_it_develops,
                coping_paths = excluded.coping_paths,
                treatment_paths = excluded.treatment_paths,
                generated_at = excluded.generated_at",
        )
        .bind(&explainer.slug)
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

    async fn cached_slugs(&self) -> anyhow::Result<Vec<String>> {
        let rows = sqlx::query_as::<_, (String,)>("SELECT slug FROM disorder_explainers")
            .fetch_all(&self.pool)
            .await?;

        Ok(rows.into_iter().map(|(slug,)| slug).collect())
    }

    async fn stale_slugs(&self, cutoff: DateTime<Utc>, limit: u32) -> anyhow::Result<Vec<String>> {
        let rows = sqlx::query_as::<_, (String,)>(
            "SELECT slug FROM disorder_explainers
             WHERE generated_at < ?1
             ORDER BY generated_at ASC
             LIMIT ?2",
        )
        .bind(cutoff)
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
        let row = sqlx::query_as::<_, (String, f32, f32, String, String, String, DateTime<Utc>)>(
            "SELECT user_id, valence, energy, headline, note, basis, generated_at
             FROM user_states WHERE user_id = ?1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(user_id, valence, energy, headline, note, basis, generated_at)| UserState {
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                valence,
                energy,
                headline,
                note,
                basis: tags_from_json(&basis),
                generated_at,
            },
        ))
    }

    async fn save(&self, state: &UserState) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO user_states (user_id, valence, energy, headline, note, basis, generated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(user_id) DO UPDATE SET
                valence = excluded.valence,
                energy = excluded.energy,
                headline = excluded.headline,
                note = excluded.note,
                basis = excluded.basis,
                generated_at = excluded.generated_at",
        )
        .bind(state.user_id.to_string())
        .bind(state.valence)
        .bind(state.energy)
        .bind(&state.headline)
        .bind(&state.note)
        .bind(tags_to_json(&state.basis))
        .bind(state.generated_at)
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
             (id, user_id, phq9_answers, phq9_score, gad7_answers, gad7_score, crisis_flag, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
        )
        .bind(assessment.id.to_string())
        .bind(assessment.user_id.to_string())
        .bind(serde_json::to_string(&assessment.phq9_answers).unwrap_or_default())
        .bind(assessment.phq9_score as i32)
        .bind(serde_json::to_string(&assessment.gad7_answers).unwrap_or_default())
        .bind(assessment.gad7_score as i32)
        .bind(assessment.crisis_flag)
        .bind(assessment.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<WellbeingAssessment>> {
        let row = sqlx::query_as::<_, (String, String, String, i32, String, i32, bool, DateTime<Utc>)>(
            "SELECT id, user_id, phq9_answers, phq9_score, gad7_answers, gad7_score, crisis_flag, created_at
             FROM wellbeing_assessments WHERE user_id = ?1 ORDER BY created_at DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, user_id, phq9_answers, phq9_score, gad7_answers, gad7_score, crisis_flag, created_at)| {
                WellbeingAssessment {
                    id: Uuid::parse_str(&id).unwrap_or_default(),
                    user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                    phq9_answers: serde_json::from_str(&phq9_answers).unwrap_or_default(),
                    phq9_score: phq9_score as u8,
                    gad7_answers: serde_json::from_str(&gad7_answers).unwrap_or_default(),
                    gad7_score: gad7_score as u8,
                    crisis_flag,
                    created_at,
                }
            },
        ))
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

type StoryRow = (String, String, String, String, String, bool, DateTime<Utc>, bool, Option<DateTime<Utc>>, DateTime<Utc>);

fn story_from_row(
    (id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at): StoryRow,
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
        reviewed_at,
        created_at,
    }
}

#[async_trait]
impl LifeStoryRepository for SqliteLifeStoryRepository {
    async fn create(&self, story: &LifeStory) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO life_stories (id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
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
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn get(&self, id: Uuid) -> anyhow::Result<Option<LifeStory>> {
        let row = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at
             FROM life_stories WHERE id = ?1",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(story_from_row))
    }

    async fn list_approved(&self, limit: u32) -> anyhow::Result<Vec<LifeStory>> {
        let rows = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at
             FROM life_stories WHERE status = 'approved' ORDER BY created_at DESC LIMIT ?1",
        )
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(story_from_row).collect())
    }

    async fn list_for_user(&self, user_id: Uuid) -> anyhow::Result<Vec<LifeStory>> {
        let rows = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at
             FROM life_stories WHERE user_id = ?1 ORDER BY created_at DESC",
        )
        .bind(user_id.to_string())
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(story_from_row).collect())
    }

    async fn list_pending(&self) -> anyhow::Result<Vec<LifeStory>> {
        let rows = sqlx::query_as::<_, StoryRow>(
            "SELECT id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at, anonymous, reviewed_at, created_at
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
        sqlx::query("DELETE FROM life_stories WHERE id = ?1 AND user_id = ?2")
            .bind(id.to_string())
            .bind(user_id.to_string())
            .execute(&self.pool)
            .await?;

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
        let rows = sqlx::query_as::<
            _,
            (
                String, String, String, String, String, bool, DateTime<Utc>, bool,
                Option<DateTime<Utc>>, DateTime<Utc>, i64, i64, String, Option<String>,
            ),
        >(
            "SELECT s.id, s.user_id, s.body, s.diagnosis_slug, s.status, s.crisis_flag,
                    s.consented_at, s.anonymous, s.reviewed_at, s.created_at,
                    (SELECT COUNT(*) FROM story_upvotes v WHERE v.story_id = s.id) AS upvotes,
                    (SELECT COUNT(*) FROM story_upvotes v WHERE v.story_id = s.id AND v.user_id = ?1) AS mine,
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
                   anonymous, reviewed_at, created_at, upvotes, mine, display_name, avatar)| {
                StoryFeedItem {
                    story: story_from_row((
                        id, user_id, body, diagnosis_slug, status, crisis_flag, consented_at,
                        anonymous, reviewed_at, created_at,
                    )),
                    upvotes: upvotes.max(0) as u32,
                    viewer_upvoted: mine > 0,
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

    async fn upvote(&self, story_id: Uuid, user_id: Uuid) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO story_upvotes (story_id, user_id, created_at) VALUES (?1, ?2, ?3)
             ON CONFLICT(story_id, user_id) DO NOTHING",
        )
        .bind(story_id.to_string())
        .bind(user_id.to_string())
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn remove_upvote(&self, story_id: Uuid, user_id: Uuid) -> anyhow::Result<()> {
        sqlx::query("DELETE FROM story_upvotes WHERE story_id = ?1 AND user_id = ?2")
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
