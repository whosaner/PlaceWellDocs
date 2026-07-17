# PlaceWell Deploy Script
# Location: C:\PlaceWell\Docs\scripts\deploy.ps1 (version-controlled in PlaceWellDocs)
# Usage:    C:\PlaceWell\Docs\scripts\deploy.ps1
#           (uses absolute C:\PlaceWell\... paths, so it runs from any working directory)
# Deploys UI + PDF Generator + QR Service to the Linode server and restarts services.
# Note: does NOT deploy the mobile app (that goes through EAS build/submit).

$SERVER = "root@45.56.71.137"

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
scp $uiTar "${SERVER}:/tmp/placewell-ui.tar.gz"
scp $qrTar "${SERVER}:/tmp/placewell-qr.tar.gz"

# ── Extract and restart ──────────────────────────────────────────────────────
Write-Host "Extracting and restarting services..." -ForegroundColor Yellow
ssh $SERVER "tar -xzf /tmp/placewell-ui.tar.gz -C /opt/placewell-ui && tar -xzf /tmp/placewell-qr.tar.gz -C /opt/placewell-service && rm -f /tmp/placewell-ui.tar.gz /tmp/placewell-qr.tar.gz && systemctl restart placewell-ui placewell.service && echo '--- placewell-ui ---' && systemctl status placewell-ui --no-pager && echo '--- placewell.service ---' && systemctl status placewell.service --no-pager"

# ── Cleanup ───────────────────────────────────────────────────────────────────
Remove-Item $uiTar -ErrorAction SilentlyContinue
Remove-Item $qrTar -ErrorAction SilentlyContinue
Remove-Item $uiStaging -Recurse -ErrorAction SilentlyContinue
Remove-Item $qrStaging -Recurse -ErrorAction SilentlyContinue

Write-Host "=== Deploy Complete ===" -ForegroundColor Green
