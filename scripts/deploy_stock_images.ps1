[CmdletBinding()]
param(
    [string]$Server = $(if ($env:PLACEWELL_DEPLOY_SERVER) {
        $env:PLACEWELL_DEPLOY_SERVER
    } else {
        'root@45.56.71.137'
    }),

    [string]$FirebaseProject = $(if ($env:PLACEWELL_FIREBASE_PROJECT) {
        $env:PLACEWELL_FIREBASE_PROJECT
    } else {
        'placewell-prod-60ef3'
    }),

    [string]$StockMastersRoot = $(if ($env:PLACEWELL_STOCK_MASTERS) {
        $env:PLACEWELL_STOCK_MASTERS
    } else {
        'C:\PlaceWell\PlaceWell-StockImageMasters'
    }),

    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$remoteRoot = '/opt/placewell-stock'
$releaseIdPattern = '^[0-9a-f]{64}$'
$immutableFilePattern = '\.([0-9a-f]{64})\.webp$'

if ($Server -notmatch '^[A-Za-z0-9_.@:\[\]-]+$') {
    throw "SSH target '$Server' contains unsupported characters."
}
if ($FirebaseProject -notmatch '^[a-z0-9-]+$') {
    throw "Firebase project '$FirebaseProject' is not a valid project ID."
}

function Invoke-Native {
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [scriptblock]$Command
    )

    Write-Host "`n==> $Description" -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & $Command
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$Description failed with exit code $exitCode."
    }
}

function Assert-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found on PATH."
    }
}

