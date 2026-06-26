param(
    [string]$FirmwareDir = "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331",
    [string]$FlashToolPath = "",
    [int]$CountdownSeconds = 20,
    [int]$MonitorSeconds = 120,
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

    $namePattern = "^(flash_tool|flash_tool_console|SPFlashTool|SPFlashToolV6|SP_MDT|mdt|SPMultiPortDownload|SP_MultiportDownload|SPMultiPortFlashDownloadProject)\.exe$"
    @(Get-ChildItem -LiteralPath $toolsRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $namePattern -and $_.FullName -notmatch "DownloadTool\.exe$" } |
        ForEach-Object {
            $kind = if ($_.Name -match "flash_tool|SPFlashTool") { "SP Flash Tool" } else { "SP MDT" }
            $rank = if ($_.FullName -match "sp-flash-tool|SP_Flash_Tool_v5|v5") { 1 } elseif ($_.FullName -match "SP_Flash_Tool_V6|v6") { 2 } elseif ($kind -eq "SP Flash Tool") { 3 } else { 4 }
            [pscustomobject]@{ Path = $_.FullName; Kind = $kind; Rank = $rank }
        } | Sort-Object Rank, Path)
}

function Get-RelatedDeviceSnapshot {
    $pnp = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "OPPO|MediaTek|MTK|Preloader|PreLoader|VCOM|CDC|MT65|Android|ADB|Fastboot|BROM|BootROM|USB Port" -or
            $_.PNPDeviceID -match "VID_22D9|VID_0E8D|VID_18D1"
        } |
        Select-Object Name, Status, ConfigManagerErrorCode, PNPDeviceID, Service)

    $ports = @(Get-CimInstance Win32_SerialPort -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "OPPO|MediaTek|MTK|Preloader|PreLoader|VCOM|CDC|USB|BROM|BootROM" -or
            $_.PNPDeviceID -match "VID_22D9|VID_0E8D"
        } |
        Select-Object DeviceID, Name, PNPDeviceID, Status)

    [pscustomobject]@{
        devices = $pnp
        ports = $ports
    }
}

