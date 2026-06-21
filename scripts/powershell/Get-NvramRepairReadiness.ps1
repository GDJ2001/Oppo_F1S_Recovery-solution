param(
    [string]$FirmwareDir = "",
    [string]$SnWriteToolDir = "",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Find-DefaultFirmwareDir {
    param([string]$RepoRoot)

    $stockRoot = Join-Path $RepoRoot "firmware\stock"
    if (-not (Test-Path -LiteralPath $stockRoot)) {
        return $null
    }

    $scatter = Get-ChildItem -LiteralPath $stockRoot -Recurse -File -Filter "MT6750_Android_scatter.txt" -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1

    if ($scatter) {
        return $scatter.Directory.FullName
    }

    return $null
}

function Find-SnWriter {
    param([string]$RepoRoot, [string]$ToolDir)

    $roots = @()
    if (-not [string]::IsNullOrWhiteSpace($ToolDir)) {
        $roots += $ToolDir
    }
    $roots += (Join-Path $RepoRoot "tools\sn-write-tool")
    $roots += (Join-Path $RepoRoot "tools")

    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $exe = Get-ChildItem -LiteralPath $root -Recurse -File -Filter "SN_Writer.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -First 1
        if ($exe) {
            return $exe.FullName
        }
    }

    return $null
}

function Find-DatabaseFiles {
    param([string]$Dir)

    $files = @()
    if (-not [string]::IsNullOrWhiteSpace($Dir) -and (Test-Path -LiteralPath $Dir)) {
        $files = @(Get-ChildItem -LiteralPath $Dir -Recurse -File -ErrorAction SilentlyContinue)
    }

    $apDb = $files |
        Where-Object { $_.Name -match "(_database_AP$|^APDB|AP_DB|APDatabase)" } |
        Sort-Object Length -Descending |
        Select-Object -First 1

    $mdDb = $files |
        Where-Object { $_.Name -match "(_database$|^BPLGU|MDDB|MD_DB|modem.*database)" -and $_.Name -notmatch "_AP$" } |
        Sort-Object Length -Descending |
        Select-Object -First 1

    return [pscustomobject]@{
        apDatabase = if ($apDb) { $apDb.FullName } else { $null }
        mdDatabase = if ($mdDb) { $mdDb.FullName } else { $null }
    }
}

function Get-RelatedUsbDevices {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FriendlyName -match "OPPO|Android|ADB|Fastboot|MediaTek|MTK|Preloader|VCOM|CDC|META" -or
            $_.InstanceId -match "VID_0E8D|VID_22D9|VID_18D1"
        } |
        Select-Object Status, Class, FriendlyName, InstanceId
}

$repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($FirmwareDir)) {
    $FirmwareDir = Find-DefaultFirmwareDir -RepoRoot $repoRoot
}
elseif (-not [IO.Path]::IsPathRooted($FirmwareDir)) {
    $FirmwareDir = Join-Path $repoRoot $FirmwareDir
}

$snWriter = Find-SnWriter -RepoRoot $repoRoot -ToolDir $SnWriteToolDir
$databases = Find-DatabaseFiles -Dir $FirmwareDir
$devices = @(Get-RelatedUsbDevices)

$warnings = @()
if (-not $snWriter) {
    $warnings += "SN_Writer.exe was not found under tools."
}
if (-not $databases.apDatabase) {
    $warnings += "AP database file was not found in the firmware directory."
}
if (-not $databases.mdDatabase) {
    $warnings += "MD/BPLGU database file was not found in the firmware directory."
}
if (@($devices | Where-Object { $_.FriendlyName -match "MediaTek|MTK|Preloader|VCOM|CDC|META" -or $_.InstanceId -match "VID_0E8D" }).Count -eq 0) {
    $warnings += "No MediaTek preloader/META/VCOM interface is currently visible."
}
$warnings += "Only restore the phone's original IMEI from its box/sticker/paperwork. Do not generate or substitute identifiers."

$result = [ordered]@{
    repositoryRoot = $repoRoot
    firmwareDir = $FirmwareDir
    snWriter = $snWriter
    apDatabase = $databases.apDatabase
    mdDatabase = $databases.mdDatabase
    detectedDevices = $devices
    ok = [bool]($snWriter -and $databases.apDatabase -and $databases.mdDatabase)
    warnings = $warnings
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "OPPO F1s NVRAM/IMEI repair readiness"
Write-Host "Firmware dir : $($result.firmwareDir)"
Write-Host "SN Writer    : $($result.snWriter)"
Write-Host "AP database  : $($result.apDatabase)"
Write-Host "MD database  : $($result.mdDatabase)"

if ($devices.Count -gt 0) {
    Write-Host ""
    Write-Host "Detected related USB devices:"
    $devices | Format-Table -AutoSize
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    $warnings | ForEach-Object { Write-Warning $_ }
}

Write-Host ""
if ($result.ok) {
    Write-Host "NVRAM repair tool status: READY"
    exit 0
}

Write-Host "NVRAM repair tool status: NOT READY"
exit 1
