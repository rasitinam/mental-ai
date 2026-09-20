# Launches the ngrok tunnel to the local backend detached, with no console
# window - used by the "MentalAI ngrok" scheduled task (see
# docs/RUNNING_BACKGROUND.md) so the TestFlight/Android builds can reach the
# backend after a reboot without anyone opening a terminal. Safe to run
# manually too: if ngrok is already running, it does nothing.
#
# The domain is ngrok's free static domain for this account, so the URL baked
# into the app never changes. ngrok reconnects on its own if the network is
# not up yet at logon.

$ErrorActionPreference = "Stop"

$domain = "status-enticing-easeful.ngrok-free.dev"
$port = 8787

if (Get-Process -Name "ngrok" -ErrorAction SilentlyContinue) {
    exit 0
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$logPath = Join-Path $repoRoot "backend\data\startup.log"

# winget installs a shim under WinGet\Links; a scheduled task's PATH may not
# include it, so look there explicitly before giving up.
$ngrok = (Get-Command ngrok -ErrorAction SilentlyContinue).Source
if (-not $ngrok) {
    $ngrok = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\ngrok.exe"
}
if (-not (Test-Path $ngrok)) {
    "$(Get-Date -Format o)  ngrok.exe not found - not starting the tunnel." | Out-File -FilePath $logPath -Append -Encoding utf8
    exit 1
}

Start-Process -FilePath $ngrok -ArgumentList "http", $port, "--domain=$domain", "--log=stdout" -WindowStyle Hidden -RedirectStandardOutput (Join-Path $repoRoot "backend\data\ngrok.log")
