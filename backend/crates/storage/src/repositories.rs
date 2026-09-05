use async_trait::async_trait;
use chrono::{DateTime, Utc};
use mental_domain::repository::{
    InsightRepository, JournalRepository, LifeAnalysisRepository, MoodRepository, ReportRepository,
    ResearchRepository, UserRepository,
};
use mental_domain::report::LifeAnalysis;
use mental_domain::{DailyMentalReport, Insight, JournalEntry, MoodEntry, ResearchArticle, User};
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
        let row = sqlx::query_as::<_, (String, String, String, DateTime<Utc>)>(
            "SELECT id, display_name, timezone, created_at FROM users WHERE id = ?1",
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|(id, display_name, timezone, created_at)| User {
            id: Uuid::parse_str(&id).unwrap_or_default(),
            display_name,
            timezone,
            created_at,
        }))
    }

    async fn upsert(&self, user: &User) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO users (id, display_name, timezone, created_at) VALUES (?1, ?2, ?3, ?4)
             ON CONFLICT(id) DO UPDATE SET display_name = excluded.display_name, timezone = excluded.timezone",
        )
        .bind(user.id.to_string())
        .bind(&user.display_name)
        .bind(&user.timezone)
        .bind(user.created_at)
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
            "INSERT INTO insights (id, title, body, source_article_ids, tags, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        )
        .bind(insight.id.to_string())
        .bind(&insight.title)
        .bind(&insight.body)
        .bind(serde_json::to_string(&insight.source_article_ids).unwrap_or_default())
        .bind(tags_to_json(&insight.tags))
        .bind(insight.created_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn recent(&self, limit: u32) -> anyhow::Result<Vec<Insight>> {
        let rows = sqlx::query_as::<_, (String, String, String, String, String, DateTime<Utc>)>(
            "SELECT id, title, body, source_article_ids, tags, created_at FROM insights
             ORDER BY created_at DESC LIMIT ?1",
        )
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, title, body, source_ids, tags, created_at)| Insight {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                title,
                body,
                source_article_ids: serde_json::from_str(&source_ids).unwrap_or_default(),
                tags: tags_from_json(&tags),
                created_at,
            })
            .collect())
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
            "INSERT INTO life_analyses (id, user_id, period_start, period_end, narrative, key_patterns, generated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        )
        .bind(analysis.id.to_string())
        .bind(analysis.user_id.to_string())
        .bind(analysis.period_start)
        .bind(analysis.period_end)
        .bind(&analysis.narrative)
        .bind(tags_to_json(&analysis.key_patterns))
        .bind(analysis.generated_at)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn latest_for_user(&self, user_id: Uuid) -> anyhow::Result<Option<LifeAnalysis>> {
        let row = sqlx::query_as::<_, (String, String, DateTime<Utc>, DateTime<Utc>, String, String, DateTime<Utc>)>(
            "SELECT id, user_id, period_start, period_end, narrative, key_patterns, generated_at
             FROM life_analyses WHERE user_id = ?1 ORDER BY generated_at DESC LIMIT 1",
        )
        .bind(user_id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(
            |(id, user_id, period_start, period_end, narrative, key_patterns, generated_at)| LifeAnalysis {
                id: Uuid::parse_str(&id).unwrap_or_default(),
                user_id: Uuid::parse_str(&user_id).unwrap_or_default(),
                period_start,
                period_end,
                narrative,
                key_patterns: tags_from_json(&key_patterns),
                generated_at,
            },
        ))
    }
}
