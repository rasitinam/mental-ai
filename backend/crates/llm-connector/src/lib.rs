//! Provider-agnostic LLM connector.
//!
//! `analysis-engine` and the chat API never talk to an LLM vendor's SDK
//! directly — they depend only on the `LlmProvider` trait below. Today
//! that trait is implemented by `OpenAiCompatibleProvider`, which speaks
//! the OpenAI Chat Completions wire format and works against OpenAI's own
//! API, Azure OpenAI, or any self-hosted OpenAI-schema-compatible endpoint
//! (set `MENTAL_AI__LLM__BASE_URL` and `MENTAL_AI__LLM__CHAT_MODEL`, e.g.
//! to point at a "gpt-5.x" style model as it becomes available). Swapping
//! vendors later means adding a new struct here, not touching callers.
//!
//! `tools` implements MCP-style function calling: the analysis engine
//! registers local functions (fetch mood history, search the knowledge
//! base, ...) as `Tool` schemas, the model can request a call, and the
//! caller executes it and feeds the result back in the same turn.

pub mod error;
pub mod openai_compatible;
pub mod prompts;
pub mod tools;

use async_trait::async_trait;
pub use error::LlmError;
use serde::{Deserialize, Serialize};
pub use tools::{Tool, ToolCall, ToolResult};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: Role,
    pub content: String,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Role {
    System,
    User,
    Assistant,
    Tool,
}

#[derive(Debug, Clone, Default)]
pub struct ChatRequest {
    pub messages: Vec<ChatMessage>,
    pub tools: Vec<Tool>,
    pub temperature: Option<f32>,
}

#[derive(Debug, Clone)]
pub struct ChatResponse {
    pub message: ChatMessage,
    pub tool_calls: Vec<ToolCall>,
}

#[async_trait]
pub trait LlmProvider: Send + Sync {
    async fn chat(&self, request: ChatRequest) -> Result<ChatResponse, LlmError>;
    async fn embed(&self, texts: &[String]) -> Result<Vec<Vec<f32>>, LlmError>;
}
