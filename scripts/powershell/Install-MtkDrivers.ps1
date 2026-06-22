param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$repoRoot = Resolve-RepoRoot
$driverRoot = Join-Path $repoRoot "drivers\mtk-usb"

if (-not (Test-Path -LiteralPath $driverRoot)) {
    throw "Driver directory not found: $driverRoot"
}

$infFiles = @(Get-ChildItem -LiteralPath $driverRoot -Recurse -File -Filter "*.inf" |
    Where-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
        $_.FullName -match "mediatek|mtk|oppo|vcom" -or
            $content -match "MediaTek|MTK|VCOM|PreLoader|VID_0E8D|VID_22D9"
    })

if ($infFiles.Count -eq 0) {
    throw "No extracted MediaTek driver INF files found under $driverRoot"
}

Write-Host "MediaTek driver INF files:"
$infFiles | Select-Object FullName | Format-Table -AutoSize

if ($WhatIf) {
    Write-Host ""
    Write-Host "WhatIf mode: no drivers were installed."
    exit 0
}

if (-not (Test-IsAdministrator)) {
    throw "Run PowerShell as Administrator to install drivers with pnputil."
}

foreach ($inf in $infFiles) {
    Write-Host ""
    Write-Host "Installing $($inf.FullName)"
    & pnputil.exe /add-driver $inf.FullName /install
    if ($LASTEXITCODE -ne 0) {
        throw "pnputil failed for $($inf.FullName) with exit code $LASTEXITCODE"
    }
}

Write-Host ""
Write-Host "Rescanning devices..."
& pnputil.exe /scan-devices

Write-Host ""
Write-Host "Driver installation commands completed. Power the phone off, connect with no buttons first, and rerun Get-FlashingReadiness.ps1."
Write-Host "If Preloader/VCOM is not detected, retry with only Volume Up, then only Volume Down. Do not hold both volume buttons on this phone."
