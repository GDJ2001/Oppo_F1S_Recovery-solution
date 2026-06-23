# F1s Terminal Flasher

This folder contains the repo-owned terminal controller for the OPPO F1s A1601 recovery flow.

It does not patch or replace SP Flash Tool. It validates firmware, prefers the local SP Flash Tool v5 runtime under `tools\sp-flash-tool`, launches the supported flasher, monitors Windows OPPO/MediaTek preloader state, and writes logs.

Commands:

```powershell
.\src\cli\f1s-flasher.ps1 status
.\src\cli\f1s-flasher.ps1 prepare
.\src\cli\f1s-flasher.ps1 flash -CountdownSeconds 20 -MonitorSeconds 90
.\src\cli\f1s-flasher.ps1 monitor -MonitorSeconds 90
.\src\cli\f1s-flasher.ps1 snwrite
```

Flashing still requires the MediaTek flashing engine. The terminal tool controls validation, setup, timing, and detection; it does not implement the proprietary MediaTek BROM/DA protocol itself.

During a live attempt, connect the phone fully powered off with no buttons first. If Preloader/VCOM is not detected, retry only `Volume Up`, then only `Volume Down`; do not hold both volume buttons on this phone.
