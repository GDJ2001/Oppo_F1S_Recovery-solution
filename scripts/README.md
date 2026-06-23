# Scripts

Windows PowerShell automation for the OPPO F1s flashing workflow.

Use `powershell/Start-F1sTerminalFlasher.ps1` as the main entry point.

Use `powershell/Restore-GitHubAssets.ps1` to restore release-hosted firmware/tools into the ignored local folders before validation. Use `powershell/Test-GitHubAssetReadiness.ps1`, `powershell/Prepare-GitHubAssets.ps1`, and `powershell/Publish-GitHubAssets.ps1` only after local assets have been validated.

The flashing scripts validate firmware and tools before asking for Preloader/VCOM mode. For this phone, connect powered off with no buttons first; if needed, retry only `Volume Up`, then only `Volume Down`.
