# Hard-Brick Recovery Track

Use this track only when the OPPO F1s A1601 no longer boots, does not enter useful recovery, and only appears briefly as a MediaTek USB device or not at all.

This is a research and salvage workflow. It still does not use OPPO `DownloadTool.exe`, does not patch login or authorization checks, and does not clone or substitute IMEI/NVRAM/RPMB data.

## Current Technical Position

- Target device: OPPO F1s A1601 / A1601EX / MT6750.
- Active extracted firmware: `firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331`.
- Active flash runtime: SP Flash Tool v5 when present under `tools\sp-flash-tool`.
- Known blocker from prior attempt: SP Flash Tool reported `STATUS_SEC_INSUFFICIENT_BUFFER` and requested a verified modem image.
- Research result: no trusted public A1601-specific `.auth` file has been found.

## Hard Recovery Command

Run this before connecting the phone:

```powershell
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command hard -CountdownSeconds 20 -MonitorSeconds 120
```

Dry monitor without launching the flasher:

```powershell
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command hard -NoLaunch -NoPrompt -CountdownSeconds 0 -MonitorSeconds 30
```

The hard-recovery command:

- validates the active firmware,
- finds SP Flash Tool/SP MDT while excluding `DownloadTool.exe`,
- copies the scatter path to the clipboard,
- launches the flasher unless `-NoLaunch` is used,
- monitors Windows USB state every 250 ms,
- distinguishes BROM, Preloader/VCOM, normal OPPO USB, recovery/ADB/Fastboot, driver error, and no-device states,
- writes plain-text and JSONL evidence logs under `logs`.

## Attach Order

1. Disconnect the phone.
2. Hold Power for 20 seconds.
3. Leave the phone disconnected for 10 seconds.
4. Start the hard-recovery command.
5. Load the copied scatter path in the flasher.
6. Choose the least destructive download mode available.
7. Click Download/Start in the flasher.
8. Connect USB with no buttons first.
9. If nothing appears, retry only `Volume Up`.
10. If still nothing appears, retry only `Volume Down`.

Do not hold both volume buttons on this phone. That enters ColorOS Recovery and is not the Preloader/BROM attach path.

## Flashing Risk Rules

Use `Download Only` first when the tool allows it.

Do not use `Format All + Download` as a default. That can destroy NVRAM/NVDATA, calibration data, and other unique device state.

Only consider checking `preloader` when all of these are true:

- the phone is already hard-bricked,
- the firmware has passed validation,
- the scatter/preloader family matches A1601 MT6750,
- the preloader identity is in the expected `oppo6750_15131` or `oppo6750_15331` family,
- the user explicitly accepts that a wrong preloader can make the device unrecoverable without lab equipment.

If the flasher asks for an auth file, custom DA, or verified image that the package does not contain, stop and record the exact error. Do not rename OTA certificates, random auth files, or unsigned images to satisfy the field.

## Evidence To Capture

Keep the generated log files from `logs` after every attempt. They are needed to distinguish:

- no electrical USB enumeration,
- driver failure,
- BROM mode,
- Preloader/VCOM mode,
- normal Android USB,
- recovery/ADB/Fastboot.

For a hard-bricked A1601, the most useful evidence is a short-lived `VID_0E8D` MediaTek device or an OPPO/MediaTek preloader port. If Windows never sees either one, the next step is hardware-level inspection: cable, USB port, battery state, charge path, boot key matrix, test point, or eMMC failure.

## Post-Recovery

After the phone boots, do not write a generated IMEI. Use SN Writer only with the phone's original IMEI from the box, label, or paperwork. Then verify baseband, SIM registration, Wi-Fi MAC, Bluetooth MAC, and that Wi-Fi no longer shows `NVRAM WARNING: Err = 0x10`.
