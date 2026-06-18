param(
    [string]$FirmwareDir = "",
    [string]$SnWriteToolDir = "",
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

$readinessScript = Join-Path $PSScriptRoot "Get-NvramRepairReadiness.ps1"
$readinessParams = @{ Json = $true }
if (-not [string]::IsNullOrWhiteSpace($FirmwareDir)) {
    $readinessParams.FirmwareDir = $FirmwareDir
}
if (-not [string]::IsNullOrWhiteSpace($SnWriteToolDir)) {
    $readinessParams.SnWriteToolDir = $SnWriteToolDir
}

$readiness = (& $readinessScript @readinessParams | ConvertFrom-Json)

Write-Host "SN Writer    : $($readiness.snWriter)"
Write-Host "AP database  : $($readiness.apDatabase)"
Write-Host "MD database  : $($readiness.mdDatabase)"
Write-Host ""
Write-Warning "Enter only the phone's original IMEI from the box/sticker/paperwork. Do not generate or substitute identifiers."
Write-Warning "SN_Writer.exe from this mirror is not Authenticode-signed. Use it only if you accept that trust boundary."

if (-not $readiness.snWriter) {
    throw "SN_Writer.exe was not found."
}
if (-not $readiness.apDatabase -or -not $readiness.mdDatabase) {
    throw "Required AP/MD database files were not found in the firmware directory."
}

$clip = @"
AP database:
$($readiness.apDatabase)

MD database:
$($readiness.mdDatabase)
"@
Set-Clipboard -Value $clip
Write-Host ""
Write-Host "The AP/MD database paths have been copied to the clipboard."

if ($ValidateOnly) {
    exit 0
}

Start-Process -FilePath $readiness.snWriter -WorkingDirectory (Split-Path -Parent $readiness.snWriter)
