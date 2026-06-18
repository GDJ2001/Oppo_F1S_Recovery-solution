# OPPO A1601 Official Recovery OTA

The connected phone reports:

```text
ro.product.model=A1601
ro.product.device=A1601
ro.build.display.id=A1601EX_11_D.01_170328
ro.product.board=full_oppo6750_15331
ro.board.platform=mt6750
ro.oppo.version=US
ro.build.version.opporom=V3.0.0i
```

The older scatter package in this repo is `A1601EX_11_A.15_160913`. It targets the same A1601/MT6750 family but is older than the phone's current installed build, so it should not be used blindly for a normal recovery.

## Downloaded Official OTA Packages

### D.01 Wipe Package - Current Branch Recovery Candidate

- Source: OPPO-hosted S3 firmware bucket
- URL: `http://downloads.oppo.com.s3.amazonaws.com/firmware/A1601%206.0/A1601EX_11_OTA_001_all_201703281552_wipe.zip`
- Local path: `firmware\ota\A1601EX_11_OTA_001_all_201703281552_wipe.zip`
- Size: `1581433299` bytes
- SHA-256: `4B1729DB654B4705C5AAA64129B688546F4152875B7D41F8AD49EB19E09DB748`
- MD5: `50A2097A0D423ED314B319ED0A7FA452`
- Metadata `version_name`: `A1601EX_11_D.01_170328`
- Metadata `ota-id`: `A1601EX_11.D.01_INT_001_201703281552`
- Metadata `wipe`: `1`
- Metadata `wipe-data`: `1`
- Result: not yet installed. This is a data-wiping recovery package and should only be selected after the user accepts data loss.

### A.41 - Recommended Official Recovery Candidate

- Source: OPPO-hosted S3 firmware bucket
- URL: `http://downloads.oppo.com.s3.amazonaws.com/firmware/A1601/A1601EX_11_OTA_041_all_201912261125.zip`
- Local path: `firmware\ota\A1601EX_11_OTA_041_all_201912261125.zip`
- Size: `1556852704` bytes
- SHA-256: `182EBD484B0CA85B176A10378BE2442EB0685E79AAE1523C8088C0452237F023`
- Metadata `version_name`: `A1601EX_11_A.41_191226`
- Metadata `pre-device`: `A1601`
- Metadata `wipe`: `0`

### A.40 - Older Candidate Rejected By Phone

- Source: OPPO-hosted S3 firmware bucket
- URL: `http://downloads.oppo.com.s3.amazonaws.com/firmware/A1601/A1601EX_11_OTA_040_all_201907091708.zip`
- Local path: `firmware\ota\A1601EX_11_OTA_040_all_201907091708.zip`
- Size: `1556821800` bytes
- SHA-256: `A42F3004B6628B74A3B115B6F9F72A0E49FE6FFAC710183ECD6F7C8C3847A71B`
- Metadata `version_name`: `A1601EX_11_A.40_190709`
- Metadata `pre-device`: `A1601`
- Metadata `wipe`: `0`
- Result: stock recovery rejected it because the installed OS was newer than the package.

The ZIP contains a recovery updater script and `META-INF/CERT.RSA`. It is intended for stock recovery/local update workflows, not SP Flash Tool scatter flashing.

Validate an OTA with:

```powershell
.\scripts\powershell\Test-A1601OtaPackage.ps1 -OtaPath firmware\ota\A1601EX_11_OTA_041_all_201912261125.zip
```

## Recovery Use

For a working phone that can enter stock recovery, use the newest official OPPO-hosted recovery OTA first. `A.41_191226` is newer than `A.40_190709`, but the phone rejected both because its installed branch/version compares higher. The D.01 wipe package matches the phone's reported `A1601EX_11_D.01_170328` branch and is the next stock-recovery candidate, but it wipes data. Public records mention `A.42_210906`, but I did not find an official OPPO-hosted recovery OTA URL for that build; those files currently appear on third-party firmware sites.

Important: the updater script writes boot, modem, loader, trustzone, and preloader images. Do not interrupt the update. Keep the battery charged and use the stock recovery/local update method only if the phone model is confirmed as `A1601`.
