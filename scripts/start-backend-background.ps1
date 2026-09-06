# Launches the release backend detached, with no console window - used
# by the "MentalAI Backend" scheduled task (see docs/RUNNING_BACKGROUND.md)
# so the research/insight pipeline keeps working across logins without
# anyone having to open a terminal. Safe to run manually too: if the
# backend is already running, it does nothing.

$ErrorActionPreference = "Stop"

$alreadyRunning = Get-Process -Name "mental-ai-server" -ErrorAction SilentlyContinue
if ($alreadyRunning) {
    exit 0
}

if (-not $env:MENTAL_AI_LLM_API_KEY) {
    # Nothing to log this to (no console) - write to the same place the
    # server itself would, so `Get-Content backend\data\startup.log` still
    # explains a silent failure.
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $logPath = Join-Path $repoRoot "backend\data\startup.log"
    "$(Get-Date -Format o)  MENTAL_AI_LLM_API_KEY not set - not starting." | Out-File -FilePath $logPath -Append -Encoding utf8
    exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot "backend"
$exePath = Join-Path $backendDir "target\release\mental-ai-server.exe"

Start-Process -FilePath $exePath -WorkingDirectory $backendDir -WindowStyle Hidden
