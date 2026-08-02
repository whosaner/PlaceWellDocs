# Plan — Expo SDK 55 Upgrade + Firebase Analytics Activation

*Covers roadmap item #9 (and closes `prod-firebase-android`). Owner: app. Estimated **2–4 days**. Last updated 2026-08-02.*

Referenced from `Docs/roadmap/ROADMAP.md`. This is the execution runbook; the roadmap is the index.

---

## Why the two are one initiative

Firebase Analytics was deferred because `@react-native-firebase` conflicts with **Expo SDK 54 + New Architecture + Swift AppDelegate**. SDK 55 resolves this, so the upgrade and the analytics activation are done together. The `src/utils/analytics.js` wrapper is already wired across the app (10 events) and silently no-ops until the native module exists — so **turning analytics on needs zero app-screen code changes**.

## Current state (verified 2026-08-02)

- **Expo SDK 54** (`expo ~54.0.35`), **React Native 0.81.5**, **React 19.1.0**, **New Architecture ON** (SDK 54 default; not explicitly pinned in `app.json`).
- Notable deps: `@react-navigation/* 7`, `react-native-reanimated ~4.1`, `react-native-gesture-handler ~2.28`, `react-native-screens ~4.16`, `react-native-svg 15`, `expo-camera ~17`, `expo-audio`, `expo-build-properties ^57`. `package.json > expo.install.exclude` pins `react-native-svg` + `react-native-worklets`.
- **Firebase: NOT installed** (no `@react-native-firebase/*`). Wrapper `src/utils/analytics.js` present + unit-tested.
- Config files: **`GoogleService-Info.plist` present** in `PlaceWellApp/` (also an EAS **secret** `GOOGLE_SERVICES_INFOPLIST`). **`google-services.json` (Android) MISSING.**
- No Firebase config plugin in `app.json > plugins` yet (currently: expo-camera, expo-asset, expo-font, expo-audio).
- Store privacy currently declared **"Data Not Collected"** on both stores.

## Sequencing

The SDK 55 upgrade is disruptive (RN version bump touches native modules). Two options:
- **Upgrade-first** (recommended if doing the whole Next-Up batch): do this plan before #10–#12 so those features are built/tested once on SDK 55.
- **Wins-first**: ship #10 (SDK-agnostic, trivial) immediately, then run this plan before #11/#12.

---

## Phase 1 — Upgrade Expo SDK 54 → 55  (0.5–2 days)

**Pre-flight**
- [ ] Clean git tree; branch `chore/expo-sdk-55`.
- [ ] Read the **official Expo SDK 55 changelog/release notes** + the **React Native Upgrade Helper** for the target RN version. List breaking changes touching your deps: reanimated/worklets, gesture-handler, screens, svg, camera, navigation, safe-area-context.
- [ ] Confirm New Architecture status/migration notes for SDK 55 (expected ON).
- [ ] Baseline: `npx expo-doctor` + `npx jest --no-coverage` (record current green count).

**Upgrade**
- [ ] `npx expo install expo@^55.0.0` (or the SDK-55 upgrade command Expo documents).
- [ ] `npx expo install --fix` — aligns every `expo-*` and core native dep (react, react-native, reanimated, gesture-handler, screens, svg, safe-area-context) to the SDK 55 matrix.
- [ ] Reconcile deps not covered by `--fix` (react-navigation, lucide-react-native, react-native-launch-arguments) to RN-compatible versions.
- [ ] Re-check `package.json > expo.install.exclude` pins (`react-native-svg`, `react-native-worklets`) — update/remove if SDK 55 changes them.
- [ ] `npx expo-doctor` → resolve all warnings.

**Build & verify**
- [ ] `npx jest --no-coverage` → all green (fix RN-API breakages).
- [ ] Preview/dev-client build; on-device smoke (cold start, scan, setup, recall, bulk import, photo capture, keyboard).
- [ ] `npm run maestro:smoke` (seed first with `Docs/scripts/seed-test-fixtures.ps1 -HmacSecret <prod> -DryRun`... actually a REAL seed if Firestore fixtures were purged).
- [ ] Full regression via `PlaceWellApp/VERIFICATION_CHECKLIST.txt` (camera scan, deep links, photo flows, keyboard).
- [ ] EAS **production** build both platforms; verify on TestFlight + Play internal testing.

