param(
    [string]$ManifestPath = "firmware\download-manifest.json",
    [string[]]$OnlyId = @(),
    [switch]$IncludeManual,
    [switch]$DryRun,
    [int]$DelaySecondsBetweenItems = 10
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
Set-Location $repoRoot

function Resolve-RepoPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path $repoRoot $Path
}

function Write-DownloadLog {
    param([Parameter(Mandatory = $true)][string]$Message)

    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Host $line
    Add-Content -LiteralPath $script:LogPath -Value $line
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-FileMd5 {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm MD5).Hash.ToUpperInvariant()
}

function Test-DownloadedFile {
    param(
        [Parameter(Mandatory = $true)]$Item,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $file = Get-Item -LiteralPath $Path
    if ($Item.PSObject.Properties.Name -contains "expectedSizeBytes") {
        $expectedSize = [int64]$Item.expectedSizeBytes
        if ($file.Length -ne $expectedSize) {
            Write-DownloadLog ("{0}: size mismatch for existing file. expected={1} actual={2}" -f $Item.id, $expectedSize, $file.Length)
            return $false
        }
    }

    if ($Item.PSObject.Properties.Name -contains "sha256") {
        $expectedHash = [string]$Item.sha256
        if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
            $actualHash = Get-FileSha256 -Path $Path
            if ($actualHash -ne $expectedHash.ToUpperInvariant()) {
                Write-DownloadLog ("{0}: SHA-256 mismatch for existing file. expected={1} actual={2}" -f $Item.id, $expectedHash, $actualHash)
                return $false
            }
        }
    }

    if ($Item.PSObject.Properties.Name -contains "md5") {
        $expectedMd5 = [string]$Item.md5
        if (-not [string]::IsNullOrWhiteSpace($expectedMd5)) {
            $actualMd5 = Get-FileMd5 -Path $Path
            if ($actualMd5 -ne $expectedMd5.ToUpperInvariant()) {
                Write-DownloadLog ("{0}: MD5 mismatch for existing file. expected={1} actual={2}" -f $Item.id, $expectedMd5, $actualMd5)
                return $false
            }
        }
    }

    return $true
}

function Move-InvalidExistingFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $invalidPath = "$Path.invalid-$stamp"
    Move-Item -LiteralPath $Path -Destination $invalidPath
    Write-DownloadLog ("Moved invalid existing file to {0}" -f $invalidPath)
}

function Invoke-DirectDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $partial = "$Destination.partial"
    try {
        Write-DownloadLog ("Starting BITS download: {0}" -f $Url)
        Start-BitsTransfer -Source $Url -Destination $partial -TransferType Download -ErrorAction Stop
    }
    catch {
        Write-DownloadLog ("BITS failed, falling back to Invoke-WebRequest: {0}" -f $_.Exception.Message)
        Invoke-WebRequest -Uri $Url -OutFile $partial -UseBasicParsing
    }

    Move-Item -LiteralPath $partial -Destination $Destination -Force
}

function Invoke-GoogleDriveDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $partial = "$Destination.partial"
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) {
        throw "curl.exe is required for resumable Google Drive downloads."
    }

    $idMatch = [regex]::Match($Url, '/d/([^/]+)')
    if (-not $idMatch.Success) {
        $idMatch = [regex]::Match($Url, '[?&]id=([^&]+)')
    }
    if (-not $idMatch.Success) {
        throw "Google Drive file ID could not be parsed from: $Url"
    }

    $fileId = $idMatch.Groups[1].Value
    $directUrl = "https://drive.usercontent.google.com/download?id=$fileId&export=download&confirm=t"
    Write-DownloadLog ("Starting resumable Google Drive download through curl.exe: {0}" -f $Url)
    & $curl.Source -L --fail --retry 10 --retry-delay 30 --speed-limit 1024 --speed-time 180 --continue-at - --output $partial $directUrl
    if ($LASTEXITCODE -ne 0) {
        throw "curl.exe failed with exit code $LASTEXITCODE"
    }

    Move-Item -LiteralPath $partial -Destination $Destination -Force
}

function Invoke-MediaFireDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $partial = "$Destination.partial"
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) {
        throw "curl.exe is required for resumable MediaFire downloads."
    }

    Write-DownloadLog ("Resolving MediaFire download page: {0}" -f $Url)
    $page = Invoke-WebRequest -Uri $Url -UseBasicParsing
    $match = [regex]::Match(
        [string]$page.Content,
        'href="(https://download[^"]+)"',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    if (-not $match.Success) {
        throw "MediaFire direct download URL was not found."
    }

    $directUrl = [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value)
    Write-DownloadLog "Starting resumable MediaFire download."
    & $curl.Source -L --fail --retry 10 --retry-delay 30 --speed-limit 1024 --speed-time 180 --continue-at - --output $partial $directUrl
    if ($LASTEXITCODE -ne 0) {
        throw "curl.exe failed with exit code $LASTEXITCODE"
    }

    Move-Item -LiteralPath $partial -Destination $Destination -Force
}

