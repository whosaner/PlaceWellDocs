# PlaceWell Deploy Script
# Location: C:\PlaceWell\Docs\scripts\deploy.ps1 (version-controlled in PlaceWellDocs)
# Usage:    C:\PlaceWell\Docs\scripts\deploy.ps1
#           C:\PlaceWell\Docs\scripts\deploy.ps1 -DeployStockImages
#           (uses absolute C:\PlaceWell\... paths, so it runs from any working directory)
# Deploys UI + PDF Generator + QR Service to the Linode server and restarts services.
# Pass -DeployStockImages to run the paired Firebase/Linode stock-artwork deployment
# after the normal server deployment. The default behavior is unchanged.
# Note: does NOT deploy the mobile app (that goes through EAS build/submit).

[CmdletBinding()]
param(
    [switch]$DeployStockImages
)

$ErrorActionPreference = "Stop"
$SERVER = "root@45.56.71.137"

function Invoke-Native {
    param(
        [Parameter(Mandatory)]
        [string]$Description,
        [Parameter(Mandatory)]
        [scriptblock]$Command
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE."
    }
}

Write-Host "=== PlaceWell Deploy ===" -ForegroundColor Cyan

# ── Stage UI + PDF Generator ──────────────────────────────────────────────────
$uiStaging = "$env:TEMP\placewell-ui-staging"
$uiTar = "$env:TEMP\placewell-ui.tar.gz"
Remove-Item $uiStaging -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $uiStaging | Out-Null

Copy-Item -Recurse "C:\PlaceWell\PlaceWellUI\app" "$uiStaging\app"
Copy-Item -Recurse "C:\PlaceWell\PlaceWellUI\data" "$uiStaging\data"
Copy-Item "C:\PlaceWell\PlaceWellUI\requirements.txt" "$uiStaging\requirements.txt"
Copy-Item "C:\PlaceWell\PlaceWellUI\.env.example" "$uiStaging\.env.example"
Copy-Item "C:\PlaceWell\PlaceWellUI\README.md" "$uiStaging\README.md"
Copy-Item -Recurse "C:\PlaceWell\PlaceWellPdfGenerator\placewell_generator" "$uiStaging\placewell_generator"
Copy-Item "C:\PlaceWell\PlaceWellPdfGenerator\requirements.txt" "$uiStaging\pdf_requirements.txt"
Get-ChildItem -Path $uiStaging -Directory -Recurse -Filter "__pycache__" | Remove-Item -Recurse -Force

Remove-Item $uiTar -ErrorAction SilentlyContinue
tar -czf $uiTar -C $uiStaging .
Write-Host "UI packed $(((Get-Item $uiTar).Length / 1KB).ToString('0'))KB" -ForegroundColor Yellow

# ── Stage QR Service ──────────────────────────────────────────────────────────
$qrStaging = "$env:TEMP\placewell-qr-staging"
$qrTar = "$env:TEMP\placewell-qr.tar.gz"
Remove-Item $qrStaging -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $qrStaging | Out-Null

Copy-Item -Recurse "C:\PlaceWell\PlaceWellQRService\app" "$qrStaging\app"
Copy-Item "C:\PlaceWell\PlaceWellQRService\requirements.txt" "$qrStaging\requirements.txt"
Get-ChildItem -Path $qrStaging -Directory -Recurse -Filter "__pycache__" | Remove-Item -Recurse -Force

Remove-Item $qrTar -ErrorAction SilentlyContinue
tar -czf $qrTar -C $qrStaging .
Write-Host "QR packed $(((Get-Item $qrTar).Length / 1KB).ToString('0'))KB" -ForegroundColor Yellow

# ── Upload both ───────────────────────────────────────────────────────────────
Write-Host "Uploading..." -ForegroundColor Yellow
Invoke-Native "UI upload" {
    scp $uiTar "${SERVER}:/tmp/placewell-ui.tar.gz"
}
Invoke-Native "QR Service upload" {
    scp $qrTar "${SERVER}:/tmp/placewell-qr.tar.gz"
}

# ── Extract and restart ──────────────────────────────────────────────────────
Write-Host "Extracting and restarting services..." -ForegroundColor Yellow
$remoteDeploy = @'
set -euo pipefail

