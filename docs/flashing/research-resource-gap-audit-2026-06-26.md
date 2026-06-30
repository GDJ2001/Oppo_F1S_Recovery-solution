# Research Resource Gap Audit - 2026-06-26

This audit compares `Special/deep-research-report.md` and
`Special/deep-research-report2.md` against the current firmware/release
manifests.

## Already Covered In Project Assets

These resources from the research are already represented in
`firmware/download-manifest.json` and/or `config/github-release-assets.json`.

| Research resource | Project coverage |
|---|---|
| `A1601EX_11_OTA_001_all_201703281552_wipe.zip` | Present as `official-ota-d01-wipe` |
| `A1601EX_11_OTA_002_all_201704120142_wipe.zip` | Present as `official-ota-002-wipe` after 2026-06-26 download |
| `A1601EX_11_OTA_040_all_201907091708.zip` | Present as `official-ota-a40` |
| `A1601EX_11_OTA_041_all_201912261125.zip` | Present as `official-ota-a41` |
| `Oppo_F1S_A1601_MT6750_EX_11_A.15_160913.zip` | Present as `a15-scatter-local-record` |
| `Oppo_F1S_A1601_(A1601EX_11_A.16_160920)_by_(FirmwareOS.com).zip` | Present as `a16-androidfilehost` after 2026-06-26 download |
| `Oppo_F1S_A1601_(A1601EX_11_A.33_170814)_by_(FirmwareOS.com).zip` | Present as `a33-androidfilehost` after 2026-06-30 download |
| `Oppo_F1S_A1601_MT6750_EX_11_A.24_161119.zip` | Present as `a24-scatter-google-drive` |
| `A1601EX_11_A.40_190709` OFP/service package | Present as `a40-addrom-ofp-service` and extracted active A40 dataset |
| `A1601EX_11_A.41_191226.tar.bz2` | Present as `a41-ahmadservicecenter-tarbz2` |
| `OPPO-F1S-A1601EX_11_A.41_191226_RepairMyMobile.zip` | Present as `a41-rmm-ofp-mediafire` |

## Remaining Actionable Firmware/Recovery Resources

These were specifically named by the research reports and are tracked in the
download manifest, but they are not currently present as verified local files.

| Priority | Resource | Source from research | Why it matters | Notes |
|---:|---|---|---|---|
| 1 | `A1601EX_11_A.41_191226.rar` | GSM-Firmware file `id=59518` | Full/service A41 package in a different container from the tar.bz2 and RMM ZIP | Useful comparison candidate for OFP contents and possible verified/signed image differences. |
| 2 | `A1601EX_11_A.42_210906.zip` | HalabTech file `id=547512` | Latest named branch in the research | Medium-to-low confidence, but important because A42 may be newer than the installed branch. |
| 3 | `OPPO A1601EX No Auth Firmware` | HalabTech folder `id=94604` | Only A1601-specific no-auth listing found | Treat as research-only unless extracted and validated. Do not treat as OPPO-authentic. |
| 4 | `Oppo F1S A1601EX Official Firmware` | NeedROM page | Login-gated user-uploaded firmware whose instructions reference `MT6750_Android_scatter.txt` | Useful as documentation/source lead; package provenance is weak. |
| 5 | `A1601EX_11_A.24_161119 Scatter firmware` from HalabTech | HalabTech folder `id=94604` | Same build family as current A24, but from another source | Lower priority because A24 is already covered from Google Drive/AddROM/FirmwareFile-style source. |

## Missing Auth-Adjacent Research Artifacts

These are not safe default flashing resources, but the research named them as
auth/custom-bin leads. Keep them separate from active firmware assets.

| Priority | Resource | Source from research | Intended handling |
|---:|---|---|---|
| 1 | `PRELOADER AUTH DA FILE (BFT)` | NeedROM generic auth/DA bundle | Research-only. Generic `Auth_sv5.auth`, `New_sv5.auth`, and DA collection; not A1601-specific. Do not use as trusted auth. |
| 2 | `A1601_Tested_Custom.Bin_File_By_Filewale.com.zip` | Filewale | Research-only. Tiny third-party `custom.bin` lead, not an OPPO source. |
| 3 | `OPPO F1 PLUS (A1601) CM2 MT2 Boot File By GSM Tested File` | GSM Tested File | Research-only. High mislabel risk because it says F1 Plus while A1601 is F1s. |

## Mentioned But Not Yet Actionable

The reports mention builds or repositories without a concrete package already
captured in the project manifest.

- A.36, A.37, A.38, A.39 branches surfaced in search context.
- Archived official public references for A.37, A.40, and A.41 were mentioned;
  A.40 and A.41 are covered, A.37 is not.
