# OFP Extraction Status

The repository now includes a local source-code OFP extractor application for
the OPPO F1s A1601 MediaTek service package.

## Extractor App

- Launcher:
  `tools\ofp-extractor\Extract-OFP-Dataset.ps1`
- CMD wrapper:
  `tools\ofp-extractor\Extract-OFP-Dataset.cmd`
- Core extractor:
  `scripts\python\extract_mtk_ofp.py`

Run:

```powershell
.\tools\ofp-extractor\Extract-OFP-Dataset.ps1 -CleanOutput
```

Default source OFP:

`firmware\stock\Firmware + Tool\oppo6750_15331.ofp`

Default output folder:

`firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331`

## Expected Validation

After extraction, run:

```powershell
.\scripts\powershell\Test-F1sFirmwarePackage.ps1 `
  -FirmwareDir ".\firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331"
```

Expected result: `Package status: OK`.

The output must include:

- `MT6750_Android_scatter.txt`
- nonzero scatter-referenced images
- matching AP/MD database files for SN Write/NVRAM repair

## Safety

Do not run downloaded OFP extractor executables directly in this repository.
Only run third-party GUI extractors inside an isolated VM/sandbox with a copied
OFP file and an empty output folder.