function Get-LowercaseFileSha256 {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Assert-ExactFileBytes {
    param(
        [Parameter(Mandatory)]
        [string]$ExpectedPath,

        [Parameter(Mandatory)]
        [string]$ActualPath,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $expected = [System.IO.File]::ReadAllBytes($ExpectedPath)
    $actual = [System.IO.File]::ReadAllBytes($ActualPath)
    if ($expected.Length -ne $actual.Length) {
        throw "$Description byte count mismatch: expected $($expected.Length), got $($actual.Length)."
    }

    for ($index = 0; $index -lt $expected.Length; $index++) {
        if ($expected[$index] -ne $actual[$index]) {
            throw "$Description differs at byte offset $index."
        }
    }
}

function Get-StockReleaseFacts {
    param(
        [Parameter(Mandatory)]
        [string]$PackageRoot
    )

    $manifestPath = Join-Path $PackageRoot 'manifest.v1.json'
    $manifestDigestPath = Join-Path $PackageRoot 'manifest.v1.json.sha256'
    $catalogDigestPath = Join-Path $PackageRoot 'catalog.v1.digest.json'
    $imageRoot = Join-Path $PackageRoot 'img'

    foreach ($requiredPath in @(
        $manifestPath,
        $manifestDigestPath,
        $catalogDigestPath,
        $imageRoot
    )) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "Prepared stock release is missing '$requiredPath'."
        }
    }

    $manifestBytes = [System.IO.File]::ReadAllBytes($manifestPath)
    $manifestDigest = Get-LowercaseFileSha256 -Path $manifestPath
    if ($manifestDigest -notmatch $releaseIdPattern) {
        throw "Manifest SHA-256 '$manifestDigest' is not a lowercase 64-character digest."
    }

    $expectedDigestFile = "$manifestDigest  manifest.v1.json`n"
    $actualDigestFile = [System.IO.File]::ReadAllText(
        $manifestDigestPath,
        [System.Text.Encoding]::ASCII
    )
    if ($actualDigestFile -cne $expectedDigestFile) {
        throw 'manifest.v1.json.sha256 does not exactly describe the prepared manifest bytes.'
    }

    $manifest = [System.Text.Encoding]::UTF8.GetString($manifestBytes) |
        ConvertFrom-Json
    $catalogDigest = Get-Content -LiteralPath $catalogDigestPath -Raw |
        ConvertFrom-Json

    $revision = [int64]$manifest.manifestRevision
    if ($revision -lt 1) {
        throw "Invalid manifestRevision '$revision'."
    }
    if ([string]$manifest.baseUrl -notmatch '^https://.+/stock-images/img/$') {
        throw "Manifest baseUrl '$($manifest.baseUrl)' is not the Firebase stock-image URL."
    }

    if ([string]$catalogDigest.manifest.sha256 -cne $manifestDigest) {
        throw 'catalog.v1.digest.json manifest SHA-256 does not match the manifest.'
    }
    if ([int64]$catalogDigest.manifest.bytes -ne $manifestBytes.Length) {
        throw 'catalog.v1.digest.json manifest byte count does not match the manifest.'
    }

    $entryProperties = @($manifest.images.PSObject.Properties)
    if ($entryProperties.Count -ne [int64]$manifest.catalog.entryCount) {
        throw 'Manifest entryCount does not match its image map.'
    }

    $manifestObjects = @()
    $manifestObjectNames = @{}
    $currentImageBytes = [int64]0
    foreach ($property in $entryProperties) {
        $entry = $property.Value
        $fileName = [string]$entry.file
        if ($manifestObjectNames.ContainsKey($fileName)) {
            throw "Manifest contains duplicate object filename '$fileName'."
        }
        $manifestObjectNames[$fileName] = $true

        $imagePath = Join-Path $imageRoot $fileName
        if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
            throw "Manifest object '$fileName' is missing."
        }

        $expectedSha = [string]$entry.sha256
        $expectedBytes = [int64]$entry.bytes
        if ($expectedSha -notmatch $releaseIdPattern) {
            throw "Manifest object '$fileName' has invalid SHA-256 '$expectedSha'."
        }
        if ([string]$entry.assetId -cne $expectedSha) {
            throw "Manifest object '$fileName' assetId does not match its SHA-256."
        }
        $actualFile = Get-Item -LiteralPath $imagePath
        $actualSha = Get-LowercaseFileSha256 -Path $imagePath
        if ($actualFile.Length -ne $expectedBytes) {
            throw "Manifest object '$fileName' has size $($actualFile.Length), expected $expectedBytes."
        }
        if ($actualSha -cne $expectedSha) {
            throw "Manifest object '$fileName' has SHA-256 $actualSha, expected $expectedSha."
        }
        if ($fileName -cnotmatch "\.$([regex]::Escape($expectedSha))\.webp$") {
            throw "Manifest object '$fileName' does not embed its SHA-256."
        }
        if ([string]$entry.contentType -cne 'image/webp') {
            throw "Manifest object '$fileName' has unexpected contentType '$($entry.contentType)'."
        }

        $currentImageBytes += $expectedBytes
        $manifestObjects += [pscustomobject]@{
            FileName = $fileName
            Sha256 = $expectedSha
            Bytes = $expectedBytes
        }
    }

    if ($currentImageBytes -ne [int64]$manifest.catalog.imageBytes) {
        throw 'Manifest catalog imageBytes does not match its entries.'
    }

    $deploymentObjects = @()
    $deploymentImageBytes = [int64]0
    $imageItems = @(Get-ChildItem -LiteralPath $imageRoot -Force)
    foreach ($item in $imageItems) {
        if (-not $item.PSIsContainer -and $item.Extension -ceq '.webp') {
            $match = [regex]::Match($item.Name, $immutableFilePattern)
            if (-not $match.Success) {
                throw "Deployment object '$($item.Name)' is not content-hash named."
            }

            $actualSha = Get-LowercaseFileSha256 -Path $item.FullName
            $filenameSha = $match.Groups[1].Value
            if ($actualSha -cne $filenameSha) {
                throw "Deployment object '$($item.Name)' does not match its filename SHA-256."
            }

            $header = [System.IO.File]::ReadAllBytes($item.FullName)
            if (
                $header.Length -lt 12 -or
                [System.Text.Encoding]::ASCII.GetString($header, 0, 4) -cne 'RIFF' -or
                [System.Text.Encoding]::ASCII.GetString($header, 8, 4) -cne 'WEBP'
            ) {
                throw "Deployment object '$($item.Name)' does not have a WebP signature."
            }

            $deploymentImageBytes += [int64]$item.Length
            $deploymentObjects += [pscustomobject]@{
                FileName = $item.Name
                Sha256 = $actualSha
                Bytes = [int64]$item.Length
            }
        } else {
            throw "Unexpected item '$($item.Name)' exists in the deployment image directory."
        }
    }

    if ($deploymentObjects.Count -ne [int64]$catalogDigest.images.deploymentObjects.count) {
        throw 'Deployment WebP count does not match catalog.v1.digest.json.'
    }
    if ($deploymentImageBytes -ne [int64]$catalogDigest.images.deploymentObjects.bytes) {
        throw 'Deployment WebP bytes do not match catalog.v1.digest.json.'
    }
    if ($entryProperties.Count -ne [int64]$catalogDigest.images.currentCatalog.count) {
        throw 'Current manifest object count does not match catalog.v1.digest.json.'
    }
    if ($currentImageBytes -ne [int64]$catalogDigest.images.currentCatalog.bytes) {
        throw 'Current manifest object bytes do not match catalog.v1.digest.json.'
    }
    if (
        [int64]$catalogDigest.completeCatalogBytes -ne
        $manifestBytes.Length + $currentImageBytes
    ) {
        throw 'completeCatalogBytes does not match the manifest and current images.'
    }
    if (
        [int64]$catalogDigest.completeDeploymentBytes -ne
        $manifestBytes.Length + $deploymentImageBytes
    ) {
        throw 'completeDeploymentBytes does not match the manifest and deployment images.'
    }

    foreach ($manifestObject in $manifestObjects) {
        if (-not ($deploymentObjects.FileName -ccontains $manifestObject.FileName)) {
            throw "Current manifest object '$($manifestObject.FileName)' is absent from the deployment set."
        }
    }

    $retainedObjects = @(
        $deploymentObjects |
        Where-Object { -not $manifestObjectNames.ContainsKey($_.FileName) }
    )
    $retainedBytes = [int64]0
    foreach ($retainedObject in $retainedObjects) {
        $retainedBytes += [int64]$retainedObject.Bytes
    }
    if ($retainedObjects.Count -ne [int64]$catalogDigest.images.deploymentObjects.retainedOnlyCount) {
        throw 'Retained-only object count does not match catalog.v1.digest.json.'
    }
    if ($retainedBytes -ne [int64]$catalogDigest.images.deploymentObjects.retainedOnlyBytes) {
        throw 'Retained-only object bytes do not match catalog.v1.digest.json.'
    }

    return [pscustomobject]@{
        ReleaseId = $manifestDigest
        ManifestDigest = $manifestDigest
        ManifestRevision = $revision
        ManifestBytes = [int64]$manifestBytes.Length
        ManifestEntryCount = [int64]$entryProperties.Count
        CurrentImageBytes = $currentImageBytes
        DeploymentObjectCount = [int64]$deploymentObjects.Count
        DeploymentImageBytes = $deploymentImageBytes
        BaseUrl = [string]$manifest.baseUrl
        ManifestObjects = $manifestObjects
        DeploymentObjects = $deploymentObjects
    }
}

