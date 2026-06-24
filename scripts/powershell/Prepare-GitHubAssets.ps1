[CmdletBinding()]
param(
    [string]$ManifestPath = "config\github-release-assets.json",
    [string]$OutputDir = "artifacts\github-assets",
    [switch]$Clean,
    [switch]$AllowMissingOptional
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
Set-Location $repoRoot

function Resolve-RepoPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return Join-Path $repoRoot $Path
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Copy-AssetPath {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    if (Test-Path -LiteralPath $Source -PathType Container) {
        if (Test-Path -LiteralPath $Destination) {
            Remove-Item -LiteralPath $Destination -Recurse -Force
        }
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function Assert-NoForbiddenFiles {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$ForbiddenNames
    )

    if (-not (Test-Path -LiteralPath $Path)) { return }

    foreach ($name in $ForbiddenNames) {
        $matches = Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ieq $name }
        if ($matches) {
            $list = ($matches | Select-Object -ExpandProperty FullName) -join [Environment]::NewLine
            throw "Forbidden file '$name' found in staged assets:$([Environment]::NewLine)$list"
        }
    }
}

function New-ZipFromDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDirectory,
        [Parameter(Mandatory = $true)][string]$ZipPath
    )

    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    $parent = Split-Path -Parent $ZipPath
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    & tar.exe -a -cf $ZipPath -C $SourceDirectory .
    if ($LASTEXITCODE -ne 0) {
        throw "ZIP64 archive creation failed for: $SourceDirectory"
    }
}

function New-ZipFromStagePaths {
    param(
        [Parameter(Mandatory = $true)][string]$StageRoot,
        [Parameter(Mandatory = $true)][string[]]$RelativePaths,
        [Parameter(Mandatory = $true)][string]$ZipPath
    )

    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    $parent = Split-Path -Parent $ZipPath
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    $paths = @()
    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path $StageRoot $relativePath
        if (Test-Path -LiteralPath $fullPath) {
            $paths += $fullPath
        }
    }

    if ($paths.Count -eq 0) {
        throw "No stage paths exist for ZIP: $ZipPath"
    }

    Compress-Archive -LiteralPath $paths -DestinationPath $ZipPath -CompressionLevel Optimal
}

$manifestFullPath = Resolve-RepoPath $ManifestPath
if (-not (Test-Path -LiteralPath $manifestFullPath -PathType Leaf)) {
    throw "Manifest not found: $manifestFullPath"
}

$manifest = Get-Content -LiteralPath $manifestFullPath -Raw | ConvertFrom-Json
$outputFullPath = Resolve-RepoPath $OutputDir
$stageRoot = Join-Path $outputFullPath ([string]$manifest.release.assetRoot)
$bundleDir = Join-Path $outputFullPath "bundles"
$reportPath = Join-Path $outputFullPath "validation-report.md"

if ($Clean -and (Test-Path -LiteralPath $outputFullPath)) {
    Remove-Item -LiteralPath $outputFullPath -Recurse -Force
}

New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
New-Item -ItemType Directory -Path $bundleDir -Force | Out-Null

$errors = [System.Collections.Generic.List[string]]::new()
$preparedItems = [System.Collections.Generic.List[object]]::new()

