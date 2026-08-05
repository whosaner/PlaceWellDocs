# Plan — Expo SDK 57 Upgrade + Firebase Analytics Activation

*Covers roadmap item #9 (and closes `prod-firebase-android`). Owner: app. Estimated **2–4 days** (54→57 is a **3-SDK jump** — budget the upper end). Last updated 2026-08-05.*

Referenced from `Docs/roadmap/ROADMAP.md`. This is the execution runbook; the roadmap is the index.

> **Retarget note (2026-08-05):** this plan originally aimed at SDK 55. SDK 55 and 56 have since shipped and **SDK 57 is now the current stable (`latest`)**. We target **57** to land on the newest release in one upgrade rather than immediately falling behind. The Firebase/New-Arch fix that caused the deferral has been in place since ~SDK 55, so 57 is strictly better for analytics.

---

## Why the two are one initiative

Firebase Analytics was deferred because `@react-native-firebase` conflicts with **Expo SDK 54 + New Architecture + Swift AppDelegate**. That conflict has been resolved **from SDK 55 onward**, and we target the current stable **SDK 57**, so the upgrade and the analytics activation are done together. The `src/utils/analytics.js` wrapper is already wired across the app (10 events) and silently no-ops until the native module exists — so **turning analytics on needs zero app-screen code changes**.

## Current state (verified 2026-08-05)

- **App is on Expo SDK 54** (`expo ~54.0.35`), **React Native 0.81.5**, **React 19.1.0**, **New Architecture ON** (SDK 54 default; not explicitly pinned in `app.json`).
- **Expo releases 54, 55, 56, 57 have all shipped; `latest` = 57 (57.0.x).** The app is **3 SDKs behind** — hence targeting 57 directly.
- Notable deps: `@react-navigation/* 7`, `react-native-reanimated ~4.1`, `react-native-gesture-handler ~2.28`, `react-native-screens ~4.16`, `react-native-svg 15`, `expo-camera ~17`, `expo-audio`, `expo-build-properties ^57`. `package.json > expo.install.exclude` pins `react-native-svg` + `react-native-worklets`.
- **Firebase: NOT installed** (no `@react-native-firebase/*`). Wrapper `src/utils/analytics.js` present + unit-tested.
- Config files: **`GoogleService-Info.plist` present** in `PlaceWellApp/` (also an EAS **secret** `GOOGLE_SERVICES_INFOPLIST`). **`google-services.json` (Android) MISSING.**
- No Firebase config plugin in `app.json > plugins` yet (currently: expo-camera, expo-asset, expo-font, expo-audio).
- Store privacy currently declared **"Data Not Collected"** on both stores.

## Sequencing

The SDK 57 upgrade is disruptive (a 3-version RN bump touches native modules). Two options:
- **Upgrade-first** (recommended if doing the whole Next-Up batch): do this plan before #10–#12 so those features are built/tested once on SDK 57.
- **Wins-first**: ship #10 (SDK-agnostic, trivial) immediately, then run this plan before #11/#12.

**Timing:** do **not** run this while a build is in store review — wait until the current build is approved and live, then branch, upgrade, test hard, and ship analytics as a follow-up (v1.1) update.

---

## Pre-flight research findings (verified 2026-08-05)

Version data is authoritative — pulled from Expo's bundled-native-modules manifests for `sdk-54` … `sdk-57` (`raw.githubusercontent.com/expo/expo/sdk-XX/packages/expo/bundledNativeModules.json`). Narrative items marked **⟶ verify** must be confirmed against the official release notes during pre-flight (the web changelogs are client-rendered and couldn't be scraped here).

### Version progression — you cross every one of these

| SDK | React Native | React | gesture-handler | reanimated | worklets | screens | datetimepicker |
|---|---|---|---|---|---|---|---|
| **54 (now)** | 0.81.5 | 19.1.0 | 2.28 | 4.1.1 | 0.5.1 | 4.16 | 8.4.4 |
| 55 | 0.83.10 | 19.2.0 | 2.30 | 4.2.1 | 0.7.4 | 4.23 | 8.6.0 |
| 56 | 0.85.3 | 19.2.3 | 2.31.1 | 4.3.1 | 0.8.3 | 4.26 | **9.1.0** |
| **57 (target)** | **0.86.2** | 19.2.3 | 2.32 | 4.5.1 | 0.10.1 | 4.26 | 9.1.0 |

