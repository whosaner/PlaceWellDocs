# PlaceWell Maestro E2E Testing — Setup & Usage Guide

**What is Maestro?**
Maestro is a free, open-source mobile E2E test runner. It drives the app from
outside (via the OS accessibility layer) — no test code inside the app binary,
no npm packages added to production dependencies. The `.maestro/` YAML flows
never affect what users install from the Play Store or App Store.

---

## Prerequisites

### 1. Java 17+

Maestro requires Java 17 or higher.

**Check:**
```
java -version
```

**Install (Windows):** Download from https://adoptium.net and set `JAVA_HOME`.

**Install (macOS):**
```
brew install openjdk@17
```

### 2. Maestro CLI

**macOS / Linux:**
```bash
curl -fsSL "https://get.maestro.mobile.dev" | bash
```

**Windows:**
1. Download the latest `maestro.zip` from https://github.com/mobile-dev-inc/maestro/releases
2. Extract to `C:\maestro`
3. Add `C:\maestro\bin` to your `PATH` environment variable

**Verify install:**
```
maestro --version
```

### 3. Android Emulator (for local testing)

An AVD must be running before executing flows.

**Start emulator from Android Studio:**
- Tools → Device Manager → Play button on your AVD

**Or via command line:**
```
emulator -avd <your_avd_name>
```

**Verify Maestro can see it:**
```
maestro list-devices
```

### 4. Install the PlaceWell APK on the emulator

You need the PlaceWell app installed on the emulator/device before running flows.

**Option A — From EAS (recommended for CI):**
```
cd C:\PlaceWell\PlaceWellApp
eas build --profile production --platform android --non-interactive
```
Then download the AAB from https://expo.dev and install it.

**Option B — Debug build for local development:**
```
cd C:\PlaceWell\PlaceWellApp
npx expo run:android
```

**Verify the app is installed:**
```
adb shell pm list packages | grep placewell
```

---

## Running Tests

### One command (recommended): `npm run maestro`

`scripts/maestro/run-maestro.mjs` is the single end-to-end entry point. It runs
five steps in order — (1) check the Maestro CLI, (2) check a device, **auto-starting**
an emulator if none is running, (3) check the app, **auto-installing** the newest
build from `builds\` when it isn't on the device (an `.aab` is converted via
bundletool), (4) seed Firestore fixtures, (5) run the flow(s) with the derived
`PW_*` env vars:

```
cd C:\PlaceWell\PlaceWellApp
npm run maestro                    # smoke suite (seed + run)
npm run maestro -- screenshots     # store screenshot flow
npm run maestro -- regression      # full regression suite
npm run maestro -- .maestro/smoke/CORE-01_first-launch-empty-home.yaml
npm run maestro -- --app builds\app.aab   # install this build first (.aab/.apk)
npm run maestro -- --no-start-device      # don't auto-start an emulator
npm run maestro -- --no-seed              # skip Firestore seeding
npm run maestro -- --print                # show the plan + derived env, run nothing
```

To install a build, drop the EAS `.aab`/`.apk` into
`C:\PlaceWell\PlaceWellApp\builds\` (or pass `--app <path>`, or set
`PLACEWELL_APP_ARTIFACT`); the runner auto-detects the newest one. Prefer not to
type npm? Use the PowerShell entry:

```
C:\PlaceWell\Docs\scripts\run-maestro.ps1          # interactive menu
C:\PlaceWell\Docs\scripts\run-maestro.ps1 smoke    # or pass a target directly
```

It does **not build** the app — that's a one-time step done only when app code
changes:

```
npx expo run:android          # debug/dev build, installs to the running device
eas build -p android          # release build (drop the .aab into builds\)
```

The individual steps below are still available if you want finer control.

### Run the full smoke suite (fastest — use on every push)

```
cd C:\PlaceWell\PlaceWellApp
maestro test .maestro/smoke -e APP_ID=com.placewell.app
```

### Run a single flow by file

```
maestro test .maestro/smoke/CORE-01_first-launch-empty-home.yaml -e APP_ID=com.placewell.app
```

### Run a single flow by scenario ID (via generator script)

```
npm run maestro:test -- --id SCAN-03
```

### Run a flow with required env vars

Some flows need QR data from your Firestore test order.
Set these once per session (or in a `.env.maestro` file):

```powershell
# Windows PowerShell
$env:APP_ID = "com.placewell.app"
$env:PW_SCAN_EXISTING_SPICE_LINK = "placewell://scan/YOUR_SPICE_LABEL_ID"
$env:PW_SCAN_EXISTING_STORAGE_LINK = "placewell://scan/YOUR_STORAGE_LABEL_ID"
$env:PW_ORDER_LINK = "placewell://order/YOUR_ORDER_ID"
$env:PW_SCAN_NEW_SPICE_URL = "https://placewell.app/s/LABELID-SIG"
```

```bash
# macOS/Linux
export APP_ID=com.placewell.app
export PW_SCAN_EXISTING_SPICE_LINK=placewell://scan/YOUR_SPICE_LABEL_ID
export PW_SCAN_EXISTING_STORAGE_LINK=placewell://scan/YOUR_STORAGE_LABEL_ID
export PW_ORDER_LINK=placewell://order/YOUR_ORDER_ID
export PW_SCAN_NEW_SPICE_URL=https://placewell.app/s/LABELID-SIG
```

Then run any flow and the env vars are passed automatically.

### Run the full regression suite

```
maestro test .maestro -e APP_ID=com.placewell.app --include-tags regression
```

### Watch mode (re-runs on file save)

```
maestro test .maestro/smoke/CORE-01_first-launch-empty-home.yaml -e APP_ID=com.placewell.app --continuous
```

---

## Managing Scenarios

### List all scenarios and their status

```
npm run maestro:list
```

Output shows each scenario ID, whether it's implemented or planned, the file
path, and its tags.

### Add a new scenario (no YAML editing needed)

```
npm run maestro:add -- --prompt "Test that when a user scans a garage label it opens LabelDetail"
```

The script will:
1. Classify your prompt into the right feature area
2. Pick a base template
3. Generate a YAML flow file in the correct subfolder
4. Update `.maestro/scenario-index.yaml`
5. Print the file path, tags, and required env vars

### Add a scenario with a specific ID

```
npm run maestro:add -- --id SETUP-03 --prompt "Create new garage label with Shelves default"
```

---

## Folder Structure

```
C:\PlaceWell\PlaceWellApp\
  .maestro\
    config.yaml               — workspace settings
    scenario-index.yaml       — registry of all 46 scenarios
    smoke\                    — P0 flows, run on every push
    scanner\                  — QR scan / deep link entry flows
    label-setup\              — label creation wizard flows
    label-detail\             — non-spice detail/edit/delete flows
    label-recall\             — spice recall/freshness flows
    bulk-import\              — order QR bulk import flows
    home\                     — carousel/search/filter flows
    settings\                 — settings/profile flows
    errors\                   — negative / error-state flows
    subflows\
      common\                 — reusable launch, scan, modal helpers
      home\                   — home-specific helpers
      setup\                  — room/zone/photo picker helpers
  scripts\
    maestro\
      add-scenario.mjs        — scenario generator CLI
      render-template.mjs     — YAML template renderer
      scenario-catalog.json   — all 46 scenario definitions
      selector-catalog.json   — all testIDs organized by screen
