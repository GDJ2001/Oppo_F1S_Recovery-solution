param(
    [string]$OtaPath = "firmware\ota\A1601EX_11_OTA_040_all_201907091708.zip",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Read-ZipEntryText {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$EntryName
    )

    $entry = $Archive.GetEntry($EntryName)
    if (-not $entry) {
        return $null
    }

    $reader = [IO.StreamReader]::new($entry.Open())
    try {
        return $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
}

function Convert-Metadata {
    param([string]$Text)

    $metadata = [ordered]@{}
    foreach ($line in ($Text -split "`r?`n")) {
        if ($line -match "^\s*([^=]+)=(.*)\s*$") {
            $metadata[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    return $metadata
}

$repoRoot = Resolve-RepoRoot
if (-not [IO.Path]::IsPathRooted($OtaPath)) {
    $OtaPath = Join-Path $repoRoot $OtaPath
}

$result = [ordered]@{
    otaPath = $OtaPath
    exists = Test-Path -LiteralPath $OtaPath
    length = $null
    sha256 = $null
    entryCount = 0
    metadata = $null
    targetsA1601 = $false
    hasRecoveryUpdater = $false
    hasSignature = $false
    warnings = @()
    ok = $false
}

if (-not $result.exists) {
    $result.warnings += "OTA package not found."
}
else {
    $file = Get-Item -LiteralPath $OtaPath
    $result.length = $file.Length
    $result.sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $OtaPath).Hash

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($OtaPath)
    try {
        $result.entryCount = $archive.Entries.Count
        $metadataText = Read-ZipEntryText -Archive $archive -EntryName "META-INF/com/android/metadata"
        $updaterScript = Read-ZipEntryText -Archive $archive -EntryName "META-INF/com/google/android/updater-script"

        if ($metadataText) {
            $result.metadata = Convert-Metadata -Text $metadataText
            $result.targetsA1601 = $result.metadata["pre-device"] -eq "A1601" `
                -or $result.metadata["ota-id"] -match "^A1601EX_11\." `
                -or $result.metadata["ota_version"] -match "^A1601EX_11\." `
                -or $result.metadata["version_name"] -match "^A1601EX_11_"
        }
        else {
            $result.warnings += "Missing META-INF/com/android/metadata."
        }

        $result.hasRecoveryUpdater = [bool]$updaterScript
        $result.hasSignature = [bool]$archive.GetEntry("META-INF/CERT.RSA")

        if ($updaterScript -and $updaterScript -notmatch 'getprop\("ro\.product\.device"\) == "A1601"') {
            $result.warnings += "Updater script does not assert ro.product.device == A1601."
        }

        if ($updaterScript -and $updaterScript -match "preloader") {
            $result.warnings += "OTA updates preloader partitions through recovery. Battery should be charged and the package must not be interrupted."
        }
    }
    finally {
        $archive.Dispose()
    }
}

$result.ok = $result.exists -and $result.targetsA1601 -and $result.hasRecoveryUpdater -and $result.hasSignature

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "OPPO A1601 OTA package check"
Write-Host "OTA path        : $($result.otaPath)"
Write-Host "Exists          : $($result.exists)"
Write-Host "Length          : $($result.length)"
Write-Host "SHA-256         : $($result.sha256)"
Write-Host "Entry count     : $($result.entryCount)"
Write-Host "Targets A1601   : $($result.targetsA1601)"
Write-Host "Recovery updater: $($result.hasRecoveryUpdater)"
Write-Host "Signed ZIP      : $($result.hasSignature)"

if ($result.metadata) {
    Write-Host ""
    Write-Host "Metadata:"
    $result.metadata.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)"
    }
}

if ($result.warnings.Count -gt 0) {
    Write-Host ""
    $result.warnings | ForEach-Object { Write-Warning $_ }
}

Write-Host ""
if ($result.ok) {
    Write-Host "OTA status: OK"
    exit 0
}

Write-Host "OTA status: NOT READY"
exit 1
