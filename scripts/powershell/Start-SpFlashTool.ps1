param(
    [string]$FlashToolPath = "",
    [string]$FirmwareDir = "",
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

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
            $rank = if ($_.FullName -match "SP_Flash_Tool_V6|v6") { 1 } elseif ($_.FullName -match "sp-flash-tool|SP_Flash_Tool_v5|v5") { 2 } elseif ($kind -eq "SP Flash Tool") { 3 } else { 4 }
            [pscustomobject]@{ Path = $_.FullName; Kind = $kind; Rank = $rank }
        } | Sort-Object Rank, Path)
}

$repoRoot = Resolve-RepoRoot
$validator = Join-Path $PSScriptRoot "Test-F1sFirmwarePackage.ps1"
$validationArgs = @{}
if (-not [string]::IsNullOrWhiteSpace($FirmwareDir)) { $validationArgs.FirmwareDir = $FirmwareDir }

Write-Host "Validating firmware package..."
& $validator @validationArgs
if ($LASTEXITCODE -ne 0) { throw "Firmware validation failed. Use a complete loose scatter package before opening the flasher." }

$validationArgs.Json = $true
$validation = (& $validator @validationArgs | ConvertFrom-Json)
$scatterPath = $validation.scatterPath

if ([string]::IsNullOrWhiteSpace($FlashToolPath)) {
    $candidate = Find-FlashingTools -RepoRoot $repoRoot | Select-Object -First 1
    if ($candidate) { $FlashToolPath = $candidate.Path }
}
if ([string]::IsNullOrWhiteSpace($FlashToolPath) -or -not (Test-Path -LiteralPath $FlashToolPath)) {
    Write-Warning "No SP Flash Tool or SP MDT executable was found. DownloadTool.exe is intentionally not supported."
    Write-Host "Expected:"
    Write-Host "  $(Join-Path $repoRoot 'tools\SP_Flash_Tool_V6*\**\SPFlashToolV6.exe')"
    Write-Host "  $(Join-Path $repoRoot 'tools\sp-flash-tool\**\flash_tool.exe')"
    Write-Host "  $(Join-Path $repoRoot 'tools\SP_MDT*\**\mdt.exe')"
    exit 1
}

$toolName = Split-Path -Leaf $FlashToolPath
$toolKind = if ($toolName -match "flash_tool|SPFlashTool") { "SP Flash Tool" } else { "SP MDT" }
Set-Clipboard -Value $scatterPath
Write-Host "Flashing tool : $FlashToolPath"
Write-Host "Tool type     : $toolKind"
Write-Host "Scatter file  : $scatterPath"
Write-Host "The scatter path has been copied to the clipboard."
Write-Warning "Use Download Only first. Avoid Format All + Download."
Write-Warning "Leave preloader unchecked unless exact A1601 hardware is confirmed and the phone is hard-bricked."
if ($ValidateOnly) { exit 0 }
Start-Process -FilePath $FlashToolPath -WorkingDirectory (Split-Path -Parent $FlashToolPath)
