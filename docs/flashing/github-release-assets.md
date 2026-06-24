# GitHub Release Assets

Large firmware, driver, and flashing tool binaries are stored as GitHub Release assets. The Git repository stays as the control plane: scripts, manifests, checksums, and procedure docs.

## Structure

The release staging root is:

```text
Oppo_F1S_Recovery_assets/
```

Prepared assets:

```text
firmware-raw--<manifest-id>--<original-archive-name>
oppo-f1s-firmware-extracted.zip
oppo-f1s-tools.zip
oppo-f1s-drivers.zip
oppo-f1s-checksums.zip
release-assets.json
SHA256SUMS.txt
```

Raw firmware archives are uploaded individually because one combined firmware
bundle would exceed GitHub's 2 GiB per-asset limit. Other asset groups remain
ZIP bundles.

The tracked manifest is:

```powershell
config\github-release-assets.json
```

It records the source path, restore path, intended use, validation status, size, and SHA-256 for approved assets.

## Prepare

Run after local firmware/tools have been downloaded and validated:

```powershell
.\scripts\powershell\Test-GitHubAssetReadiness.ps1 -AllowMissingOptional
```

```powershell
.\scripts\powershell\Prepare-GitHubAssets.ps1 -Clean
```

The prepare step refuses:

- missing required assets
- size or SHA-256 mismatches
- staged `DownloadTool.exe`

Output is written under:

```powershell
artifacts\github-assets
```

## Publish

Create or update the GitHub Release assets:

```powershell
.\scripts\powershell\Publish-GitHubAssets.ps1 -CreateRelease
```

Dry run:

```powershell
.\scripts\powershell\Publish-GitHubAssets.ps1 -DryRun
```

The default release tag is `oppo-f1s-assets-v1`.

## Restore

From a clean checkout, restore binaries from the GitHub Release:

```powershell
.\scripts\powershell\Restore-GitHubAssets.ps1 -Force
```

Then validate before flashing:

```powershell
.\scripts\powershell\Test-F1sFirmwarePackage.ps1 -FirmwareDir "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331"
.\scripts\powershell\Start-SpFlashTool.ps1 -ValidateOnly
.\scripts\powershell\Start-SnWriteTool.ps1 -ValidateOnly
```

Do not commit ZIP/OFP/EXE/DLL/SYS binaries directly to Git.
