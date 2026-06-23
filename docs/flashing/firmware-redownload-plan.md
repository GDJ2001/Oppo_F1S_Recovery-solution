# Firmware Redownload Plan

Firmware binaries were removed from this repo after corrupted local copies were found. The repo now keeps a tracked manifest and automation only; large downloaded files remain ignored by Git.

## Manifest

Tracked manifest:

```powershell
firmware\download-manifest.json
```

It records the firmware assets found in current docs and Git history:

- A.41 RepairMyMobile MediaFire OFP service package.
- A.24 Google Drive scatter package.
- A.40 AddROM OFP service package.
- Official OPPO A.41, A.40, and D.01 recovery OTA packages.
- A.15 local/user-provided scatter archive record.
- A.41 tar.bz2 candidate record with no preserved direct URL.

## Midnight Download

Dry run:

```powershell
.\scripts\powershell\Invoke-FirmwareDownloads.ps1 -DryRun -IncludeManual
```

Register a one-time task for the next local midnight:

```powershell
.\scripts\powershell\Register-MidnightFirmwareDownloads.ps1
```

Register for a specific time:

```powershell
.\scripts\powershell\Register-MidnightFirmwareDownloads.ps1 -At "2026-06-24 00:00"
```

Run manually:

```powershell
.\scripts\powershell\Invoke-FirmwareDownloads.ps1
```

Download only one item:

```powershell
.\scripts\powershell\Invoke-FirmwareDownloads.ps1 -OnlyId official-ota-a41
```

## Behavior

- Downloads run one by one in manifest priority order.
- Direct OPPO OTA URLs use BITS first, then fall back to `Invoke-WebRequest`.
- Google Drive uses `curl.exe` with retries where available.
- Manual/browser-gated sources are logged and skipped by default.
- Files are written under ignored firmware folders such as `firmware\downloads` and `firmware\ota`.
- Existing files are accepted only when expected size and SHA-256 match.
- Invalid existing files are moved aside with an `.invalid-<timestamp>` suffix during a real run.
- New files that fail validation are moved aside with a `.failed-<timestamp>` suffix.
- Logs are written under `logs\firmware-downloads-*.log`.

## After Download

Do not flash a package just because it downloaded. Extract to scratch first, validate it, and only then copy a clean scatter/OFP extraction output into the active firmware folder.

Useful validation commands:

```powershell
.\scripts\powershell\Test-F1sFirmwarePackage.ps1 -FirmwareDir "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331"
.\scripts\powershell\Test-A1601OtaPackage.ps1 -OtaPath "firmware\ota\A1601EX_11_OTA_041_all_201912261125.zip"
```

Manual items still need a browser download if no stable direct URL exists in the repo history.
