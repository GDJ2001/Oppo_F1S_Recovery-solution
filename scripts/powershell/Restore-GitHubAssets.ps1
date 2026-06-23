[CmdletBinding()]
param(
    [string]$ManifestPath = "config\github-release-assets.json",
    [string]$Tag,
    [string]$DownloadDir = "artifacts\github-assets-download",
    [switch]$NoDownload,
    [switch]$Force
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

$manifestFullPath = Resolve-RepoPath $ManifestPath
if (-not (Test-Path -LiteralPath $manifestFullPath -PathType Leaf)) {
    throw "Manifest not found: $manifestFullPath"
}

$manifest = Get-Content -LiteralPath $manifestFullPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($Tag)) {
    $Tag = [string]$manifest.release.defaultTag
}

$downloadFullPath = Resolve-RepoPath $DownloadDir
$extractRoot = Join-Path $downloadFullPath "extracted"
New-Item -ItemType Directory -Path $downloadFullPath -Force | Out-Null

if (-not $NoDownload) {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw "GitHub CLI 'gh' is required to download release assets. Install/authenticate gh, or use -NoDownload with assets already in $downloadFullPath."
    }

    $assetNames = @($manifest.bundles | ForEach-Object { [string]$_.assetName })
    $assetNames += "SHA256SUMS.txt"
    foreach ($assetName in $assetNames) {
        & $gh.Source release download $Tag --pattern $assetName --dir $downloadFullPath --clobber
        if ($LASTEXITCODE -ne 0) { throw "gh release download failed for $assetName with exit code $LASTEXITCODE" }
    }
}

$bundleChecksumPath = Join-Path $downloadFullPath "SHA256SUMS.txt"
if (Test-Path -LiteralPath $bundleChecksumPath -PathType Leaf) {
    Get-Content -LiteralPath $bundleChecksumPath | Where-Object { $_.Trim() } | ForEach-Object {
        $parts = $_ -split "\s+", 2
        if ($parts.Count -ne 2) { throw "Invalid checksum line: $_" }
        $expected = $parts[0].ToUpperInvariant()
        $assetName = $parts[1].Trim()
        $assetPath = Join-Path $downloadFullPath $assetName
        if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) { throw "Missing downloaded asset: $assetPath" }
        $actual = Get-FileSha256 -Path $assetPath
        if ($actual -ne $expected) { throw "Bundle checksum mismatch for $assetName. expected=$expected actual=$actual" }
    }
}

if (Test-Path -LiteralPath $extractRoot) {
    Remove-Item -LiteralPath $extractRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

foreach ($bundle in $manifest.bundles) {
    $zipPath = Join-Path $downloadFullPath ([string]$bundle.assetName)
    if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
        throw "Missing bundle ZIP: $zipPath"
    }

    $bundleExtractPath = Join-Path $extractRoot ([string]$bundle.id)
    New-Item -ItemType Directory -Path $bundleExtractPath -Force | Out-Null
    Expand-Archive -LiteralPath $zipPath -DestinationPath $bundleExtractPath -Force
}

foreach ($item in $manifest.items) {
    $bundle = @($manifest.bundles | Where-Object { $_.id -eq $item.bundle })[0]
    if (-not $bundle) { throw "Unknown bundle for item $($item.id): $($item.bundle)" }

    $source = Join-Path (Join-Path $extractRoot ([string]$bundle.id)) ([string]$item.stageRelativePath)
    if (-not (Test-Path -LiteralPath $source)) {
        if ([bool]$item.required) {
            throw "Required item missing from release bundle: $($item.id) at $source"
        }
        continue
    }

    $destination = Resolve-RepoPath ([string]$item.restorePath)
    $destinationParent = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null

    if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        throw "Restore target already exists. Use -Force to replace: $destination"
    }

    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force

    if ((Test-Path -LiteralPath $destination -PathType Leaf) -and ($item.PSObject.Properties.Name -contains "sha256")) {
        $expectedHash = ([string]$item.sha256).ToUpperInvariant()
        if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
            $actualHash = Get-FileSha256 -Path $destination
            if ($actualHash -ne $expectedHash) {
                throw "Restored file checksum mismatch for $($item.id). expected=$expectedHash actual=$actualHash"
            }
        }
    }
}

Write-Host "GitHub release assets restored from tag: $Tag"