foreach ($item in $manifest.items) {
    $source = Resolve-RepoPath ([string]$item.sourcePath)
    $required = [bool]$item.required
    if (-not (Test-Path -LiteralPath $source)) {
        $message = "{0}: missing source {1}" -f $item.id, $source
        if ($required -or -not $AllowMissingOptional) {
            $errors.Add($message)
        }
        else {
            Write-Warning $message
        }
        continue
    }

    if (Test-Path -LiteralPath $source -PathType Leaf) {
        $file = Get-Item -LiteralPath $source
        if ($item.PSObject.Properties.Name -contains "expectedSizeBytes") {
            $expectedSize = [int64]$item.expectedSizeBytes
            if ($file.Length -ne $expectedSize) {
                $errors.Add(("{0}: size mismatch for {1}. expected={2} actual={3}" -f $item.id, $source, $expectedSize, $file.Length))
                continue
            }
        }

        if ($item.PSObject.Properties.Name -contains "sha256") {
            $expectedHash = ([string]$item.sha256).ToUpperInvariant()
            if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
                $actualHash = Get-FileSha256 -Path $source
                if ($actualHash -ne $expectedHash) {
                    $errors.Add(("{0}: SHA-256 mismatch for {1}. expected={2} actual={3}" -f $item.id, $source, $expectedHash, $actualHash))
                    continue
                }
            }
        }
    }

    $bundle = @($manifest.bundles | Where-Object { $_.id -eq $item.bundle })[0]
    if (-not $bundle) {
        $errors.Add(("{0}: unknown bundle {1}" -f $item.id, $item.bundle))
        continue
    }

    $destination = Join-Path (Join-Path $stageRoot ([string]$bundle.stagePath)) ([string]$item.stageRelativePath)
    Copy-AssetPath -Source $source -Destination $destination

    $preparedItems.Add([pscustomobject]@{
        id = $item.id
        bundle = $item.bundle
        sourcePath = $item.sourcePath
        stagePath = (($destination.Substring($stageRoot.Length)).TrimStart("\", "/"))
        restorePath = $item.restorePath
        validationStatus = $item.validationStatus
        intendedUse = $item.intendedUse
    }) | Out-Null
}

if ($errors.Count -gt 0) {
    $details = ($errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    throw "Cannot prepare GitHub assets because required assets are missing or invalid:$([Environment]::NewLine)$details"
}

Assert-NoForbiddenFiles -Path $stageRoot -ForbiddenNames @($manifest.policy.forbiddenNames)

$checksumDir = Join-Path $stageRoot "firmware\checksums"
New-Item -ItemType Directory -Path $checksumDir -Force | Out-Null

$releaseManifest = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("o")
    assetRoot = $manifest.release.assetRoot
    items = @($preparedItems)
}
$releaseManifestPath = Join-Path $checksumDir "asset-manifest.json"
$releaseManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $releaseManifestPath -Encoding UTF8

$report = @(
    "# OPPO F1s GitHub Asset Validation Report",
    "",
    "- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")",
    "- Prepared items: $($preparedItems.Count)",
    "- Forbidden file check: passed",
    "",
    "## Prepared Items",
    ""
)
$report += $preparedItems | ForEach-Object { "- `$($_.id)` -> `$($_.stagePath)` ($($_.validationStatus))" }
$report | Set-Content -LiteralPath $reportPath -Encoding UTF8
Copy-Item -LiteralPath $reportPath -Destination (Join-Path $checksumDir "validation-report.md") -Force

$docsDir = Join-Path $stageRoot "docs"
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
$flashingOrder = @(
    "# OPPO F1s Recovery Asset Flashing Order",
    "",
    "1. Restore release assets into the repository workspace.",
    "2. Validate firmware and tools before connecting the phone.",
    "3. Open SP Flash Tool/SP MDT through the guided scripts only.",
    "4. Use Download Only / normal download mode and keep preloader unchecked unless exact hardware match is confirmed.",
    "5. After Android boots, use SN Writer only to restore the phone's original IMEI from legitimate paperwork.",
    "",
    "Do not use OPPO DownloadTool.exe in this workflow."
)
$flashingOrder | Set-Content -LiteralPath (Join-Path $docsDir "flashing-order.md") -Encoding UTF8
Copy-Item -LiteralPath $reportPath -Destination (Join-Path $docsDir "validation-report.md") -Force

$checksums = Get-ChildItem -LiteralPath $stageRoot -Recurse -Force -File |
    Where-Object { $_.FullName -notlike "*\firmware\checksums\SHA256SUMS.txt" } |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($stageRoot.Length).TrimStart("\", "/").Replace("\", "/")
        "{0}  {1}" -f (Get-FileSha256 -Path $_.FullName), $relative
    }

