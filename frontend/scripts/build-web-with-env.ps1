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
  'ENABLE_OCR',
  'ENABLE_NOTIFICATIONS',
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
  flutter build web --source-maps @dartDefines
  node scripts/upload-web-sourcemaps.mjs
} finally {
  Pop-Location
}
