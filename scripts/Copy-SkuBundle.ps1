[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BundlePath,

    [string]$DestinationDirectory = (
        "C:\PlaceWell\PlaceWellPdfGenerator\placewell_generator\skus"
    )
)

$ErrorActionPreference = "Stop"
$resolvedBundle = (Resolve-Path -LiteralPath $BundlePath).Path
$temporaryDirectory = $null

try {
    if (Test-Path -LiteralPath $resolvedBundle -PathType Leaf) {
        $temporaryDirectory = Join-Path (
            [System.IO.Path]::GetTempPath()
        ) ("placewell-sku-bundle-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
        Expand-Archive -LiteralPath $resolvedBundle `
            -DestinationPath $temporaryDirectory
        $bundleDirectory = $temporaryDirectory
    }
    else {
        $bundleDirectory = $resolvedBundle
    }

    $generatedDirectory = Join-Path $bundleDirectory (
        "generated\PlaceWellPdfGenerator"
    )
    $skuFiles = Get-ChildItem -LiteralPath $generatedDirectory `
        -Filter "*.json" -File

    New-Item -ItemType Directory -Path $DestinationDirectory `
        -Force | Out-Null

    foreach ($skuFile in $skuFiles) {
        $destination = Join-Path $DestinationDirectory $skuFile.Name
        Copy-Item -LiteralPath $skuFile.FullName `
            -Destination $destination -Force
        Write-Host "Copied $($skuFile.Name) to $destination"
    }
}
finally {
    if ($temporaryDirectory -and (
        Test-Path -LiteralPath $temporaryDirectory
    )) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
