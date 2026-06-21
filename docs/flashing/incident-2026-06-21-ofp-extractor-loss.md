# Incident Record: OFP Extractor Workspace Loss

Date: 2026-06-21

## Summary

An OPPO MTK OFP extractor was executed against the A40 OFP firmware package and unexpectedly removed most workspace content. The repository later returned to a clean Git-tracked state, but that state is older than the safer SP Flash Tool workflow that had been implemented during the repair session.

Do not run OFP extractors or flashing executables without an isolated scratch directory, backups, and an explicit dry-run/behavior review.

## Current Repository State

- `.git` is present. Before this incident record was added, `git status --short` was clean.
- The repository content appears restored to the earlier committed scaffold/workflow, not the latest safe workflow edits.
- `firmware` contains only tracked placeholder folders:
  - `firmware\checksums`
  - `firmware\recovery`
  - `firmware\scatter`
  - `firmware\stock`
- No local A40/A41/A15 firmware packages are currently visible in `firmware`.
- No SP Flash/SP MDT/SN Writer executable is currently visible under `tools`.
- `scripts\powershell\Start-OppoDownloadTool.ps1` existed after the restore and was removed again to exclude DownloadTool.

## Downloaded/Generated Files Lost Or Not Currently Present

These files existed during the session but are not currently visible:

- `firmware\downloads\A1601EX_11_A.40_190709_addrom_google_drive.zip`
- `firmware\downloads\halabtech-a40-page.html`
- `firmware\downloads\halabtech-a40-download-probe.bin`
- `firmware\stock\A1601EX_11_A.40_190709_ofp\...`
- `firmware\stock\A1601EX_11_A.40_190709\Firmware`
- `firmware\stock\A1601EX_11_A.40_190709_extracted`
- `tools\oppo_decrypt`
- `tools\OPPO-MTK-OFP-EXTRACTOR`
- `tools\quarantine\mtk_ofp_extractor.exe.disabled`

The A40 Google Drive package was confirmed to be an OFP service package, not a loose scatter package. It contained `oppo6750_15331.ofp`, `DownloadTool.exe`, and AP/MD database files.

## Implemented Safety Changes That Are Missing From Current Code

The current codebase does not include these later safety changes:

- Delete/remove `scripts\powershell\Start-OppoDownloadTool.ps1`.
- Update docs so they do not recommend OPPO DownloadTool.
- Reject packages containing `DownloadTool.exe`.
- Reject OFP-only packages for the SP Flash Tool workflow.
- Require `MT6750_Android_scatter.txt`.
- Require all scatter-referenced downloadable image files to exist and be nonzero.
- Reject zero-byte critical images such as `system.img`.
- Require AP and MD/BPLGU database files for later SN Write/NVRAM repair.
- Validate model/build markers: `A1601`, `A1601EX`, `oppo6750_15331`, or `MT6750`.
- Prefer target path `firmware\stock\A1601EX_11_A.40_190709\Firmware`.
- Discover SP Flash Tool v6 executable name `SPFlashToolV6.exe`.
- Discover SP MDT executable name `mdt.exe`.
- Search for SN Writer under both `tools\sn-write-tool` and `tools\SN_Write_Tool_v*`.
- Add an A40 intake helper for archives, while rejecting OFP-only output.

## Current High-Risk Stale Files

- `scripts\powershell\Start-OppoDownloadTool.ps1`
- `docs\flashing\nvram-imei-repair.md`, because it still recommends OPPO DownloadTool for an OFP package.
- `docs\flashing\downloaded-tools.md`, because it still documents launching the OFP tool.
- `scripts\powershell\Test-F1sFirmwarePackage.ps1`, because it only checks missing files and can miss zero-byte images and OFP/DownloadTool packages.
- `scripts\powershell\Start-SpFlashTool.ps1`, because tool discovery is too narrow and does not include `SPFlashToolV6.exe` or `mdt.exe`.
- `scripts\powershell\Get-FlashingReadiness.ps1`, because readiness can be misleading when tools are missing and firmware validation is weak.

## Rules For Next Work

- Do not run third-party OFP extractors in this workspace.
- Do not unpack, patch, or repack `DownloadTool.exe` to remove login, account, or authorization checks.
- Do not run firmware/flashing executables until the firmware validator passes.
- Put any user-provided firmware archive under `firmware\downloads`.
- Extract only into a new scratch directory outside the repo first, then copy validated output into the repo.
- Use SP Flash Tool/SP MDT only with a loose scatter package.
- Do not use `DownloadTool.exe`.
- Do not store or script IMEI values. Restore only the phone's original IMEI manually in SN Write Tool.

## Known Source Findings

- AddROM/Google Drive A40 source downloaded successfully during the session, but it was OFP/service firmware rather than loose scatter.
- HalabTech A40 page listed `A1601EX_11_A.40_190709` as a 2 GB tar, but direct automated download was blocked by Cloudflare/login flow.
- `bkerler/oppo_decrypt` failed on the A40 OFP with `Unknown key`.
- `mfdl/OPPO-MTK-OFP-EXTRACTOR` must not be used in this workspace after the destructive behavior observed.
