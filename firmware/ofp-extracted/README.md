# OFP Extraction Output

This folder is reserved for extracted OFP datasets. Firmware images under this
folder are ignored by Git because they are large local binaries.

Default extraction target:

`A1601EX_11_A40_190709_oppo6750_15331`

Run the local extractor app:

```powershell
.\tools\ofp-extractor\Extract-OFP-Dataset.ps1 -CleanOutput
```

The output should contain `MT6750_Android_scatter.txt`, nonzero images, and the
matching AP/MD database files before it is used for flashing or NVRAM repair.
