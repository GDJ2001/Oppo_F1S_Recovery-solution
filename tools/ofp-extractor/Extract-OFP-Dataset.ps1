param(
    [string]$OfpPath = "",
    [string]$OutputDir = "",
    [switch]$CleanOutput,
    [switch]$NoValidate
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Find-Python {
    $candidates = @(
        "C:\Python312\python.exe",
        "python.exe",
        "py.exe"
    )

    foreach ($candidate in $candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    return $null
}

function Test-PythonDependency {
    param([string]$PythonPath)

    $probe = "import Cryptodome.Cipher; print('ok')"
    $result = & $PythonPath -c $probe 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python dependency missing: Cryptodome. Install with: $PythonPath -m pip install pycryptodomex"
    }
}

function Copy-DatabaseFiles {
    param(
        [string]$SourceDir,
        [string]$TargetDir
    )

    $databases = Get-ChildItem -LiteralPath $SourceDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "_database(_AP)?$" }

    foreach ($database in $databases) {
        Copy-Item -LiteralPath $database.FullName -Destination $TargetDir -Force
        Write-Host "Copied database: $($database.Name)"
    }
}

$repoRoot = Resolve-RepoRoot

if ([string]::IsNullOrWhiteSpace($OfpPath)) {
    $OfpPath = Join-Path $repoRoot "firmware\stock\Firmware + Tool\oppo6750_15331.ofp"
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331"
}

$OfpPath = (Resolve-Path -LiteralPath $OfpPath).Path
$extractor = Join-Path $repoRoot "scripts\python\extract_mtk_ofp.py"
if (-not (Test-Path -LiteralPath $extractor)) {
    throw "Extractor script not found: $extractor"
}

$python = Find-Python
if ([string]::IsNullOrWhiteSpace($python)) {
    throw "Python was not found. Install Python 3 and pycryptodomex, then retry."
}

Test-PythonDependency -PythonPath $python

if ($CleanOutput -and (Test-Path -LiteralPath $OutputDir)) {
    $resolvedOutput = (Resolve-Path -LiteralPath $OutputDir).Path
    $allowedRoot = Join-Path $repoRoot "firmware\ofp-extracted"
    if (-not $resolvedOutput.StartsWith($allowedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean output outside firmware\ofp-extracted: $resolvedOutput"
    }
    Write-Host "Cleaning output folder: $resolvedOutput"
    Get-ChildItem -LiteralPath $resolvedOutput -Force | Remove-Item -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host "OFP source : $OfpPath"
Write-Host "Output dir : $OutputDir"
Write-Host "Extractor  : $extractor"
Write-Host "Python     : $python"
Write-Host ""

& $python $extractor $OfpPath $OutputDir --overwrite
if ($LASTEXITCODE -ne 0) {
    throw "OFP extraction failed with exit code $LASTEXITCODE."
}

Copy-DatabaseFiles -SourceDir (Split-Path -Parent $OfpPath) -TargetDir $OutputDir

$manifest = Join-Path $OutputDir "EXTRACTION-MANIFEST.txt"
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OfpPath).Hash
@"
OPPO F1s A1601 OFP Extraction Manifest

Source OFP:
$OfpPath

Source SHA-256:
$hash

Extraction command:
$PSCommandPath -OfpPath "$OfpPath" -OutputDir "$OutputDir"

Validation:
$(if ($NoValidate) { "Skipped by -NoValidate" } else { "Run by this launcher after extraction" })

Safety:
- Do not run unknown prebuilt OFP extractor executables directly in this repository.
- Flashing preloader remains risky; leave it unchecked unless exact hardware match is confirmed and the phone is hard-bricked.
"@ | Set-Content -LiteralPath $manifest -Encoding ASCII

if (-not $NoValidate) {
    $validator = Join-Path $repoRoot "scripts\powershell\Test-F1sFirmwarePackage.ps1"
    if (Test-Path -LiteralPath $validator) {
        Write-Host ""
        Write-Host "Validating extracted firmware..."
        & $validator -FirmwareDir $OutputDir
        if ($LASTEXITCODE -ne 0) {
            throw "Extracted firmware validation failed."
        }
    }
}

Write-Host ""
Write-Host "OFP extraction completed."
Write-Host "Extracted dataset: $OutputDir"
