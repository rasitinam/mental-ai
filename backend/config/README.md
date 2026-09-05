# Config

- `default.toml` — committed defaults, safe to read in a private repo (no secrets).
- `local.toml` — optional, git-ignored, for machine-specific overrides. Copy `default.toml` to `local.toml` and edit if you need different values locally.
- Environment variables override both files: prefix `MENTAL_AI`, `__` as the nesting separator, e.g. `MENTAL_AI__SERVER__PORT=9090`.
- The LLM API key is **never** read from these files — set the environment variable named by `llm.api_key_env` (default `MENTAL_AI_LLM_API_KEY`).
