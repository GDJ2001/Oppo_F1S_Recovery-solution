# SP Flash Tool Workflow

This repo uses SP Flash Tool or SP MDT with a loose MediaTek scatter package. It does not use or modify OPPO `DownloadTool.exe`.

## Validate Firmware

```powershell
.\scripts\powershell\Test-F1sFirmwarePackage.ps1 -FirmwareDir "firmware\stock\A1601EX_11_A.40_190709\Firmware"
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
.\scripts\powershell\Start-SpFlashTool.ps1 -FirmwareDir "firmware\stock\A1601EX_11_A.40_190709\Firmware"
```

Use `Download Only` first. Leave `preloader` unchecked unless exact A1601 hardware is confirmed and the phone is hard-bricked.

Do not put the phone into Preloader/VCOM mode until firmware validation and tool discovery both pass.
