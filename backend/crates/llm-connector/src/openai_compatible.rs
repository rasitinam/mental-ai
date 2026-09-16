use async_trait::async_trait;
use serde_json::json;

use crate::{ChatMessage, ChatRequest, ChatResponse, LlmError, LlmProvider, Role, ToolCall};

/// Talks to any endpoint implementing the OpenAI Chat Completions +
/// Embeddings wire format (OpenAI itself, Azure OpenAI, vLLM/Ollama in
/// compatibility mode, etc). `base_url`, `chat_model`, and
/// `embedding_model` are read from config so switching models (e.g. to a
/// newer "gpt-5.x" chat model) is a config change, not a code change.
pub struct OpenAiCompatibleProvider {
    client: reqwest::Client,
    base_url: String,
    api_key: String,
    chat_model: String,
    embedding_model: String,
}

impl OpenAiCompatibleProvider {
    pub fn new(base_url: String, api_key: String, chat_model: String, embedding_model: String) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url,
            api_key,
            chat_model,
            embedding_model,
        }
    }

    fn role_str(role: Role) -> &'static str {
        match role {
            Role::System => "system",
            Role::User => "user",
            Role::Assistant => "assistant",
            Role::Tool => "tool",
        }
    }
}

#[async_trait]
impl LlmProvider for OpenAiCompatibleProvider {
    async fn chat(&self, request: ChatRequest) -> Result<ChatResponse, LlmError> {
        let messages: Vec<_> = request
            .messages
            .iter()
            .map(|m| json!({ "role": Self::role_str(m.role), "content": m.content }))
            .collect();

        let tools: Vec<_> = request
            .tools
            .iter()
            .map(|t| {
                json!({
                    "type": "function",
                    "function": {
                        "name": t.name,
                        "description": t.description,
                        "parameters": t.parameters_schema,
                    }
                })
            })
            .collect();

        let mut body = json!({
            "model": self.chat_model,
            "messages": messages,
        });
        // Newer "reasoning" models (o1/o3-style, and some GPT-5.x chat
        // models) reject any `temperature` other than the default (1) and
        // return a 400. Only send it when a caller explicitly opted in;
        // otherwise let the API use its own default so this works across
        // both classic and reasoning-style chat models.
        if let Some(temperature) = request.temperature {
            body["temperature"] = json!(temperature);
        }
        if !tools.is_empty() {
            body["tools"] = json!(tools);
        }

        let resp = self
            .client
            .post(format!("{}/chat/completions", self.base_url))
            .bearer_auth(&self.api_key)
            .json(&body)
            .send()
            .await?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(LlmError::Provider(format!("{status}: {text}")));
        }

        let payload: serde_json::Value = resp.json().await?;
        let choice = payload["choices"].get(0).ok_or_else(|| {
            LlmError::Parse("response contained no choices".to_string())
        })?;

        let content = choice["message"]["content"].as_str().unwrap_or("").to_string();

        let tool_calls = choice["message"]["tool_calls"]
            .as_array()
            .map(|calls| {
                calls
                    .iter()
                    .filter_map(|c| {
                        Some(ToolCall {
                            id: c["id"].as_str()?.to_string(),
                            name: c["function"]["name"].as_str()?.to_string(),
                            arguments: serde_json::from_str(c["function"]["arguments"].as_str()?)
                                .unwrap_or(serde_json::Value::Null),
                        })
                    })
                    .collect()
            })
            .unwrap_or_default();

        let usage_tokens = payload["usage"]["total_tokens"].as_u64().map(|n| n as u32);

        Ok(ChatResponse {
            message: ChatMessage {
                role: Role::Assistant,
                content,
            },
            tool_calls,
            usage_tokens,
        })
    }

    async fn embed(&self, texts: &[String]) -> Result<Vec<Vec<f32>>, LlmError> {
        let body = json!({
            "model": self.embedding_model,
            "input": texts,
        });

        let resp = self
            .client
            .post(format!("{}/embeddings", self.base_url))
            .bearer_auth(&self.api_key)
            .json(&body)
            .send()
            .await?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(LlmError::Provider(format!("{status}: {text}")));
        }

        let payload: serde_json::Value = resp.json().await?;
        let data = payload["data"]
            .as_array()
            .ok_or_else(|| LlmError::Parse("response contained no data".to_string()))?;

        Ok(data
            .iter()
            .filter_map(|d| {
                d["embedding"]
                    .as_array()
                    .map(|arr| arr.iter().filter_map(|v| v.as_f64().map(|f| f as f32)).collect())
            })
            .collect())
    }

    async fn synthesize_speech(&self, text: &str) -> Result<Vec<u8>, LlmError> {
        // "gpt-4o-mini-tts" is OpenAI's expressive, natural-sounding voice
        // model — a clear step up from the classic "tts-1" voices, and
        // the only one of the two that takes `instructions` to steer
        // delivery. "nova" reads as warm rather than clipped/announcer-y,
        // which fits a wellness companion better than a neutral narrator.
        let body = json!({
            "model": "gpt-4o-mini-tts",
            "voice": "nova",
            "input": text,
            "response_format": "mp3",
            "instructions": "Speak warmly and calmly, like a caring friend checking in \
                — unhurried, gentle, natural conversational pacing, not like a news \
                announcer or an automated assistant.",
        });

        let resp = self
            .client
            .post(format!("{}/audio/speech", self.base_url))
            .bearer_auth(&self.api_key)
            .json(&body)
            .send()
            .await?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(LlmError::Provider(format!("{status}: {text}")));
        }

        Ok(resp.bytes().await?.to_vec())
    }
}
