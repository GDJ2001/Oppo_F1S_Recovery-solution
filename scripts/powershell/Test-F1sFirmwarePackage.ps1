param(
    [string]$FirmwareDir = "",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    $path = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $path
}

function Resolve-InputPath {
    param([string]$RepoRoot, [string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or [IO.Path]::IsPathRooted($Path)) { return $Path }
    return Join-Path $RepoRoot $Path
}

function Find-DefaultFirmwareDir {
    param([string]$RepoRoot)

    $preferred = Join-Path $RepoRoot "firmware\stock\A1601EX_11_A.40_190709\Firmware"
    if (Test-Path -LiteralPath (Join-Path $preferred "MT6750_Android_scatter.txt")) { return $preferred }

    $stockRoot = Join-Path $RepoRoot "firmware\stock"
    if (-not (Test-Path -LiteralPath $stockRoot)) { return $null }

    $scatter = Get-ChildItem -LiteralPath $stockRoot -Recurse -File -Filter "MT6750_Android_scatter.txt" -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1
    if ($scatter) { return $scatter.Directory.FullName }

    $ofpDir = Get-ChildItem -LiteralPath $stockRoot -Recurse -File -Filter "*.ofp" -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1
    if ($ofpDir) { return $ofpDir.Directory.FullName }

    return $null
}

function Read-ScatterDownloads {
    param([string]$ScatterPath)

    $partitions = @()
    $current = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $ScatterPath) {
        if ($line -match "^\s*-\s*partition_index:") {
            if ($current.Count -gt 0) { $partitions += [pscustomobject]$current }
            $current = [ordered]@{}
        }
        elseif ($line -match "^\s*partition_name:\s*(.+?)\s*$") { $current.partition_name = $Matches[1] }
        elseif ($line -match "^\s*file_name:\s*(.+?)\s*$") { $current.file_name = $Matches[1] }
        elseif ($line -match "^\s*is_download:\s*(true|false)\s*$") { $current.is_download = [System.Convert]::ToBoolean($Matches[1]) }
    }
    if ($current.Count -gt 0) { $partitions += [pscustomobject]$current }
    return $partitions | Where-Object { $_.is_download -eq $true -and $_.file_name -and $_.file_name -ne "NONE" }
}

function Find-DatabaseFiles {
    param([string]$Dir)
    $files = @()
    if ($Dir -and (Test-Path -LiteralPath $Dir)) {
        $files = @(Get-ChildItem -LiteralPath $Dir -Recurse -File -ErrorAction SilentlyContinue)
    }
    $apDb = $files | Where-Object { $_.Name -match "(_database_AP$|^APDB|AP_DB|APDatabase)" } | Sort-Object Length -Descending | Select-Object -First 1
    $mdDb = $files | Where-Object { $_.Name -match "(_database$|^BPLGU|MDDB|MD_DB|modem.*database)" -and $_.Name -notmatch "_AP$" } | Sort-Object Length -Descending | Select-Object -First 1
    [pscustomobject]@{
        apDatabase = if ($apDb) { $apDb.FullName } else { $null }
        mdDatabase = if ($mdDb) { $mdDb.FullName } else { $null }
    }
}

function Get-PackageMarkers {
    param([string]$FirmwareDir, [string]$ScatterPath)
    $text = @($FirmwareDir)
    if ($ScatterPath -and (Test-Path -LiteralPath $ScatterPath)) { $text += (Get-Content -LiteralPath $ScatterPath -Raw) }
    if ($FirmwareDir -and (Test-Path -LiteralPath $FirmwareDir)) {
        $text += (Get-ChildItem -LiteralPath $FirmwareDir -Recurse -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    }
    $joined = $text -join [Environment]::NewLine
    @("A1601", "A1601EX", "oppo6750_15331", "MT6750") | Where-Object { $joined -match [regex]::Escape($_) }
}

function Get-MtkUsbDevices {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FriendlyName -match "OPPO|Android|ADB|Fastboot|MediaTek|MTK|Preloader|VCOM|CDC" -or
            $_.InstanceId -match "VID_0E8D|VID_22D9|VID_18D1"
        } |
        Select-Object Status, Class, FriendlyName, InstanceId
}

$repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($FirmwareDir)) { $FirmwareDir = Find-DefaultFirmwareDir -RepoRoot $repoRoot }
else { $FirmwareDir = Resolve-InputPath -RepoRoot $repoRoot -Path $FirmwareDir }

$result = [ordered]@{
    repositoryRoot = $repoRoot
    firmwareDir = $FirmwareDir
    scatterPath = $null
    ok = $false
    rejectedReasons = @()
    missingFiles = @()
    zeroLengthFiles = @()
    downloadablePartitions = @()
    apDatabase = $null
    mdDatabase = $null
    modelMarkers = @()
    detectedDevices = @()
    warnings = @()
}

