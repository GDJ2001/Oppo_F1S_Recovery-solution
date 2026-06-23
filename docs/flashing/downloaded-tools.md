# Downloaded Tools And Firmware

This file records the local OPPO F1s A1601 flashing assets.

## Current Firmware Dataset

Current OFP-extracted scatter dataset:

```text
firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331
```

Source:

```text
firmware\stock\Firmware + Tool\oppo6750_15331.ofp
```

Extraction app:

```text
tools\ofp-extractor\Extract-OFP-Dataset.ps1
```

Source OFP SHA-256:

```text
FBD3CC8EBB421ADFA0D9C7D20E3BB6B6ABA03D9C64112DA79AA2143C4BF75DAC
```

Validation result:

```text
Package status: OK
Scatter: firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331\MT6750_Android_scatter.txt
AP DB:   firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331\A1601EX_11_A.40_190709_database_AP
MD DB:   firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331\A1601EX_11_A.40_190709_database
```

Notes:

- Firmware binaries and extracted images are local-only and ignored by Git.
- Do not use or patch OPPO `DownloadTool.exe`.
- Use SP Flash Tool v5 with the extracted scatter dataset.

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

The current target is the OFP-extracted A40 scatter dataset:

```text
firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331\MT6750_Android_scatter.txt
```

That directory must also contain all scatter-referenced image files with nonzero size plus matching AP/MD database files.

## Required Tools

SP Flash Tool v5 should exist under:

```text
tools\sp-flash-tool\**\flash_tool.exe
```

Redownloaded archive:

```text
tools\downloads\en-SP_Flash_Tool_v5.1924_Win.zip
```

SHA-256:

```text
90C6CC2C52D419B3442EBE0E6E020DF1BB12E4F26F00C0C8CD9394C39C6081D2
```

Other accepted executable shapes:

```text
tools\sp-flash-tool\**\flash_tool.exe
```

SN Write Tool is needed after firmware flashing to restore only the phone's original IMEI manually:

```text
tools\sn-write-tool\**\SN_Writer.exe
```

Downloaded archives should be kept under:

```text
tools\downloads\
```

Do not store IMEI values in this repository.

## Driver Readiness

Installed driver-store entry:

```text
Published name: oem157.inf
Original name:  cdc-acm.inf
Provider:       MediaTek Inc.
Version:        01/04/2023 3.0.1512.0
Signer:         Microsoft Windows Hardware Compatibility Publisher
```

The exported INF contains the OPPO preloader hardware ID:

```text
USB\VID_22D9&PID_0006
```

Local driver source archive:

```text
drivers\oppo-usb-driver-v4.0.1.6\Oppo-USB-Driver-Setup-V4.0.1.6.zip
```

SHA-256:

```text
CB4B8454A012685FE13B142C8486F29AABE7DE462D6277AB11FEF553360F2FFC
```

Additional Microsoft Catalog driver staged for reference:

```text
drivers\mtk-usb\microsoft-catalog-mediatek-preloader-win10-2015\20896845_fdc6bb5aa9a9bac99adf85d931d6c21d1130a96e.cab
```

SHA-256:

```text
CE72E97C07582AD41DEBFAEEE6F6284ECD28285DF5F9CAA05193653FB236561F
```