function Get-HardRecoveryKind {
    param($Snapshot)

    $devices = @($Snapshot.devices)
    $ports = @($Snapshot.ports)

    $problem = @($devices | Where-Object { $_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne 0 })
    if ($problem.Count -gt 0) { return "driver-error" }

    if (@($devices | Where-Object { $_.PNPDeviceID -match "VID_0E8D&PID_0003" -or $_.Name -match "BROM|BootROM|MTK USB Port" }).Count -gt 0) {
        return "brom-ready"
    }

    if (@($devices | Where-Object { $_.PNPDeviceID -match "VID_0E8D&PID_2000|VID_0E8D&PID_2001|VID_22D9&PID_0006|VID_22D9&PID_2000" -or $_.Name -match "Preloader|PreLoader|VCOM|MediaTek|MTK|CDC" }).Count -gt 0 -or $ports.Count -gt 0) {
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
        [string]$LogPath,
        [string]$JsonlPath
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
    [pscustomobject]@{
        timestamp = $timestamp
        state = $Kind
        devices = $Snapshot.devices
        ports = $Snapshot.ports
    } | ConvertTo-Json -Depth 6 -Compress | Add-Content -LiteralPath $JsonlPath
}

$repoRoot = Resolve-RepoRoot
if (-not [IO.Path]::IsPathRooted($FirmwareDir)) {
    $FirmwareDir = Join-Path $repoRoot $FirmwareDir
}

$validator = Join-Path $PSScriptRoot "Test-F1sFirmwarePackage.ps1"
$logsDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $logsDir ("f1s-hard-recovery-{0}.log" -f $stamp)
$jsonlPath = Join-Path $logsDir ("f1s-hard-recovery-{0}.jsonl" -f $stamp)

Write-Host "OPPO F1s hard-recovery session"
Write-Host "Firmware: $FirmwareDir"
Write-Host "Log     : $logPath"
Write-Host "JSONL   : $jsonlPath"
Write-Host ""

$validation = (& $validator -FirmwareDir $FirmwareDir -Json | ConvertFrom-Json)
if (-not $validation.ok) {
    $validation.rejectedReasons | ForEach-Object { Write-Warning $_ }
    throw "Firmware validation failed. Refusing to continue with hard recovery."
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
Write-Warning "Hard recovery can make the phone permanently unrecoverable if the wrong preloader or partition map is used."
Write-Warning "Use Download Only first when the tool allows it. Do not use Format All + Download as a default."
Write-Warning "Only consider checking preloader after confirming the scatter/preloader family matches A1601 MT6750/oppo6750_15131 or oppo6750_15331 and the phone is truly hard-bricked."
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
Write-Host "Hard-brick attach order:"
Write-Host "  1. Disconnect the phone."
Write-Host "  2. Hold Power for 20 seconds, then leave it disconnected for 10 seconds."
Write-Host "  3. In the flasher, load the scatter and choose the least destructive download mode available."
Write-Host "  4. Click Download/Start in the flasher."
Write-Host "  5. Connect USB with no buttons first."
Write-Host "  6. If nothing appears, retry only Volume Up, then only Volume Down."
Write-Host "  7. Do not hold both volume buttons; that enters ColorOS Recovery on this phone."
Write-Host ""

if (-not $NoPrompt) {
    Read-Host "Set the flasher now, click Download/Start, then press Enter here to begin the hard-recovery monitor"
}

if (-not $NoCountdown) {
    for ($i = $CountdownSeconds; $i -ge 1; $i--) {
        Write-Progress -Activity "Prepare to attach hard-bricked phone" -Status "$i seconds remaining" -PercentComplete ((($CountdownSeconds - $i) / [Math]::Max($CountdownSeconds, 1)) * 100)
        Write-Host ("Attach phone in {0,2}..." -f $i)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Activity "Prepare to attach hard-bricked phone" -Completed
}

Write-Host ""
Write-Host "Monitoring BROM/Preloader/DA state for $MonitorSeconds seconds..."
$lastSignature = ""
$lastKindNotice = ""
$deadline = (Get-Date).AddSeconds($MonitorSeconds)
$ready = $false
$driverError = $false

while ((Get-Date) -lt $deadline) {
    $snapshot = Get-RelatedDeviceSnapshot
    $kind = Get-HardRecoveryKind -Snapshot $snapshot
    $signature = ($snapshot | ConvertTo-Json -Depth 5 -Compress)

    if ($signature -ne $lastSignature) {
        Write-Snapshot -Snapshot $snapshot -Kind $kind -LogPath $logPath -JsonlPath $jsonlPath
        $lastSignature = $signature
    }

    if ($kind -eq "brom-ready") {
        [console]::Beep(1400, 350)
        Write-Host ""
        Write-Host "BROM READY: MediaTek BootROM is visible. Proceed only if the flasher has already accepted the scatter and mode."
        $ready = $true
        break
    }
    elseif ($kind -eq "preloader-ready") {
        [console]::Beep(1200, 350)
        Write-Host ""
        Write-Host "PRELOADER READY: MediaTek/OPPO Preloader/VCOM is visible. Proceed in the flasher while it is visible."
        $ready = $true
        break
    }
    elseif ($kind -eq "driver-error") {
        [console]::Beep(400, 500)
        Write-Host ""
        Write-Warning "A matching USB device appeared, but Windows reports a driver/problem code. Stop and fix the driver."
        $driverError = $true
        break
    }
    elseif ($kind -eq "normal-oppo-usb" -or $kind -eq "recovery-adb-fastboot") {
        if ($kind -ne $lastKindNotice) {
            Write-Host ("Device visible as {0}; this is not a hard-recovery flash state." -f $kind)
            $lastKindNotice = $kind
        }
    }

    Start-Sleep -Milliseconds 250
}

Write-Host ""
Write-Host "Log written to : $logPath"
Write-Host "JSONL written to: $jsonlPath"
if ($ready) { exit 0 }
if ($driverError) { exit 2 }

Write-Warning "No BROM/Preloader/DA device was detected in the monitor window."
exit 1