find_python() {
    for candidate in "$@"; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

UI_PYTHON="$(find_python \
    /opt/placewell-ui/venv/bin/python \
    /opt/placewell-ui/.venv/bin/python)" || {
    echo "PlaceWellUI virtualenv Python was not found." >&2
    exit 1
}
QR_PYTHON="$(find_python \
    /opt/placewell-service/.venv/bin/python \
    /opt/placewell-service/venv/bin/python)" || {
    echo "PlaceWell QR Service virtualenv Python was not found." >&2
    exit 1
}

echo "[1/5] Verifying and extracting release archives"
tar -tzf /tmp/placewell-ui.tar.gz >/dev/null
tar -tzf /tmp/placewell-qr.tar.gz >/dev/null
if [ -d /opt/placewell-ui/placewell_generator/skus ]; then
    find /opt/placewell-ui/placewell_generator/skus \
        -maxdepth 1 -type f -name '*.json' -delete
fi
tar -xzf /tmp/placewell-ui.tar.gz -C /opt/placewell-ui
tar -xzf /tmp/placewell-qr.tar.gz -C /opt/placewell-service

if ! grep -q '^PLACEWELL_ENV=production$' /opt/placewell-ui/.env \
    || ! grep -q '^SKU_COMPILER_ALLOWED_ORIGINS=https://placewell.app$' \
        /opt/placewell-ui/.env; then
    echo "PlaceWellUI production Origin environment is incomplete." >&2
    exit 1
fi

echo "[2/5] Installing and checking UI/PdfGenerator dependencies"
"$UI_PYTHON" -m pip install \
    --disable-pip-version-check \
    --no-input \
    --quiet \
    -r /opt/placewell-ui/requirements.txt \
    -r /opt/placewell-ui/pdf_requirements.txt
"$UI_PYTHON" -m pip check
install -d -m 700 /opt/placewell-ui/runtime/sku-compiler

echo "[3/5] Installing and checking QR Service dependencies"
"$QR_PYTHON" -m pip install \
    --disable-pip-version-check \
    --no-input \
    --quiet \
    -r /opt/placewell-service/requirements.txt
"$QR_PYTHON" -m pip check

echo "[4/5] Restarting services"
rm -f /tmp/placewell-ui.tar.gz /tmp/placewell-qr.tar.gz
systemctl reset-failed placewell-ui placewell.service || true
systemctl restart placewell-ui placewell.service

echo "[5/5] Waiting for health checks"
for attempt in $(seq 1 30); do
    if systemctl is-active --quiet placewell-ui placewell.service \
        && curl -fs http://127.0.0.1:8080/health \
            >/tmp/placewell-ui-health.json \
        && curl -fs http://127.0.0.1:8000/health \
            >/tmp/placewell-qr-health.json; then
        cat /tmp/placewell-ui-health.json
        echo
        cat /tmp/placewell-qr-health.json
        echo
        rm -f \
            /tmp/placewell-ui-health.json \
            /tmp/placewell-qr-health.json
        exit 0
    fi
    sleep 1
done

echo "Service health checks failed." >&2
systemctl status placewell-ui placewell.service --no-pager -l || true
echo "=== placewell-ui journal ===" >&2
journalctl -u placewell-ui -n 100 --no-pager -o cat || true
echo "=== placewell QR Service journal ===" >&2
journalctl -u placewell.service -n 100 --no-pager -o cat || true
exit 1
'@
$remoteDeploy = $remoteDeploy.Replace("`r`n", "`n")
Invoke-Native "Server extraction and restart" {
    $remoteDeploy | ssh $SERVER "bash -se"
}

# ── Cleanup ───────────────────────────────────────────────────────────────────
Remove-Item $uiTar -ErrorAction SilentlyContinue
Remove-Item $qrTar -ErrorAction SilentlyContinue
Remove-Item $uiStaging -Recurse -ErrorAction SilentlyContinue
Remove-Item $qrStaging -Recurse -ErrorAction SilentlyContinue

if ($DeployStockImages) {
    Write-Host "Deploying stock artwork..." -ForegroundColor Yellow
    & "$PSScriptRoot\deploy_stock_images.ps1" -Server $SERVER
    if (-not $?) {
        throw "Stock artwork deployment failed."
    }
}

Write-Host "=== Deploy Complete ===" -ForegroundColor Green
