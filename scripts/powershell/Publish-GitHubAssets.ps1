[CmdletBinding()]
param(
    [string]$ManifestPath = "config\github-release-assets.json",
    [string]$BundleDir = "artifacts\github-assets\bundles",
    [string]$Tag,
    [switch]$CreateRelease,
    [switch]$DryRun
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

$manifestFullPath = Resolve-RepoPath $ManifestPath
if (-not (Test-Path -LiteralPath $manifestFullPath -PathType Leaf)) {
    throw "Manifest not found: $manifestFullPath"
}

$manifest = Get-Content -LiteralPath $manifestFullPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($Tag)) {
    $Tag = [string]$manifest.release.defaultTag
}

$bundleFullPath = Resolve-RepoPath $BundleDir
if (-not (Test-Path -LiteralPath $bundleFullPath -PathType Container)) {
    throw "Bundle directory not found. Run Prepare-GitHubAssets.ps1 first: $bundleFullPath"
}

$releaseAssetsPath = Join-Path $bundleFullPath "release-assets.json"
if (-not (Test-Path -LiteralPath $releaseAssetsPath -PathType Leaf)) {
    throw "Release asset manifest not found. Run Prepare-GitHubAssets.ps1 first: $releaseAssetsPath"
}

$releaseAssets = Get-Content -LiteralPath $releaseAssetsPath -Raw | ConvertFrom-Json
$requiredAssets = @($releaseAssets.assets | ForEach-Object { Join-Path $bundleFullPath ([string]$_.assetName) })
$requiredAssets += $releaseAssetsPath
$requiredAssets += Join-Path $bundleFullPath "SHA256SUMS.txt"
$requiredAssets = @($requiredAssets | Sort-Object { (Get-Item -LiteralPath $_).Length })
$missing = @($requiredAssets | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    throw "Missing release bundle files:$([Environment]::NewLine)$(($missing | ForEach-Object { "- $_" }) -join [Environment]::NewLine)"
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw "GitHub CLI 'gh' is required to publish release assets. Install/authenticate gh, then retry."
}

if ($CreateRelease) {
    & $gh.Source release view $Tag *> $null
    $releaseExists = ($LASTEXITCODE -eq 0)
    if ($releaseExists) {
        Write-Host "Release already exists; reusing tag: $Tag"
    }
    else {
        $createArgs = @("release", "create", $Tag, "--title", "OPPO F1s Recovery Assets $Tag", "--notes", "Firmware/tool binary assets for the OPPO F1s A1601 recovery workflow.")
        if ($DryRun) {
            Write-Host ("DRY RUN: gh {0}" -f ($createArgs -join " "))
        }
        else {
            & $gh.Source @createArgs
            if ($LASTEXITCODE -ne 0) { throw "gh release create failed with exit code $LASTEXITCODE" }
        }
    }
}

foreach ($assetPath in $requiredAssets) {
    $uploadArgs = @("release", "upload", $Tag, $assetPath, "--clobber")
    if ($DryRun) {
        Write-Host ("DRY RUN: gh {0}" -f ($uploadArgs -join " "))
        continue
    }

    Write-Host ("Uploading {0} ({1:N0} bytes)..." -f (Split-Path -Leaf $assetPath), (Get-Item -LiteralPath $assetPath).Length)
    & $gh.Source @uploadArgs
    if ($LASTEXITCODE -ne 0) {
        throw "gh release upload failed for $assetPath with exit code $LASTEXITCODE"
    }
}

Write-Host "Release asset publish command completed for tag: $Tag"
exit 0
