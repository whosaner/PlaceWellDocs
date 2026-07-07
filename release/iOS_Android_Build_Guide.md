# PlaceWell — iOS & Android Production Build Guide

Last updated: 2026-07-07

---

## Overview

Builds run **in the cloud** on Expo's servers (EAS Build). Your laptop just sends the code up — you do not need a Mac to build iOS. The compiled IPA/APK is then submitted directly to the App Store / Play Store from the cloud.

---

## One-Time Setup (do once per machine)

### 1. Install EAS CLI
```
npm install -g eas-cli
```

### 2. Create an Expo account
- Go to **expo.dev**
- Sign up with `niralu.53@gmail.com`
- Verify email

### 3. Log in to EAS
```
cd C:\PlaceWell\PlaceWellApp
eas login
```
A browser window opens — log in with your Expo account. Session is saved permanently.

---

## Firebase Setup (one-time per platform)

Firebase config files are **gitignored** (contain sensitive keys). They must be uploaded to EAS as secrets AND placed locally for builds.

### iOS

1. Go to **console.firebase.google.com** → project `placewell-prod`
2. Project Settings → Your Apps → **iOS+**
3. Bundle ID: `com.placewell.app` → Register app
4. Download `GoogleService-Info.plist`
5. Place at: `C:\PlaceWell\PlaceWellApp\GoogleService-Info.plist`
6. Upload to EAS (one-time):
```
cd C:\PlaceWell\PlaceWellApp
eas secret:create --scope project --name GOOGLE_SERVICES_INFOPLIST --type file --value ./GoogleService-Info.plist
```

### Android

1. Go to **console.firebase.google.com** → project `placewell-prod`
2. Project Settings → Your Apps → **Android**
3. Package name: `com.placewell.app` → Register app
4. Download `google-services.json`
5. Place at: `C:\PlaceWell\PlaceWellApp\google-services.json`
6. Upload to EAS (one-time):
```
cd C:\PlaceWell\PlaceWellApp
eas secret:create --scope project --name GOOGLE_SERVICES_JSON --type file --value ./google-services.json
```

---

## App Store Connect Setup (done once)

| Item | Value |
|---|---|
| Bundle ID | `com.placewell.app` |
| App Name | PlaceWell |
| App ID (ascAppId) | `6788545365` |
| Apple ID | `niralu.53@gmail.com` |
| Apple Team ID | `CM5N45M892` |

These are already configured in `eas.json`.

---

## Before Every Build — Checklist

- [ ] All code changes committed and pushed to GitHub
- [ ] `npx jest --no-coverage` — all tests passing
- [ ] Assets in place:
  - `assets/icon.png` — 1024×1024 PNG
  - `assets/splash.png` — 1242×2688 PNG
  - `assets/adaptive-icon.png` — 1024×1024 PNG (transparent)

---

## iOS Build

### Run the build
```
cd C:\PlaceWell\PlaceWellApp
eas build --platform ios --profile production
```

- Build runs in the cloud (~20–40 minutes)
- Your laptop can sleep/close during the build
- EAS emails you when done
- You receive a download link for the `.ipa` file

### Submit to App Store / TestFlight
```
eas submit --platform ios
```

- EAS uploads the IPA directly to App Store Connect
- Goes to **TestFlight** first for internal testing
- After testing, go to App Store Connect → submit for App Store review

---

## Android Build

### First — add Firebase Android secret to EAS (one-time)
See Firebase Setup → Android section above.

### Run the build
```
cd C:\PlaceWell\PlaceWellApp
eas build --platform android --profile production
```

### Submit to Google Play
```
eas submit --platform android
```

---

## Build Both Platforms at Once
```
eas build --platform all --profile production
```

---

## Future Builds (routine updates)

For every new version after the first:
```
cd C:\PlaceWell\PlaceWellApp
eas build --platform ios --profile production
eas submit --platform ios
```

`autoIncrement: true` in `eas.json` automatically bumps the build number each time — you don't need to manually update `app.json`.

---

## EAS Build Prompts — What to Answer

