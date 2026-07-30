# seed-test-fixtures.ps1 — generate / seed PlaceWell's deterministic test QR fixtures.
# Location: C:\PlaceWell\Docs\scripts\seed-test-fixtures.ps1 (version-controlled in PlaceWellDocs)
#
# Wraps PlaceWellQRService\scripts\seed_test_fixtures.py and passes your PRODUCTION
# HMAC secret, so the generated QR URLs are signed correctly and validate in the
# production app. The Python signer reads PLACEWELL_HMAC_SECRET; this script sets it
# for the child process ONLY — it is never printed and is restored/cleared afterwards.
#
# The fixture label IDs (PWMSP2, PWMST3, PWMGR4, PWMXS5, PWMXT6, PWMBK8, PWMQR7) are
# FIXED and deterministic: SIG = SHA256("<secret>:<id>")[:4]. Same secret + same id =
# same URL every time, so the QR codes are permanent (as long as the secret is unchanged).
#
# The secret is the SAME value your QR-service server runs with (PLACEWELL_HMAC_SECRET) —
# NOT the dev fallback in PlaceWellApp\app.config.js.
#
# Usage:
#   # Print correct signed URLs + write scannable QR PNGs, WITHOUT touching Firestore:
#   .\seed-test-fixtures.ps1 -HmacSecret "<prod-secret>" -DryRun -QrImages -Out qr-review
#
#   # Just print the signed URLs / Maestro env block (no writes, no images):
#   .\seed-test-fixtures.ps1 -HmacSecret "<prod-secret>" -DryRun
#
#   # REAL seed into Firestore (writes docs; needs PlaceWellQRService\serviceAccountKey.json):
#   .\seed-test-fixtures.ps1 -HmacSecret "<prod-secret>"
#
#   # If PLACEWELL_HMAC_SECRET is already set in your shell, you may omit -HmacSecret.
#   # Forward any extra seeder args verbatim after --:
#   .\seed-test-fixtures.ps1 -HmacSecret "<prod-secret>" -DryRun -- --env-out fixtures.env
#
# Requirements: the QR service's Python deps (python-dotenv, qrcode[pil], and — for a
# real seed — firebase-admin). Run inside the QR service venv, or point $env:PYTHON at it.
#
# If PowerShell blocks the script (execution policy), run:
#   powershell -ExecutionPolicy Bypass -File .\seed-test-fixtures.ps1 -HmacSecret "<prod-secret>" -DryRun -QrImages

param(
    # Production PLACEWELL_HMAC_SECRET used to sign the fixture URLs. Optional only if
    # PLACEWELL_HMAC_SECRET is already set in the shell.
    [string] $HmacSecret,

    # --dry-run: print URLs / render images WITHOUT writing to Firestore.
    [switch] $DryRun,

    # --qr-images: render a scannable QR PNG for each fixture.
    [switch] $QrImages,

    # --out <dir>: output directory for QR images (relative to the QR service repo).
    [string] $Out = 'qr-review',

    # --env-out <path>: also write the KEY=VALUE Maestro env block to this file.
    [string] $EnvOut,

    # Any additional args are forwarded verbatim to seed_test_fixtures.py.
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Rest
)

$ErrorActionPreference = 'Stop'

# Resolve the PlaceWellQRService repo (sibling of Docs under C:\PlaceWell).
# Override with $env:PLACEWELL_QR_SERVICE_DIR if your layout differs.
$QrServiceDir = if ($env:PLACEWELL_QR_SERVICE_DIR) {
    $env:PLACEWELL_QR_SERVICE_DIR
} else {
    Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'PlaceWellQRService'
}

$SeedScript = Join-Path $QrServiceDir 'scripts\seed_test_fixtures.py'
if (-not (Test-Path $SeedScript)) {
    Write-Host "Seed script not found: $SeedScript" -ForegroundColor Red
    Write-Host "Set `$env:PLACEWELL_QR_SERVICE_DIR to the PlaceWellQRService repo path and re-run." -ForegroundColor Yellow
    exit 1
}

# Resolve the HMAC secret: -HmacSecret param wins, else an already-set shell env var.
$Secret = if ($HmacSecret) { $HmacSecret } else { $env:PLACEWELL_HMAC_SECRET }
if (-not $Secret) {
    Write-Host "No HMAC secret provided." -ForegroundColor Red
    Write-Host "Pass -HmacSecret '<your production PLACEWELL_HMAC_SECRET>' (the same value the QR service server runs with)." -ForegroundColor Yellow
    Write-Host "Signatures MUST use the production secret, or the QR codes read as invalid in the app." -ForegroundColor Yellow
    exit 1
}

# Resolve the Python interpreter.
$Python = if ($env:PYTHON) { $env:PYTHON } else { 'python' }
if (-not (Get-Command $Python -ErrorAction SilentlyContinue)) {
    Write-Host "Python interpreter '$Python' not found. Install Python or set `$env:PYTHON to its path." -ForegroundColor Red
    exit 1
}

# Build the seeder args. The script path is relative to the QR service dir (we run there).
$PyArgs = @('scripts\seed_test_fixtures.py')
if ($DryRun)   { $PyArgs += '--dry-run' }
if ($QrImages) { $PyArgs += @('--qr-images', '--out', $Out) }
if ($EnvOut)   { $PyArgs += @('--env-out', $EnvOut) }
if ($Rest) {
    if ($Rest[0] -eq '--') { $Rest = $Rest[1..($Rest.Count - 1)] }
    if ($Rest.Count -gt 0) { $PyArgs += $Rest }
}

Write-Host ""
Write-Host "=== Seed PlaceWell test fixtures ===" -ForegroundColor Cyan
Write-Host "  QR service : $QrServiceDir"
Write-Host "  Command    : $Python $($PyArgs -join ' ')"
Write-Host "  HMAC secret: provided ($($Secret.Length) chars; passed to child only, not stored)"
if ($DryRun) {
    Write-Host "  Mode       : dry run - Firestore will NOT be modified." -ForegroundColor Green
} else {
    Write-Host "  Mode       : REAL SEED - this WILL write to Firestore." -ForegroundColor Yellow
}
Write-Host ""

# Set PLACEWELL_HMAC_SECRET for the child process only; restore the previous value
# (or remove it) afterwards so the secret does not linger in the interactive session.
$Prev = $env:PLACEWELL_HMAC_SECRET
$Code = 1
try {
    $env:PLACEWELL_HMAC_SECRET = $Secret
    Push-Location $QrServiceDir
    try {
        & $Python @PyArgs
        $Code = $LASTEXITCODE
    } finally {
        Pop-Location
    }
} finally {
    if ($null -eq $Prev) {
        Remove-Item Env:\PLACEWELL_HMAC_SECRET -ErrorAction SilentlyContinue
    } else {
        $env:PLACEWELL_HMAC_SECRET = $Prev
    }
}

if ($Code -eq 0 -and $QrImages) {
    Write-Host ""
    Write-Host "QR images written to: $(Join-Path $QrServiceDir $Out)" -ForegroundColor Green
}

exit $Code
