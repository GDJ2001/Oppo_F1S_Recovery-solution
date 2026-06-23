# Firmware

Local storage for firmware, recovery images, scatter files, and checksums.

- `stock/`: stock ROM or stock partition images
- `recovery/`: custom or patched recovery images
- `scatter/`: MediaTek scatter files
- `checksums/`: SHA-256 files and verification records

Large firmware binaries are ignored by Git. Commit only metadata, checksums, and notes.

Tracked redownload manifest:

- `download-manifest.json`: recorded firmware URLs, expected paths, sizes, hashes, and manual-source notes

GitHub Release asset metadata lives in `config/github-release-assets.json`. Firmware binaries are restored from GitHub Releases into ignored local folders before validation/flashing.
