# OPPO F1s A1601 NVRAM and Original IMEI Repair

The Wi-Fi network name `NVRAM WARNING: Err = 0x10` and a missing IMEI usually indicate corrupted or empty MediaTek NVRAM/NVDATA identity records. A recovery OTA or user-data wipe does not rebuild those records.

## Current Local State

- Existing full scatter firmware: `A1601EX_11_A.15_160913`
- Downloaded preferred firmware: `A1601EX_11_A.41_191226`
- Downloaded A.41 firmware type: OPPO `.ofp` service package, not a loose SP Flash Tool scatter package
- SN Write Tool archive: `tools\sn-write-tool\SN_Write_Tool_v1.2020.00.zip`
- SN Write executable: `tools\sn-write-tool\SN_Write_Tool_v1.2020.00\SN_Write_Tool_v1.2020.00\SN_Writer.exe`
- Important trust note: `SN_Writer.exe` is not Authenticode-signed.

## Firmware Requirement

Use a complete A1601 scatter/service firmware package. A valid loose scatter package must include:

- `MT6750_Android_scatter.txt`
- boot/system/modem images referenced by the scatter
- AP database file, commonly named like `*_database_AP`
- MD/BPLGU database file, commonly named like `*_database` or `BPLGU*`

The downloaded A.41 package includes `oppo6750_15331.ofp`, `DownloadTool.exe`, and A.41 AP/MD database files. Use OPPO DownloadTool for this package. The already extracted A.15 package has a scatter and AP/MD database files, but it is old.

Known indexed candidates:

| Build | Source | Notes |
| --- | --- | --- |
| `A1601EX_11_A.42_210906.zip` | Filewale / GB Firmware / HalabTech indexes | Public pages list 1.63 GB packages, but downloads may require login or paid access. |
| `A1601EX_11_A.41_191226` | RepairMyMobile / Filewale / HalabTech indexes | RepairMyMobile recommends A.41 for F1s A1601; MediaFire mirror was unstable during download. |
| `A1601EX_11_A.15_160913` | Local repo package | Usable fallback for validation and database selection, but older than the phone's branch. |

## Workflow

1. For the downloaded A.41 OFP package, validate and open OPPO DownloadTool:

   ```powershell
   .\scripts\powershell\Start-OppoDownloadTool.ps1 -ValidateOnly
   .\scripts\powershell\Start-OppoDownloadTool.ps1
   ```

   Power the phone off before connecting it for the actual flash. The phone must appear as MediaTek preloader/VCOM, not normal MTP.

2. For a loose scatter package, validate the full scatter firmware:

   ```powershell
   .\scripts\powershell\Test-F1sFirmwarePackage.ps1 -FirmwareDir "firmware\stock\<package>\Firmware"
   ```

3. Confirm SP Flash readiness:

   ```powershell
   .\scripts\powershell\Get-FlashingReadiness.ps1
   ```

4. Flash a loose scatter package using SP Flash Tool GUI:

   ```powershell
   .\scripts\powershell\Start-SpFlashTool.ps1 -FirmwareDir "firmware\stock\<package>\Firmware"
   ```

   Use `Download Only` first. Leave `preloader` unchecked unless the package is confirmed exact for the A1601 hardware variant or the device is hard-bricked.

5. Boot Android and confirm baseband is present.

6. Check NVRAM repair readiness:

   ```powershell
   .\scripts\powershell\Get-NvramRepairReadiness.ps1 -FirmwareDir "firmware\stock\A1601EX_11_A.41_191226_RepairMyMobile\A1601EX_11_A.41_191226_RMM"
   ```

7. Start SN Write Tool:

   ```powershell
   .\scripts\powershell\Start-SnWriteTool.ps1 -FirmwareDir "firmware\stock\A1601EX_11_A.41_191226_RepairMyMobile\A1601EX_11_A.41_191226_RMM"
   ```

   The helper copies AP/MD database paths to the clipboard. In SN Write Tool, select the copied AP/MD database files and enter only the phone's original IMEI from its box, sticker, receipt, SIM tray label, or carrier paperwork.

## Verification

After repair:

- `*#06#` or Settings must show the original IMEI.
- Baseband must be non-empty.
- Wi-Fi scan must no longer show `NVRAM WARNING: Err = 0x10`.
- Wi-Fi/Bluetooth MAC addresses should be non-null and stable after reboot.
- SIM registration and mobile signal should work.

## Safety Rules

- Do not write a generated, random, or borrowed IMEI.
- Do not use `Format All + Download` unless every lower-risk option has failed and you have accepted that it can erase calibration/identity partitions.
- Keep any readback backup of `nvram`, `nvdata`, `protect1`, `protect2`, and `proinfo` if you can obtain one before formatting.
- Do not flash firmware for a different OPPO model or storage variant.
