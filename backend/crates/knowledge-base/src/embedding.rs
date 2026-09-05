use std::sync::Arc;

use mental_llm_connector::LlmProvider;

/// Thin wrapper around `LlmProvider::embed` so callers depend on this
/// crate's `Embedder`, not on `llm-connector` directly — keeps the
/// dependency graph pointing one way (ingest/analysis -> knowledge-base
/// -> llm-connector).
pub struct Embedder {
    provider: Arc<dyn LlmProvider>,
}

impl Embedder {
    pub fn new(provider: Arc<dyn LlmProvider>) -> Self {
        Self { provider }
    }

    pub async fn embed_one(&self, text: &str) -> anyhow::Result<Vec<f32>> {
        let mut result = self.provider.embed(&[text.to_string()]).await?;
        Ok(result.pop().unwrap_or_default())
    }

    pub async fn embed_many(&self, texts: &[String]) -> anyhow::Result<Vec<Vec<f32>>> {
        Ok(self.provider.embed(texts).await?)
    }
}
