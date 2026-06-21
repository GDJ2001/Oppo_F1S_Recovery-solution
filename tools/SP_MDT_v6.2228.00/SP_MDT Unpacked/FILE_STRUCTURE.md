# SP Multiport Download Tool v6.2228.00 — File Structure

> Unpacked from `SP_MDT_v6.2228.00` packed distribution by spmdttool.com

---

## Directory Tree

```
SP_MDT Unpacked/
│
├── mdt.exe                              # Main executable (SP Multiport Download Tool)
├── mdt_resource.res                     # Compiled Qt resource bundle (icons, UI assets)
├── mdt_setting.ini                      # Primary application settings (clean/default)
├── mdt_setting.ini.PzgpmK              # Settings backup variant
├── mdt_setting.ini.TvVhvg              # Settings backup variant
├── mdt_setting.ini.wqrTBH              # Settings backup variant (FormatAllAndDownload scene)
│
├── SP_MultiportDownload.ini             # DA options config (default)
├── SP_MultiportDownload.ini.HzLawe     # Extended config backup (full download settings)
├── SP_MultiportDownload.ini.NnHQas     # Extended config backup
├── SP_MultiportDownload.ini.SjtIHw     # Extended config backup
├── SP_MultiportDownload.ini.uwuIcc     # Extended config backup
│
├── Credits.txt                          # Distribution credits (spmdttool.com)
├── How-to Use.url                       # Shortcut → https://androidmtk.com/use-sp-multiport-download-tool
├── Official Website.url                 # Shortcut → https://spmdttool.com/
│
│   ┌──────────────────────────────────────────────────────────────┐
│   │  CORE LIBRARIES (MediaTek Flash / Image / SLA)              │
│   └──────────────────────────────────────────────────────────────┘
├── flash.dll                            # Windows flash engine library
├── flash.lib                            # Import library for flash.dll
├── libflash.1.0.0.so                   # Linux flash engine shared object
├── imageChecker.dll                     # Windows image integrity checker
├── imageChecker.lib                     # Import library for imageChecker.dll
├── libimagechecker.1.0.0.so            # Linux image checker shared object
├── SLA_Challenge.dll                    # Secure Library Authentication challenge DLL
├── SLA_Challenge.lib                    # Import library for SLA_Challenge.dll
│
│   ┌──────────────────────────────────────────────────────────────┐
│   │  OPENSSL LIBRARIES                                          │
│   └──────────────────────────────────────────────────────────────┘
├── libeay32.dll                         # OpenSSL crypto library (runtime)
├── libeay32.lib                         # OpenSSL crypto static/import library (12.5 MB)
│
│   ┌──────────────────────────────────────────────────────────────┐
│   │  QT 5 FRAMEWORK                                             │
│   └──────────────────────────────────────────────────────────────┘
├── Qt5Core.dll                          # Qt5 core module
├── Qt5Gui.dll                           # Qt5 GUI module
├── Qt5Widgets.dll                       # Qt5 widgets module
├── Qt5Xml.dll                           # Qt5 XML parsing module
│
│   ┌──────────────────────────────────────────────────────────────┐
│   │  MSVC C++ RUNTIME (Visual Studio 2015/2017)                 │
│   └──────────────────────────────────────────────────────────────┘
├── concrt140.dll                        # Concurrency Runtime (release)
├── concrt140d.dll                       # Concurrency Runtime (debug)
├── msvcp140.dll                         # MS C++ Standard Library (release)
├── msvcp140d.dll                        # MS C++ Standard Library (debug)
├── ucrtbase.dll                         # Universal CRT (release)
├── ucrtbased.dll                        # Universal CRT (debug)
├── vccorlib140.dll                      # VC CoreLib (release)
├── vccorlib140d.dll                     # VC CoreLib (debug)
├── vcruntime140.dll                     # VC Runtime (release)
├── vcruntime140d.dll                    # VC Runtime (debug)
│
│   ┌──────────────────────────────────────────────────────────────┐
│   │  SUBDIRECTORIES                                             │
│   └──────────────────────────────────────────────────────────────┘
├── Driver/
│   └── Download MediaTek Driver.url     # Shortcut → https://mtkdriver.com/latest
│
├── plugins/
│   └── platforms/                       # Qt platform integration plugins
│       ├── qdirect2d.dll                # Direct2D platform (release)
│       ├── qdirect2dd.dll               # Direct2D platform (debug)
│       ├── qminimal.dll                 # Minimal platform (release)
│       ├── qminimald.dll                # Minimal platform (debug)
│       ├── qoffscreen.dll              # Offscreen platform (release)
│       ├── qoffscreend.dll             # Offscreen platform (debug)
│       ├── qwindows.dll                 # Windows platform (release)
│       └── qwindowsd.dll               # Windows platform (debug)
│
└── styles/
    └── qwindowsvistastyle.dll           # Qt Windows Vista/Aero style plugin
```

