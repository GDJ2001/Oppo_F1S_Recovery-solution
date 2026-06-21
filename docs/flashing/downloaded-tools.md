# Downloaded Tools And Firmware

This file records the local OPPO F1s A1601 flashing assets.

## Current Firmware In `firmware\stock`

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

The required target remains a loose scatter package:

```text
firmware\stock\A1601EX_11_A.40_190709\Firmware\MT6750_Android_scatter.txt
```

That directory must also contain all scatter-referenced image files with nonzero size plus matching AP/MD database files.

## Required Tools

At least one of these must exist under `tools`:

```text
tools\SP_Flash_Tool_V6*\**\SPFlashToolV6.exe
tools\sp-flash-tool\**\flash_tool.exe
tools\SP_MDT*\**\mdt.exe
```

SN Write Tool is needed after firmware flashing to restore only the phone's original IMEI manually:

```text
tools\SN_Write_Tool_v*\**\SN_Writer.exe
tools\sn-write-tool\**\SN_Writer.exe
```

Do not store IMEI values in this repository.
