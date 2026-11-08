$ErrorActionPreference = "Stop"

$Base = "C:\Apps\MentalAI"
$Backend = "$Base\backend"

Set-Location $Backend

$env:Path = "C:\msys64\ucrt64\bin;$env:USERPROFILE\.cargo\bin;$env:Path"

$env:MENTAL_AI__SERVER__HOST = "127.0.0.1"
$env:MENTAL_AI__SERVER__PORT = "8787"
$env:MENTAL_AI__DATABASE__URL = "sqlite://data/mental_ai.db?mode=rw"
$env:MENTAL_AI__RESEARCH_INGEST__ENABLED = "true"

# Import persisted User/Machine secrets when the scheduled-task process
# did not inherit them. Never write secret values to logs or source control.
$RequiredEnvironment = @(
    "MENTAL_AI_LLM_API_KEY",
    "MENTAL_AI_SMTP_USER",
    "MENTAL_AI_SMTP_PASSWORD",
    "MENTAL_AI_SMTP_HOST",
    "MENTAL_AI_SMTP_FROM",
    "MENTAL_AI_APPLE_SHARED_SECRET"
)

foreach ($Name in $RequiredEnvironment) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($Name, "Process"))) {
        $Value = [Environment]::GetEnvironmentVariable($Name, "User")
        if ([string]::IsNullOrWhiteSpace($Value)) {
            $Value = [Environment]::GetEnvironmentVariable($Name, "Machine")
        }
        if (![string]::IsNullOrWhiteSpace($Value)) {
            Set-Item -Path "Env:$Name" -Value $Value
        }
    }
}

$Log = "$Base\logs\backend.log"
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null

"Starting Mental AI: $(Get-Date)" | Out-File $Log -Append
"Service config: research_ingest=enabled" | Out-File $Log -Append
"Service config: llm_api_key=$(if ($env:MENTAL_AI_LLM_API_KEY) {'present'} else {'MISSING'})" | Out-File $Log -Append
"Service config: smtp_credentials=$(if ($env:MENTAL_AI_SMTP_USER -and $env:MENTAL_AI_SMTP_PASSWORD) {'present'} else {'MISSING - email verification falls back to log-only mode'})" | Out-File $Log -Append
"Service config: firebase_service_account=$(if (Test-Path "$Backend\firebase-service-account.json") {'present'} else {'MISSING - push disabled'})" | Out-File $Log -Append
"Service config: apple_shared_secret=$(if ($env:MENTAL_AI_APPLE_SHARED_SECRET) {'present'} else {'not configured'})" | Out-File $Log -Append

& "$Backend\target\release\mental-ai-server.exe" *>> $Log

"Backend exited with code $LASTEXITCODE at $(Get-Date)" | Out-File $Log -Append

exit $LASTEXITCODE
