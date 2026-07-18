# run-tests.ps1 — run PlaceWell unit tests across projects.
# Location: C:\PlaceWell\Docs\scripts\run-tests.ps1 (version-controlled in PlaceWellDocs)
# Runs the app (Jest) and Python (pytest) unit suites and prints a per-project summary.
#
# Usage:
#   .\run-tests.ps1              # all projects
#   .\run-tests.ps1 app          # PlaceWellApp (Jest) only
#   .\run-tests.ps1 qrservice    # PlaceWellQRService (pytest) only
#   .\run-tests.ps1 pdf          # PlaceWellPdfGenerator (pytest, if it has tests)
#   .\run-tests.ps1 ui           # PlaceWellUI (pytest, if it has tests)
#
# If PowerShell blocks the script (execution policy), run:
#   powershell -ExecutionPolicy Bypass -File .\run-tests.ps1

param(
    [ValidateSet('all', 'app', 'qrservice', 'pdf', 'ui')]
    [string] $Project = 'all'
)

$ErrorActionPreference = 'Stop'

# Repo workspace root (Docs\scripts -> Docs -> C:\PlaceWell).
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string] $name, [string] $status, [string] $note) {
    $results.Add([pscustomobject]@{ Project = $name; Status = $status; Note = $note })
}

# ── PlaceWellApp: Jest ────────────────────────────────────────────────────────
function Invoke-JestSuite([string] $dir, [string] $name) {
    $path = Join-Path $root $dir
    if (-not (Test-Path (Join-Path $path 'package.json'))) { Add-Result $name 'SKIP' 'no package.json'; return }
    if (-not (Test-Path (Join-Path $path 'node_modules'))) {
        Add-Result $name 'SKIP' 'node_modules missing (run: npm install --legacy-peer-deps)'
        return
    }
    Write-Host "`n--- $name (Jest) ---" -ForegroundColor Cyan
    Push-Location $path
    try { & npx jest --no-coverage; $code = $LASTEXITCODE } finally { Pop-Location }
    Add-Result $name ($(if ($code -eq 0) { 'PASS' } else { 'FAIL' })) "exit $code"
}

# ── Python projects: pytest ───────────────────────────────────────────────────
function Get-PythonExe([string] $path) {
    $venv = Join-Path $path '.venv\Scripts\python.exe'
    if (Test-Path $venv) { return $venv }
    return 'python'
}

function Invoke-PytestSuite([string] $dir, [string] $name) {
    $path = Join-Path $root $dir
    $testsDir = Join-Path $path 'tests'
    $hasTests = (Test-Path $testsDir) -and
        (Get-ChildItem $testsDir -Filter 'test_*.py' -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $hasTests) { Add-Result $name 'SKIP' 'no test_*.py found'; return }
    $py = Get-PythonExe $path
    Write-Host "`n--- $name (pytest) ---" -ForegroundColor Cyan
    Push-Location $path
    try { & $py -m pytest -q; $code = $LASTEXITCODE } finally { Pop-Location }
    Add-Result $name ($(if ($code -eq 0) { 'PASS' } else { 'FAIL' })) "exit $code"
}

if ($Project -in 'all', 'app') { Invoke-JestSuite 'PlaceWellApp' 'PlaceWellApp' }
if ($Project -in 'all', 'qrservice') { Invoke-PytestSuite 'PlaceWellQRService' 'PlaceWellQRService' }
if ($Project -in 'all', 'pdf') { Invoke-PytestSuite 'PlaceWellPdfGenerator' 'PlaceWellPdfGenerator' }
if ($Project -in 'all', 'ui') { Invoke-PytestSuite 'PlaceWellUI' 'PlaceWellUI' }

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
($results | Format-Table -AutoSize | Out-String).Trim() | Write-Host

$failed = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
if ($failed -gt 0) {
    Write-Host "`n$failed project(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host "`nAll test suites passed (or were skipped)." -ForegroundColor Green
exit 0
