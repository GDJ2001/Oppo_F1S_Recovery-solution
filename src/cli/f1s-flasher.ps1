param(
    [ValidateSet("status", "prepare", "flash", "monitor", "hard", "snwrite")]
    [string]$Command = "status",
    [string]$FirmwareDir = "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331",
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

function Get-PreferredFlashToolPath {
    $root = Join-Path $script:RepoRoot "tools\sp-flash-tool"
    if (-not (Test-Path -LiteralPath $root)) {
        return ""
    }

    $candidate = Get-ChildItem -LiteralPath $root -Recurse -File -Filter "flash_tool.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($candidate) { return $candidate.FullName }
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

$preferredFlashTool = Get-PreferredFlashToolPath

switch ($Command) {
    "status" {
        Write-Header "Flashing Readiness"
        Invoke-RepoScript -ScriptName "Get-FlashingReadiness.ps1" -Parameters @{ FirmwareDir = $firmwarePath }

        Write-Header "NVRAM/IMEI Repair Readiness"
        Invoke-RepoScript -ScriptName "Get-NvramRepairReadiness.ps1" -Parameters @{ FirmwareDir = $firmwarePath }
    }

    "prepare" {
        Write-Header "Firmware Validation"
        Invoke-RepoScript -ScriptName "Test-F1sFirmwarePackage.ps1" -Parameters @{ FirmwareDir = $firmwarePath }

        Write-Header "Tool Runtime"
        if ($preferredFlashTool) {
            Write-Host "Using SP Flash Tool runtime:"
            Write-Host $preferredFlashTool
        }
        else {
            Write-Warning "SP Flash Tool v5 was not found under tools\sp-flash-tool."
        }

        Write-Header "Driver And Device State"
        Invoke-RepoScript -ScriptName "Get-FlashingReadiness.ps1" -Parameters @{ FirmwareDir = $firmwarePath }
    }

    "flash" {
        $params = @{
            FirmwareDir = $firmwarePath
            CountdownSeconds = $CountdownSeconds
            MonitorSeconds = $MonitorSeconds
        }
        if ($preferredFlashTool) { $params.FlashToolPath = $preferredFlashTool }
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
        if ($preferredFlashTool) { $params.FlashToolPath = $preferredFlashTool }

        Invoke-RepoScript -ScriptName "Start-F1sGuidedFlashSession.ps1" -Parameters $params
    }

    "hard" {
        $params = @{
            FirmwareDir = $firmwarePath
            CountdownSeconds = $CountdownSeconds
            MonitorSeconds = $MonitorSeconds
        }
        if ($preferredFlashTool) { $params.FlashToolPath = $preferredFlashTool }
        if ($NoLaunch) { $params.NoLaunch = $true }
        if ($NoPrompt) { $params.NoPrompt = $true }

        Invoke-RepoScript -ScriptName "Start-F1sHardRecoverySession.ps1" -Parameters $params
    }

    "snwrite" {
        Invoke-RepoScript -ScriptName "Start-SnWriteTool.ps1" -Parameters @{ FirmwareDir = $firmwarePath }
    }
}
