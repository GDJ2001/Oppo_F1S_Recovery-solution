param(
    [string]$FirmwareDir = "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331",
    [string]$FlashToolPath = "",
    [int]$CountdownSeconds = 20,
    [int]$MonitorSeconds = 90,
    [switch]$NoLaunch,
    [switch]$NoCountdown,
    [switch]$NoPrompt
)

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

    $namePattern = "^(flash_tool|flash_tool_console)\.exe$"
    @(Get-ChildItem -LiteralPath $toolsRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $namePattern -and $_.FullName -notmatch "DownloadTool\.exe$" } |
        ForEach-Object {
            $kind = if ($_.Name -match "flash_tool|SPFlashTool") { "SP Flash Tool" } else { "SP MDT" }
            $rank = if ($_.FullName -match "SP_Flash_Tool_V6|v6") { 1 } elseif ($_.FullName -match "v5|sp-flash-tool") { 2 } elseif ($kind -eq "SP Flash Tool") { 3 } else { 4 }
            [pscustomobject]@{ Path = $_.FullName; Kind = $kind; Rank = $rank }
        } | Sort-Object Rank, Path)
}

function Get-RelatedDeviceSnapshot {
    $pnp = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "OPPO|MediaTek|MTK|Preloader|PreLoader|VCOM|CDC|MT65|Android|ADB|Fastboot" -or
            $_.PNPDeviceID -match "VID_22D9|VID_0E8D|VID_18D1"
        } |
        Select-Object Name, Status, ConfigManagerErrorCode, PNPDeviceID, Service)

    $ports = @(Get-CimInstance Win32_SerialPort -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "OPPO|MediaTek|MTK|Preloader|PreLoader|VCOM|CDC|USB" -or
            $_.PNPDeviceID -match "VID_22D9|VID_0E8D"
        } |
        Select-Object DeviceID, Name, PNPDeviceID, Status)

    [pscustomobject]@{
        devices = $pnp
        ports = $ports
    }
}

function Get-DeviceKind {
    param($Snapshot)

    $devices = @($Snapshot.devices)
    $ports = @($Snapshot.ports)

    $preloaderDevices = @($devices | Where-Object { $_.PNPDeviceID -match "VID_22D9&PID_0006|VID_22D9&PID_2000|VID_0E8D&PID_2000|VID_0E8D&PID_0003" -or $_.Name -match "Preloader|PreLoader|VCOM|MediaTek|MTK|CDC" })
    if ($preloaderDevices.Count -gt 0 -or $ports.Count -gt 0) {
        $problem = @($preloaderDevices | Where-Object { $_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne 0 })
        if ($problem.Count -gt 0) { return "preloader-driver-error" }
        return "preloader-ready"
    }

    if (@($devices | Where-Object { $_.Name -match "Recovery|ADB|Android|Fastboot" -or $_.PNPDeviceID -match "VID_18D1" }).Count -gt 0) {
        return "recovery-adb-fastboot"
    }

    if (@($devices | Where-Object { $_.Name -match "MTP|OPPO|USB Mass Storage|Remote NDIS" -or $_.PNPDeviceID -match "VID_22D9" }).Count -gt 0) {
        return "normal-oppo-usb"
    }

    return "none"
}

