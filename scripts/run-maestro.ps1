# run-maestro.ps1 — direct entry point to run PlaceWell's Maestro tests.
# Location: C:\PlaceWell\Docs\scripts\run-maestro.ps1 (version-controlled in PlaceWellDocs)
# Wraps `npm run maestro` in the sibling PlaceWellApp repo so you don't have to
# type npm commands. Run with no args for an interactive menu, or pass a target.
#
# Usage:
#   .\run-maestro.ps1                  # interactive menu
#   .\run-maestro.ps1 smoke            # run a target directly
#   .\run-maestro.ps1 screenshots
#   .\run-maestro.ps1 -- --print       # forward args to the runner
#
# If PowerShell blocks the script (execution policy), run:
#   powershell -ExecutionPolicy Bypass -File .\run-maestro.ps1

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Rest
)

$ErrorActionPreference = 'Stop'

# Resolve the PlaceWellApp repo (sibling of Docs under C:\PlaceWell).
# Override with $env:PLACEWELL_APP_DIR if your layout differs.
$AppDir = if ($env:PLACEWELL_APP_DIR) {
    $env:PLACEWELL_APP_DIR
} else {
    Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'PlaceWellApp'
}

if (-not (Test-Path (Join-Path $AppDir 'package.json'))) {
    Write-Host "PlaceWellApp not found at: $AppDir" -ForegroundColor Red
    Write-Host "Set `$env:PLACEWELL_APP_DIR to the PlaceWellApp repo path and re-run." -ForegroundColor Yellow
    exit 1
}

function Invoke-Maestro([string[]] $RunnerArgs) {
    Push-Location $AppDir
    try {
        if ($RunnerArgs -and $RunnerArgs.Count -gt 0) {
            & npm run maestro -- @RunnerArgs
        } else {
            & npm run maestro
        }
    } finally {
        Pop-Location
    }
    exit $LASTEXITCODE
}

# Passthrough: if args were given, forward straight to the runner.
if ($Rest -and $Rest.Count -gt 0) {
    if ($Rest[0] -eq '--') { $Rest = $Rest[1..($Rest.Count - 1)] }
    Invoke-Maestro $Rest
}

# No args -> interactive menu.
Write-Host ""
Write-Host "=== PlaceWell Maestro ===" -ForegroundColor Cyan
Write-Host "  [1] Smoke suite        (seed + run)"
Write-Host "  [2] Screenshot flow    (seed + run)"
Write-Host "  [3] Regression suite   (seed + run)"
Write-Host "  [4] Seed fixtures only (no test run)"
Write-Host "  [5] Custom args"
Write-Host "  [Q] Quit"
$choice = Read-Host "Select"

switch ($choice.ToUpper()) {
    '1' { Invoke-Maestro @('smoke') }
    '2' { Invoke-Maestro @('screenshots') }
    '3' { Invoke-Maestro @('regression') }
    '4' {
        Push-Location $AppDir
        try { & npm run maestro:seed } finally { Pop-Location }
        exit $LASTEXITCODE
    }
    '5' {
        $custom = Read-Host "Enter args (e.g. screenshots --no-seed --app builds\app.aab)"
        Invoke-Maestro ($custom -split '\s+')
    }
    'Q' { exit 0 }
    default { Write-Host "Unknown choice." -ForegroundColor Yellow; exit 1 }
}
