# Drivers

Keep driver installation notes and local-only driver package placeholders here.

- `adb-fastboot/`: ADB/Fastboot driver notes
- `mtk-usb/`: MediaTek USB/VCOM/preloader driver notes

Driver installers are ignored by Git. Document download sources and checksums instead.

MediaTek USB/VCOM driver CABs from Microsoft Update Catalog have been downloaded under `mtk-usb/` and extracted in place. Use:

```powershell
.\scripts\powershell\Install-MtkDrivers.ps1 -WhatIf
```

Run without `-WhatIf` from an Administrator PowerShell window to install the extracted driver `.inf` files.
