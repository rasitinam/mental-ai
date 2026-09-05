//! Local-first retrieval-augmented-generation (RAG) index over ingested
//! research. Deliberately not a dedicated vector database: at the scale
//! of "one user's curated research feed" (thousands, not millions, of
//! articles), brute-force cosine similarity over embeddings stored in
//! SQLite is fast enough and keeps the whole product dependency-light and
//! fully local. If corpus size ever demands it, swap `SqliteVectorStore`
//! for a real vector DB behind the same `VectorStore` trait.

pub mod embedding;
pub mod store;

pub use embedding::Embedder;
pub use store::{ScoredArticle, SqliteVectorStore, VectorStore};
