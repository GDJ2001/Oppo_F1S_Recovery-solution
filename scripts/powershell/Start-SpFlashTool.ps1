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

function Find-FlashTool {
    param([string]$RepoRoot)

    $searchRoots = @(
        (Join-Path $RepoRoot "tools\sp-flash-tool"),
        (Join-Path $RepoRoot "firmware\stock")
    )

    foreach ($root in $searchRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $candidate = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "^(flash_tool|SPFlashTool|flash_tool_console)\.exe$" } |
            Select-Object -First 1

        if ($candidate) {
            return $candidate.FullName
        }
    }

    return $null
}

$repoRoot = Resolve-RepoRoot
$validator = Join-Path $PSScriptRoot "Test-F1sFirmwarePackage.ps1"

$validationArgs = @()
if (-not [string]::IsNullOrWhiteSpace($FirmwareDir)) {
    $validationArgs += "-FirmwareDir"
    $validationArgs += $FirmwareDir
}

Write-Host "Validating firmware package..."
& $validator @validationArgs
if ($LASTEXITCODE -ne 0) {
    throw "Firmware validation failed. Fix the package or path before opening SP Flash Tool."
}

if ([string]::IsNullOrWhiteSpace($FirmwareDir)) {
    $validation = (& $validator -Json | ConvertFrom-Json)
}
else {
    $validation = (& $validator -FirmwareDir $FirmwareDir -Json | ConvertFrom-Json)
}
$scatterPath = $validation.scatterPath

if ([string]::IsNullOrWhiteSpace($FlashToolPath)) {
    $FlashToolPath = Find-FlashTool -RepoRoot $repoRoot
}

if ([string]::IsNullOrWhiteSpace($FlashToolPath) -or -not (Test-Path -LiteralPath $FlashToolPath)) {
    Write-Host ""
    Write-Warning "SP Flash Tool executable was not found."
    Write-Host "Place SP Flash Tool under:"
    Write-Host "  $(Join-Path $repoRoot 'tools\sp-flash-tool')"
    Write-Host ""
    Write-Host "Then run this script again."
    exit 1
}

Set-Clipboard -Value $scatterPath
Write-Host ""
Write-Host "SP Flash Tool : $FlashToolPath"
Write-Host "Scatter file  : $scatterPath"
Write-Host "The scatter path has been copied to the clipboard."
Write-Host ""
Write-Warning "Use Download Only unless you intentionally need another mode. Flashing userdata wipes data. Flashing preloader can brick the phone if the package is wrong."

if ($ValidateOnly) {
    exit 0
}

Start-Process -FilePath $FlashToolPath -WorkingDirectory (Split-Path -Parent $FlashToolPath)
