param(
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Find-FirstFile {
    param(
        [string]$Root,
        [string]$Filter
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        return $null
    }

    return Get-ChildItem -LiteralPath $Root -Recurse -File -Filter $Filter -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Invoke-Capture {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return @{
            exitCode = $null
            output = "Not found: $FilePath"
        }
    }

    $output = & $FilePath @Arguments 2>&1
    return @{
        exitCode = $LASTEXITCODE
        output = ($output -join [Environment]::NewLine)
    }
}

$repoRoot = Resolve-RepoRoot
$validator = Join-Path $PSScriptRoot "Test-F1sFirmwarePackage.ps1"
$adb = Join-Path $repoRoot "tools\adb-fastboot\platform-tools\adb.exe"
$fastboot = Join-Path $repoRoot "tools\adb-fastboot\platform-tools\fastboot.exe"
$flashTool = Find-FirstFile -Root (Join-Path $repoRoot "tools\sp-flash-tool") -Filter "flash_tool.exe"
$driverInfs = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot "drivers\mtk-usb") -Recurse -File -Filter "*.inf" -ErrorAction SilentlyContinue)

$firmware = & $validator -Json | ConvertFrom-Json
$adbDevices = Invoke-Capture -FilePath $adb -Arguments @("devices", "-l")
$fastbootDevices = Invoke-Capture -FilePath $fastboot -Arguments @("devices", "-l")
$usbDevices = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FriendlyName -match "OPPO|Android|ADB|Fastboot|MediaTek|MTK|Preloader|VCOM|CDC" -or
        $_.InstanceId -match "VID_0E8D|VID_22D9|VID_18D1"
    } |
    Select-Object Status, Class, FriendlyName, InstanceId)

$hasMtkPreloader = @($usbDevices | Where-Object {
    $_.FriendlyName -match "MediaTek|MTK|Preloader|VCOM|CDC" -or $_.InstanceId -match "VID_0E8D"
}).Count -gt 0

$hasOppoMtp = @($usbDevices | Where-Object {
    $_.FriendlyName -match "OPPO A1601|OPPO|USB Mass Storage" -or $_.InstanceId -match "VID_22D9"
}).Count -gt 0

$adbVisible = ($adbDevices.output -split "`r?`n" | Where-Object {
    $_ -match "\bdevice\b" -and $_ -notmatch "List of devices"
}).Count -gt 0

$fastbootVisible = -not [string]::IsNullOrWhiteSpace($fastbootDevices.output)

$nextAction = if (-not $firmware.ok) {
    "Fix firmware package validation errors before flashing."
}
elseif (-not $flashTool) {
    "Download or extract SP Flash Tool under tools\sp-flash-tool."
}
elseif ($driverInfs.Count -eq 0) {
    "Download or extract MTK USB/VCOM drivers under drivers\mtk-usb."
}
elseif ($hasMtkPreloader) {
    "Preloader/VCOM mode is visible. Open SP Flash Tool and use Download Only after reviewing selected partitions."
}
elseif ($hasOppoMtp) {
    "Phone is in normal USB/MTP mode. Install MTK drivers if needed, power off the phone, then reconnect it in preloader mode."
}
else {
    "No matching OPPO/MTK USB device is visible. Connect the phone or check the USB cable/driver state."
}

$result = [ordered]@{
    firmwareOk = [bool]$firmware.ok
    scatterPath = $firmware.scatterPath
    spFlashTool = if ($flashTool) { $flashTool.FullName } else { $null }
    adbPath = $adb
    fastbootPath = $fastboot
    mtkDriverInfCount = $driverInfs.Count
    adbVisible = $adbVisible
    fastbootVisible = $fastbootVisible
    mtkPreloaderVisible = $hasMtkPreloader
    oppoNormalUsbVisible = $hasOppoMtp
    usbDevices = $usbDevices
    nextAction = $nextAction
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "OPPO F1s flashing readiness"
Write-Host "Firmware OK          : $($result.firmwareOk)"
Write-Host "Scatter              : $($result.scatterPath)"
Write-Host "SP Flash Tool        : $($result.spFlashTool)"
Write-Host "MTK driver INF files : $($result.mtkDriverInfCount)"
Write-Host "ADB visible          : $($result.adbVisible)"
Write-Host "Fastboot visible     : $($result.fastbootVisible)"
Write-Host "Preloader/VCOM       : $($result.mtkPreloaderVisible)"
Write-Host "Normal OPPO USB/MTP  : $($result.oppoNormalUsbVisible)"

if ($usbDevices.Count -gt 0) {
    Write-Host ""
    Write-Host "Matching USB devices:"
    $usbDevices | Format-Table -AutoSize
}

Write-Host ""
Write-Host "Next action: $nextAction"