| Prompt | Answer |
|---|---|
| Expo Go warning | Ignore — press Enter |
| App version source | Select "remote" (recommended) |
| Create EAS project for @beniralu/placewell? | Y |
| iOS app uses standard/exempt encryption? | Y |
| Log in to Apple account? | Y |
| Generate Apple Distribution Certificate? | Y |
| Generate Apple Provisioning Profile? | Y |

---

## Pending Before App Store Submission

| Item | Status |
|---|---|
| Final app icon (replace placeholder) | ⏳ Pending |
| Final splash screen (replace placeholder) | ⏳ Pending |
| Firebase iOS secret uploaded to EAS | ✅ Done |
| Firebase Android secret uploaded to EAS | ⏳ Pending |
| Move hmacSecret + qrServiceToken to EAS secrets | ⏳ Pending |
| Privacy Policy URL | ⏳ Pending |
| App Store screenshots | ⏳ Pending |

See full checklist: `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md`

---

## Key Files

| File | Purpose |
|---|---|
| `C:\PlaceWell\PlaceWellApp\eas.json` | EAS build and submit configuration |
| `C:\PlaceWell\PlaceWellApp\app.json` | App metadata, bundle ID, permissions |
| `C:\PlaceWell\PlaceWellApp\assets\icon.png` | App icon |
| `C:\PlaceWell\PlaceWellApp\assets\splash.png` | Splash screen |
| `C:\PlaceWell\PlaceWellApp\assets\adaptive-icon.png` | Android adaptive icon |
| `C:\PlaceWell\PlaceWellApp\GoogleService-Info.plist` | Firebase iOS config (gitignored) |
| `C:\PlaceWell\PlaceWellApp\google-services.json` | Firebase Android config (gitignored) |
| `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md` | Full pre-release checklist |


---

## Before Every Build — Checklist

- [ ] All code changes committed and pushed to GitHub
- [ ] `npx jest --no-coverage` — all tests passing
- [ ] Assets in place:
  - `assets/icon.png` — 1024×1024 PNG
  - `assets/splash.png` — 1242×2688 PNG
  - `assets/adaptive-icon.png` — 1024×1024 PNG (transparent)

---

## iOS Build

### Run the build
```
cd C:\PlaceWell\PlaceWellApp
eas build --platform ios --profile production
```

- Build runs in the cloud (~20–40 minutes)
- Your laptop can sleep/close during the build
- EAS emails you when done
- You receive a download link for the `.ipa` file

### Submit to App Store / TestFlight
```
eas submit --platform ios
```

- EAS uploads the IPA directly to App Store Connect
- Goes to **TestFlight** first for internal testing
- After testing, go to App Store Connect → submit for App Store review

---

## Android Build

### Run the build
```
cd C:\PlaceWell\PlaceWellApp
eas build --platform android --profile production
```

### Submit to Google Play
```
eas submit --platform android
```

---

## Build Both Platforms at Once
```
eas build --platform all --profile production
```

---

## Future Builds (routine updates)

For every new version after the first:
```
cd C:\PlaceWell\PlaceWellApp
eas build --platform ios --profile production
eas submit --platform ios
```

`autoIncrement: true` in `eas.json` automatically bumps the build number each time — you don't need to manually update `app.json`.

---

## Pending Before App Store Submission

| Item | Status |
|---|---|
| Final app icon (replace placeholder) | ⏳ Pending |
| Final splash screen (replace placeholder) | ⏳ Pending |
| Firebase `GoogleService-Info.plist` (iOS) | ⏳ Pending |
| Firebase `google-services.json` (Android) | ⏳ Pending |
| Move secrets to EAS (hmacSecret, qrServiceToken) | ⏳ Pending |
| Privacy Policy URL | ⏳ Pending |
| App Store screenshots | ⏳ Pending |

See full checklist: `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md`

---

## Key Files

| File | Purpose |
|---|---|
| `C:\PlaceWell\PlaceWellApp\eas.json` | EAS build and submit configuration |
| `C:\PlaceWell\PlaceWellApp\app.json` | App metadata, bundle ID, permissions |
| `C:\PlaceWell\PlaceWellApp\assets\icon.png` | App icon |
| `C:\PlaceWell\PlaceWellApp\assets\splash.png` | Splash screen |
| `C:\PlaceWell\PlaceWellApp\assets\adaptive-icon.png` | Android adaptive icon |
| `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md` | Full pre-release checklist |
