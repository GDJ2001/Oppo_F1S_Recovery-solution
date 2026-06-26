# SP Flash Tool Workflow

This repo uses SP Flash Tool or SP MDT with a loose MediaTek scatter package. It does not use or modify OPPO `DownloadTool.exe`.

## Validate Firmware

```powershell
.\scripts\powershell\Test-F1sFirmwarePackage.ps1 -FirmwareDir "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331"
```

The validator rejects:

- OFP/service packages
- packages containing `DownloadTool.exe`
- missing `MT6750_Android_scatter.txt`
- missing or zero-byte scatter images
- missing AP/MD database files
- packages without A1601/MT6750 identity markers

## Open Flasher

Only after validation passes:

```powershell
.\scripts\powershell\Start-SpFlashTool.ps1 -FirmwareDir "firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331"
```

Current flasher location is SP Flash Tool v5:

```text
tools\sp-flash-tool\**\flash_tool.exe
```

Use `Download Only`/normal download mode first. Leave `preloader` unchecked unless exact A1601 hardware is confirmed and the phone is hard-bricked.

Do not put the phone into Preloader/VCOM mode until firmware validation and tool discovery both pass.

## Guided Terminal Session

Use this when the GUI flasher is hard to time correctly:

```powershell
.\scripts\powershell\Start-F1sGuidedFlashSession.ps1 -CountdownSeconds 20 -MonitorSeconds 90
```

The script validates firmware, launches SP Flash Tool, copies the scatter path to the clipboard, starts a countdown, and logs OPPO/MediaTek USB state changes under `logs`.

For this phone, do not hold both volume buttons because that enters ColorOS Recovery. Start the flasher first, then connect the powered-off phone with no buttons. If that is not detected, retry with only `Volume Up`, then only `Volume Down`.

## Terminal Controller

The repo also has a terminal controller that prefers the local SP Flash Tool v5 runtime when it exists:

```powershell
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command status
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command prepare
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command flash -CountdownSeconds 20 -MonitorSeconds 90
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command monitor -MonitorSeconds 90
```

This is the custom terminal entry point for the project. It does not patch MediaTek/OPPO tools; it uses SP Flash Tool as a runtime dependency and owns validation, countdown, driver/device monitoring, and logs.

## Hard-Brick Track

If the phone is now hard-bricked, use the separate hard-recovery session:

```powershell
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command hard -CountdownSeconds 20 -MonitorSeconds 120
```

That command records BROM/Preloader evidence more aggressively and keeps high-risk write decisions manual. See `hard-recovery.md` before checking `preloader` or considering any format mode.