- GBFirmware, ROMDevelopers, OppoStockROM, HardReset, XDA, GSMHosting,
  Whirlpool, Martview, Telegram-indexed results, and Reddit were search
  surfaces, but no additional exact asset is currently tracked from them.

## Manifest Work

The missing research resources now have manifest entries. Public downloads are
verified locally where possible; gated/manual sources remain documented source
leads.

## Acquisition Status

This section records the state after the gap-closure download passes.

| Resource | Status | Evidence / next action |
|---|---|---|
| `A1601EX_11_OTA_002_all_201704120142_wipe.zip` | Acquired | Downloaded from historical OPPO S3 URL. Size `1581428614`, SHA-256 `FC1C90533289F14AE2345C30232F4E059D140B1475A6D420366F0ADBA5B8F097`, MD5 `AFF5866444EBCCAE44ED837985602E22`. Archive lists expected recovery OTA files including `boot.img`, `lk.bin`, `md1rom.img`, `preloader_oppo6750_15131.bin`, `scatter.txt`, `system.new.dat`, `system.transfer.list`, and Android OTA certificates. |
| `Oppo_F1S_A1601_(A1601EX_11_A.16_160920)_by_(FirmwareOS.com).zip` | Acquired | Downloaded from AndroidFileHost mirror endpoint. Size `1614050748`, SHA-256 `ED7807463F8A32A24C1D445B5892906DFB43D0C609CB822851100DCF644A74C9`, MD5 `9A9615AD062A062EEA00C6FD12A57388`. Archive wrapper contains nested `Firmware/A1601EX_11_A.16_160920.zip`. |
| `Oppo_F1S_A1601_(A1601EX_11_A.33_170814)_by_(FirmwareOS.com).zip` | Acquired | Downloaded from AndroidFileHost mirror endpoint. Size `1633642442`, SHA-256 `53557236B60E94767CE06720B711C9A8C3362B16C2604B69FA7A93FDD0B1595A`, MD5 `549BCB3680C7ED4CA16F15C4602CB9A7`. Archive wrapper contains nested `Firmware/A1601EX_11_A.33_170814.zip`. |
| `A1601EX_11_A.41_191226.rar` | Manual/gated | GSM-Firmware page redirects/protects direct download. Keep manifest entry as manual unless a lawful direct archive is provided. |
| `A1601EX_11_A.42_210906.zip` | Manual/gated | HalabTech/GiveMeROM download endpoints redirect without a valid session, Filewale requires sign-in, and GBFirmware exposes public metadata but its React download component uses an authenticated `/api/v1/auth/files/{id...}` route. Keep as manual until user supplies the archive or a public direct source is found. |
| `OPPO A1601EX No Auth Firmware` | Manual/research-only | HalabTech folder listing only. Do not use as active flashing input without extraction and validation. |
| NeedROM A1601EX firmware | Manual/research-only | Login-gated; keep as a source lead only unless a lawful archive is supplied and validated. |
| NeedROM generic auth/DA bundle | Acquired/research-only/quarantined | Manually copied from `C:\Users\GDJ\Downloads` to `firmware\downloads\research-only\PRELOADER_AUTH_DA_FILE_BFT\Preloader-Auth-DA-Files-BFT_Needrom.rar`. Size `453729624`, SHA-256 `E05EE4209AFE49FFB66A057841B9FEC30CB51A77130AFE92D35A925B0AE734A8`. Archive listing has 3525 entries, including generic `auth_sv5.auth` variants, generic MTK DA binaries, OPPO/MT6750-looking preloaders, and a `BYPASS` folder. This is not A1601-specific and must not be treated as trusted auth. |
| Filewale `custom.bin` and GSM Tested File CM2 boot helper | Manual/research-only | Both remain untrusted research leads. The CM2 boot helper has high mislabel risk because it says F1 Plus while A1601 is F1s. |

## Remaining Download Priority

The highest-value remaining downloads are:

1. `A1601EX_11_A.42_210906.zip`
2. `A1601EX_11_A.41_191226.rar`
3. HalabTech `OPPO A1601EX No Auth Firmware` listing, research-only

The remaining items are not failed validations; they are access-controlled
source leads. Do not attempt to bypass login/session checks or scrape protected
file URLs. If the user obtains those archives manually, place them at the
manifest destination paths and run the extraction/auth audit before promotion.

Do not spend time reacquiring A16, A33, or OTA_002 unless their local files fail
hash verification.

For every downloaded candidate, extract to scratch first, then search for:

- `MT6750_Android_scatter.txt`
- `*.auth`
- `custom.bin`
- `*DA*`
- `*-verified.img`
- `*-signed.img`
- AP database files
- MD/BPLGU/database files
- A1601/A1601EX/oppo6750 identity markers

Do not promote any resource into the active flashing path unless the validator
passes and the package does not require OPPO `DownloadTool.exe`.
