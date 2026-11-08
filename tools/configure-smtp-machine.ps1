# Configure SMTP for the Mental.AI backend Scheduled Task (currently running as SYSTEM).
# SMTP credentials are stored in Windows Machine environment scope so the SYSTEM task can read them.
$ErrorActionPreference = "Stop"

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
if (!$Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Open PowerShell as Administrator before configuring SMTP for the SYSTEM task."
}

Write-Host "SMTP credentials will be stored in Machine environment scope." -ForegroundColor Yellow
Write-Host "Machine-scoped environment variables may be readable by other processes on this server."
Write-Host "Use a dedicated SMTP account or app password, not your normal mailbox password."
Write-Host ""

$SmtpUser = (Read-Host "SMTP username / email address").Trim()
if ([string]::IsNullOrWhiteSpace($SmtpUser)) { throw "SMTP username cannot be empty." }

$HostInput = (Read-Host "SMTP host [smtp.gmail.com]").Trim()
$SmtpHost = if ([string]::IsNullOrWhiteSpace($HostInput)) { "smtp.gmail.com" } else { $HostInput }

$FromInput = (Read-Host "From address [$SmtpUser]").Trim()
$SmtpFrom = if ([string]::IsNullOrWhiteSpace($FromInput)) { $SmtpUser } else { $FromInput }

$ToInput = (Read-Host "Test recipient [$SmtpUser]").Trim()
$TestTo = if ([string]::IsNullOrWhiteSpace($ToInput)) { $SmtpUser } else { $ToInput }

$SecurePassword = Read-Host "SMTP password / app password" -AsSecureString
if ($SecurePassword.Length -eq 0) { throw "SMTP password cannot be empty." }

$Bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
try {
    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Bstr)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Bstr)
}

try {
    # Test the exact credentials before persisting them.
    $env:MENTAL_AI_SMTP_USER = $SmtpUser
    $env:MENTAL_AI_SMTP_PASSWORD = $PlainPassword
    $env:MENTAL_AI_SMTP_HOST = $SmtpHost
    $env:MENTAL_AI_SMTP_FROM = $SmtpFrom
    $env:MENTAL_AI_SMTP_TEST_TO = $TestTo

    Write-Host ""
    Write-Host "=== SMTP authentication and send test (TLS port 465) ===" -ForegroundColor Cyan
    py -3 "$PSScriptRoot\test_smtp.py"
    if ($LASTEXITCODE -ne 0) {
        throw "SMTP test failed. Credentials were NOT saved to Machine scope. Correct the SMTP settings and run again."
    }

    $Confirm = Read-Host "SMTP server accepted the test message. Save credentials to Machine scope for the SYSTEM task? Type YES"
    if ($Confirm -cne "YES") {
        Write-Host "Credentials were not persisted. The current shell test passed, but the SYSTEM task still cannot use them." -ForegroundColor Yellow
        return
    }

    [Environment]::SetEnvironmentVariable("MENTAL_AI_SMTP_USER", $SmtpUser, "Machine")
    [Environment]::SetEnvironmentVariable("MENTAL_AI_SMTP_PASSWORD", $PlainPassword, "Machine")
    [Environment]::SetEnvironmentVariable("MENTAL_AI_SMTP_HOST", $SmtpHost, "Machine")
    [Environment]::SetEnvironmentVariable("MENTAL_AI_SMTP_FROM", $SmtpFrom, "Machine")

    Write-Host ""
    Write-Host "SMTP credentials saved to Machine scope." -ForegroundColor Green
    Write-Host "The SYSTEM backend task can read them on its next start."
    Write-Host "Check the test recipient's inbox and spam folder; SMTP acceptance alone does not prove final delivery."
} finally {
    $env:MENTAL_AI_SMTP_PASSWORD = $null
    $PlainPassword = $null
    $SecurePassword = $null
}