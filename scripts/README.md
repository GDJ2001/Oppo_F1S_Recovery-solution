# Scripts

Windows PowerShell automation for the OPPO F1s flashing workflow.

Use `powershell/Start-F1sTerminalFlasher.ps1` as the main entry point.

The flashing scripts validate firmware and tools before asking for Preloader/VCOM mode. For this phone, connect powered off with no buttons first; if needed, retry only `Volume Up`, then only `Volume Down`.