function Assert-FirebaseReleaseConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ManifestDigest
    )

    $config = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ([string]$config.hosting.public -cne 'hosting') {
        throw "Firebase Hosting public directory is '$($config.hosting.public)', expected 'hosting'."
    }

    $manifestRule = @(
        $config.hosting.headers |
        Where-Object { $_.source -ceq '/stock-images/manifest.v1.json' }
    )
    if ($manifestRule.Count -ne 1) {
        throw 'firebase.json must contain exactly one manifest header rule.'
    }

    $digestHeader = @(
        $manifestRule[0].headers |
        Where-Object { $_.key -ceq 'X-Content-SHA256' }
    )
    if (
        $digestHeader.Count -ne 1 -or
        [string]$digestHeader[0].value -cne $ManifestDigest
    ) {
        throw 'firebase.json X-Content-SHA256 does not match the prepared manifest.'
    }
}

function ConvertTo-Base64Utf8 {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Value))
}

function Get-RemoteVerifierInvocation {
    param(
        [Parameter(Mandatory)]
        [string]$ReleasePath,

        [Parameter(Mandatory)]
        [pscustomobject]$Facts,

        [Parameter(Mandatory)]
        [string]$VerifierBase64
    )

    return "python3 -c `"import base64;exec(compile(base64.b64decode('$VerifierBase64'),'<stock-release-verifier>','exec'))`" '$ReleasePath' '$($Facts.ManifestDigest)' '$($Facts.ManifestRevision)' '$($Facts.ManifestBytes)' '$($Facts.DeploymentObjectCount)' '$($Facts.DeploymentImageBytes)'"
}

function Invoke-Remote {
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$Command
    )

    $script = ($Command -replace "`r`n", "`n") -replace "`r", "`n"

    Invoke-Native $Description {
        $previousOutputEncoding = $OutputEncoding
        $OutputEncoding = New-Object System.Text.UTF8Encoding($false)
        try {
            $script | & ssh -T $Server 'bash -s'
        } finally {
            $OutputEncoding = $previousOutputEncoding
        }
    }
}

function Get-LastHttpHeaderValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $pattern = "^(?i:$([regex]::Escape($Name))):\s*(.+?)\s*$"
    $values = @(
        Get-Content -LiteralPath $Path |
        ForEach-Object {
            if ($_ -match $pattern) {
                $Matches[1]
            }
        }
    )
    if ($values.Count -eq 0) {
        return $null
    }
    return [string]$values[-1]
}

function Invoke-CurlDownload {
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [string]$HeaderPath
    )

    Invoke-Native $Description {
        $arguments = @(
            '--fail',
            '--silent',
            '--show-error',
            '--location',
            '--retry',
            '3',
            '--output',
            $OutputPath
        )
        if ($HeaderPath) {
            $arguments += @('--dump-header', $HeaderPath)
        }
        $arguments += $Url
        & curl.exe @arguments
    }
}

function Get-FirebasePreviewUrl {
    param(
        [Parameter(Mandatory)]
        [object]$Value
    )

    if ($Value -is [string]) {
        if ($Value -match '^https://[A-Za-z0-9.-]+\.web\.app/?$') {
            return $Value.TrimEnd('/')
        }
        return $null
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($entry in $Value.GetEnumerator()) {
            $url = Get-FirebasePreviewUrl -Value $entry.Value
            if ($url) {
                return $url
            }
        }
        return $null
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        foreach ($item in $Value) {
            $url = Get-FirebasePreviewUrl -Value $item
            if ($url) {
                return $url
            }
        }
        return $null
    }

    foreach ($property in $Value.PSObject.Properties) {
        $url = Get-FirebasePreviewUrl -Value $property.Value
        if ($url) {
            return $url
        }
    }
    return $null
}

