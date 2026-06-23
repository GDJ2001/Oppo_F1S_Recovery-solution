# OFP Extractor

This folder is reserved for OFP extraction notes and local extractor assets.

Run the extractor app:

```powershell
.\tools\ofp-extractor\Extract-OFP-Dataset.ps1 -CleanOutput
```

Or double-click/run:

```cmd
tools\ofp-extractor\Extract-OFP-Dataset.cmd
```

The working extractor for this repo is:

`scripts\python\extract_mtk_ofp.py`

The extracted OPPO F1s A40 dataset is:

`firmware\ofp-extracted\A1601EX_11_A40_190709_oppo6750_15331`

Validated source OFP:

`firmware\stock\Firmware + Tool\oppo6750_15331.ofp`

Do not place or run unknown prebuilt OFP extractor executables directly in this
repository. If a GUI extractor is needed later, run it only inside a VM/sandbox
with a copied OFP file and an empty output folder.

Reference source projects used during research:

- `https://github.com/bkerler/oppo_decrypt`
- `https://github.com/mfdl/OPPO-MTK-OFP-EXTRACTOR`
