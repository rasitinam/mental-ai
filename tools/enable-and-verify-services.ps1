# Enables the research-ingest engine, validates SMTP delivery, and restarts
# the existing Windows Scheduled Task without touching the live SQLite DB.
$ErrorActionPreference = "Stop"

$Repo = "C:\Apps\MentalAI-GitSync"
$Live = "C:\Apps\MentalAI"
$TaskName = "MentalAI Backend"

function Import-PersistedEnvironment([string]$Name) {
    if (![string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($Name, "Process"))) {
        return
    }

    $Value = [Environment]::GetEnvironmentVariable($Name, "User")
    if ([string]::IsNullOrWhiteSpace($Value)) {
        $Value = [Environment]::GetEnvironmentVariable($Name, "Machine")
    }

    if (![string]::IsNullOrWhiteSpace($Value)) {
        Set-Item -Path "Env:$Name" -Value $Value
    }
}

Write-Host "=== 1. Sync service scripts from GitHub ===" -ForegroundColor Cyan
if (!(Test-Path "$Repo\.git")) { throw "GitSync clone missing: $Repo" }
$Dirty = git -C $Repo status --porcelain
if ($LASTEXITCODE -ne 0) { throw "Cannot inspect GitSync status." }
if ($Dirty) { throw "GitSync has local changes. Commit or stash them before running this helper." }

git -C $Repo fetch origin
if ($LASTEXITCODE -ne 0) { throw "Git fetch failed." }
git -C $Repo pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw "Git fast-forward failed." }

$Commit = (git -C $Repo rev-parse --short HEAD).Trim()
Write-Host "GitHub commit: $Commit"

Write-Host "`n=== 2. Load service environment (values stay hidden) ===" -ForegroundColor Cyan
$EnvironmentNames = @(
    "MENTAL_AI_LLM_API_KEY",
    "MENTAL_AI_SMTP_USER",
    "MENTAL_AI_SMTP_PASSWORD",
    "MENTAL_AI_SMTP_HOST",
    "MENTAL_AI_SMTP_FROM",
    "MENTAL_AI_SMTP_TEST_TO",
    "MENTAL_AI_APPLE_SHARED_SECRET"
)
foreach ($Name in $EnvironmentNames) { Import-PersistedEnvironment $Name }

if ([string]::IsNullOrWhiteSpace($env:MENTAL_AI_LLM_API_KEY)) {
    throw "MENTAL_AI_LLM_API_KEY is missing for this Windows account. Research embeddings and AI features cannot work without it."
}
if ([string]::IsNullOrWhiteSpace($env:MENTAL_AI_SMTP_USER) -or
    [string]::IsNullOrWhiteSpace($env:MENTAL_AI_SMTP_PASSWORD)) {
    throw "SMTP_USER or SMTP_PASSWORD is missing for this Windows account. Backend will otherwise fall back to log-only mode."
}
if (!(Test-Path "$Live\backend\firebase-service-account.json")) {
    throw "Firebase service-account JSON is missing from the live backend folder."
}

Write-Host "LLM API key: present (hidden)"
Write-Host "SMTP credentials: present (hidden)"
Write-Host "Firebase service account: present (file only; never printed)"

Write-Host "`n=== 3. Send one real SMTP self-test ===" -ForegroundColor Cyan
$SmtpTest = Join-Path $Repo "tools\test_smtp.py"
if (!(Test-Path $SmtpTest)) { throw "SMTP test utility missing: $SmtpTest" }

py -3 $SmtpTest
if ($LASTEXITCODE -ne 0) {
    throw "SMTP test failed. Backend will not be restarted until SMTP credentials/network are fixed."
}

Write-Host "`n=== 4. Activate research ingestion in the live startup script ===" -ForegroundColor Cyan
Copy-Item (Join-Path $Repo "start-mental-ai.ps1") (Join-Path $Live "start-mental-ai.ps1") -Force
New-Item -ItemType Directory -Force -Path "$Live\tools" | Out-Null
Copy-Item $SmtpTest "$Live\tools\test_smtp.py" -Force