function Test-FirebaseRelease {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Facts,

        [Parameter(Mandatory)]
        [string]$PackageRoot,

        [Parameter(Mandatory)]
        [string]$VerificationRoot,

        [Parameter(Mandatory)]
        [string]$CacheBust,

        [Parameter(Mandatory)]
        [string]$HostingOrigin
    )

    New-Item -ItemType Directory -Path $VerificationRoot -Force | Out-Null

    $firebaseRoot = "$($HostingOrigin.TrimEnd('/'))/stock-images/"
    $manifestUrl = "${firebaseRoot}manifest.v1.json?release=$CacheBust"
    $manifestDownload = Join-Path $VerificationRoot 'manifest.v1.json'
    $manifestHeaders = Join-Path $VerificationRoot 'manifest.headers.txt'
    Invoke-CurlDownload `
        -Description 'Downloading the live Firebase manifest' `
        -Url $manifestUrl `
        -OutputPath $manifestDownload `
        -HeaderPath $manifestHeaders

    $liveDigest = Get-LowercaseFileSha256 -Path $manifestDownload
    if ($liveDigest -cne $Facts.ManifestDigest) {
        throw "Firebase manifest SHA-256 is $liveDigest, expected $($Facts.ManifestDigest)."
    }
    Assert-ExactFileBytes `
        -ExpectedPath (Join-Path $PackageRoot 'manifest.v1.json') `
        -ActualPath $manifestDownload `
        -Description 'Firebase manifest'

    $liveManifest = Get-Content -LiteralPath $manifestDownload -Raw |
        ConvertFrom-Json
    if ([int64]$liveManifest.manifestRevision -ne $Facts.ManifestRevision) {
        throw "Firebase manifestRevision is $($liveManifest.manifestRevision), expected $($Facts.ManifestRevision)."
    }

    $manifestContentType = Get-LastHttpHeaderValue `
        -Path $manifestHeaders `
        -Name 'Content-Type'
    if (-not $manifestContentType -or $manifestContentType -notmatch '^application/json(?:;|$)') {
        throw "Firebase manifest Content-Type is '$manifestContentType', expected application/json."
    }
    $manifestCacheControl = Get-LastHttpHeaderValue `
        -Path $manifestHeaders `
        -Name 'Cache-Control'
    if (
        -not $manifestCacheControl -or
        $manifestCacheControl -notmatch 'max-age=300' -or
        $manifestCacheControl -notmatch 'must-revalidate'
    ) {
        throw "Firebase manifest Cache-Control is '$manifestCacheControl'."
    }
    $manifestHeaderDigest = Get-LastHttpHeaderValue `
        -Path $manifestHeaders `
        -Name 'X-Content-SHA256'
    if ($manifestHeaderDigest -cne $Facts.ManifestDigest) {
        throw "Firebase X-Content-SHA256 is '$manifestHeaderDigest', expected $($Facts.ManifestDigest)."
    }

    foreach ($metadataFile in @(
        'manifest.v1.json.sha256',
        'catalog.v1.digest.json'
    )) {
        $downloadPath = Join-Path $VerificationRoot $metadataFile
        Invoke-CurlDownload `
            -Description "Downloading live Firebase $metadataFile" `
            -Url "${firebaseRoot}${metadataFile}?release=$CacheBust" `
            -OutputPath $downloadPath
        Assert-ExactFileBytes `
            -ExpectedPath (Join-Path $PackageRoot $metadataFile) `
            -ActualPath $downloadPath `
            -Description "Firebase $metadataFile"
    }

    $objectRoot = Join-Path $VerificationRoot 'img'
    New-Item -ItemType Directory -Path $objectRoot -Force | Out-Null
    $objectHeaders = Join-Path $VerificationRoot 'object.headers.txt'
    $objectNumber = 0
    foreach ($object in $Facts.DeploymentObjects) {
        $objectNumber++
        $downloadPath = Join-Path $objectRoot $object.FileName
        $objectUrl = "${firebaseRoot}img/$($object.FileName)"
        Invoke-CurlDownload `
            -Description "Verifying Firebase WebP $objectNumber/$($Facts.DeploymentObjectCount)" `
            -Url $objectUrl `
            -OutputPath $downloadPath `
            -HeaderPath $objectHeaders

        $download = Get-Item -LiteralPath $downloadPath
        if ($download.Length -ne $object.Bytes) {
            throw "Firebase object '$($object.FileName)' has size $($download.Length), expected $($object.Bytes)."
        }
        $downloadSha = Get-LowercaseFileSha256 -Path $downloadPath
        if ($downloadSha -cne $object.Sha256) {
            throw "Firebase object '$($object.FileName)' has SHA-256 $downloadSha, expected $($object.Sha256)."
        }

        $contentType = Get-LastHttpHeaderValue -Path $objectHeaders -Name 'Content-Type'
        if (-not $contentType -or $contentType -notmatch '^image/webp(?:;|$)') {
            throw "Firebase object '$($object.FileName)' Content-Type is '$contentType'."
        }
        $cacheControl = Get-LastHttpHeaderValue -Path $objectHeaders -Name 'Cache-Control'
        if (
            -not $cacheControl -or
            $cacheControl -notmatch 'max-age=31536000' -or
            $cacheControl -notmatch 'immutable'
        ) {
            throw "Firebase object '$($object.FileName)' Cache-Control is '$cacheControl'."
        }
    }
}

$remoteVerifier = @'
import hashlib
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
expected_digest = sys.argv[2]
expected_revision = int(sys.argv[3])
expected_manifest_bytes = int(sys.argv[4])
expected_object_count = int(sys.argv[5])
expected_object_bytes = int(sys.argv[6])

manifest_path = root / "manifest.v1.json"
digest_path = root / "manifest.v1.json.sha256"
catalog_path = root / "catalog.v1.digest.json"
image_root = root / "img"

manifest_bytes = manifest_path.read_bytes()
manifest_digest = hashlib.sha256(manifest_bytes).hexdigest()
if manifest_digest != expected_digest:
    raise SystemExit(f"manifest digest {manifest_digest} != {expected_digest}")
if len(manifest_bytes) != expected_manifest_bytes:
    raise SystemExit("manifest byte count mismatch")
if digest_path.read_text(encoding="ascii") != f"{expected_digest}  manifest.v1.json\n":
    raise SystemExit("manifest digest artifact mismatch")

manifest = json.loads(manifest_bytes.decode("utf-8"))
if manifest.get("manifestRevision") != expected_revision:
    raise SystemExit("manifest revision mismatch")

catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
if catalog["manifest"]["sha256"] != expected_digest:
    raise SystemExit("catalog manifest digest mismatch")
if catalog["manifest"]["bytes"] != expected_manifest_bytes:
    raise SystemExit("catalog manifest byte count mismatch")

objects = sorted(image_root.iterdir())
if any(not path.is_file() or path.suffix != ".webp" for path in objects):
    raise SystemExit("unexpected item in release img directory")
if len(objects) != expected_object_count:
    raise SystemExit(f"deployment object count {len(objects)} != {expected_object_count}")

object_sizes = {}
object_total = 0
for path in objects:
    match = re.search(r"\.([0-9a-f]{64})\.webp$", path.name)
    if not match:
        raise SystemExit(f"invalid immutable filename: {path.name}")
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest != match.group(1):
        raise SystemExit(f"immutable object digest mismatch: {path.name}")
    if data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        raise SystemExit(f"invalid WebP signature: {path.name}")
    object_sizes[path.name] = len(data)
    object_total += len(data)

if object_total != expected_object_bytes:
    raise SystemExit(f"deployment object bytes {object_total} != {expected_object_bytes}")
if catalog["images"]["deploymentObjects"]["count"] != expected_object_count:
    raise SystemExit("catalog deployment object count mismatch")
if catalog["images"]["deploymentObjects"]["bytes"] != expected_object_bytes:
    raise SystemExit("catalog deployment object bytes mismatch")

entries = manifest.get("images", {})
if len(entries) != manifest["catalog"]["entryCount"]:
    raise SystemExit("manifest entry count mismatch")
current_total = 0
for entry in entries.values():
    name = entry["file"]
    if name not in object_sizes:
        raise SystemExit(f"manifest object is missing: {name}")
    if object_sizes[name] != entry["bytes"]:
        raise SystemExit(f"manifest object byte mismatch: {name}")
    if entry["sha256"] not in name:
        raise SystemExit(f"manifest object filename digest mismatch: {name}")
    if entry.get("contentType") != "image/webp":
        raise SystemExit(f"manifest object content type mismatch: {name}")
    current_total += entry["bytes"]

if current_total != manifest["catalog"]["imageBytes"]:
    raise SystemExit("manifest current image byte total mismatch")
if catalog["images"]["currentCatalog"]["count"] != len(entries):
    raise SystemExit("catalog current object count mismatch")
if catalog["images"]["currentCatalog"]["bytes"] != current_total:
    raise SystemExit("catalog current object bytes mismatch")
if catalog["completeCatalogBytes"] != len(manifest_bytes) + current_total:
    raise SystemExit("complete catalog byte total mismatch")
if catalog["completeDeploymentBytes"] != len(manifest_bytes) + object_total:
    raise SystemExit("complete deployment byte total mismatch")

print(json.dumps({
    "releaseId": expected_digest,
    "manifestRevision": expected_revision,
    "manifestBytes": expected_manifest_bytes,
    "deploymentObjectCount": expected_object_count,
    "deploymentImageBytes": expected_object_bytes,
}, sort_keys=True))
'@

$stockMastersRoot = [System.IO.Path]::GetFullPath($StockMastersRoot)
$prepareScript = Join-Path $stockMastersRoot 'prepare_release.ps1'
$packageRoot = Join-Path $stockMastersRoot 'hosting\stock-images'
$firebaseConfig = Join-Path $stockMastersRoot 'firebase.json'

if (-not (Test-Path -LiteralPath $prepareScript -PathType Leaf)) {
    throw "Stock release preparation script was not found at '$prepareScript'."
}
if (-not (Test-Path -LiteralPath $firebaseConfig -PathType Leaf)) {
    throw "Firebase configuration was not found at '$firebaseConfig'."
}

Write-Host '=== PlaceWell Stock Artwork Deployment ===' -ForegroundColor Cyan
Write-Host "Stock masters: $stockMastersRoot"

Push-Location $stockMastersRoot
try {
    Write-Host "`n==> Preparing and testing the deterministic release" -ForegroundColor Cyan
    & $prepareScript
    if (-not $?) {
        throw 'prepare_release.ps1 failed.'
    }
} finally {
    Pop-Location
}