function Invoke-AndroidFileHostDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $partial = "$Destination.partial"
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) {
        throw "curl.exe is required for resumable AndroidFileHost downloads."
    }

    $idMatch = [regex]::Match($Url, '[?&]fid=([^&]+)')
    if (-not $idMatch.Success) {
        throw "AndroidFileHost file ID could not be parsed from: $Url"
    }

    $fileId = $idMatch.Groups[1].Value
    Write-DownloadLog ("Resolving AndroidFileHost mirrors for file ID {0}" -f $fileId)
    $mirrorResponse = $null
    $lastError = $null
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            $mirrorResponse = Invoke-RestMethod `
                -Uri "https://androidfilehost.com/libs/otf/mirrors.otf.php" `
                -Method Post `
                -Body @{ submit = "submit"; action = "getdownloadmirrors"; fid = $fileId } `
                -ErrorAction Stop
            break
        }
        catch {
            $lastError = $_.Exception.Message
            Write-DownloadLog ("AndroidFileHost mirror resolution attempt {0} failed: {1}" -f $attempt, $lastError)
            if ($attempt -lt 5) { Start-Sleep -Seconds (10 * $attempt) }
        }
    }
    if (-not $mirrorResponse) {
        throw "AndroidFileHost mirror resolution failed after retries: $lastError"
    }

    if (-not $mirrorResponse -or [string]$mirrorResponse.STATUS -ne "1") {
        throw ("AndroidFileHost mirror resolution failed: {0}" -f ($mirrorResponse | ConvertTo-Json -Compress))
    }

    $mirror = @($mirrorResponse.MIRRORS | Where-Object { $_.url -and $_.selectable -eq "1" } | Select-Object -First 1)
    if (-not $mirror) {
        $mirror = @($mirrorResponse.MIRRORS | Where-Object { $_.url } | Select-Object -First 1)
    }
    if (-not $mirror) {
        throw "AndroidFileHost did not return a usable mirror URL."
    }

    Write-DownloadLog ("Starting resumable AndroidFileHost download from {0}" -f $mirror.name)
    & $curl.Source -L --fail --retry 10 --retry-delay 30 --speed-limit 1024 --speed-time 180 --continue-at - --output $partial ([string]$mirror.url)
    if ($LASTEXITCODE -ne 0) {
        throw "curl.exe failed with exit code $LASTEXITCODE"
    }

    Move-Item -LiteralPath $partial -Destination $Destination -Force
}

$manifestFullPath = Resolve-RepoPath $ManifestPath
if (-not (Test-Path -LiteralPath $manifestFullPath -PathType Leaf)) {
    throw "Manifest not found: $manifestFullPath"
}

$logsDir = Resolve-RepoPath "logs"
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
$script:LogPath = Join-Path $logsDir ("firmware-downloads-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

$manifest = Get-Content -LiteralPath $manifestFullPath -Raw | ConvertFrom-Json
$items = @($manifest.items) | Sort-Object priority
if ($OnlyId.Count -gt 0) {
    $wanted = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $OnlyId) { [void]$wanted.Add($id) }
    $items = $items | Where-Object { $wanted.Contains([string]$_.id) }
}

Write-DownloadLog ("Repo: {0}" -f $repoRoot)
Write-DownloadLog ("Manifest: {0}" -f $manifestFullPath)
Write-DownloadLog ("Items selected: {0}" -f @($items).Count)
if ($DryRun) {
    Write-DownloadLog "Dry run: no downloads or file moves will be performed."
}

foreach ($item in $items) {
    $destination = Resolve-RepoPath ([string]$item.destination)
    $destinationDir = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null

    Write-DownloadLog ("--- {0}: {1}" -f $item.id, $item.title)
    Write-DownloadLog ("Method: {0}" -f $item.method)
    Write-DownloadLog ("Destination: {0}" -f $destination)

    if (Test-DownloadedFile -Item $item -Path $destination) {
        Write-DownloadLog ("{0}: already present and verified; skipping." -f $item.id)
        continue
    }

    if ($DryRun) {
        if (($item.method -eq "manual") -and $item.sourceUrl) {
            Write-DownloadLog ("Manual source URL: {0}" -f $item.sourceUrl)
        }
        elseif ($item.sourceUrl) {
            Write-DownloadLog ("Would download: {0}" -f $item.sourceUrl)
        }
        else {
            Write-DownloadLog "No direct source URL recorded; manual reacquisition required."
        }
        continue
    }

    Move-InvalidExistingFile -Path $destination

    $downloadAttempted = $false
    switch ([string]$item.method) {
        "direct" {
            $downloadAttempted = $true
            Invoke-DirectDownload -Url ([string]$item.sourceUrl) -Destination $destination
        }
        "google-drive" {
            $downloadAttempted = $true
            Invoke-GoogleDriveDownload -Url ([string]$item.sourceUrl) -Destination $destination
        }
        "mediafire" {
            $downloadAttempted = $true
            Invoke-MediaFireDownload -Url ([string]$item.sourceUrl) -Destination $destination
        }
        "androidfilehost" {
            $downloadAttempted = $true
            Invoke-AndroidFileHostDownload -Url ([string]$item.sourceUrl) -Destination $destination
        }
        "manual" {
            if ($IncludeManual) {
                if ($item.sourceUrl) {
                    Write-DownloadLog ("Manual browser download required: {0}" -f $item.sourceUrl)
                }
                else {
                    Write-DownloadLog "Manual download required; no direct URL was preserved in project history."
                }
            }
            else {
                Write-DownloadLog "Skipping manual item. Re-run with -IncludeManual to print manual source details in the log."
            }
        }
        default {
            Write-DownloadLog ("Skipping unsupported method: {0}" -f $item.method)
        }
    }

    if ($downloadAttempted) {
        if (Test-DownloadedFile -Item $item -Path $destination) {
            Write-DownloadLog ("{0}: download verified." -f $item.id)
        }
        else {
            $badPath = "$destination.failed-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")
            Move-Item -LiteralPath $destination -Destination $badPath -Force
            Write-DownloadLog ("{0}: downloaded file failed validation and was moved to {1}" -f $item.id, $badPath)
        }

        if ($DelaySecondsBetweenItems -gt 0) {
            Start-Sleep -Seconds $DelaySecondsBetweenItems
        }
    }
}

Write-DownloadLog "Firmware download run complete."
