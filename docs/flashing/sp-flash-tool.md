# SP Flash Tool Workflow

This project provides helper scripts for SP Flash Tool. It does not reimplement MediaTek flashing or bypass device security.

## Prerequisites

- OPPO F1s A1601 confirmed as the target device
- Extracted firmware package under `firmware\stock`
- MTK VCOM/CDC drivers installed
- SP Flash Tool extracted under `tools\sp-flash-tool`
- Phone battery charged enough for flashing

Downloaded tool paths and hashes are recorded in `docs\flashing\downloaded-tools.md`.

## Validate Firmware

Run:

```powershell
.\scripts\powershell\Test-F1sFirmwarePackage.ps1
```

The script checks:

- The `MT6750_Android_scatter.txt` file exists
- Files referenced by downloadable scatter entries exist
- Whether Windows currently sees an OPPO, Android, or MediaTek USB device
- Risk warnings for `preloader` and `userdata`

For a full readiness view, run:

```powershell
.\scripts\powershell\Get-FlashingReadiness.ps1
```

This reports whether the phone is still in normal OPPO USB/MTP mode or visible as MediaTek preloader/VCOM.

## Open SP Flash Tool

Run:

```powershell
.\scripts\powershell\Start-SpFlashTool.ps1
```

The script validates the package, finds `flash_tool.exe`, copies the scatter path to the clipboard, and opens the tool.

In SP Flash Tool:

1. Load the copied scatter file.
2. Use `Download Only` for a normal stock restore.
3. Review selected partitions before pressing Download.
4. Power off the phone.
5. Connect USB while holding the required OPPO F1s preloader key combo.
6. Wait for completion before disconnecting.

## Current Recommendation

Use the GUI path for the first flash. This SP Flash Tool package includes command-mode schema files, but command mode can start partition writes with less opportunity to inspect the selected partitions. The helper script therefore opens the GUI and copies the scatter path instead of launching a console flash.

Before pressing `Download`, review the selected partitions. For a lower-risk restore, consider leaving `preloader` unchecked unless the device is already hard-bricked or you have confirmed the package exactly matches the A1601 variant.

## Safety Notes

- Flashing `userdata` wipes data.
- Flashing `preloader` can hard-brick the phone if the package does not match the exact variant.
- Do not use firmware intended for a different model or region.
- Keep original NVRAM/NVDATA backups if available; they can contain radio identity data.
- The downloaded SP Flash Tool executable is not Authenticode-signed. Treat it as an unofficial mirror download even though the ZIP hash matched the source page.