---

## File Categories Summary

| Category                        | Files | Total Size (approx) |
|---------------------------------|------:|---------------------:|
| Main Application                |     2 |            ~790 KB  |
| Configuration (.ini)            |     9 |             ~6 KB   |
| Core Libraries (flash/SLA)      |     8 |             ~4.5 MB |
| OpenSSL                         |     2 |            ~13.8 MB |
| Qt 5 Framework                  |     4 |            ~15.3 MB |
| Qt Plugins (platforms + styles) |     9 |            ~13.8 MB |
| MSVC C++ Runtime                |    10 |             ~7.1 MB |
| Documentation / Links           |     3 |             <1 KB   |
| Driver shortcuts                |     1 |             <1 KB   |
| **Total**                       | **48**|          **~55 MB** |

---

## Configuration Files Explained

### `mdt_setting.ini` (Primary Settings)
Controls the MDT application behavior:
- **[Files]** — Paths to Auth, Cert, and Flash XML files
- **[DownloadSetting]** — Auto-polling and comport selection
- **[DAOptions]** — Download Agent battery, logging, checksum settings
- **[DownloadScene]** — Flash operation mode (FirmwareUpgrade, FormatAllAndDownload, etc.)
- **[EfuseSettings]** — eFuse blow/readback configuration
- **[RebootScene]** — Post-flash reboot mode (META, Normal, etc.)
- **[MetaSetting]** — META mode connection settings (USB/UART, Modem/ADB log)
- **[ComportNumber]** — Up to 16 COM port channel assignments

### `SP_MultiportDownload.ini` (DA Options)
Minimal config for Download Agent (DA) settings:
- Battery detection mode
- UART/USB logging configuration
- Checksum verification toggles

### `.ini.XXXXXX` Backup Files
These are auto-generated backup/rollback snapshots of the configuration files, created by the application when settings are modified. They can be safely ignored or deleted.

---

## Key Components

| Component              | Purpose                                                      |
|------------------------|--------------------------------------------------------------|
| `mdt.exe`              | Main GUI application for multi-port firmware download        |
| `flash.dll`            | MediaTek flash engine — handles firmware write operations    |
| `imageChecker.dll`     | Validates firmware image integrity before flashing           |
| `SLA_Challenge.dll`    | Handles Secure Library Authentication (device auth)          |
| `libeay32.dll`         | OpenSSL cryptographic operations (secure communication)      |
| `Qt5*.dll`             | Qt5 GUI framework for the user interface                     |
| `plugins/platforms/*`  | Qt platform abstraction layer (Windows rendering backends)   |
| `styles/*`             | Qt visual style plugins (Windows Vista/Aero look)            |

---

## Notes

- The `.so` files (`libflash.1.0.0.so`, `libimagechecker.1.0.0.so`) are **Linux shared objects** included alongside the Windows build — likely for cross-platform support or bundled from the same build system.
- Both **release** and **debug** variants of MSVC runtime and Qt platform plugins are included — the debug versions (`*d.dll`) are not required for normal operation.
- The application requires **MediaTek USB VCOM drivers** to be installed. Use the `Driver/Download MediaTek Driver.url` shortcut to obtain them.
