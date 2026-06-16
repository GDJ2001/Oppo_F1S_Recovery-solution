# Oppo F1S Recovery Solution

Repository scaffold for a recovery utility targeting the OPPO F1s. The layout separates application code, device configuration, recovery assets, documentation, and local-only firmware/tooling.

## Folder Structure

```text
.
|-- assets/              # UI assets, icons, screenshots, and branding material
|-- config/              # Device profiles and runtime configuration templates
|-- docs/                # User guides, device notes, flashing steps, troubleshooting
|-- drivers/             # Driver notes and placeholders for local driver packages
|-- firmware/            # Local firmware/recovery files; large binaries are gitignored
|-- logs/                # Runtime/debug logs; ignored except for .gitkeep
|-- releases/            # Release notes and packaged build metadata
|-- scripts/             # Automation scripts for setup, validation, and packaging
|-- src/                 # Recovery tool source code
|-- tests/               # Unit, integration, and fixture-based tests
|-- tools/               # Local third-party tools such as ADB/Fastboot/SP Flash Tool
`-- .gitignore
```

## Notes

- Do not commit copyrighted firmware dumps, stock ROM packages, driver installers, or third-party tool binaries.
- Store checksums and source links in `firmware/checksums/` or folder README files instead of committing large packages.
- Keep device-specific assumptions in `config/devices/` so the recovery workflow can be reviewed and updated safely.
- The current A1601 recovery OTA research and local package notes are in `docs/flashing/a1601-official-ota.md`.