**Likely breakage hot-spots** — reanimated 4 / worklets bump (animations, sheets), gesture-handler + screens (drawers, pickers, transitions), expo-camera API (scanner), any removed RN APIs.

**Rollback:** abandon the branch; stay on SDK 54 (analytics stays deferred). No production impact until you ship a 55 build.

---

## Phase 2 — Enable Firebase Analytics  (0.5–1 day)

**Use `@react-native-firebase`.** (The old `expo-firebase-analytics` is deprecated — do not use.)

**Packages & plugin**
- [ ] `npx expo install @react-native-firebase/app @react-native-firebase/analytics`.
- [ ] `app.json > plugins`: add `"@react-native-firebase/app"`.
- [ ] iOS static frameworks (Firebase requirement) via the already-present `expo-build-properties`:
      `["expo-build-properties", { "ios": { "useFrameworks": "static" } }]`.
      This is the historical New-Arch/AppDelegate conflict point — **verify a clean prebuild + EAS build on SDK 55** here (this is the whole reason we waited for 55).

**Config files**
- [ ] **iOS** — wire the existing `GoogleService-Info.plist`: set `app.json > ios.googleServicesFile`. It's already EAS secret `GOOGLE_SERVICES_INFOPLIST`; in `app.config.js` resolve `ios.googleServicesFile` from that file secret at build time (mirror how secrets are read today).
- [ ] **Android** — download **`google-services.json`** from Firebase Console → Project Settings → **Android app `com.placewell.app`**; place in `PlaceWellApp/`; set `app.json > android.googleServicesFile`; add an EAS **file** secret `GOOGLE_SERVICES_JSON` mirroring the iOS pattern. *(This closes `prod-firebase-android`.)*
- [ ] Keep both files out of git (gitignored) — provided via EAS at build time.

**Activate & verify**
- [ ] With the package installed, `analytics.js`'s `require('@react-native-firebase/analytics')` now resolves → `_analytics` set → all 10 events (`label_scanned`, `label_created`, …) fire. **No screen code changes.**
- [ ] Enable DebugView (iOS `-FIRDebugEnabled`; Android `adb shell setprop debug.firebase.analytics.app com.placewell.app`); exercise scan → setup → recall → bulk import; confirm events in Firebase **DebugView**, then the Analytics dashboard.

---

## Phase 3 — Compliance, build, submit  (0.5–1 day)

- [ ] ⚠️ **Update privacy declarations BEFORE shipping the analytics build:**
  - **App Store → App Privacy**: change from "Data Not Collected" → declare **App activity** (app interactions), **Diagnostics** (crash/performance), **Device or other IDs**; *not linked to identity*, *not used for tracking*. Update `Docs/release/store-listing/AppStore_PasteReady.txt` §4.
  - **Google Play → Data safety**: same three data types; *encrypted in transit* = Yes; *deletion request path* = Yes. Update `Docs/release/store-listing/Play_Data_Safety_AnswerSheet.txt` (Data Safety section).
- [ ] Verify the Firebase Analytics data map is accurate (analytics does **not** include label contents/notes/photos — the wrapper only sends event names + non-personal params).
- [ ] Bump version; EAS production build both platforms (`autoIncrement`).
- [ ] `eas submit` both; keep store "What's New" generic (analytics is invisible to users).

---

## Definition of done

- App runs on **SDK 55**; jest suite green; Maestro smoke green; `VERIFICATION_CHECKLIST` regression clean; both stores accept the new build.
- Firebase Analytics events visible in the Firebase dashboard.
- **Store privacy declarations updated** on both stores to match.
- Roadmap closed: **#9** (analytics) + **`prod-firebase-android`** (google-services.json).

## Risks / watch-outs

- **RN version jump** is the biggest risk — budget time for reanimated/gesture/screens fixes.
- **Firebase + New Arch on iOS** — the exact thing SDK 55 is supposed to fix; validate with a real EAS build early in Phase 2, not just a local prebuild.
- **Don't ship analytics without the privacy update** — mismatch can get an app flagged/rejected on either store.
