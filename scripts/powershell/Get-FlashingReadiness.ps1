param([switch]$Json)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -Scope Global -ErrorAction SilentlyContinue) {
    $Global:PSNativeCommandUseErrorActionPreference = $false
}

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Find-FlashingTools {
    param([string]$RepoRoot)
    $toolsRoot = Join-Path $RepoRoot "tools"
    if (-not (Test-Path -LiteralPath $toolsRoot)) { return @() }
    $namePattern = "^(flash_tool|flash_tool_console|SPFlashTool|SPFlashToolV6|SP_MDT|mdt|SPMultiPortDownload|SP_MultiportDownload|SPMultiPortFlashDownloadProject)\.exe$"
    @(Get-ChildItem -LiteralPath $toolsRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $namePattern -and $_.FullName -notmatch "DownloadTool\.exe$" } |
        ForEach-Object {
            $kind = if ($_.Name -match "flash_tool|SPFlashTool") { "SP Flash Tool" } else { "SP MDT" }
            $rank = if ($_.FullName -match "SP_Flash_Tool_V6|v6") { 1 } elseif ($_.FullName -match "v5|sp-flash-tool") { 2 } elseif ($kind -eq "SP Flash Tool") { 3 } else { 4 }
            [pscustomobject]@{ Path = $_.FullName; Kind = $kind; Rank = $rank }
        } | Sort-Object Rank, Path)
}

function Invoke-Capture {
    param([string]$FilePath, [string[]]$Arguments = @())
    if (-not (Test-Path -LiteralPath $FilePath)) { return @{ exitCode = $null; output = "Not found: $FilePath" } }
    try {
        $output = & $FilePath @Arguments 2>&1 | ForEach-Object { "$_" }
        return @{ exitCode = $LASTEXITCODE; output = ($output -join [Environment]::NewLine) }
    }
    catch { return @{ exitCode = $LASTEXITCODE; output = $_.Exception.Message } }
}

$repoRoot = Resolve-RepoRoot
$validator = Join-Path $PSScriptRoot "Test-F1sFirmwarePackage.ps1"
$adb = Join-Path $repoRoot "tools\adb-fastboot\platform-tools\adb.exe"
$fastboot = Join-Path $repoRoot "tools\adb-fastboot\platform-tools\fastboot.exe"
$flashTool = Find-FlashingTools -RepoRoot $repoRoot | Select-Object -First 1
$driverInfs = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot "drivers\mtk-usb") -Recurse -File -Filter "*.inf" -ErrorAction SilentlyContinue)
$firmware = & $validator -Json | ConvertFrom-Json
$adbDevices = Invoke-Capture -FilePath $adb -Arguments @("devices", "-l")
$fastbootDevices = Invoke-Capture -FilePath $fastboot -Arguments @("devices", "-l")
$usbDevices = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match "OPPO|Android|ADB|Fastboot|MediaTek|MTK|Preloader|VCOM|CDC" -or $_.InstanceId -match "VID_0E8D|VID_22D9|VID_18D1" } |
    Select-Object Status, Class, FriendlyName, InstanceId)

