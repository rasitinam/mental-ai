use serde::{Deserialize, Serialize};
use serde_json::Value;

/// A locally-implemented function exposed to the model, MCP-style: a
/// name, a human description, and a JSON Schema for its arguments. The
/// registry that executes calls (see `analysis-engine::tool_registry`)
/// is kept separate from this crate so `llm-connector` never depends on
/// domain logic.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tool {
    pub name: String,
    pub description: String,
    pub parameters_schema: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCall {
    pub id: String,
    pub name: String,
    pub arguments: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolResult {
    pub call_id: String,
    pub output: Value,
}
