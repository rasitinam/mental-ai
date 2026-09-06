# Stops the backend if it's running in the background (started by the
# "MentalAI Backend" scheduled task or start-backend-background.ps1).
# Use this before rebuilding the server — Windows keeps a running exe's
# file locked, so `cargo build`/`cargo run` fails until it's stopped.

Get-Process -Name "mental-ai-server" -ErrorAction SilentlyContinue | Stop-Process -Force