if ([string]::IsNullOrWhiteSpace($FirmwareDir) -or -not (Test-Path -LiteralPath $FirmwareDir)) {
    $result.rejectedReasons += "Firmware directory was not found. Extract a loose scatter package under firmware\stock first."
}
else {
    if (@(Get-ChildItem -LiteralPath $FirmwareDir -Recurse -File -Filter "*.ofp" -ErrorAction SilentlyContinue).Count -gt 0) {
        $result.rejectedReasons += "OFP/service package detected. This SP Flash workflow requires a loose scatter package."
    }
    if (@(Get-ChildItem -LiteralPath $FirmwareDir -Recurse -File -Filter "DownloadTool.exe" -ErrorAction SilentlyContinue).Count -gt 0) {
        $result.rejectedReasons += "DownloadTool.exe detected. Login-restricted DownloadTool packages are excluded from this workflow."
    }

    $scatterPath = Join-Path $FirmwareDir "MT6750_Android_scatter.txt"
    $result.scatterPath = $scatterPath
    if (-not (Test-Path -LiteralPath $scatterPath)) {
        $result.rejectedReasons += "Required scatter file not found: $scatterPath"
    }
    else {
        $downloads = @(Read-ScatterDownloads -ScatterPath $scatterPath)
        if ($downloads.Count -eq 0) { $result.rejectedReasons += "No downloadable partitions could be parsed from the scatter file." }
        $result.downloadablePartitions = @($downloads | ForEach-Object { [pscustomobject]@{ partition = $_.partition_name; file = $_.file_name } })

        foreach ($entry in $downloads) {
            $imagePath = Join-Path $FirmwareDir $entry.file_name
            if (-not (Test-Path -LiteralPath $imagePath)) {
                $result.missingFiles += $entry.file_name
                continue
            }
            if ((Get-Item -LiteralPath $imagePath).Length -le 0) { $result.zeroLengthFiles += $entry.file_name }
        }

        foreach ($criticalImage in @("system.img", "vendor.img", "boot.img", "recovery.img", "lk.bin", "logo.bin")) {
            $criticalPath = Join-Path $FirmwareDir $criticalImage
            if ((Test-Path -LiteralPath $criticalPath) -and (Get-Item -LiteralPath $criticalPath).Length -le 0 -and $result.zeroLengthFiles -notcontains $criticalImage) {
                $result.zeroLengthFiles += $criticalImage
            }
        }

        if ($result.missingFiles.Count -gt 0) { $result.rejectedReasons += "One or more scatter-referenced image files are missing." }
        if ($result.zeroLengthFiles.Count -gt 0) { $result.rejectedReasons += "One or more scatter-referenced image files are zero bytes." }
        if ($downloads.partition_name -contains "preloader") { $result.warnings += "Scatter includes preloader. Leave it unchecked unless exact A1601 hardware is confirmed." }
        if ($downloads.partition_name -contains "userdata") { $result.warnings += "Scatter includes userdata. Flashing userdata wipes phone data." }
    }

    $databases = Find-DatabaseFiles -Dir $FirmwareDir
    $result.apDatabase = $databases.apDatabase
    $result.mdDatabase = $databases.mdDatabase
    if (-not $result.apDatabase) { $result.rejectedReasons += "AP database file was not found." }
    if (-not $result.mdDatabase) { $result.rejectedReasons += "MD/BPLGU database file was not found." }
    $result.modelMarkers = @(Get-PackageMarkers -FirmwareDir $FirmwareDir -ScatterPath $scatterPath)
    if ($result.modelMarkers.Count -eq 0) { $result.rejectedReasons += "No A1601/A1601EX/oppo6750_15331/MT6750 identity marker was found." }
}

$result.detectedDevices = @(Get-MtkUsbDevices)
if (@($result.detectedDevices | Where-Object { $_.FriendlyName -match "MediaTek|MTK|Preloader|VCOM|CDC" -or $_.InstanceId -match "VID_0E8D" }).Count -eq 0) {
    $result.warnings += "No MediaTek preloader/VCOM flashing device is currently visible. Normal MTP/ADB mode is not ready for SP flashing."
}

$result.ok = ($result.scatterPath -and (Test-Path -LiteralPath $result.scatterPath) -and @($result.rejectedReasons).Count -eq 0)

if ($Json) { $result | ConvertTo-Json -Depth 6; exit 0 }

Write-Host "OPPO F1s firmware package check"
Write-Host "Repository : $($result.repositoryRoot)"
Write-Host "Firmware   : $($result.firmwareDir)"
Write-Host "Scatter    : $($result.scatterPath)"
Write-Host "AP DB      : $($result.apDatabase)"
Write-Host "MD DB      : $($result.mdDatabase)"
Write-Host "Markers    : $($result.modelMarkers -join ', ')"
if ($result.downloadablePartitions.Count -gt 0) { Write-Host ""; $result.downloadablePartitions | Format-Table -AutoSize }
if ($result.missingFiles.Count -gt 0) { Write-Host ""; Write-Warning "Missing files:"; $result.missingFiles | ForEach-Object { Write-Warning "  $_" } }
if ($result.zeroLengthFiles.Count -gt 0) { Write-Host ""; Write-Warning "Zero-byte files:"; $result.zeroLengthFiles | ForEach-Object { Write-Warning "  $_" } }
if ($result.detectedDevices.Count -gt 0) { Write-Host ""; $result.detectedDevices | Format-Table -AutoSize }
if ($result.rejectedReasons.Count -gt 0) { Write-Host ""; $result.rejectedReasons | ForEach-Object { Write-Warning $_ } }
if ($result.warnings.Count -gt 0) { Write-Host ""; $result.warnings | ForEach-Object { Write-Warning $_ } }
Write-Host ""
if ($result.ok) { Write-Host "Package status: OK"; exit 0 }
Write-Host "Package status: NOT READY"
exit 1
