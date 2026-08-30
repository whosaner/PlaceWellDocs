# Release Validation Checklist - App Store & Play Store

Last updated: 2026-08-30

## Release target

| Item | Value |
|---|---|
| Marketing version | `1.1.0` |
| iOS bundle identifier | `com.placewell.app` |
| Android package | `com.placewell.app` |
| EAS build profile | `production` |
| Version source | EAS remote |
| Build numbers | Automatically incremented by EAS |

## 1. Local release preparation

- [x] Version updated to `1.1.0` in `app.json` and `package.json`
- [x] iOS and Android identifiers remain `com.placewell.app`
- [x] Production builds use EAS remote versioning and `autoIncrement`
- [x] Required icon, splash, and adaptive-icon files exist
- [ ] Confirm the production EAS environment contains `HMAC_SECRET` and `LOOKUP_SECRET`
- [x] Confirm Expo/EAS authentication with `npx eas-cli whoami`
- [ ] Confirm Android submission credentials are available to EAS
- [x] Run `npx expo config --type public`
- [x] Run `npx jest --no-coverage --maxWorkers=2` - 31 suites, 423 tests passed
- [ ] Commit and push the release-preparation changes
- [ ] Merge the approved feature branch into `main`

## 2. Production builds

- [ ] Build iOS and Android with:
  ```
  npx eas-cli build --platform all --profile production
  ```
- [ ] Record the EAS build URLs and assigned build numbers below

| Platform | Version | Build number | EAS build URL | Status |
|---|---:|---:|---|---|
| iOS | 1.1.0 | Pending | Pending | Not started |
| Android | 1.1.0 | Pending | Pending | Not started |

## 3. Store-track validation

- [ ] Submit the iOS build to App Store Connect/TestFlight
- [ ] Install the TestFlight build on a physical iPhone
- [ ] Submit the Android build to a Google Play internal or closed track
- [ ] Install the Play-distributed build on a physical Android device
- [ ] Verify launch, storage initialization, fonts, and navigation
- [ ] Verify camera permission denial, Open Settings recovery, and QR scanning
- [ ] Verify photo-library selection, custom-photo removal, and stock-artwork restoration
- [ ] Verify rapid bulk import and stock-artwork preparation
- [ ] Verify offline launch with previously cached stock artwork
- [ ] Verify deep links: `placewell://scan` and `https://placewell.app/s/...`
- [ ] Confirm no release-blocking crash or persistent loading state

## 4. Production rollout

- [ ] Submit version 1.1.0 for App Store review
- [ ] Promote version 1.1.0 through Google Play review/production rollout
- [ ] Record submission and approval status below

| Store | Submission status | Review status | Live status |
|---|---|---|---|
| Apple App Store | Not submitted | Not started | Version 1.0.0 currently live |
| Google Play | Not submitted | Not started | Version 1.0.0 previously uploaded to internal testing |

## Existing production configuration

- App Store Connect app ID: `6788545365`
- Apple team ID: `CM5N45M892`
- Universal links: `https://placewell.app/.well-known/apple-app-site-association`
- Android App Links: `https://placewell.app/.well-known/assetlinks.json`
- Android signing SHA-256:
  `71:60:05:01:D2:63:A4:E1:65:90:AB:4A:10:49:00:6C:D1:2A:68:35:E6:15:0C:15:D9:B4:EE:89:9A:52:37:C7`
- Stock-image manifest:
  `https://placewell-prod-60ef3.web.app/stock-images/manifest.v1.json`

## Release notes

- Expo Go functional testing of the stock-artwork update is complete.
- Production-native validation remains mandatory because Expo Go does not exercise the exact store binary, signing, or distribution environment.
- Firebase Analytics native configuration remains deferred; it is not a version 1.1.0 release dependency.
- Update this file after every build, store submission, review decision, or rollout status change.
