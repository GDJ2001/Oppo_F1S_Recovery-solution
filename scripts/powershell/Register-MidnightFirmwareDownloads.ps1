[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TaskName = "OppoF1sFirmwareDownloads",
    [datetime]$At,
    [string]$ManifestPath = "firmware\download-manifest.json"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
$downloadScript = Join-Path $repoRoot "scripts\powershell\Invoke-FirmwareDownloads.ps1"
$manifestFullPath = Join-Path $repoRoot $ManifestPath

if (-not (Test-Path -LiteralPath $downloadScript -PathType Leaf)) {
    throw "Downloader script not found: $downloadScript"
}

if (-not (Test-Path -LiteralPath $manifestFullPath -PathType Leaf)) {
    throw "Manifest not found: $manifestFullPath"
}

if (-not $PSBoundParameters.ContainsKey("At")) {
    $At = (Get-Date).Date.AddDays(1)
}

if ($At -le (Get-Date)) {
    throw "Scheduled time must be in the future. Requested: $At"
}

$argument = "-NoProfile -ExecutionPolicy Bypass -File `"$downloadScript`" -ManifestPath `"$manifestFullPath`" -IncludeManual"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument -WorkingDirectory $repoRoot
$trigger = New-ScheduledTaskTrigger -Once -At $At
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew

if ($PSCmdlet.ShouldProcess($TaskName, "Register firmware download task for $At")) {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Sequential OPPO F1s A1601 firmware redownload with checksum validation." -Force | Out-Null
    Write-Host ("Registered task '{0}' for {1}" -f $TaskName, $At)
    Write-Host ("Command: powershell.exe {0}" -f $argument)
}