$facts = Get-StockReleaseFacts -PackageRoot $packageRoot
Assert-FirebaseReleaseConfig `
    -Path $firebaseConfig `
    -ManifestDigest $facts.ManifestDigest
Write-Host "`nPrepared release facts:" -ForegroundColor Yellow
Write-Host "  Release ID: $($facts.ReleaseId)"
Write-Host "  Manifest revision: $($facts.ManifestRevision)"
Write-Host "  Manifest bytes: $($facts.ManifestBytes)"
Write-Host "  Current manifest entries: $($facts.ManifestEntryCount)"
Write-Host "  Deployment WebPs: $($facts.DeploymentObjectCount)"
Write-Host "  Deployment WebP bytes: $($facts.DeploymentImageBytes)"

$expectedBaseUrl = "https://$FirebaseProject.web.app/stock-images/img/"
if ($facts.BaseUrl -cne $expectedBaseUrl) {
    throw "Manifest baseUrl '$($facts.BaseUrl)' does not match Firebase project '$FirebaseProject' ('$expectedBaseUrl')."
}

$verifierBase64 = ConvertTo-Base64Utf8 -Value $remoteVerifier
Invoke-Native 'Validating the Linode release verifier against the local package' {
    & python -c `
        "import base64;exec(compile(base64.b64decode('$verifierBase64'),'<stock-release-verifier>','exec'))" `
        $packageRoot `
        $facts.ManifestDigest `
        $facts.ManifestRevision `
        $facts.ManifestBytes `
        $facts.DeploymentObjectCount `
        $facts.DeploymentImageBytes
}

if ($ValidateOnly) {
    Write-Host "`nValidation only: no Linode or Firebase changes were made." -ForegroundColor Green
    return
}