$checksumsPath = Join-Path $checksumDir "SHA256SUMS.txt"
$checksums | Set-Content -LiteralPath $checksumsPath -Encoding UTF8

$releaseAssets = [System.Collections.Generic.List[object]]::new()

foreach ($bundle in $manifest.bundles) {
    $bundleStagePath = Join-Path $stageRoot ([string]$bundle.stagePath)
    if (-not (Test-Path -LiteralPath $bundleStagePath)) {
        New-Item -ItemType Directory -Path $bundleStagePath -Force | Out-Null
    }

    $assetMode = if ($bundle.PSObject.Properties.Name -contains "assetMode") { [string]$bundle.assetMode } else { "zip" }
    if ($assetMode -eq "individual-files") {
        $bundleItems = @($preparedItems | Where-Object { $_.bundle -eq $bundle.id })
        foreach ($preparedItem in $bundleItems) {
            $sourcePath = Join-Path $stageRoot ([string]$preparedItem.stagePath)
            if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
                throw "Individual release asset must be a file: $sourcePath"
            }

            $leaf = Split-Path -Leaf $sourcePath
            $assetName = "{0}--{1}--{2}" -f $bundle.id, $preparedItem.id, $leaf
            $assetName = $assetName.Replace("[", ".").Replace("]", ".")
            $assetPath = Join-Path $bundleDir $assetName
            Copy-Item -LiteralPath $sourcePath -Destination $assetPath -Force

            $releaseAssets.Add([pscustomobject]@{
                assetName = $assetName
                mode = "direct"
                bundle = $bundle.id
                itemIds = @($preparedItem.id)
            }) | Out-Null
        }
    }
    else {
        $zipPath = Join-Path $bundleDir ([string]$bundle.assetName)
        if ($bundle.PSObject.Properties.Name -contains "includePaths") {
            New-ZipFromStagePaths -StageRoot $stageRoot -RelativePaths @($bundle.includePaths) -ZipPath $zipPath
        }
        else {
            New-ZipFromDirectory -SourceDirectory $bundleStagePath -ZipPath $zipPath
        }

        $releaseAssets.Add([pscustomobject]@{
            assetName = [string]$bundle.assetName
            mode = "zip"
            bundle = $bundle.id
            itemIds = @($preparedItems | Where-Object { $_.bundle -eq $bundle.id } | Select-Object -ExpandProperty id)
        }) | Out-Null
    }
}

$releaseAssetsPath = Join-Path $bundleDir "release-assets.json"
[pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("o")
    assets = @($releaseAssets)
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $releaseAssetsPath -Encoding UTF8

$maxReleaseAssetBytes = 2GB
$oversized = @(Get-ChildItem -LiteralPath $bundleDir -File | Where-Object { $_.Length -ge $maxReleaseAssetBytes })
if ($oversized.Count -gt 0) {
    $details = ($oversized | ForEach-Object { "- $($_.Name): $($_.Length) bytes" }) -join [Environment]::NewLine
    throw "One or more prepared assets exceed GitHub's 2 GiB per-asset limit:$([Environment]::NewLine)$details"
}

$bundleChecksums = Get-ChildItem -LiteralPath $bundleDir -File |
    Where-Object { $_.Name -ne "SHA256SUMS.txt" } |
    Sort-Object Name |
    ForEach-Object { "{0}  {1}" -f (Get-FileSha256 -Path $_.FullName), $_.Name }
$bundleChecksums | Set-Content -LiteralPath (Join-Path $bundleDir "SHA256SUMS.txt") -Encoding UTF8

Write-Host "Prepared GitHub assets under: $outputFullPath"
Write-Host "Release assets:"
Get-ChildItem -LiteralPath $bundleDir -File | Sort-Object Name | ForEach-Object {
    Write-Host ("- {0} ({1:N0} bytes)" -f $_.Name, $_.Length)
}
