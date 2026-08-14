param(
    [double]$Threshold = 60,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$rootDirectory = Split-Path -Parent $PSScriptRoot
Push-Location $rootDirectory

try {
    if (-not $SkipTests) {
        & fvm dart run melos run test:coverage
        if ($LASTEXITCODE -ne 0) { throw "Coverage tests failed." }
    }

    $reports = Get-ChildItem -Path apps, packages -Filter lcov.info -Recurse |
        Where-Object { $_.FullName -match "[\\/]coverage[\\/]lcov\.info$" }

    if ($reports.Count -eq 0) { throw "No LCOV reports were found." }

    $linesFound = 0
    $linesHit = 0
    foreach ($report in $reports) {
        $included = $true
        foreach ($line in Get-Content $report.FullName) {
            if ($line -match '^SF:(.+)$') {
                $included = $Matches[1] -notmatch '\.(g|freezed|config)\.dart$'
            }
            if ($included -and $line -match '^LF:(\d+)$') {
                $linesFound += [int]$Matches[1]
            }
            if ($included -and $line -match '^LH:(\d+)$') {
                $linesHit += [int]$Matches[1]
            }
        }
    }

    if ($linesFound -eq 0) { throw "LCOV reports contain no measurable lines." }

    $coverage = [math]::Round(($linesHit / $linesFound) * 100, 2)
    Write-Host "Workspace line coverage: $coverage% ($linesHit/$linesFound)"
    Write-Host "Required threshold: $Threshold%"

    if ($coverage -lt $Threshold) {
        throw "Coverage is below the required threshold."
    }

    Write-Host "Coverage threshold satisfied."
}
finally {
    Pop-Location
}
