param(
    [string]$FirmwareDir = "firmware\stock\A1601EX_11_A.41_191226_RepairMyMobile\A1601EX_11_A.41_191226_RMM",
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

$repoRoot = Resolve-RepoRoot
if (-not [IO.Path]::IsPathRooted($FirmwareDir)) {
    $FirmwareDir = Join-Path $repoRoot $FirmwareDir
}

$downloadTool = Join-Path $FirmwareDir "DownloadTool.exe"
$ofp = Join-Path $FirmwareDir "oppo6750_15331.ofp"
$apDb = Join-Path $FirmwareDir "A1601EX_11_A.41_191226_database_AP"
$mdDb = Join-Path $FirmwareDir "A1601EX_11_A.41_191226_database"

$missing = @($downloadTool, $ofp, $apDb, $mdDb | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($missing.Count -gt 0) {
    Write-Host "Missing required files:"
    $missing | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "OPPO DownloadTool package"
Write-Host "Firmware dir : $FirmwareDir"
Write-Host "DownloadTool : $downloadTool"
Write-Host "OFP package  : $ofp"
Write-Host "AP database  : $apDb"
Write-Host "MD database  : $mdDb"
Write-Host ""
Write-Warning "DownloadTool.exe is not Authenticode-signed. Use only if you accept that trust boundary."
Write-Warning "This OFP workflow can wipe data and rewrite firmware partitions. Restore only the phone's original IMEI afterward."

if ($ValidateOnly) {
    exit 0
}

Start-Process -FilePath $downloadTool -WorkingDirectory $FirmwareDir
