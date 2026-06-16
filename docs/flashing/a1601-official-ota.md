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

## Downloaded Official OTA

- Source: OPPO-hosted S3 firmware bucket
- URL: `http://downloads.oppo.com.s3.amazonaws.com/firmware/A1601/A1601EX_11_OTA_040_all_201907091708.zip`
- Local path: `firmware\ota\A1601EX_11_OTA_040_all_201907091708.zip`
- Size: `1556821800` bytes
- SHA-256: `A42F3004B6628B74A3B115B6F9F72A0E49FE6FFAC710183ECD6F7C8C3847A71B`
- Metadata `version_name`: `A1601EX_11_A.40_190709`
- Metadata `pre-device`: `A1601`
- Metadata `wipe`: `0`

The ZIP contains a recovery updater script and `META-INF/CERT.RSA`. It is intended for stock recovery/local update workflows, not SP Flash Tool scatter flashing.

Validate it with:

```powershell
.\scripts\powershell\Test-A1601OtaPackage.ps1
```

## Recovery Use

For a working phone that can enter stock recovery, this OTA package is a better first recovery candidate than the older A.15 scatter package. It targets `A1601` directly and is newer than the phone's current `D.01_170328` build.

Important: the updater script writes boot, modem, loader, trustzone, and preloader images. Do not interrupt the update. Keep the battery charged and use the stock recovery/local update method only if the phone model is confirmed as `A1601`.
