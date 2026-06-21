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

$hasMtkPreloader = @($usbDevices | Where-Object { $_.FriendlyName -match "MediaTek|MTK|Preloader|VCOM|CDC" -or $_.InstanceId -match "VID_0E8D" }).Count -gt 0
$hasOppoMtp = @($usbDevices | Where-Object { $_.FriendlyName -match "OPPO A1601|OPPO|USB Mass Storage|Remote NDIS" -or $_.InstanceId -match "VID_22D9" }).Count -gt 0
$adbVisible = ($adbDevices.output -split "`r?`n" | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices|daemon" }).Count -gt 0
$fastbootVisible = $fastbootDevices.exitCode -eq 0 -and (($fastbootDevices.output -split "`r?`n" | Where-Object { $_ -match "^\S+\s+fastboot\b" }).Count -gt 0)

$nextAction = if (-not $firmware.ok) {
    "Fix firmware validation errors before flashing. This package is not a loose SP Flash scatter package if OFP/DownloadTool is reported."
}
elseif (-not $flashTool) {
    "Extract SP Flash Tool v6, SP Flash Tool v5, or SP MDT under tools. DownloadTool.exe is intentionally excluded."
}
elseif ($driverInfs.Count -eq 0) {
    "Install/extract MTK USB/VCOM drivers under drivers\mtk-usb."
}
elseif ($hasMtkPreloader) {
    "Preloader/VCOM mode is visible. Open the guided flasher and use Download Only."
}
elseif ($hasOppoMtp) {
    "Phone is in normal USB/MTP/RNDIS mode. Power off, hold both volume keys, and reconnect for preloader mode only after firmware validation passes."
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
    oppoNormalUsbVisible = $hasOppoMtp
    usbDevices = $usbDevices
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
Write-Host "Normal OPPO USB/MTP  : $($result.oppoNormalUsbVisible)"
if ($result.firmwareRejectReasons.Count -gt 0) { Write-Host ""; $result.firmwareRejectReasons | ForEach-Object { Write-Warning $_ } }
if ($usbDevices.Count -gt 0) { Write-Host ""; $usbDevices | Format-Table -AutoSize }
Write-Host ""
Write-Host "Next action: $nextAction"
