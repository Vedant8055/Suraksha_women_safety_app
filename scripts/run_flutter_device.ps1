param(
  [Parameter(Mandatory = $true)]
  [string]$PcIpv4,
  [string]$FlavorEnv = "development",
  [int]$Port = 5000
)

Set-Location "$PSScriptRoot\.."

$apiBase = "http://$PcIpv4:$Port/api"
$socketBase = "http://$PcIpv4:$Port"

Write-Host "Running Flutter app with:"
Write-Host "APP_ENV=$FlavorEnv"
Write-Host "API_BASE_URL=$apiBase"
Write-Host "SOCKET_BASE_URL=$socketBase"

flutter run `
  --dart-define=APP_ENV=$FlavorEnv `
  --dart-define=API_BASE_URL=$apiBase `
  --dart-define=SOCKET_BASE_URL=$socketBase
