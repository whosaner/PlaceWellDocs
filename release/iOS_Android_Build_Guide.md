# PlaceWell - iOS & Android Production Build Guide

Last updated: 2026-08-30

## Current release configuration

| Item | Value |
|---|---|
| Marketing version | `1.1.0` |
| EAS project | `e346f522-16a7-4760-b90d-6596a4f5b66e` |
| iOS bundle identifier | `com.placewell.app` |
| Android package | `com.placewell.app` |
| App Store Connect ID | `6788545365` |
| Apple team ID | `CM5N45M892` |
| EAS profile | `production` |
| Version source | Remote |
| Build-number handling | `autoIncrement: true` |

EAS Build compiles both store binaries in Expo's cloud. A Mac is not
required to start the iOS build.

## Before every production build

Run from `C:\PlaceWell\PlaceWellApp`.

1. Confirm the intended branch is clean, committed, and pushed:
   ```
   git status --short --branch
   ```
2. Confirm the Expo account:
   ```
   npx eas-cli whoami
   ```
3. Confirm the public Expo configuration resolves:
   ```
   npx expo config --type public
   ```
4. Run the complete test suite:
   ```
   npx jest --no-coverage --maxWorkers=2
   ```
5. Confirm the production EAS environment provides both variables required
   by `app.config.js`:
   - `HMAC_SECRET`
   - `LOOKUP_SECRET`
6. Confirm `assets/icon.png`, `assets/splash.png`, and
   `assets/adaptive-icon.png` are present.

Do not start a production build from an uncommitted or unpushed release
state.

## Build both platforms

```
npx eas-cli build --platform all --profile production
```

EAS assigns the next iOS build number and Android version code remotely.
Do not manually increment them in `app.json`.

After the command starts, copy both build URLs and assigned build numbers
into `Release_Validation_Checklist.md`.

## iOS submission and validation

Submit the completed iOS build to App Store Connect:

```
npx eas-cli submit --platform ios --profile production --latest
```

The iOS submit profile already contains the Apple ID, App Store Connect app
ID, and team ID. Submission uploads the build to App Store Connect; it does
not automatically release it to customers.

Install the build through TestFlight and complete the physical-device checks
in `Release_Validation_Checklist.md` before submitting version 1.1.0 for App
Store review.

## Android submission and validation

Submit the completed Android App Bundle:

```
npx eas-cli submit --platform android --profile production --latest
```

The production submit profile pins Android submissions to the `internal`
track. The Google Play service-account key is stored on EAS and must not be
committed to the repository.

Upload first to an internal or closed test track. Install the Play-distributed
build and complete the physical-device checks before promoting it to
production.

## Rollout sequence

1. Build both production binaries from the approved `main` commit.
2. Submit iOS to TestFlight and Android to an internal/closed Play track.
3. Validate the distributed binaries on physical devices.
4. Submit iOS for App Store review.
5. Promote Android through the chosen production rollout.
6. Update `Release_Validation_Checklist.md` after every status change.

## Important files

| File | Purpose |
|---|---|
| `C:\PlaceWell\PlaceWellApp\app.json` | Marketing version, identifiers, permissions, assets |
| `C:\PlaceWell\PlaceWellApp\app.config.js` | Dynamic build configuration and required production variables |
| `C:\PlaceWell\PlaceWellApp\eas.json` | Build, versioning, and submission profiles |
| `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md` | Release status and validation record |

## Notes

- Expo Go testing is useful but does not replace TestFlight and Google Play
  distributed-build testing.
- Firebase Analytics native setup is deferred and is not required for the
  1.1.0 build.
- Never commit production credentials, `.env` files, Apple keys, or Google
  service-account JSON files.