```

---

## Test Data Setup

The smoke suite and screenshot flow need a small set of real Firestore labels
from a **dedicated Maestro test order** (`maestro_test_kit`, never used for real
customers). These are seeded automatically with fixed, deterministic IDs, so the
same QR URLs regenerate every time — even if you delete them from Firestore.

### Seed the fixtures (host initialization step)

Maestro cannot run a host script itself (flow steps target the device,
`runScript` is a sandboxed JS engine, and there is no host-command hook), so
seed on the **host, before** running the flows:

```
cd C:\PlaceWell\PlaceWellApp
npm run maestro:seed               # writes labels + order to Firestore (idempotent)
npm run maestro:seed -- --dry-run  # preview the URLs without writing
```

This delegates to `PlaceWellQRService/scripts/seed_test_fixtures.py`, which needs
that repo's `.env` (`PLACEWELL_HMAC_SECRET`) and Firebase credentials
(`GOOGLE_APPLICATION_CREDENTIALS`). The seeded IDs match
`.maestro/smoke-labels.json`, so `npm run maestro:smoke` derives matching signed
URLs automatically.

### Seed + run in one step

```
npm run maestro:smoke:seed         # seed Firestore, then run the smoke suite
```

In CI, run the two as sequential steps (seed job/step, then `maestro test`).

### Sources of truth

The label IDs live in two places that must stay in sync:
`.maestro/smoke-labels.json` (drives the smoke runner) and the seeder's
`FIXTURES` list (drives Firestore). Both currently use
`PWMSP2 / PWMST3 / PWMXS5 / PWMXT6 / PWMQR7`.

---

## MAESTRO_TEST_MODE

For error-state flows (network failures, invalid QR, order-not-found), a
`MAESTRO_TEST_MODE=true` flag can be passed to the app at launch:

```yaml
- launchApp:
    arguments:
      MAESTRO_TEST_MODE: "true"
```

The flag is read at startup via `react-native-launch-arguments` and defaults
to `false`. It has **zero effect in production** — a real user cannot pass
launch arguments when opening the app normally.

The flag gates fault-injection hooks that are not yet implemented (Phase 2).
Current smoke flows do not require it.

---

## iOS Testing

Maestro supports iOS Simulator only (not physical iPhone).

**Run on iOS Simulator (macOS only):**
```bash
maestro test .maestro/smoke -e APP_ID=com.placewell.app --platform ios
```

Requires the app installed on the simulator:
```bash
npx expo run:ios --simulator "iPhone 16"
```

---

## CI/CD (GitHub Actions)

The free-tier approach runs Maestro on an Android emulator in GitHub Actions
with no Maestro Cloud cost.

Recommended workflow trigger: push to `main`, nightly cron for full regression.

See the full plan at:
`C:\PlaceWell\Docs\maestro\Maestro_Implementation_Plan.md` (Section 6)

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `maestro: command not found` | Add Maestro bin to PATH; verify with `maestro --version` |
| `No devices found` | Start an Android emulator or connect device via USB with ADB debugging on |
| Flow fails on `assertVisible: "text"` | Check testID spelling in selector-catalog.json; prefer `id:` selectors over text |
| `openLink` does nothing | Verify the app is installed and the deep link prefix is registered (`placewell://`) |
| `getInitialURL` re-triggers old label | Already fixed — requires the latest app build |
| Flow hangs on date picker | Use the platform-specific date helper subflow; native pickers are high-flake |
| `LOOKUP_SECRET` causing blank label name | Verify the env var matches the server's `.env` value |

---

## Reference

- Maestro docs: https://docs.maestro.dev
- Maestro GitHub: https://github.com/mobile-dev-inc/maestro
- PlaceWell Maestro plan: `C:\PlaceWell\Docs\maestro\Maestro_Implementation_Plan.md`
- Scenario catalog: `C:\PlaceWell\PlaceWellApp\scripts\maestro\scenario-catalog.json`
- Selector catalog: `C:\PlaceWell\PlaceWellApp\scripts\maestro\selector-catalog.json`
