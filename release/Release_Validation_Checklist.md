# Release Validation Checklist — App Store & Play Store

Last updated: 2026-07-07

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

## Current status (as of 2026-07-07)

| Item | Status |
|---|---|
| `eas.json` | ✅ Created |
| Bundle ID / package name | ✅ `com.placewell.app` |
| Permissions (camera, photos) | ✅ Declared |
| Deep link / universal link config | ✅ Configured |
| App icon | ⏳ Placeholder only — replace before submission |
| Splash screen | ⏳ Placeholder only |
| Firebase config files | ❌ Not yet added |
| Secrets in EAS | ❌ Still in app.json |
| App Store Connect app created | ❌ Pending |
| Google Play app created | ❌ Pending |
| Privacy policy | ❌ Pending |

---

Notes: EAS respects metro.config.js. If using a custom dev client or EAS builds, ensure the same metro config and native deps are used.