# Release Validation Checklist — App Store & Play Store

Last updated: 2026-08-20

---

## Phase 1 — Assets (⚡ Owner action required)

- [ ] **App icon** — `assets/icon.png`, 1024×1024 PNG, no transparency, no rounded corners, solid background. Use AI prompt at `C:\PlaceWell\Docs\etsy\PlaceWell_App_Icon_AI_Prompt.txt`.
- [ ] **Splash screen** — `assets/splash.png`, 1242×2688 PNG, background `#F5F0E8`, centered logo.
- [ ] **Android adaptive icon** — `assets/adaptive-icon.png`, 1024×1024 PNG with transparent background, design within inner 66%.

## Phase 2 — Accounts & Config (⚡ Owner action required)

- [ ] **App Store Connect** — Create app at appstoreconnect.apple.com → Bundle ID `com.placewell.app`. Note numeric App ID and Apple Team ID. Fill into `eas.json`.
- [ ] **Google Play Console** — Create app at play.google.com/console → Package `com.placewell.app`.
- [ ] **Privacy Policy** — Host a privacy policy at a public URL (e.g. placewell.app/privacy). Required by both stores.
- [ ] **App Store screenshots** — Minimum: 6.7" iPhone (1290×2796). Screens: Home, Label Setup, Label Recall, Scanner.

## Phase 3 — Firebase Analytics (⚡ Owner action required)

- [ ] **iOS** — Download `GoogleService-Info.plist` from Firebase Console → iOS app (`com.placewell.app`). Place in `C:\PlaceWell\PlaceWellApp\`.
- [ ] **Android** — Download `google-services.json` from Firebase Console → Android app (`com.placewell.app`). Place in `C:\PlaceWell\PlaceWellApp\`.
- [ ] Add `@react-native-firebase/app` to `plugins` in `app.json`.

## Phase 4 — Security

- [ ] **Move secrets to EAS** — `hmacSecret` and `qrServiceToken` are currently hardcoded in `app.json`. Run:
  ```
  eas secret:create --name HMAC_SECRET --value "..."
  eas secret:create --name QR_SERVICE_TOKEN --value "..."
  ```
  Then update app code to read from EAS environment instead of `app.json` extra.

## Phase 5 — Build tooling

- [ ] Install EAS CLI: `npm install -g eas-cli`
- [ ] Login: `eas login`
- [ ] Ensure metro.config.js is committed (`resolverMainFields: ['react-native','main']`).
- [ ] Lock Expo SDK / React Native versions; confirm EAS support.
- [ ] Clear Metro cache: `npx expo start -c`

## Phase 6 — Pre-build validation

- [ ] `npx jest --no-coverage` — all tests passing (currently 232)
- [ ] Verify deep links on device: `placewell://scan`, `https://placewell.app/s/...`
- [ ] Verify camera, QR scan, photo picker on physical device
- [ ] Verify fonts load, storage init, all UX flows end-to-end

## Phase 7 — Build & Submit (iOS first)

- [ ] `eas build --platform ios --profile production`
- [ ] Submit to TestFlight: `eas submit --platform ios`
- [ ] Test on real iPhone via TestFlight — all flows verified
- [ ] Submit for App Store review in App Store Connect

## Phase 8 — Android

- [ ] `eas build --platform android --profile production`
- [ ] `eas submit --platform android`
- [ ] Submit for Google Play review

---

## Android Signing — SHA-256 Fingerprint

### What it is
The SHA-256 fingerprint uniquely identifies the Android keystore used to sign every PlaceWell build. It is required for:
- **`assetlinks.json`** — tells Android OS that `placewell.app` links should open directly in the PlaceWell app (App Links / Digital Asset Links)
- **Google Play signing verification** — proves future APK/AAB updates come from the same developer

### How to retrieve it
```
cd C:\PlaceWell\PlaceWellApp
eas credentials --platform android
```
Select **production** build profile. The fingerprint is shown under **Configuration: Build Credentials**.

### Current value (generated 2026-07-09)
```
SHA-256: 71:60:05:01:D2:63:A4:E1:65:90:AB:4A:10:49:00:6C:D1:2A:68:35:E6:15:0C:15:D9:B4:EE:89:9A:52:37:C7
Key Alias: 256c9dae2571d40de5b467e9171468ac
MD5:       82:4A:B9:24:1E:6D:22:C5:A0:7D:3A:42:9B:41:EB:FB
SHA1:      29:BE:03:5A:97:EB:D9:CD:16:CA:17:15:39:5D:77:96:63:BF:B7:53
```

### Is this one-time or recurring?
**One-time.** The keystore is stored permanently on EAS servers and reused for every future build. The SHA-256 fingerprint never changes as long as you use the same EAS keystore. Only needs updating if the keystore is ever regenerated (which would also break Play Store update delivery — avoid unless absolutely necessary).

### Where is assetlinks.json deployed?
- Live URL: `https://placewell.app/.well-known/assetlinks.json`
- Source copy: `C:\PlaceWell\Docs\deployment\assetlinks.json`
- Server path: `/var/www/placewell-well-known/.well-known/assetlinks.json`

### Where is apple-app-site-association deployed?
- Live URL: `https://placewell.app/.well-known/apple-app-site-association`
- Source copy: `C:\PlaceWell\Docs\deployment\apple-app-site-association`
- Server path: `/var/www/placewell-well-known/.well-known/apple-app-site-association`
- Apple Team ID: `CM5N45M892` / Bundle ID: `com.placewell.app`

---

## Current status (as of 2026-08-20)

| Item | Status |
|---|---|
| `eas.json` | ✅ Created |
| Bundle ID / package name | ✅ `com.placewell.app` |
| Permissions (camera, photos) | ✅ Declared |
| Deep link / universal link config | ✅ Configured |
| `assetlinks.json` (Android App Links) | ✅ Live at placewell.app |
| `apple-app-site-association` (iOS Universal Links) | ✅ Live at placewell.app |
| iOS production build | ✅ v1.0.0 build 9 |
| Android production build | ✅ v1.0.0 build 2 |
| iOS submitted to TestFlight | ✅ |
| Android uploaded to Play internal testing | ✅ |
| Stock-image paired production release | ✅ Firebase Hosting and Linode `current` verified on revision 1; 78 entries; manifest SHA-256 `15d924088ca75a955e532da6092f49dc0a2d26312b9ceda0bc83dd868a174a00` |
| Stock-image UI / QR Service contract | ✅ Production allocation and lookup return optional `image_key` |
| Stock-image physical-device validation | ⏳ Pending on iPhone and Android |
| App icon | ⏳ Placeholder — replace before App Store submission |
| Splash screen | ⏳ Placeholder |
| Firebase config files | ⏳ Deferred to Expo SDK 57 |
| Secrets in EAS | ❌ Still in app.json |
| Privacy policy | ❌ Pending |
| App Store screenshots | ❌ Pending |

---

Notes: EAS respects metro.config.js. If using a custom dev client or EAS builds, ensure the same metro config and native deps are used.