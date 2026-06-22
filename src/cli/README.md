# F1s Terminal Flasher

This folder contains the repo-owned terminal controller for the OPPO F1s A1601 recovery flow.

It does not patch or replace SP MDT/SP Flash Tool. It validates firmware, prefers the local `SP_MDT Unpacked` runtime when present, launches the supported flasher, monitors Windows OPPO/MediaTek preloader state, and writes logs.

Commands:

```powershell
.\src\cli\f1s-flasher.ps1 status
.\src\cli\f1s-flasher.ps1 prepare
.\src\cli\f1s-flasher.ps1 flash -CountdownSeconds 20 -MonitorSeconds 90
.\src\cli\f1s-flasher.ps1 monitor -MonitorSeconds 90
.\src\cli\f1s-flasher.ps1 snwrite
```

Flashing still requires the MediaTek flashing engine. The terminal tool controls validation, setup, timing, and detection; it does not implement the proprietary MediaTek BROM/DA protocol itself.
