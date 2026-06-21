# Downloaded Tools And Firmware

This file records the local OPPO F1s A1601 flashing assets.

## Current Firmware In `firmware\stock`

Validated SP Flash fallback:

```text
firmware\stock\A1601EX_11_A24_161119\Firmware
```

Source:

```text
https://drive.google.com/uc?id=1Ex9ZBmv6uH--xEJ8vgbDKvNghG0b63DA
listed by https://firmwarefile.com/oppo-a1601 and https://oppostockrom.com/oppo-f1s-a1601
```

Downloaded archive:

```text
firmware\downloads\Oppo_F1S_A1601_MT6750_EX_11_A.24_161119_google_drive.zip
```

SHA-256:

```text
52EEFBC19ED2E168F6C8CC52B3E2305790E70AAB447588F4FC6447B4C8AFC039
```

Validation result:

```text
Package status: OK
Scatter: firmware\stock\A1601EX_11_A24_161119\Firmware\MT6750_Android_scatter.txt
AP DB:   firmware\stock\A1601EX_11_A24_161119\Firmware\A1601EX_11_A.24_161119_database_AP
MD DB:   firmware\stock\A1601EX_11_A24_161119\Firmware\A1601EX_11_A.24_161119_database
```

Notes:

- The source archive included `DownloadTool.exe`; it was not used and was excluded from the clean stock firmware folder.
- Use this A24 package as the current validated SP Flash/SP MDT fallback because the available A40 package is OFP/service format.

User-provided A40 archive:

```text
firmware\stock\[up_addROM.com]_Oppo_F1S_A1601_EX_11_A.40_190709.zip
```

SHA-256:

```text
443D86FD94E4C1AAFB090018E5E88DD024C0844BB0DB1316F7C7A3012C0F83FE
```

Extracted service-package directory:

```text
firmware\stock\Firmware + Tool
```

Contents found:

```text
A1601EX_11_A.40_190709_database
A1601EX_11_A.40_190709_database_AP
DownloadTool.exe
oppo6750_15331.ofp
```

Important hashes:

```text
oppo6750_15331.ofp  FBD3CC8EBB421ADFA0D9C7D20E3BB6B6ABA03D9C64112DA79AA2143C4BF75DAC
DownloadTool.exe    0A037394E0EA0181AB208C3C108B5C6981E921A3E5F2B1D365481060FCC854DD
```

Status: rejected for this SP Flash workflow.

Reason:

- no `MT6750_Android_scatter.txt`
- no loose partition image files for SP Flash Tool
- contains `oppo6750_15331.ofp`
- contains `DownloadTool.exe`

The package may be an OPPO service/OFP firmware package, but this repo will not unpack or modify `DownloadTool.exe` to remove login or authorization checks.

## Required For Flashing

The current validated target is the loose A24 fallback:

```text
firmware\stock\A1601EX_11_A24_161119\Firmware\MT6750_Android_scatter.txt
```

That directory must also contain all scatter-referenced image files with nonzero size plus matching AP/MD database files.

## Required Tools

At least one of these must exist under `tools`. Current restored tool:

```text
tools\SP_MDT_v6.2228.00\SP_MDT_v6.2228.00\mdt.exe
```

Downloaded archive:

```text
tools\downloads\SP_MDT_v6.2228.00.zip
```

SHA-256:

```text
94FBA3A15EA101E63BE185F1D0597EBD65CB33896545F53819A09AE0E80A4D2D
```

Other accepted executable shapes:

```text
tools\SP_Flash_Tool_V6*\**\SPFlashToolV6.exe
tools\sp-flash-tool\**\flash_tool.exe
tools\SP_MDT*\**\mdt.exe
```

SN Write Tool is needed after firmware flashing to restore only the phone's original IMEI manually:

```text
tools\SN_Write_Tool_v1.2436.00\SN_Write_Tool_v1.2436.00\SN_Writer.exe
```

Downloaded archive:

```text
tools\downloads\SN_Write_Tool_v1.2436.00.zip
```

SHA-256:

```text
799E9949CCC14DF58BDC8E43F2647276A224D2164AA23EB626C1471E2F26C157
```

Do not store IMEI values in this repository.