foreach ($command in @('tar', 'scp', 'ssh', 'curl.exe', 'firebase')) {
    Assert-Command -Name $command
}

$token = [Guid]::NewGuid().ToString('N')
$workRoot = Join-Path $env:TEMP "placewell-stock-deploy-$token"
$archivePath = Join-Path $workRoot "$($facts.ReleaseId).tar.gz"
$firebaseVerificationRoot = Join-Path $workRoot 'firebase-verification'
$firebasePreviewOutput = Join-Path $workRoot 'firebase-preview.json'
$firebaseChannel = "stock-$($facts.ReleaseId.Substring(0, 12))-$($token.Substring(0, 8))"
$remoteStage = "$remoteRoot/.staging/$($facts.ReleaseId).$token"
$remoteIncoming = "$remoteRoot/.incoming/$token.tar.gz"
$remoteRelease = "$remoteRoot/releases/$($facts.ReleaseId)"
$remoteLock = "$remoteRoot/.deploy.lock"
$remoteLockAcquired = $false
$linodeActivationAttempted = $false
$firebasePromoted = $false
$preserveRemoteRecovery = $false
$deploymentCompleted = $false

New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

try {
    Invoke-Native 'Packing the exact stock release package' {
        & tar -czf $archivePath -C $packageRoot .
    }

    $lockCommand = @"
set -euo pipefail
umask 022
install -d -m 0755 '$remoteRoot' '$remoteRoot/releases'
install -d -m 0700 '$remoteRoot/.staging' '$remoteRoot/.incoming'
restorecon -RF '$remoteRoot'
if ! mkdir '$remoteLock' 2>/dev/null; then
    echo 'Another stock deployment holds the remote lock:' >&2
    cat '$remoteLock/info' >&2 2>/dev/null || true
    exit 73
fi
chmod 0700 '$remoteLock'
printf '%s\n' '$token' > '$remoteLock/token'
printf '%s\n' 'server=$Server token=$token started=$([DateTime]::UtcNow.ToString('o'))' > '$remoteLock/info'
chmod 0600 '$remoteLock/token' '$remoteLock/info'
"@
    Invoke-Remote -Description 'Acquiring the Linode stock deployment lock' -Command $lockCommand
    $remoteLockAcquired = $true

    $prepareRemoteStage = @"
set -euo pipefail
test "`$(cat '$remoteLock/token')" = '$token'
rm -rf '$remoteStage'
rm -f '$remoteIncoming'
install -d -m 0700 '$remoteStage'
"@
    Invoke-Remote -Description 'Creating the Linode staging directory' -Command $prepareRemoteStage

    Invoke-Native 'Uploading the stock release archive to Linode staging' {
        & scp $archivePath "${Server}:$remoteIncoming"
    }

    $stageVerifier = Get-RemoteVerifierInvocation `
        -ReleasePath $remoteStage `
        -Facts $facts `
        -VerifierBase64 $verifierBase64
    $releaseVerifier = Get-RemoteVerifierInvocation `
        -ReleasePath $remoteRelease `
        -Facts $facts `
        -VerifierBase64 $verifierBase64
    $serviceReadVerifier = @"
representative="`$(find '$remoteRelease/img' -maxdepth 1 -type f -name '*.webp' -print -quit)"
test -n "`$representative"
for unit in placewell-ui.service placewell.service; do
    service_user="`$(systemctl show -p User --value "`$unit")"
    if [ -z "`$service_user" ]; then
        service_user=root
    fi
    id -u "`$service_user" >/dev/null
    runuser -u "`$service_user" -- test -r '$remoteRelease/manifest.v1.json'
    runuser -u "`$service_user" -- test -r "`$representative"
done
"@

    $finalizeRemoteRelease = @"
set -euo pipefail
test "`$(cat '$remoteLock/token')" = '$token'
tar -xzf '$remoteIncoming' -C '$remoteStage'
rm -f '$remoteIncoming'
$stageVerifier
find '$remoteStage' -type d -exec chmod 0555 {} +
find '$remoteStage' -type f -exec chmod 0444 {} +
if [ -e '$remoteRelease' ] || [ -L '$remoteRelease' ]; then
    if [ -L '$remoteRelease' ] || [ ! -d '$remoteRelease' ]; then
        echo 'Existing immutable release path is not a directory.' >&2
        exit 77
    fi
    restorecon -RF '$remoteRelease'
    $releaseVerifier
    rm -rf '$remoteStage'
else
    mv '$remoteStage' '$remoteRelease'
    restorecon -RF '$remoteRelease'
    $releaseVerifier
fi
$serviceReadVerifier
"@
    Invoke-Remote `
        -Description 'Verifying and finalizing the immutable Linode release' `
        -Command $finalizeRemoteRelease

    Push-Location $stockMastersRoot
    try {
        Invoke-Native "Deploying Firebase preview channel $firebaseChannel" {
            & firebase hosting:channel:deploy $firebaseChannel `
                --project $FirebaseProject `
                --expires 1h `
                --json `
                --non-interactive
        } | Set-Content -LiteralPath $firebasePreviewOutput -Encoding UTF8
        $previewResult = Get-Content -LiteralPath $firebasePreviewOutput -Raw |
            ConvertFrom-Json
        $firebasePreviewUrl = Get-FirebasePreviewUrl -Value $previewResult
        if (-not $firebasePreviewUrl) {
            throw 'Firebase preview deployment did not return a usable web.app URL.'
        }
    } finally {
        Pop-Location
    }

    Test-FirebaseRelease `
        -Facts $facts `
        -PackageRoot $packageRoot `
        -VerificationRoot $firebaseVerificationRoot `
        -CacheBust $token `
        -HostingOrigin $firebasePreviewUrl

    $verifyFinalLinodeRelease = @"
set -euo pipefail
test "`$(cat '$remoteLock/token')" = '$token'
$releaseVerifier
$serviceReadVerifier
"@
    Invoke-Remote `
        -Description 'Re-verifying the immutable Linode release after Firebase preview verification' `
        -Command $verifyFinalLinodeRelease

    $liveOrigin = $facts.BaseUrl -replace '/stock-images/img/$', ''
    $previousLiveManifest = Join-Path $workRoot 'firebase-live-before-promotion.json'
    Invoke-CurlDownload `
        -Description 'Recording the current Firebase live release' `
        -Url "$($liveOrigin.TrimEnd('/'))/stock-images/manifest.v1.json?release=${token}-before" `
        -OutputPath $previousLiveManifest
    $previousFirebaseDigest = Get-LowercaseFileSha256 -Path $previousLiveManifest

    $activateRemoteRelease = @"
set -euo pipefail
test "`$(cat '$remoteLock/token')" = '$token'
current='$remoteRoot/current'
new_link='$remoteRoot/.current.$token'
rollback_link='$remoteRoot/.current.rollback.$token'
new_target='releases/$($facts.ReleaseId)'
had_current=0
old_target=''
rollback_needed=0
state_file='$remoteLock/activation-state'

rollback_current() {
    if [ "`$had_current" -eq 1 ]; then
        mv -Tf "`$rollback_link" "`$current"
    else
        rm -f "`$current"
    fi
    rm -f "`$state_file"
}

trap 'if [ "`$rollback_needed" -eq 1 ]; then rollback_current; fi' ERR

if [ -L "`$current" ]; then
    had_current=1
    old_target="`$(readlink "`$current")"
    ln -s "`$old_target" "`$rollback_link"
    printf '%s\n' 'had-current' > "`$state_file"
elif [ -e "`$current" ]; then
    echo 'Refusing to replace non-symlink /opt/placewell-stock/current.' >&2
    exit 74
else
    printf '%s\n' 'no-current' > "`$state_file"
fi

rm -f "`$new_link"
ln -s "`$new_target" "`$new_link"
mv -Tf "`$new_link" "`$current"
rollback_needed=1

activation_ok=1
if [ "`$(readlink "`$current")" != "`$new_target" ]; then
    activation_ok=0
fi
if [ "`$(sha256sum "`$current/manifest.v1.json" | awk '{print `$1}')" != '$($facts.ManifestDigest)' ]; then
    activation_ok=0
fi

if [ "`$activation_ok" -ne 1 ]; then
    rollback_current
    rollback_needed=0
    echo 'Linode current activation verification failed; the prior pointer was restored.' >&2
    exit 75
fi

current_representative="`$(find "`$current/img" -maxdepth 1 -type f -name '*.webp' -print -quit)"
test -n "`$current_representative"
for unit in placewell-ui.service placewell.service; do
    service_user="`$(systemctl show -p User --value "`$unit")"
    if [ -z "`$service_user" ]; then
        service_user=root
    fi
    runuser -u "`$service_user" -- test -r "`$current/manifest.v1.json"
    runuser -u "`$service_user" -- test -r "`$current_representative"
done

rollback_needed=0
trap - ERR
"@
    $linodeActivationAttempted = $true
    Invoke-Remote `
        -Description 'Atomically activating Linode with rollback armed' `
        -Command $activateRemoteRelease

    $promotionError = $null
    try {
        Push-Location $stockMastersRoot
        try {
            Invoke-Native "Promoting verified Firebase preview $firebaseChannel to live" {
                & firebase hosting:clone `
                    "${FirebaseProject}:$firebaseChannel" `
                    "${FirebaseProject}:live" `
                    --project $FirebaseProject `
                    --non-interactive
            }
        } finally {
            Pop-Location
        }
    } catch {
        $promotionError = $_
    }

    $liveVerificationRoot = Join-Path $workRoot 'firebase-live-verification'
    try {
        Test-FirebaseRelease `
            -Facts $facts `
            -PackageRoot $packageRoot `
            -VerificationRoot $liveVerificationRoot `
            -CacheBust "${token}-live" `
            -HostingOrigin $liveOrigin
        $firebasePromoted = $true
        if ($promotionError) {
            Write-Warning 'Firebase promotion reported an error, but the live release passed full verification.'
        }
    } catch {
        if (-not $promotionError) {
            $promotionError = $_
        }
    }

    if (-not $firebasePromoted) {
        $liveManifest = Join-Path $workRoot 'firebase-live-manifest.json'
        $observedPreviousDigestCount = 0
        $observedNewDigest = $false
        $observedUnknownOutcome = $false
        for ($attempt = 1; $attempt -le 6; $attempt++) {
            try {
                Invoke-CurlDownload `
                    -Description "Resolving Firebase live promotion outcome (attempt $attempt of 6)" `
                    -Url "$($liveOrigin.TrimEnd('/'))/stock-images/manifest.v1.json?release=${token}-outcome-${attempt}-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())" `
                    -OutputPath $liveManifest
                $liveDigest = Get-LowercaseFileSha256 -Path $liveManifest
                if ($liveDigest -ceq $facts.ManifestDigest) {
                    $observedNewDigest = $true
                    break
                }
                if ($liveDigest -ceq $previousFirebaseDigest) {
                    $observedPreviousDigestCount++
                } else {
                    $observedUnknownOutcome = $true
                }
            } catch {
                $observedUnknownOutcome = $true
            }
            if ($attempt -lt 6) {
                Start-Sleep -Seconds 5
            }
        }

        if ($observedNewDigest) {
            $preserveRemoteRecovery = $true
            throw "Firebase live serves the new manifest, but full release verification failed. The Linode recovery lock was preserved. Error: $promotionError"
        }

        if (-not $observedUnknownOutcome -and $observedPreviousDigestCount -eq 6) {
            throw $promotionError
        }

        $preserveRemoteRecovery = $true
        throw "Firebase promotion outcome is ambiguous and the Linode rollback lock was preserved for manual recovery. Error: $promotionError"
    }

    $finalizeActivation = @"