$preloaderDevices = @($usbDevices | Where-Object { $_.FriendlyName -match "MediaTek|MTK|Preloader|PreLoader|VCOM|CDC" -or $_.InstanceId -match "VID_0E8D|VID_22D9&PID_0006|VID_22D9&PID_2000" })
$problemDevices = @($preloaderDevices | Where-Object { $_.Status -and $_.Status -ne "OK" })
$problemUsbDevices = @($usbDevices | Where-Object { $_.Status -and $_.Status -ne "OK" })
$normalOppoDevices = @($usbDevices | Where-Object { $_.FriendlyName -match "OPPO A1601|OPPO|USB Mass Storage|Remote NDIS|MTP" -or $_.InstanceId -match "VID_22D9" })
$recoveryOrDebugDevices = @($usbDevices | Where-Object { $_.FriendlyName -match "Recovery|ADB|Android|Fastboot" -or $_.InstanceId -match "VID_18D1" })
$hasMtkPreloader = $preloaderDevices.Count -gt 0
$hasPreloaderDriverError = $problemDevices.Count -gt 0
$hasOppoMtp = $normalOppoDevices.Count -gt 0
$hasRecoveryOrDebug = $recoveryOrDebugDevices.Count -gt 0
$adbVisible = ($adbDevices.output -split "`r?`n" | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices|daemon" }).Count -gt 0
$fastbootVisible = $fastbootDevices.exitCode -eq 0 -and (($fastbootDevices.output -split "`r?`n" | Where-Object { $_ -match "^\S+\s+fastboot\b" }).Count -gt 0)

$deviceState = if ($hasMtkPreloader -and $hasPreloaderDriverError) {
    "preloader-driver-error"
}
elseif ($hasMtkPreloader) {
    "preloader-ready"
}
elseif ($adbVisible -or $fastbootVisible -or $hasRecoveryOrDebug) {
    "recovery-adb-fastboot"
}
elseif ($hasOppoMtp) {
    "normal-oppo-usb"
}
else {
    "no-device"
}

$nextAction = if (-not $firmware.ok) {
    "Fix firmware validation errors before flashing. This package is not a loose SP Flash scatter package if OFP/DownloadTool is reported."
}
elseif (-not $flashTool) {
    "Extract SP Flash Tool v6, SP Flash Tool v5, or SP MDT under tools. DownloadTool.exe is intentionally excluded."
}
elseif ($driverInfs.Count -eq 0) {
    "Install/extract MTK USB/VCOM drivers under drivers\mtk-usb."
}
elseif ($deviceState -eq "preloader-driver-error") {
    "Preloader/VCOM appeared, but Windows reports a driver/problem status. Fix the driver before flashing."
}
elseif ($deviceState -eq "preloader-ready") {
    "Preloader/VCOM mode is visible. Open the guided flasher and use Download Only."
}
elseif ($deviceState -eq "recovery-adb-fastboot") {
    "Phone is visible in recovery/ADB/Fastboot, which is not flash-ready for SP MDT. Power off fully, connect with no buttons first; if not detected, retry only Volume Up, then only Volume Down."
}
elseif ($deviceState -eq "normal-oppo-usb") {
    "Phone is in normal OPPO/Android USB mode, which is not flash-ready for SP MDT. Power off fully, connect with no buttons first; if not detected, retry only Volume Up, then only Volume Down."
}
else {
    "No matching OPPO/MTK USB device is visible."
}

$result = [ordered]@{
    firmwareOk = [bool]$firmware.ok
    firmwareRejectReasons = $firmware.rejectedReasons
    scatterPath = $firmware.scatterPath
    flashingTool = if ($flashTool) { $flashTool.Path } else { $null }
    flashingToolKind = if ($flashTool) { $flashTool.Kind } else { $null }
    mtkDriverInfCount = $driverInfs.Count
    adbVisible = $adbVisible
    fastbootVisible = $fastbootVisible
    mtkPreloaderVisible = $hasMtkPreloader
    preloaderDriverError = $hasPreloaderDriverError
    oppoNormalUsbVisible = $hasOppoMtp
    recoveryAdbFastbootVisible = $hasRecoveryOrDebug
    deviceState = $deviceState
    usbDevices = $usbDevices
    problemUsbDevices = $problemUsbDevices
    nextAction = $nextAction
}

if ($Json) { $result | ConvertTo-Json -Depth 6; exit 0 }
Write-Host "OPPO F1s flashing readiness"
Write-Host "Firmware OK          : $($result.firmwareOk)"
Write-Host "Scatter              : $($result.scatterPath)"
Write-Host "Flashing tool        : $($result.flashingTool)"
Write-Host "Flashing tool kind   : $($result.flashingToolKind)"
Write-Host "MTK driver INF files : $($result.mtkDriverInfCount)"
Write-Host "ADB visible          : $($result.adbVisible)"
Write-Host "Fastboot visible     : $($result.fastbootVisible)"
Write-Host "Preloader/VCOM       : $($result.mtkPreloaderVisible)"
Write-Host "Preloader error      : $($result.preloaderDriverError)"
Write-Host "Normal OPPO USB/MTP  : $($result.oppoNormalUsbVisible)"
Write-Host "Recovery/ADB/Fastboot: $($result.recoveryAdbFastbootVisible)"
Write-Host "Device state         : $($result.deviceState)"
if ($result.firmwareRejectReasons.Count -gt 0) { Write-Host ""; $result.firmwareRejectReasons | ForEach-Object { Write-Warning $_ } }
if ($usbDevices.Count -gt 0) { Write-Host ""; $usbDevices | Format-Table -AutoSize }
if ($problemUsbDevices.Count -gt 0) { Write-Host ""; $problemUsbDevices | ForEach-Object { Write-Warning "Windows reports a driver/problem status: $($_.FriendlyName) [$($_.Status)] $($_.InstanceId)" } }
Write-Host ""
Write-Host "Next action: $nextAction"