$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
$ActionText = ($Task.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join " "
if ($ActionText -notmatch [regex]::Escape("$Live\start-mental-ai.ps1")) {
    throw "Scheduled Task does not point to $Live\start-mental-ai.ps1. No restart was attempted. Current action: $ActionText"
}
$CurrentUser = ([Security.Principal.WindowsIdentity]::GetCurrent().Name -replace '^.*\\', '')
$TaskUser = ([string]$Task.Principal.UserId -replace '^.*\\', '')
if ($TaskUser -and $TaskUser -notmatch "^(SYSTEM|LOCAL SERVICE|NETWORK SERVICE)$" -and
    $CurrentUser -ine $TaskUser) {
    throw "Scheduled Task runs as '$($Task.Principal.UserId)' but this shell is '$([Security.Principal.WindowsIdentity]::GetCurrent().Name)'. Run this helper under the task account so its User-scoped SMTP/LLM secrets can be verified."
}
Write-Host "Task principal: $($Task.Principal.UserId)"
Write-Host "Research ingestion: enabled by startup script"

Write-Host "`n=== 5. Restart backend ===" -ForegroundColor Cyan
$Log = "$Live\logs\backend.log"
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null
$Marker = "SERVICE_ACTIVATION_MARKER $([guid]::NewGuid().ToString())"
"$Marker $(Get-Date -Format o)" | Out-File $Log -Append
if ((Get-ScheduledTask -TaskName $TaskName).State -eq "Running") {
    Stop-ScheduledTask -TaskName $TaskName
}
for ($i = 0; $i -lt 30; $i++) {
    if (!(Get-Process -Name "mental-ai-server" -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Seconds 1
}
if (Get-Process -Name "mental-ai-server" -ErrorAction SilentlyContinue) {
    throw "Backend process did not stop; refusing to start a second copy."
}
Start-ScheduledTask -TaskName $TaskName

$Healthy = $false
for ($i = 0; $i -lt 45; $i++) {
    try {
        $Health = Invoke-RestMethod "http://127.0.0.1:8787/health" -TimeoutSec 4
        $Healthy = $true
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}
if (!$Healthy) { throw "Backend did not become healthy after restart. Inspect $Live\logs\backend.log." }

Write-Host "Backend health: OK" -ForegroundColor Green
Write-Host "Scheduled task: $((Get-ScheduledTask -TaskName $TaskName).State)"

Write-Host "`n=== 6. Wait for first research-ingest cycle ===" -ForegroundColor Cyan
$Log = "$Live\logs\backend.log"
$ResearchLine = $null
for ($i = 0; $i -lt 180; $i++) {
    if (Test-Path $Log) {
        $Lines = @(Get-Content $Log -Tail 10000)
        $MarkerIndex = -1
        for ($j = $Lines.Count - 1; $j -ge 0; $j--) {
            if ($Lines[$j] -like "*$Marker*") { $MarkerIndex = $j; break }
        }
        if ($MarkerIndex -ge 0 -and $MarkerIndex + 1 -lt $Lines.Count) {
            $ResearchLine = $Lines[($MarkerIndex + 1)..($Lines.Count - 1)] |
                Select-String "research ingest cycle complete" |
                Select-Object -Last 1
        }
        if ($ResearchLine) { break }
    }
    Start-Sleep -Seconds 2
}

if (!$ResearchLine) {
    Write-Host "Research cycle has not logged completion within 6 minutes. Backend is healthy; inspect the latest backend log." -ForegroundColor Yellow
} else {
    Write-Host $ResearchLine.Line
    if ($ResearchLine.Line -match 'errors=\[\]') {
        Write-Host "Research ingest cycle: completed without source/embedding errors." -ForegroundColor Green
    } else {
        Write-Host "Research ingest logged errors. Read the line above; the scheduler remains active." -ForegroundColor Yellow
    }
}

Write-Host "`n=== Service activation summary ===" -ForegroundColor Green
Write-Host "Commit: $Commit"
Write-Host "Research ingest: enabled"
Write-Host "SMTP self-test: accepted by SMTP server; check inbox/spam"
Write-Host "Firebase service-account file: present"
Write-Host "Backend health: OK"
Write-Host "Database was not copied, deleted, or modified by this helper."
