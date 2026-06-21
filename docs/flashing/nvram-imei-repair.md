# OPPO F1s A1601 NVRAM and Original IMEI Repair

`NVRAM WARNING: Err = 0x10` and missing IMEI usually mean MediaTek NVRAM/NVDATA identity data is corrupted or empty. A recovery OTA or user-data wipe does not rebuild those records.

## Required Firmware State

First flash a complete loose scatter firmware package. OFP/service packages are not accepted for this workflow.

Expected firmware shape:

```text
firmware\stock\A1601EX_11_A24_161119\Firmware\MT6750_Android_scatter.txt
```

The same firmware directory must include matching AP and MD/BPLGU database files for SN Write Tool.

## SN Write Flow

After Android boots from a valid firmware flash:

```powershell
.\scripts\powershell\Get-NvramRepairReadiness.ps1 -FirmwareDir "firmware\stock\A1601EX_11_A24_161119\Firmware"
.\scripts\powershell\Start-SnWriteTool.ps1 -FirmwareDir "firmware\stock\A1601EX_11_A24_161119\Firmware"
```

Enter only the phone's original IMEI from the box/sticker/paperwork. Do not generate, borrow, modify, or store IMEI values.

## Verification

- `*#06#` shows the original IMEI.
- Baseband is present.
- SIM registration works.
- Wi-Fi no longer shows `NVRAM WARNING: Err = 0x10`.
- Wi-Fi/Bluetooth MAC addresses remain stable after reboot.
