# Firmware Authentication Audit - 2026-06-24

## Scope

All reacquired OPPO F1s A1601 firmware archives were extracted under:

```text
firmware\scratch\archive-audit
```

Nested archives were also extracted. The A40 and both A41
`oppo6750_15331.ofp` files were decoded with the repository's source-code
extractor:

```text
scripts\python\extract_mtk_ofp.py
```

Bundled `DownloadTool.exe` files were not executed or modified.

## Result

No package contains a MediaTek/OPPO flashing authentication file.

The audit found none of the following:

- `*.auth`
- `auth_sv5.auth`
- a DAA/SLA authentication certificate or key
- `md1img-verified.img`
- another `*-verified.img` or `*-signed.img` modem image

The A15, A24, A40, and A41 scatter data all map partition `md1img` to
`md1rom.img`. This is the same unsigned/ordinary modem image layout that
triggered SP Flash Tool error `STATUS_SEC_INSUFFICIENT_BUFFER`.

## Package Matrix

| Package | Extracted form | Auth result | Other security files | Flash workflow result |
| --- | --- | --- | --- | --- |
| A15 scatter | Loose MT6750 scatter | No auth file | `15131-efuse_oppo6750.xml`, `Efuse.ini`, `secro.img` | Complete scatter package; validator passes |
| A24 scatter | Loose MT6750 scatter | No auth file | Same EFUSE/SECRO files; includes `DownloadTool.exe` | Images are complete, but active validator rejects the directory because `DownloadTool.exe` is present |
| A40 AddROM | OFP decoded to 20 entries | No auth entry or file | EFUSE/SECRO files; service wrapper includes `DownloadTool.exe` | Decoded dataset passes the structural validator |
| A41 RepairMyMobile | Nested ZIP, then OFP decoded to 20 entries | No auth entry or file | EFUSE/SECRO files; service wrapper includes `DownloadTool.exe` | Decoded dataset passes the structural validator |
| A41 AhmadServiceCenter | TAR.BZ2, then OFP decoded to 20 entries | No auth entry or file | EFUSE/SECRO files; service wrapper includes `DownloadTool.exe` | Decoded dataset passes the structural validator |
| Official A40 OTA | Recovery OTA | No flash auth file | Android `CERT.RSA`, `CERT.SF`, and `otacert` | Recovery signature only; not SP Flash authentication |
| Official A41 OTA | Recovery OTA | No flash auth file | Android `CERT.RSA`, `CERT.SF`, and `otacert` | Recovery signature only; not SP Flash authentication |
| Official D.01 OTA | Recovery wipe OTA | No flash auth file | Android `CERT.RSA`, `CERT.SF`, and `otacert` | Recovery signature only; not SP Flash authentication |

## OFP Findings

The A41 RepairMyMobile and AhmadServiceCenter OFP files are identical:

```text
SHA-256: F390361C228F27BE68C3E69C6A291EAAEE7C1DE9A22F7BDA8364541C554B7FDE
Size:    3273349456 bytes
```

The A40 OFP is different:

```text
SHA-256: FBD3CC8EBB421ADFA0D9C7D20E3BB6B6ABA03D9C64112DA79AA2143C4BF75DAC
Size:    3273349456 bytes
```

All three OFP files expose the same scatter and modem image hashes:

```text
MT6750_Android_scatter.txt:
3BB94DB342339AF4ED08515D4E02394901E68B39E46D186A31CDE07AB8B621DD

md1rom.img:
9E54644BDF8A7C45F0EF28C726E1C244A5DDA73748C041A3383A3AF8711572AA
```

The A41 preloader differs from A40, but neither package provides a verified
modem image.

## EFUSE Configuration

Every scatter/service package contains an EFUSE configuration with:

```text
Enable_SLA="false"
Enable_DAA="false"
```

This configuration does not override the phone's verified-partition checks.
It also does not convert `md1rom.img` into the `md1img-verified.img` requested
by SP Flash Tool.

## Safety Conclusion

Do not use Android OTA certificates as SP Flash auth files. Do not rename
`md1rom.img`, modify the scatter to claim that it is verified, or use a random
auth file from another OPPO/MediaTek device.

The current archives are useful for extraction, comparison, SN Writer
databases, and non-secure partition analysis. They do not provide the signed
modem image or legitimate service authentication path required to resolve the
observed secure-boot flashing error.