set -euo pipefail
test "`$(cat '$remoteLock/token')" = '$token'
test -f '$remoteLock/activation-state'
rm -f '$remoteRoot/.current.rollback.$token' '$remoteLock/activation-state'
rm -rf '$remoteStage'
rm -f '$remoteIncoming'
rm -rf '$remoteLock'
"@
    Invoke-Remote `
        -Description 'Finalizing the paired stock release' `
        -Command $finalizeActivation

    $remoteLockAcquired = $false
    $deploymentCompleted = $true
} finally {
    $cleanupError = $null
    if ($remoteLockAcquired) {
        if ($preserveRemoteRecovery) {
            Write-Warning "Remote recovery state remains at $remoteLock because the Firebase live outcome could not be determined."
            $cleanupCommand = $null
        } elseif ($linodeActivationAttempted -and -not $firebasePromoted) {
            $cleanupCommand = @"
set -euo pipefail
if [ ! -f '$remoteLock/token' ] || [ "`$(cat '$remoteLock/token')" != '$token' ]; then
    echo 'Refusing to roll back a stock deployment lock owned by another process.' >&2
    exit 76
fi
if [ -f '$remoteLock/activation-state' ]; then
    state="`$(cat '$remoteLock/activation-state')"
    if [ "`$state" = 'had-current' ]; then
        test -L '$remoteRoot/.current.rollback.$token'
        mv -Tf '$remoteRoot/.current.rollback.$token' '$remoteRoot/current'
    elif [ "`$state" = 'no-current' ]; then
        rm -f '$remoteRoot/current' '$remoteRoot/.current.rollback.$token'
    else
        echo 'Unknown stock activation rollback state.' >&2
        exit 78
    fi
fi
rm -f '$remoteRoot/.current.rollback.$token' '$remoteLock/activation-state'
rm -rf '$remoteStage'
rm -f '$remoteIncoming'
rm -rf '$remoteLock'
"@
        } else {
            $cleanupCommand = @"
set -euo pipefail
if [ ! -f '$remoteLock/token' ] || [ "`$(cat '$remoteLock/token')" != '$token' ]; then
    echo 'Refusing to remove a stock deployment lock owned by another process.' >&2
    exit 76
fi
rm -f '$remoteRoot/.current.rollback.$token' '$remoteLock/activation-state'
rm -rf '$remoteStage'
rm -f '$remoteIncoming'
rm -rf '$remoteLock'
"@
        }
        if ($cleanupCommand) {
            try {
                Invoke-Remote `
                    -Description $(if ($linodeActivationAttempted -and -not $firebasePromoted) {
                        'Restoring or cleaning Linode after incomplete activation'
                    } else {
                        'Releasing the Linode stock deployment lock'
                    }) `
                    -Command $cleanupCommand
            } catch {
                $cleanupError = $_
            }
        }
    }

    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue

    if ($cleanupError) {
        throw $cleanupError
    }
}

if (-not $deploymentCompleted) {
    throw 'Stock artwork deployment did not complete.'
}

Write-Host "`n=== Stock Artwork Deployment Complete ===" -ForegroundColor Green
Write-Host "Release: $($facts.ReleaseId)"
Write-Host "Firebase and Linode current now reference the same verified manifest bytes."
