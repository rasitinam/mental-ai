use async_trait::async_trait;
use sqlx::SqlitePool;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct ScoredArticle {
    pub article_id: Uuid,
    pub score: f32,
}

#[async_trait]
pub trait VectorStore: Send + Sync {
    async fn upsert(&self, article_id: Uuid, embedding: &[f32]) -> anyhow::Result<()>;
    async fn search(&self, query_embedding: &[f32], top_k: usize) -> anyhow::Result<Vec<ScoredArticle>>;
}

pub struct SqliteVectorStore {
    pool: SqlitePool,
}

impl SqliteVectorStore {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

fn to_bytes(embedding: &[f32]) -> Vec<u8> {
    embedding.iter().flat_map(|f| f.to_le_bytes()).collect()
}

fn from_bytes(bytes: &[u8]) -> Vec<f32> {
    bytes
        .chunks_exact(4)
        .map(|c| f32::from_le_bytes([c[0], c[1], c[2], c[3]]))
        .collect()
}

fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.len() != b.len() || a.is_empty() {
        return 0.0;
    }
    let dot: f32 = a.iter().zip(b).map(|(x, y)| x * y).sum();
    let norm_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let norm_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm_a == 0.0 || norm_b == 0.0 {
        0.0
    } else {
        dot / (norm_a * norm_b)
    }
}

#[async_trait]
impl VectorStore for SqliteVectorStore {
    async fn upsert(&self, article_id: Uuid, embedding: &[f32]) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO research_embeddings (article_id, embedding, dims) VALUES (?1, ?2, ?3)
             ON CONFLICT(article_id) DO UPDATE SET embedding = excluded.embedding, dims = excluded.dims",
        )
        .bind(article_id.to_string())
        .bind(to_bytes(embedding))
        .bind(embedding.len() as i64)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Brute-force scan. Fine up to tens of thousands of rows; see the
    /// module doc for the scaling plan if that stops being true.
    async fn search(&self, query_embedding: &[f32], top_k: usize) -> anyhow::Result<Vec<ScoredArticle>> {
        let rows: Vec<(String, Vec<u8>)> =
            sqlx::query_as("SELECT article_id, embedding FROM research_embeddings")
                .fetch_all(&self.pool)
                .await?;

        let mut scored: Vec<ScoredArticle> = rows
            .into_iter()
            .filter_map(|(id, bytes)| {
                let embedding = from_bytes(&bytes);
                Uuid::parse_str(&id).ok().map(|article_id| ScoredArticle {
                    article_id,
                    score: cosine_similarity(query_embedding, &embedding),
                })
            })
            .collect();

        scored.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));
        scored.truncate(top_k);
        Ok(scored)
    }
}