- **React Native jumps 0.81.5 → 0.86.2 — five minor releases.** This is the dominant risk. React itself only moves 19.1 → 19.2 (low).
- **`@react-native-community/datetimepicker` goes major 8 → 9** (at SDK 56).
- **Expo "unified versioning"** (from SDK 55): every `expo-*` module renumbers to match the SDK major (`expo-camera` 17 → 57.0.x, `expo-audio` 1.1 → 57.0.x). The big version-number jumps are mostly this renumber — `expo install --fix` handles them.

### Our dependency deltas (app `package.json` → SDK 57 target)

| Package | App now | SDK 57 | Risk |
|---|---|---|---|
| react-native | 0.81.5 | **0.86.2** | 🔴 5-minor jump — the core risk |
| react | 19.1.0 | 19.2.3 | 🟢 minor |
| @react-native-community/datetimepicker | 8.4.4 | **9.1.0** | 🔴 major — isolated to `DatePickerField.js` |
| react-native-gesture-handler | 2.28 | 2.32 | 🟠 app uses the legacy v1 API |
| react-native-reanimated | 4.1.1 | 4.5.1 | 🟡 transitive only (not imported by app code) |
| react-native-worklets (dev) | 0.8.0 | 0.10.1 | 🟡 pre-1.0; rebuild + babel/jest alignment |
| react-native-screens | 4.16 | 4.26 | 🟡 native; used via navigation |
| react-native-safe-area-context | 5.6 | 5.7 | 🟢 minor |
| react-native-svg | 15.15.4 | 15.15.4 | 🟢 already at target |
| @react-native-async-storage/async-storage | 2.2.0 | 2.2.0 | 🟢 unchanged |
| expo-camera | 17.0.10 | 57.0.x | 🟡 renumber; re-test scanner |
| expo-audio | 1.1.1 | 57.0.x | 🟡 renumber; re-test scan sound |
| expo-build-properties | ^57.0.3 | 57.0.8 | 🟢 already 57.x (anomalous on SDK 54; aligns) |
| other expo-* (asset/font/haptics/image-picker/…) | 3–31.x | 57.0.x | 🟢 unified renumber via `--fix` |

### Code-mapped watch-outs (what to actually test)

1. **🔴 Date pickers — `src/components/DatePickerField.js`** (the *only* `@react-native-community/datetimepicker` consumer). v8 → **v9 major**. Blast radius is one wrapper, but it drives **Best By / In Use Since** on Recall/Detail/Form. Read the v9 notes; re-test date selection on both platforms.
2. **🟠 Legacy gesture-handler API** — the app uses the **v1** API (`PanGestureHandler`, `State`) in `BulkImportScreen`, `LabelFormScreen`, `SwipeBackGesture`, `RoomFilterDrawer`. On 2.32 it likely still works but may warn/deprecate. **⟶ verify** it isn't removed; if it is, migrate those 4 files to the new `Gesture.Pan()` API. Test every swipe-to-dismiss sheet/drawer.
3. **🟡 RN-core `Animated` + `PanResponder`** — `HomeScreen` (carousel), `BulkImportScreen`, `LabelFormScreen` (×2 pickers), `SettingsScreen`, `BiDirectionalSlider`, `SwipeToConfirm`. Stable RN-core API, but with a 5-minor RN jump smoke-test every animated sheet/slider/carousel.
4. **🟡 reanimated / worklets** — **not imported by app code** (transitive via React Navigation), so low app-code risk; the work is the native rebuild + `babel.config.js` reanimated plugin + `jest` worklets alignment after `--fix`.
5. **🟢 expo-camera / expo-audio** — renumbered to 57.0.x; re-run the **scanner + scan-sound** smoke (launch-critical paths).
6. **🟢 New Architecture** — already **ON**, so RN's legacy-arch retirement across this range is low-risk for you; every native dep in the SDK 57 matrix is New-Arch-ready. **⟶ verify** no app-level `newArchEnabled` pin is needed.
7. **🟢 Firebase** — the New-Arch / static-frameworks conflict that caused the deferral is resolved from ~SDK 55; validate with a **real EAS build** on 57 in Phase 2 (not just a local prebuild).

### Pre-flight reading list

- Expo SDK **55 / 56 / 57** changelogs — `https://expo.dev/changelog/sdk-55` · `/sdk-56` · `/sdk-57`.
- RN **Upgrade Helper** `0.81.5 → 0.86.2` — `https://react-native-community.github.io/upgrade-helper/?from=0.81.5&to=0.86.2`.
- RN release notes 0.82–0.86 (New-Arch, removed APIs) — `https://github.com/facebook/react-native/releases`.
- `datetimepicker` **v9** notes — `https://github.com/react-native-datetimepicker/datetimepicker/releases`.
- gesture-handler v1→`Gesture` migration — `https://docs.swmansion.com/react-native-gesture-handler/docs/`.