function Write-Snapshot {
    param(
        $Snapshot,
        [string]$Kind,
        [string]$LogPath
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $lines = @()
    $lines += "[$timestamp] State: $Kind"

    foreach ($device in @($Snapshot.devices)) {
        $lines += "  Device: $($device.Name) | Status=$($device.Status) | Problem=$($device.ConfigManagerErrorCode) | Service=$($device.Service) | $($device.PNPDeviceID)"
    }
    foreach ($port in @($Snapshot.ports)) {
        $lines += "  Port:   $($port.DeviceID) | $($port.Name) | Status=$($port.Status) | $($port.PNPDeviceID)"
    }
    if ($Snapshot.devices.Count -eq 0 -and $Snapshot.ports.Count -eq 0) {
        $lines += "  No OPPO/MediaTek/Android USB device visible."
    }

    $lines | Tee-Object -FilePath $LogPath -Append
}

$repoRoot = Resolve-RepoRoot
if (-not [IO.Path]::IsPathRooted($FirmwareDir)) {
    $FirmwareDir = Join-Path $repoRoot $FirmwareDir
}

$validator = Join-Path $PSScriptRoot "Test-F1sFirmwarePackage.ps1"
$logsDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$logPath = Join-Path $logsDir ("f1s-guided-flash-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

Write-Host "OPPO F1s guided flash session"
Write-Host "Firmware: $FirmwareDir"
Write-Host "Log     : $logPath"
Write-Host ""

$validation = (& $validator -FirmwareDir $FirmwareDir -Json | ConvertFrom-Json)
if (-not $validation.ok) {
    $validation.rejectedReasons | ForEach-Object { Write-Warning $_ }
    throw "Firmware validation failed. Refusing to launch flasher."
}

if ([string]::IsNullOrWhiteSpace($FlashToolPath)) {
    $candidate = Find-FlashingTools -RepoRoot $repoRoot | Select-Object -First 1
    if ($candidate) { $FlashToolPath = $candidate.Path }
}
if ([string]::IsNullOrWhiteSpace($FlashToolPath) -or -not (Test-Path -LiteralPath $FlashToolPath)) {
    throw "No SP Flash Tool or SP MDT executable found under tools. DownloadTool.exe is not supported."
}

Set-Clipboard -Value $validation.scatterPath
Write-Host "Scatter path copied to clipboard:"
Write-Host $validation.scatterPath
Write-Host ""
Write-Warning "Use Download Only/normal download. Do not use Format All + Download."
Write-Warning "Leave preloader unchecked unless exact A1601 hardware is confirmed and the phone is hard-bricked."
Write-Host ""

if (-not $NoLaunch) {
    $existing = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $FlashToolPath } | Select-Object -First 1
    if (-not $existing) {
        Start-Process -FilePath $FlashToolPath -WorkingDirectory (Split-Path -Parent $FlashToolPath)
        Write-Host "Launched flasher: $FlashToolPath"
    }
    else {
        Write-Host "Flasher already running: $FlashToolPath"
    }
}

Write-Host ""
Write-Host "In the flasher, load/paste the scatter path if needed, set Download Only, and click Start/Download."
Write-Host "When the countdown begins, connect the phone powered off. Do not enter ColorOS Recovery."
Write-Host "If no detection occurs, retry with only Volume Up, then only Volume Down."
Write-Host ""

if (-not $NoPrompt) {
    Read-Host "Set the flasher to Download Only, press Start/Download in the flasher, then press Enter here to start the countdown"
}

if (-not $NoCountdown) {
    for ($i = $CountdownSeconds; $i -ge 1; $i--) {
        Write-Progress -Activity "Attach powered-off phone for preloader detection" -Status "$i seconds remaining" -PercentComplete ((($CountdownSeconds - $i) / [Math]::Max($CountdownSeconds, 1)) * 100)
        Write-Host ("Attach phone in {0,2}..." -f $i)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Activity "Attach powered-off phone for preloader detection" -Completed
}

Write-Host ""
Write-Host "Monitoring OPPO/MediaTek USB state for $MonitorSeconds seconds..."
$lastSignature = ""
$deadline = (Get-Date).AddSeconds($MonitorSeconds)
$ready = $false
$driverError = $false
$lastKindNotice = ""

while ((Get-Date) -lt $deadline) {
    $snapshot = Get-RelatedDeviceSnapshot
    $kind = Get-DeviceKind -Snapshot $snapshot
    $signature = ($snapshot | ConvertTo-Json -Depth 5 -Compress)

    if ($signature -ne $lastSignature) {
        Write-Snapshot -Snapshot $snapshot -Kind $kind -LogPath $logPath
        $lastSignature = $signature
    }

    if ($kind -eq "preloader-ready") {
        [console]::Beep(1200, 350)
        Write-Host ""
        Write-Host "PRELOADER READY: a MediaTek/OPPO preloader/VCOM device is visible without driver error."
        Write-Host "Proceed in the flasher while this device is visible."
        $ready = $true
        break
    }
    elseif ($kind -eq "preloader-driver-error") {
        [console]::Beep(400, 500)
        Write-Host ""
        Write-Warning "Preloader appeared, but Windows reports a driver/problem code. Do not flash yet."
        $driverError = $true
        break
    }
    elseif ($kind -eq "normal-oppo-usb" -or $kind -eq "recovery-adb-fastboot") {
        if ($kind -ne $lastKindNotice) {
            Write-Host ("Device visible as {0}; this is not flash-ready for SP MDT." -f $kind)
            $lastKindNotice = $kind
        }
    }

    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "Log written to: $logPath"
if ($ready) { exit 0 }
if ($driverError) { exit 2 }

Write-Warning "No clean preloader/VCOM device was detected in the monitor window."
exit 1
