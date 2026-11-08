# Enables the research-ingest engine, validates SMTP delivery, and restarts
# the existing Windows Scheduled Task without touching the live SQLite DB.
$ErrorActionPreference = "Stop"

$Repo = "C:\Apps\MentalAI-GitSync"
$Live = "C:\Apps\MentalAI"
$TaskName = "MentalAI Backend"
$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
$TaskUser = ([string]$Task.Principal.UserId -replace '^.*\\', '')
$RunsAsSystem = $TaskUser -match "^(SYSTEM|LOCAL SERVICE|NETWORK SERVICE)$"

function Import-PersistedEnvironment([string]$Name) {
    if ($RunsAsSystem) {
        # Ignore inherited administrator values. The backend task only sees Machine scope.
        Remove-Item -Path "Env:$Name" -ErrorAction SilentlyContinue
        $Value = [Environment]::GetEnvironmentVariable($Name, "Machine")
    } else {
        $Value = [Environment]::GetEnvironmentVariable($Name, "Process")
        if ([string]::IsNullOrWhiteSpace($Value)) {
            $Value = [Environment]::GetEnvironmentVariable($Name, "User")
        }
        if ([string]::IsNullOrWhiteSpace($Value)) {
            $Value = [Environment]::GetEnvironmentVariable($Name, "Machine")
        }
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
$InteractiveLlmCandidate = [Environment]::GetEnvironmentVariable("MENTAL_AI_LLM_API_KEY", "User")
if ([string]::IsNullOrWhiteSpace($InteractiveLlmCandidate)) {
    $InteractiveLlmCandidate = [Environment]::GetEnvironmentVariable("MENTAL_AI_LLM_API_KEY", "Process")
}
foreach ($Name in $EnvironmentNames) { Import-PersistedEnvironment $Name }

if ($RunsAsSystem -and [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("MENTAL_AI_LLM_API_KEY", "Machine"))) {
    $LlmCandidate = $InteractiveLlmCandidate
    if (![string]::IsNullOrWhiteSpace($LlmCandidate)) {
        $Answer = Read-Host "LLM API key exists only in this interactive account. Copy it to Machine scope for the SYSTEM backend task? Type YES"
        if ($Answer -ceq "YES") {
            [Environment]::SetEnvironmentVariable("MENTAL_AI_LLM_API_KEY", $LlmCandidate, "Machine")
            Set-Item -Path "Env:MENTAL_AI_LLM_API_KEY" -Value $LlmCandidate
        }
    }
}

if ($RunsAsSystem -and [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("MENTAL_AI_LLM_API_KEY", "Machine"))) {
    throw "MENTAL_AI_LLM_API_KEY is not available at Machine scope. The SYSTEM backend cannot read an administrator's User-scoped key. Copy it to Machine scope when prompted, or set it at Machine scope, then rerun."
}
if ([string]::IsNullOrWhiteSpace($env:MENTAL_AI_LLM_API_KEY)) {
    throw "MENTAL_AI_LLM_API_KEY is missing for this Windows account. Research embeddings and AI features cannot work without it."
}
$SmtpOk = $false
$SmtpFailure = $null
if (!(Test-Path "$Live\backend\firebase-service-account.json")) {
    throw "Firebase service-account JSON is missing from the live backend folder."
}

Write-Host "LLM API key: present for backend task (value hidden)" -ForegroundColor Green
if (![string]::IsNullOrWhiteSpace($env:MENTAL_AI_SMTP_USER) -and ![string]::IsNullOrWhiteSpace($env:MENTAL_AI_SMTP_PASSWORD)) {
    Write-Host "SMTP credentials: present for backend task (values hidden)" -ForegroundColor Green
} else {
    Write-Host "SMTP credentials: MISSING for backend task; email verification cannot send mail." -ForegroundColor Yellow
}
Write-Host "Firebase service account: present (file only; never printed)"

Write-Host "`n=== 3. Send one real SMTP self-test ===" -ForegroundColor Cyan
$SmtpTest = Join-Path $Repo "tools\test_smtp.py"
if (!(Test-Path $SmtpTest)) { throw "SMTP test utility missing: $SmtpTest" }

if ([string]::IsNullOrWhiteSpace($env:MENTAL_AI_SMTP_USER) -or
    [string]::IsNullOrWhiteSpace($env:MENTAL_AI_SMTP_PASSWORD)) {
    $SmtpFailure = "SMTP_USER or SMTP_PASSWORD is missing for this Windows account."
    Write-Host $SmtpFailure -ForegroundColor Yellow
} else {
    py -3 $SmtpTest
    $SmtpOk = ($LASTEXITCODE -eq 0)
    if (!$SmtpOk) {
        $SmtpFailure = "SMTP delivery self-test failed. The research engine will still be activated; check the SMTP error above."
        Write-Host $SmtpFailure -ForegroundColor Yellow
    }
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
if ((Get-ScheduledTask -TaskName $TaskName).State -eq "Running") {
    Stop-ScheduledTask -TaskName $TaskName
}
for ($i = 0; $i -lt 45; $i++) {
    if (!(Get-Process -Name "mental-ai-server" -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Seconds 1
}
if (Get-Process -Name "mental-ai-server" -ErrorAction SilentlyContinue) {
    throw "Backend process did not stop after 45 seconds; refusing to start a second copy."
}
# The backend holds an append handle on backend.log. Only append the marker after it exits.
"$Marker $(Get-Date -Format o)" | Out-File $Log -Append
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

$StartupLines = @(Get-Content $Log -Tail 10000)
$MarkerIndex = -1
for ($j = $StartupLines.Count - 1; $j -ge 0; $j--) {
    if ($StartupLines[$j] -like "*$Marker*") { $MarkerIndex = $j; break }
}
$NewStartupLines = @()
if ($MarkerIndex -ge 0 -and $MarkerIndex + 1 -lt $StartupLines.Count) {
    $NewStartupLines = @($StartupLines[($MarkerIndex + 1)..($StartupLines.Count - 1)])
}

$LlmRuntime = $NewStartupLines | Select-String "Service config: llm_api_key=present" | Select-Object -Last 1
$SmtpRuntime = $NewStartupLines | Select-String "verification emails go out through" | Select-Object -Last 1
$FirebaseRuntime = $NewStartupLines | Select-String "Service config: firebase_service_account=present" | Select-Object -Last 1
if ($LlmRuntime) { Write-Host "LLM environment: loaded by backend task" -ForegroundColor Green }
else { Write-Host "LLM environment: NOT CONFIRMED in backend task log" -ForegroundColor Yellow }
if ($SmtpRuntime) { Write-Host "SMTP runtime: configured ($($SmtpRuntime.Line.Trim()))" -ForegroundColor Green }
else { Write-Host "SMTP runtime: NOT CONFIGURED in backend task; check User/Machine env scope" -ForegroundColor Yellow }
if ($FirebaseRuntime) { Write-Host "Firebase credential file: detected by backend task" -ForegroundColor Green }
else { Write-Host "Firebase credential file: NOT CONFIRMED in backend task log" -ForegroundColor Yellow }

Write-Host "`n=== 6. Wait for first research-ingest cycle ===" -ForegroundColor Cyan
$Log = "$Live\logs\backend.log"
$ResearchLine = $null
for ($i = 0; $i -lt 300; $i++) {
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
    Write-Host "Research cycle has not logged completion within 10 minutes. Backend is healthy; inspect the latest backend log." -ForegroundColor Yellow
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
if ($SmtpOk) {
    Write-Host "SMTP self-test: ACCEPTED by SMTP server; check inbox/spam." -ForegroundColor Green
} else {
    Write-Host "SMTP self-test: NOT VERIFIED - $SmtpFailure" -ForegroundColor Yellow
}
Write-Host "Firebase service-account file: present"
Write-Host "Backend health: OK"
Write-Host "Database was not copied, deleted, or modified by this helper."
