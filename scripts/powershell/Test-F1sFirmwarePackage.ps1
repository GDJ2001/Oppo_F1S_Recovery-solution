param(
    [string]$FirmwareDir = "",
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
        Select-Object -First 1

    if (-not $scatter) {
        return $null
    }

    return $scatter.Directory.FullName
}

function Read-ScatterDownloads {
    param([string]$ScatterPath)

    $partitions = @()
    $current = [ordered]@{}

    foreach ($line in Get-Content -LiteralPath $ScatterPath) {
        if ($line -match "^\s*-\s*partition_index:") {
            if ($current.Count -gt 0) {
                $partitions += [pscustomobject]$current
            }
            $current = [ordered]@{}
            continue
        }

        if ($line -match "^\s*partition_name:\s*(.+?)\s*$") {
            $current.partition_name = $Matches[1]
            continue
        }

        if ($line -match "^\s*file_name:\s*(.+?)\s*$") {
            $current.file_name = $Matches[1]
            continue
        }

        if ($line -match "^\s*is_download:\s*(true|false)\s*$") {
            $current.is_download = [System.Convert]::ToBoolean($Matches[1])
            continue
        }
    }

    if ($current.Count -gt 0) {
        $partitions += [pscustomobject]$current
    }

    return $partitions | Where-Object { $_.is_download -eq $true -and $_.file_name -and $_.file_name -ne "NONE" }
}

function Get-MtkUsbDevices {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FriendlyName -match "OPPO|Android|ADB|Fastboot|MediaTek|MTK|Preloader|VCOM|CDC" -or
            $_.InstanceId -match "VID_0E8D|VID_22D9|VID_18D1"
        } |
        Select-Object Status, Class, FriendlyName, InstanceId
}

$repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($FirmwareDir)) {
    $FirmwareDir = Find-DefaultFirmwareDir -RepoRoot $repoRoot
}

$result = [ordered]@{
    repositoryRoot = $repoRoot
    firmwareDir = $FirmwareDir
    scatterPath = $null
    ok = $false
    missingFiles = @()
    downloadablePartitions = @()
    detectedDevices = @()
    warnings = @()
}

if ([string]::IsNullOrWhiteSpace($FirmwareDir) -or -not (Test-Path -LiteralPath $FirmwareDir)) {
    $result.warnings += "Firmware directory was not found. Extract the stock firmware under firmware\stock first."
}
else {
    $scatterPath = Join-Path $FirmwareDir "MT6750_Android_scatter.txt"
    $result.scatterPath = $scatterPath

    if (-not (Test-Path -LiteralPath $scatterPath)) {
        $result.warnings += "Scatter file not found: $scatterPath"
    }
    else {
        $downloads = @(Read-ScatterDownloads -ScatterPath $scatterPath)
        $result.downloadablePartitions = @($downloads | ForEach-Object {
            [pscustomobject]@{
                partition = $_.partition_name
                file = $_.file_name
            }
        })

        foreach ($entry in $downloads) {
            $imagePath = Join-Path $FirmwareDir $entry.file_name
            if (-not (Test-Path -LiteralPath $imagePath)) {
                $result.missingFiles += $entry.file_name
            }
        }

        if ($downloads.partition_name -contains "preloader") {
            $result.warnings += "Scatter includes preloader. Only flash it when the firmware exactly matches the A1601 variant."
        }

        if ($downloads.partition_name -contains "userdata") {
            $result.warnings += "Scatter includes userdata. Flashing userdata wipes phone data."
        }
    }
}

$result.detectedDevices = @(Get-MtkUsbDevices)
$hasPreloader = @($result.detectedDevices | Where-Object {
    $_.FriendlyName -match "MediaTek|MTK|Preloader|VCOM|CDC" -or $_.InstanceId -match "VID_0E8D"
}).Count -gt 0

if (-not $hasPreloader) {
    $result.warnings += "No MediaTek preloader/VCOM flashing device is currently visible. Power the phone off and connect it while holding the proper key combo after installing MTK drivers."
}

$result.ok = (
    $result.scatterPath -and
    (Test-Path -LiteralPath $result.scatterPath) -and
    @($result.missingFiles).Count -eq 0
)

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "OPPO F1s firmware package check"
Write-Host "Repository : $($result.repositoryRoot)"
Write-Host "Firmware   : $($result.firmwareDir)"
Write-Host "Scatter    : $($result.scatterPath)"
Write-Host ""

if ($result.downloadablePartitions.Count -gt 0) {
    Write-Host "Downloadable partitions:"
    $result.downloadablePartitions | Format-Table -AutoSize
}

if ($result.missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Warning "Missing files referenced by scatter:"
    $result.missingFiles | ForEach-Object { Write-Warning "  $_" }
}

if ($result.detectedDevices.Count -gt 0) {
    Write-Host ""
    Write-Host "Detected related USB devices:"
    $result.detectedDevices | Format-Table -AutoSize
}

if ($result.warnings.Count -gt 0) {
    Write-Host ""
    $result.warnings | ForEach-Object { Write-Warning $_ }
}

Write-Host ""
if ($result.ok) {
    Write-Host "Package status: OK"
    exit 0
}

Write-Host "Package status: NOT READY"
exit 1
