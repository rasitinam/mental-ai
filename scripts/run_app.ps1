Param(
    [string]$ApiBaseUrl = "http://127.0.0.1:8787",
    [string]$Device = "chrome"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location (Join-Path $repoRoot "app")
flutter pub get
flutter run -d $Device --dart-define="API_BASE_URL=$ApiBaseUrl"