**Net read:** the mechanical bump is `expo install --fix`; the *real* work is (a) the datetimepicker v9 change in one file, (b) confirming the legacy gesture-handler API still works across 4 files, and (c) a full animation + scanner/scan-sound smoke on RN 0.86. Budget the upper end (**3–4 days**) for a 3-SDK / 5-RN-minor jump.

---

## Phase 1 — Upgrade Expo SDK 54 → 57  (1–2 days; larger than a single-version bump)

**Pre-flight**
- [ ] Clean git tree; branch `chore/expo-sdk-57`.
- [ ] Work through the **Pre-flight research findings** section above (exact version deltas + code-mapped watch-outs). Open the **official Expo SDK 55/56/57 changelogs** + the **RN Upgrade Helper `0.81.5 → 0.86.2`**; confirm the ⟶ verify items (datetimepicker v9, legacy gesture-handler API, RN legacy-arch).
- [ ] Confirm New Architecture status/migration notes for SDK 57 (expected ON).
- [ ] Baseline: `npx expo-doctor` + `npx jest --no-coverage` (record current green count).

**Upgrade**
- [ ] `npx expo install expo@^57.0.0` (or the SDK-57 upgrade command Expo documents).
- [ ] `npx expo install --fix` — aligns every `expo-*` and core native dep (react, react-native, reanimated, gesture-handler, screens, svg, safe-area-context) to the SDK 57 matrix.
- [ ] Reconcile deps not covered by `--fix` (react-navigation, lucide-react-native, react-native-launch-arguments) to RN-compatible versions.
- [ ] Re-check `package.json > expo.install.exclude` pins (`react-native-svg`, `react-native-worklets`) — update/remove if SDK 57 changes them.
- [ ] `npx expo-doctor` → resolve all warnings.
- [ ] **If the direct 54→57 jump is too messy**, fall back to stepping **54→55→56→57**, running `npx jest` at each hop to localise breakage.

**Build & verify**
- [ ] `npx jest --no-coverage` → all green (fix RN-API breakages).
- [ ] Preview/dev-client build; on-device smoke (cold start, scan, setup, recall, bulk import, photo capture, keyboard).
- [ ] `npm run maestro:smoke` (seed first — a REAL seed if Firestore fixtures were purged).
- [ ] Full regression via `PlaceWellApp/VERIFICATION_CHECKLIST.txt` (camera scan, deep links, photo flows, keyboard).
- [ ] EAS **production** build both platforms; verify on TestFlight + Play internal testing.

**Likely breakage hot-spots** — reanimated 4 / worklets bumps (animations, sheets), gesture-handler + screens (drawers, pickers, transitions), expo-camera API (scanner), any removed RN APIs. A 3-SDK jump accumulates these, so expect more than a single-version upgrade.

**Rollback:** abandon the branch; stay on SDK 54 (analytics stays deferred). No production impact until you ship a 57 build.

---

## Phase 2 — Enable Firebase Analytics  (0.5–1 day)

**Use `@react-native-firebase`.** (The old `expo-firebase-analytics` is deprecated — do not use.)

**Packages & plugin**
- [ ] `npx expo install @react-native-firebase/app @react-native-firebase/analytics`.
- [ ] `app.json > plugins`: add `"@react-native-firebase/app"`.
- [ ] iOS static frameworks (Firebase requirement) via the already-present `expo-build-properties`:
      `["expo-build-properties", { "ios": { "useFrameworks": "static" } }]`.
      This was the historical New-Arch/AppDelegate conflict point (resolved from ~SDK 55) — **verify a clean prebuild + EAS build on SDK 57** here.

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

- App runs on **SDK 57**; jest suite green; Maestro smoke green; `VERIFICATION_CHECKLIST` regression clean; both stores accept the new build.
- Firebase Analytics events visible in the Firebase dashboard.
- **Store privacy declarations updated** on both stores to match.
- Roadmap closed: **#9** (analytics) + **`prod-firebase-android`** (google-services.json).

## Risks / watch-outs

- **RN version jump is the biggest risk** — and this is a **3-SDK jump (54→57)**, so breaking changes across reanimated/gesture/screens/RN core accumulate. Budget the upper end of the estimate; step through versions if the direct jump is rough.
- **Firebase + New Arch on iOS** — resolved since ~SDK 55, but still validate on 57 with a **real EAS build** early in Phase 2, not just a local prebuild.
- **Don't ship analytics without the privacy update** — a mismatch can get an app flagged/rejected on either store.
