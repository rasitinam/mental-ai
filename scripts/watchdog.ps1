# Keeps the backend and the ngrok tunnel up between logons. Run every few
# minutes by the "MentalAI Watchdog" scheduled task (see
# docs/RUNNING_BACKGROUND.md): the logon tasks only start things once, so a
# crash, an update that killed a process, or a tunnel that dropped would
# otherwise stay down until the next sign-in - and while App Review or real
# users are on the app, that means "the app doesn't work".
#
# Checks the local server, then the public tunnel end to end, and restarts
# only what is actually down. Writes one line to backend\data\watchdog.log
# per restart (nothing when all is well).

$ErrorActionPreference = "SilentlyContinue"

$repoRoot = Split-Path -Parent $PSScriptRoot
$log = Join-Path $repoRoot "backend\data\watchdog.log"
$publicHealth = "https://status-enticing-easeful.ngrok-free.dev/health"

function Write-Log($message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $message" | Out-File $log -Append -Encoding utf8
}

function Test-Url($url) {
    try {
        $r = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 15 -Headers @{ 'ngrok-skip-browser-warning' = '1' }
        return $r.StatusCode -eq 200
    } catch {
        return $false
    }
}

if (-not (Test-Url "http://127.0.0.1:8787/health")) {
    Write-Log "backend down - restarting"
    Get-Process -Name "mental-ai-server" | Stop-Process -Force
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "start-backend-background.ps1")
    Start-Sleep -Seconds 10
}

if (-not (Test-Url $publicHealth)) {
    Write-Log "tunnel down - restarting ngrok"
    Get-Process -Name "ngrok" | Stop-Process -Force
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "start-ngrok-background.ps1")
}
