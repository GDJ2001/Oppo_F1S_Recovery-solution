# Downloaded Flashing Tools

This file records the local tools downloaded for the OPPO F1s A1601 flashing workflow.

## Android Platform-Tools

- Source: Google Android Developers platform-tools download
- URL: `https://dl.google.com/android/repository/platform-tools-latest-windows.zip`
- Local ZIP: `tools\adb-fastboot\platform-tools-latest-windows.zip`
- Extracted directory: `tools\adb-fastboot\platform-tools`
- Verified version:
  - `adb.exe`: `Android Debug Bridge version 1.0.41`, `37.0.0-14910828`
  - `fastboot.exe`: `37.0.0-14910828`
- SHA-256: `4FE305812DB074CEA32903A489D061EB4454CBC90A49E8FEA677F4B7AF764918`
- Trust note: official Google download.

## MediaTek USB/VCOM Drivers

- Source: Microsoft Update Catalog search for `MediaTek USB VCOM drivers`
- Local directory: `drivers\mtk-usb`

Downloaded CAB packages:

| Package | Local path | SHA-256 |
| --- | --- | --- |
| MediaTek VCOM Windows 10 package | `drivers\mtk-usb\microsoft-mediatek-vcom-win10-2015.cab` | `CE72E97C07582AD41DEBFAEEE6F6284ECD28285DF5F9CAA05193653FB236561F` |
| MediaTek Android interfaces Windows 7/8.1 package | `drivers\mtk-usb\microsoft-mediatek-android-interfaces-win7-win81-2016.cab` | `86C3909A00973B960C761AC9A7992DAE5158E4C22966C0A3D849A586C04C359A` |

Direct Microsoft Catalog CAB URLs captured during download:

```text
https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2016/07/20896845_fdc6bb5aa9a9bac99adf85d931d6c21d1130a96e.cab
https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2016/08/20913465_17e56bbd9fe9351b9477154c0414ce86e21a42bb.cab
```

Driver install helper:

```powershell
.\scripts\powershell\Install-MtkDrivers.ps1 -WhatIf
```

Run without `-WhatIf` from an Administrator PowerShell window to install the extracted `.inf` files with `pnputil`.

## SP Flash Tool

- Source page: SoftPortal mirror for SP Flash Tool
- Download URL captured from the mirror page: `https://9r80o7.soft-load.eu/b3/5/1/3653515c170dcbe41d009d48220d1c29/en-SP_Flash_Tool_v5.1924_Win.zip`
- Local ZIP: `tools\sp-flash-tool\en-SP_Flash_Tool_v5.1924_Win.zip`
- Extracted executable: `tools\sp-flash-tool\SP_Flash_Tool_v5.1924_Win\SP_Flash_Tool_v5.1924_Win\flash_tool.exe`
- ZIP SHA-256: `90C6CC2C52D419B3442EBE0E6E020DF1BB12E4F26F00C0C8CD9394C39C6081D2`
- `flash_tool.exe` SHA-256: `67E9EB48161087D43ECA845B2DC0E9BEACAC3C0381BD1CE7989D48B17E2084A7`
- Trust note: no public official MediaTek download page was found. The ZIP hash matched the mirror's published SHA-256, but `flash_tool.exe` is not Authenticode-signed.

## Local Firmware

- Firmware archive: `Oppo_F1S_A1601_MT6750_EX_11_A.15_160913.zip`
- Firmware archive SHA-256: `A43CBA48ADC6DECC1E68D440D7D25F2E877972CB41CFA49896608410FD89E200`
- Extracted firmware directory: `firmware\stock\Oppo_F1S_A1601_MT6750_EX_11_A.15_160913\Firmware`
- Scatter file: `firmware\stock\Oppo_F1S_A1601_MT6750_EX_11_A.15_160913\Firmware\MT6750_Android_scatter.txt`

## Current Device State

Windows currently detects the phone as `OPPO A1601` over normal USB/MTP. It is not currently visible as a MediaTek preloader/VCOM flashing device. For SP Flash Tool, power the phone off and reconnect it in preloader mode after installing the MTK drivers.
