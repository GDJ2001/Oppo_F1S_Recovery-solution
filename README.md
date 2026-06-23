# OPPO F1s A1601 Recovery Tool

This repo contains the terminal-guided recovery workflow for an OPPO F1s A1601 / MT6750 phone. It validates a loose scatter firmware package, launches SP MDT/SP Flash tooling, monitors Windows preloader/VCOM detection, and prepares SN Write Tool for restoring only the phone's original IMEI.

## Main Commands

Restore GitHub Release assets first when starting from a clean checkout:

```powershell
.\scripts\powershell\Restore-GitHubAssets.ps1 -Force
```

Prepare/publish assets after local downloads have been validated:

```powershell
.\scripts\powershell\Prepare-GitHubAssets.ps1 -Clean
.\scripts\powershell\Publish-GitHubAssets.ps1 -CreateRelease
```

Then use the guided flashing commands:

```powershell
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command status
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command prepare
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command flash -CountdownSeconds 20 -MonitorSeconds 90
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command monitor -MonitorSeconds 90
.\scripts\powershell\Start-F1sTerminalFlasher.ps1 -Command snwrite
```

For the live flash attempt, start the terminal flash command first, set SP MDT to normal download/`Download Only`, then connect the phone while it is fully powered off. Use no buttons first; if Preloader/VCOM is not detected, retry only `Volume Up`, then only `Volume Down`. Do not hold both volume buttons on this phone because that enters ColorOS Recovery.

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

Do not commit firmware dumps, stock ROM packages, driver installers, third-party tool binaries, IMEI values, or generated logs. Store large recovery assets in GitHub Releases using `config/github-release-assets.json`.
