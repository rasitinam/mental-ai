$ErrorActionPreference = "Stop"

$Base = "C:\Apps\MentalAI"
$Backend = "$Base\backend"

Set-Location $Backend

$env:Path = "C:\msys64\ucrt64\bin;$env:USERPROFILE\.cargo\bin;$env:Path"

$env:MENTAL_AI__SERVER__HOST = "127.0.0.1"
$env:MENTAL_AI__SERVER__PORT = "8787"
$env:MENTAL_AI__DATABASE__URL = "sqlite://data/mental_ai.db?mode=rw"
$env:MENTAL_AI__RESEARCH_INGEST__ENABLED = "false"

$Log = "$Base\logs\backend.log"

"Starting Mental AI: $(Get-Date)" | Out-File $Log -Append

& "$Backend\target\release\mental-ai-server.exe" *>> $Log

"Backend exited with code $LASTEXITCODE at $(Get-Date)" | Out-File $Log -Append

exit $LASTEXITCODE
