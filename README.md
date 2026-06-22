# OPPO F1s A1601 Recovery Tool

This repo contains the terminal-guided recovery workflow for an OPPO F1s A1601 / MT6750 phone. It validates a loose scatter firmware package, launches SP MDT/SP Flash tooling, monitors Windows preloader/VCOM detection, and prepares SN Write Tool for restoring only the phone's original IMEI.

## Main Commands

```powershell
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command status
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command prepare
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command flash -CountdownSeconds 20 -MonitorSeconds 90
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command monitor -MonitorSeconds 90
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command snwrite
```

## Active Layout

```text
config/     Device profile notes
docs/       Flashing and NVRAM/IMEI repair guides
drivers/    Local driver packages and extracted driver references, gitignored
firmware/   Local firmware packages and stock scatter firmware, gitignored
logs/       Runtime detection logs, gitignored
scripts/    PowerShell launchers, validators, and readiness checks
src/cli/    Terminal controller
tools/      Local SP MDT/SP Flash/SN Write/ADB tools, gitignored where binary
```

Do not commit firmware dumps, stock ROM packages, driver installers, third-party tool binaries, IMEI values, or generated logs.
