# SP Flash Tool

The Windows SP Flash Tool package has been downloaded and extracted in this folder. The helper scripts look for one of these executables:

- `flash_tool.exe`
- `SPFlashTool.exe`
- `flash_tool_console.exe`

The downloaded ZIP and executable hashes are recorded in `docs\flashing\downloaded-tools.md`.

Trust note: no public official MediaTek download page was found. The local `flash_tool.exe` is not Authenticode-signed, so keep the ZIP hash and source page record with the project.

## Helper Scripts

Validate the extracted OPPO F1s firmware:

```powershell
.\scripts\powershell\Test-F1sFirmwarePackage.ps1
```

Open SP Flash Tool and copy the correct scatter path to the clipboard:

```powershell
.\scripts\powershell\Start-SpFlashTool.ps1
```

The scatter file expected for the extracted firmware is:

```text
firmware\stock\Oppo_F1S_A1601_MT6750_EX_11_A.15_160913\Firmware\MT6750_Android_scatter.txt
```

Use `Download Only` unless you intentionally need a different mode. Avoid flashing `preloader` unless the firmware exactly matches the device variant.
