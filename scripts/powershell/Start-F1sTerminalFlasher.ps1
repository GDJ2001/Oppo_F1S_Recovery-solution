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

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cli = Join-Path $repoRoot "src\cli\f1s-flasher.ps1"

$args = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $cli,
    "-Command", $Command,
    "-FirmwareDir", $FirmwareDir,
    "-CountdownSeconds", "$CountdownSeconds",
    "-MonitorSeconds", "$MonitorSeconds"
)
if ($NoLaunch) { $args += "-NoLaunch" }
if ($NoPrompt) { $args += "-NoPrompt" }

& powershell.exe @args
exit $LASTEXITCODE
