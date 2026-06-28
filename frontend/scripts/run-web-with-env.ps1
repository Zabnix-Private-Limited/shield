$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $root
$envPath = Join-Path $repoRoot 'backend\.env'

if (Test-Path $envPath) {
  Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -notmatch '=') {
      return
    }

    $name, $value = $_ -split '=', 2
    if ([string]::IsNullOrWhiteSpace($name)) {
      return
    }

    [Environment]::SetEnvironmentVariable($name.Trim(), $value, 'Process')
  }
}

$dartDefines = @()

foreach ($key in @(
  'APP_ENV',
  'API_BASE_URL',
  'GOOGLE_MAPS_API_KEY',
  'ENABLE_OCR',
  'ENABLE_NOTIFICATIONS',
  'ENABLE_SENTRY',
  'TURNSTILE_SITE_KEY',
  'SENTRY_FLUTTER_DSN',
  'SENTRY_ENVIRONMENT',
  'SENTRY_RELEASE',
  'FIREBASE_WEB_VAPID_KEY'
)) {
  $value = [Environment]::GetEnvironmentVariable($key, 'Process')
  if (-not [string]::IsNullOrWhiteSpace($value)) {
    $dartDefines += "--dart-define=$key=$value"
  }
}

Push-Location $root
try {
  node scripts/generate-web-sentry-config.mjs
  flutter run -d chrome --web-port 53431 @dartDefines
} finally {
  Pop-Location
}
