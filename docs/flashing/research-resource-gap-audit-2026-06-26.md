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
| `A1601EX_11_OTA_040_all_201907091708.zip` | Present as `official-ota-a40` |
| `A1601EX_11_OTA_041_all_201912261125.zip` | Present as `official-ota-a41` |
| `Oppo_F1S_A1601_MT6750_EX_11_A.15_160913.zip` | Present as `a15-scatter-local-record` |
| `Oppo_F1S_A1601_MT6750_EX_11_A.24_161119.zip` | Present as `a24-scatter-google-drive` |
| `A1601EX_11_A.40_190709` OFP/service package | Present as `a40-addrom-ofp-service` and extracted active A40 dataset |
| `A1601EX_11_A.41_191226.tar.bz2` | Present as `a41-ahmadservicecenter-tarbz2` |
| `OPPO-F1S-A1601EX_11_A.41_191226_RepairMyMobile.zip` | Present as `a41-rmm-ofp-mediafire` |

## Missing Actionable Firmware/Recovery Resources

These were specifically named by the research reports but are not currently
tracked as local assets or GitHub Release assets.

| Priority | Resource | Source from research | Why it matters | Notes |
|---:|---|---|---|---|
| 1 | `A1601EX_11_OTA_002_all_201704120142_wipe.zip` | Historical OPPO S3 URL | Official historical wipe OTA adjacent to D.01 package | Recovery ZIP only, not scatter/auth. Add as official OTA reference if downloadable. |
| 2 | `Oppo_F1S_A1601_(A1601EX_11_A.16_160920)_by_(FirmwareOS.com).zip` | Android File Host `fid=11410963190603863245` | Older scatter/full firmware with published MD5 | Medium-risk mirror, but useful because the research captured MD5 `9a9615ad062a062eea00c6fd12a57388`. |
| 3 | `Oppo_F1S_A1601_(A1601EX_11_A.33_170814)_by_(FirmwareOS.com).zip` | Android File Host `fid=11410963190603863341` | Later scatter/full firmware with published MD5 | Medium-risk mirror, MD5 `549bcb3680c7ed4ca16f15c4602cb9a7`. |
| 4 | `A1601EX_11_A.41_191226.rar` | GSM-Firmware file `id=59518` | Full/service A41 package in a different container from the tar.bz2 and RMM ZIP | Useful comparison candidate for OFP contents and possible verified/signed image differences. |
| 5 | `A1601EX_11_A.42_210906.zip` | HalabTech file `id=547512` | Latest named branch in the research | Medium-to-low confidence, but important because A42 may be newer than the installed branch. |
| 6 | `OPPO A1601EX No Auth Firmware` | HalabTech folder `id=94604` | Only A1601-specific no-auth listing found | Treat as research-only unless extracted and validated. Do not treat as OPPO-authentic. |
| 7 | `Oppo F1S A1601EX Official Firmware` | NeedROM page | Login-gated user-uploaded firmware whose instructions reference `MT6750_Android_scatter.txt` | Useful as documentation/source lead; package provenance is weak. |
| 8 | `A1601EX_11_A.24_161119 Scatter firmware` from HalabTech | HalabTech folder `id=94604` | Same build family as current A24, but from another source | Lower priority because A24 is already covered from Google Drive/AddROM/FirmwareFile-style source. |

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

## Next Manifest Work

Add optional, disabled-by-default entries to `firmware/download-manifest.json`
for the missing actionable resources, then download and validate one at a time.

The highest-value next downloads are:

1. `A1601EX_11_A.42_210906.zip`
2. `A1601EX_11_A.41_191226.rar`
3. A.16 Android File Host mirror
4. A.33 Android File Host mirror
5. `A1601EX_11_OTA_002_all_201704120142_wipe.zip`

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
