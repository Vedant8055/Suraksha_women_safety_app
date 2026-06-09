param(
  [string]$EnvFile = ".env"
)

Set-Location "$PSScriptRoot\..\backend"

if (-not (Test-Path $EnvFile)) {
  Write-Error "Environment file not found: $EnvFile"
  exit 1
}

Write-Host "Starting backend with env file: $EnvFile"
npm.cmd run dev
