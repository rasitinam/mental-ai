Param(
    [string]$ApiKey = $env:MENTAL_AI_LLM_API_KEY
)

if (-not $ApiKey) {
    Write-Error "Set MENTAL_AI_LLM_API_KEY (env var or -ApiKey) before running the backend."
    exit 1
}

$env:MENTAL_AI_LLM_API_KEY = $ApiKey
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $repoRoot "backend")
cargo run -p mental-ai-server
