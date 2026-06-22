param(
    [ValidateSet("status", "prepare", "flash", "monitor", "snwrite")]
    [string]$Command = "status",
    [string]$FirmwareDir = "firmware\stock\A1601EX_11_A24_161119\Firmware",
    [int]$CountdownSeconds = 20,
    [int]$MonitorSeconds = 90,
    [switch]$NoLaunch,
    [switch]$NoPrompt
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Invoke-RepoScript {
    param(
        [string]$ScriptName,
        [hashtable]$Parameters = @{}
    )

    $scriptPath = Join-Path $script:RepoRoot "scripts\powershell\$ScriptName"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Script not found: $scriptPath"
    }

    $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath)
    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]
        if ($value -is [bool]) {
            if ($value) { $args += "-$key" }
        }
        else {
            $args += "-$key"
            $args += "$value"
        }
    }

    & powershell.exe @args
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        exit $exitCode
    }
}

function Get-UnpackedMdtPath {
    $path = Join-Path $script:RepoRoot "tools\SP_MDT_v6.2228.00\SP_MDT Unpacked\mdt.exe"
    if (Test-Path -LiteralPath $path) { return $path }
    return ""
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "== $Text =="
}

$script:RepoRoot = Resolve-RepoRoot
Set-Location -LiteralPath $script:RepoRoot

$firmwarePath = $FirmwareDir
if (-not [IO.Path]::IsPathRooted($firmwarePath)) {
    $firmwarePath = Join-Path $script:RepoRoot $firmwarePath
}

$unpackedMdt = Get-UnpackedMdtPath

switch ($Command) {
    "status" {
        Write-Header "Flashing Readiness"
        Invoke-RepoScript -ScriptName "Get-FlashingReadiness.ps1"

        Write-Header "NVRAM/IMEI Repair Readiness"
        Invoke-RepoScript -ScriptName "Get-NvramRepairReadiness.ps1" -Parameters @{ FirmwareDir = $firmwarePath }
    }

    "prepare" {
        Write-Header "Firmware Validation"
        Invoke-RepoScript -ScriptName "Test-F1sFirmwarePackage.ps1" -Parameters @{ FirmwareDir = $firmwarePath }

        Write-Header "Tool Runtime"
        if ($unpackedMdt) {
            Write-Host "Using unpacked SP MDT runtime:"
            Write-Host $unpackedMdt
        }
        else {
            Write-Warning "Unpacked SP MDT runtime was not found. The existing tool discovery will pick another supported SP Flash/SP MDT executable."
        }

        Write-Header "Driver And Device State"
        Invoke-RepoScript -ScriptName "Get-FlashingReadiness.ps1"
    }

    "flash" {
        $params = @{
            FirmwareDir = $firmwarePath
            CountdownSeconds = $CountdownSeconds
            MonitorSeconds = $MonitorSeconds
        }
        if ($unpackedMdt) { $params.FlashToolPath = $unpackedMdt }
        if ($NoLaunch) { $params.NoLaunch = $true }
        if ($NoPrompt) { $params.NoPrompt = $true }

        Invoke-RepoScript -ScriptName "Start-F1sGuidedFlashSession.ps1" -Parameters $params
    }

    "monitor" {
        $params = @{
            FirmwareDir = $firmwarePath
            CountdownSeconds = 0
            MonitorSeconds = $MonitorSeconds
            NoLaunch = $true
            NoCountdown = $true
            NoPrompt = $true
        }
        if ($unpackedMdt) { $params.FlashToolPath = $unpackedMdt }

        Invoke-RepoScript -ScriptName "Start-F1sGuidedFlashSession.ps1" -Parameters $params
    }

    "snwrite" {
        Invoke-RepoScript -ScriptName "Start-SnWriteTool.ps1" -Parameters @{ FirmwareDir = $firmwarePath }
    }
}
