$ErrorActionPreference = "Stop"

$sqliteVersion = "3.1.7"
$rootDirectory = Split-Path -Parent $PSScriptRoot
$appDirectory = Join-Path $rootDirectory "apps/cotrafa-app"
$webDirectory = Join-Path $appDirectory "web"
$sqliteUrl = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqliteVersion/sqlite3.wasm"

New-Item -ItemType Directory -Path $webDirectory -Force | Out-Null

Write-Host "Installing SQLite WASM $sqliteVersion..."
Invoke-WebRequest -Uri $sqliteUrl -OutFile (Join-Path $webDirectory "sqlite3.wasm")

Write-Host "Compiling the Drift web worker..."
Push-Location $appDirectory
try {
    & fvm dart compile js -O1 -o web/drift_worker.dart.js web/drift_worker.dart
    if ($LASTEXITCODE -ne 0) { throw "Drift worker compilation failed." }
}
finally {
    Pop-Location
}

Write-Host "Cotrafa web support is ready."
