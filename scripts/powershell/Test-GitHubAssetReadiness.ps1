[CmdletBinding()]
param(
    [string]$ManifestPath = "config\github-release-assets.json",
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

function Test-ForbiddenFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$ForbiddenNames
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Where-Object { $ForbiddenNames -contains $_.Name } |
        Select-Object -ExpandProperty FullName)
}

$manifestFullPath = Resolve-RepoPath $ManifestPath
if (-not (Test-Path -LiteralPath $manifestFullPath -PathType Leaf)) {
    throw "Manifest not found: $manifestFullPath"
}

$manifest = Get-Content -LiteralPath $manifestFullPath -Raw | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

foreach ($item in $manifest.items) {
    $source = Resolve-RepoPath ([string]$item.sourcePath)
    $required = [bool]$item.required
    $status = "OK"
    $detail = ""

    if (-not (Test-Path -LiteralPath $source)) {
        $status = if ($required) { "MISSING_REQUIRED" } else { "MISSING_OPTIONAL" }
        $detail = "Source not found"
    }
    elseif (Test-Path -LiteralPath $source -PathType Leaf) {
        $file = Get-Item -LiteralPath $source
        if ($item.PSObject.Properties.Name -contains "expectedSizeBytes") {
            $expectedSize = [int64]$item.expectedSizeBytes
            if ($file.Length -ne $expectedSize) {
                $status = "INVALID"
                $detail = "Size mismatch: expected=$expectedSize actual=$($file.Length)"
            }
        }

        if (($status -eq "OK") -and ($item.PSObject.Properties.Name -contains "sha256")) {
            $expectedHash = ([string]$item.sha256).ToUpperInvariant()
            if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
                $actualHash = Get-FileSha256 -Path $source
                if ($actualHash -ne $expectedHash) {
                    $status = "INVALID"
                    $detail = "SHA-256 mismatch: expected=$expectedHash actual=$actualHash"
                }
            }
        }
    }

    if ($status -eq "OK") {
        $forbidden = Test-ForbiddenFile -Path $source -ForbiddenNames @($manifest.policy.forbiddenNames)
        if ($forbidden.Count -gt 0) {
            $status = "INVALID"
            $detail = "Forbidden file found: $($forbidden -join '; ')"
        }
    }

    $results.Add([pscustomobject]@{
        Id = $item.id
        Bundle = $item.bundle
        Required = $required
        Status = $status
        SourcePath = $item.sourcePath
        Detail = $detail
    }) | Out-Null
}

$results | Sort-Object Bundle, Id | Format-Table -AutoSize

$blocking = @($results | Where-Object {
    $_.Status -eq "INVALID" -or
    $_.Status -eq "MISSING_REQUIRED" -or
    (($_.Status -eq "MISSING_OPTIONAL") -and -not $AllowMissingOptional)
})

Write-Host ""
Write-Host ("Asset readiness: {0} OK, {1} blocking issue(s)" -f @($results | Where-Object Status -eq "OK").Count, $blocking.Count)

if ($blocking.Count -gt 0) {
    exit 1
}
