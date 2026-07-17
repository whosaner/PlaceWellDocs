# Maestro E2E Testing Implementation Plan for PlaceWell React Native / Expo App

**Status:** Plan document only. No Maestro flows or app code have been implemented yet.

**Plan basis:** This plan is grounded in the current app code in `App.js`, `src/navigation/AppNavigator.js`, `src/screens/ScannerScreen.js`, `src/screens/HomeScreen.js`, `src/screens/LabelFormScreen.js`, `src/screens/LabelDetailScreen.js`, `src/screens/LabelRecallScreen.js`, `src/screens/BulkImportScreen.js`, `src/screens/SettingsScreen.js`, `src/data/storage.js`, `src/services/qrService.js`, `src/utils/hmac.js`, `src/data/labelConfig.js`, `src/data/defaultRooms.js`, and `src/utils/identity.js`, plus shared components used by those screens.

## Source-grounded observations from the current codebase

1. **There is no onboarding screen.** On first launch, `App.js` calls `initializeStorage()` and silently seeds AsyncStorage with default rooms/zones plus device/household identity.
2. **Home is the initial route.** `AppNavigator.js` starts on `Home`; `Scanner` is modal; `LabelSetup` and `LabelEdit` both use `LabelFormScreen`; `BulkImport` and `BulkImportLabelSetup` are separate routes.
3. **Existing spice labels always end up on recall, not generic detail.** `ScannerScreen` routes existing spice labels directly to `LabelRecall`, and `LabelDetailScreen` also redirects spice labels to `LabelRecall`.
4. **Create-mode save destinations differ by path/category.** `LabelFormScreen` saves new labels to `LabelDetail`, but spice labels immediately redirect from detail to recall; bulk-import setup returns to `BulkImport`; edit mode goes back to the previous screen.
5. **`placewell://scan/<LABEL_ID>` is not enough for metadata-driven new-label tests.** That custom deep link skips HMAC (good) but carries no signature, and `lookupLabel()` explicitly returns `null` when no signature is available. That means category/default-room/freshness metadata will be missing for new-label flows unless a signed HTTPS QR URL or a test hook is used.
6. **Garage defaults are slightly asymmetric today.** `labelConfig.js` defaults garage labels to `Garage / Shelves`, but `defaultRooms.js` seeds `Garage` zones such as `Shelving Unit`, `Workbench`, etc. The setup flow therefore auto-creates a custom `Shelves` zone during garage-label setup.
7. **Bulk import is local-state creation after one server lookup.** `BulkImportScreen` fetches order data once, hides blank labels and order-QR labels, then creates local labels in AsyncStorage with `bulkCreateLabels()`.
8. **Settings currently does _not_ expose an Archived tab in the live UI.** The file comments and some stale tests still mention Archived, but the current render only exposes `Rooms & Zones` (only when custom entries exist) and `About`.
9. **Home search is inline and debounced.** `HomeScreen` uses a 300ms debounce, only shows active labels in inline results, and shows recent labels when the search field is focused with an empty query.
10. **Order-link handling is split.** `ScannerScreen` knows about `placewell://order/...` and `placewell.app/o/...`, but `AppNavigator.js` currently only normalizes `order/...` into `placewell://order/...`. For automated tests, the custom scheme is the safest order entry path until the HTTPS order-link shape is standardized.

### Lane legend used below

- **P0 CI smoke** — run on every push to `main`
- **P1 CI regression** — nightly / workflow-dispatch / pre-release
- **P2 manual/device** — physical device, local Mac/iPhone, or OS-sensitive flow
- **Live** — requires real PlaceWell QR service / live test data / valid `LOOKUP_SECRET`
- **TM** — requires a dedicated `MAESTRO_TEST_MODE=true` build or test hook

## Scenario summary table

| ID | Feature | Scenario | Lane |
|---|---|---|---|
| CORE-01 | Fresh install | First launch lands on empty Home with scan FAB | P0 CI smoke |
| CORE-02 | Fresh install | First launch opens Settings/About and profile bootstrap data exists | P1 CI regression |
| SCAN-01 | Scanner entry | Camera permission deny + allow variants from Home scan FAB | P0 CI smoke |
| SCAN-02 | Scanner entry | Signed new-label deep link opens setup (cold + warm variants) | P0 CI smoke / Live |
| SCAN-03 | Scanner entry | Existing non-spice label scan opens `LabelDetail` | P0 CI smoke |
| SCAN-04 | Scanner entry | Existing spice label scan opens `LabelRecall` | P0 CI smoke |
| SCAN-05 | Scanner entry | Order deep link opens `BulkImport` (cold + warm variants) | P0 CI smoke / Live |
| SETUP-01 | Label setup | Create new spice label with freshness metadata and land on recall | P0 CI smoke / Live |
| SETUP-02 | Label setup | Create new storage label with photo, contents, and notes | P0 CI smoke |
| SETUP-03 | Label setup | Create new garage label with auto-created `Garage / Shelves` defaults | P1 CI regression / Live |
| SETUP-04 | Label setup | Add custom room and custom zone from the setup pickers | P1 CI regression |
| SETUP-05 | Label setup | Dismiss a saveable setup flow and use `Save & Exit` | P1 CI regression |
| SETUP-06 | Label setup | Dismiss an incomplete setup flow and choose Keep Editing / Discard | P1 CI regression |
| SETUP-07 | Label setup | Required-field validation blocks Next/Save | P1 CI regression |
| DETAIL-01 | Label detail | Inline contents add/remove auto-save | P1 CI regression |
| DETAIL-02 | Label detail | Inline notes cancel/save flow | P1 CI regression |
| DETAIL-03 | Label detail | Photo change from gallery on detail screen | P1 CI regression / P2 manual-device for camera variant |
| EDIT-01 | Label edit | Full edit from detail and return to updated detail screen | P1 CI regression |
| DELETE-01 | Label delete | Delete non-spice label from detail and return to Home | P1 CI regression |
| RECALL-01 | Label recall | Recall hero + freshness pill states (Fresh / Not tracked / Past best-by variants) | P1 CI regression / TM for deterministic seeds |
| RECALL-02 | Label recall | Edit Best By and In Use Since from recall | P1 CI regression / P2 manual-device if native picker proves unstable |
| RECALL-03 | Label recall | Refill CTA cancel + confirm updates freshness state | P0 CI smoke |
| RECALL-04 | Label recall | Photo change from gallery on recall screen | P1 CI regression / P2 manual-device for camera variant |
| EDIT-02 | Label edit | Full edit from recall and return to updated recall screen | P1 CI regression |
| DELETE-02 | Label delete | Delete spice label from recall and return to Home | P1 CI regression |
| IMPORT-01 | Bulk import | Review order labels, defaults, and hidden blank/order-QR rows | P0 CI smoke / Live |
| IMPORT-02 | Bulk import | Apply global room/zone to all labels | P1 CI regression |
| IMPORT-03 | Bulk import | Per-label overrides plus add-new room/zone from picker | P1 CI regression |
| IMPORT-04 | Bulk import | Track-freshness toggle ON/OFF affects final created spice data | P1 CI regression / Live |
| IMPORT-05 | Bulk import | Customize one label in `BulkImportLabelSetup`, return, then create remaining | P1 CI regression |
| IMPORT-06 | Bulk import | Re-scan same order after setup and get `All labels already set up` path | P1 CI regression |
| HOME-01 | Home | Carousel browse and open label | P0 CI smoke |
| HOME-02 | Home | Search, clear, and recently viewed behavior | P1 CI regression |
| HOME-03 | Home | Room/zone filter drawer and clear-filter chip | P1 CI regression |
| HOME-04 | Home | Bulk delete from filter drawer (all / room / zone variants) | P1 CI regression |
| HOME-05 | Home | Coming Soon sheet opens and closes cleanly | P2 manual-device / optional CI |
| SETTINGS-01 | Settings | `Rooms & Zones` tab appears only when custom entries exist and expands correctly | P1 CI regression |
| SETTINGS-02 | Settings | Cannot delete active room / active zone | P1 CI regression |
| SETTINGS-03 | Settings | Scan sound toggle persists across relaunch | P0 CI smoke |
| SETTINGS-04 | Settings | Profile sheet edits member name, household name, and copies code | P1 CI regression |
| ERR-01 | Errors | Non-PlaceWell QR shows Invalid QR modal | P1 CI regression / TM |
| ERR-02 | Errors | Wrong HMAC signature shows Invalid QR modal | P0 CI smoke |
| ERR-03 | Errors | Label lookup auth/network failure falls back to generic setup | P1 CI regression / TM or dedicated no-token build |
| ERR-04 | Errors | Order not found modal | P1 CI regression / Live or TM |
| ERR-05 | Errors | Order lookup exception path shows `Order Error` | P1 CI regression / TM |
| ERR-06 | Errors | Save failure modal from setup/edit/recall path | P1 CI regression / TM |

### Explicit non-phase-1 items

These are real behaviors, but they should stay **manual-only or explicitly deferred** unless the team chooses to add dedicated hooks:

- **Etsy/shop button** on `HomeScreen` (external browser handoff)
- **Physical camera capture** through Expo ImagePicker camera path on both platforms
- **Archived-label flows** (data layer exists, but current UI does not expose the feature)
- **Standalone HTTPS order-link app-link parity** until the `/o/...` vs `order/...` routing path is standardized

---

## 1. Setup & folder structure

### 1.1 Workspace location

Put the Maestro workspace at the **app project root**, not the repo root:

- **Correct path:** `C:\PlaceWell\PlaceWellApp\.maestro\`
- **Reason:** the flows are testing the React Native app, and this keeps flows next to `package.json`, `eas.json`, and any media fixtures.

### 1.2 Use a standalone build, not Expo Go

For reliable Maestro work, target a **standalone Android/iOS build or dev client** with the real app ID:

- App bundle/package ID: `com.placewell.app`
- Deep links/prefixes: `placewell://`, `https://placewell.app`

Why this matters:

- `launchApp` is most reliable against the actual installed app ID.
- Production-like deep-link behavior is easier to validate.
- Expo Go adds another app shell and changes launch/deep-link behavior.

### 1.3 Proposed `.maestro/` structure

```text
C:\PlaceWell\PlaceWellApp\
  .maestro\
    config.yaml
    scenario-index.yaml
    assets\
      media\
        sample-spice.jpg
        sample-storage.jpg
        sample-garage.jpg
    subflows\
      common\
        launch-clean.yaml
        launch-warm.yaml
        open-signed-scan.yaml
        open-existing-scan.yaml
        open-order-link.yaml
        seed-gallery.yaml
        confirm-modal-primary.yaml
        confirm-modal-cancel.yaml
        dismiss-ios-open-prompt.yaml
      home\
        open-filter-drawer.yaml
      setup\
        choose-room-zone.yaml
        choose-photo-from-gallery.yaml
      recall\
        set-date-android.yaml
        set-date-ios.yaml
    smoke\
      core-first-launch.yaml
      scan-existing-spice.yaml
      scan-existing-storage.yaml
      bulk-import-review.yaml
      settings-scan-sound.yaml
    scanner\
    label-setup\
    label-detail\
    label-recall\
    bulk-import\
    home\
    settings\
    errors\
  scripts\
    maestro\
      add-scenario.mjs
      render-template.mjs
      scenario-catalog.json
      selector-catalog.json
```

### 1.4 Foldering recommendation

Use **feature-based folders** plus a small **smoke** folder:

- `smoke/` — fastest, highest-signal flows for every push
- `scanner/` — deep-link / scan-entry flows
- `label-setup/` — create-mode wizard flows
- `label-detail/` — non-spice detail/edit/delete flows
- `label-recall/` — spice recall/freshness flows
- `bulk-import/` — order flows
- `home/` — carousel/search/filter/delete flows
- `settings/` — settings/profile flows
- `errors/` — negative/fault-injected flows

### 1.5 `config.yaml` role

Use `.maestro\config.yaml` for **workspace-level** settings such as:

- flow discovery globs
- tags to include/exclude for a run
- artifact output directory
- suite-wide environment defaults (where supported)

Do **not** rely on `config.yaml` for a global `appId`. Instead, parameterize every flow header:

```yaml
appId: ${APP_ID}
---
- launchApp
```

Then run with:

```bash
maestro test .maestro -e APP_ID=com.placewell.app
```

### 1.6 Naming conventions

Use this naming pattern from day one:

- Flow files: `FEATURE-XX_short-kebab-name.yaml`
- Subflows: verb-first, e.g. `open-order-link.yaml`, `choose-room-zone.yaml`
- Tags:
  - `smoke`
  - `regression`
  - `android`
  - `ios`
  - `live-network`
  - `test-mode`
  - `destructive`
  - `manual`

### 1.7 Maestro CLI installation

**Prerequisite:** Java 17+ and a valid `JAVA_HOME`.

**Windows (recommended for current team environment):**

1. Download the latest `maestro.zip` from Maestro GitHub releases.
2. Extract to a stable folder, e.g. `C:\maestro`.
3. Add `C:\maestro\bin` to `PATH`.
4. Verify:

```powershell
maestro --help
```

**macOS:**

```bash
curl -fsSL "https://get.maestro.mobile.dev" | bash
```

or

```bash
brew tap mobile-dev-inc/tap
brew trust --formula mobile-dev-inc/tap/maestro
brew install mobile-dev-inc/tap/maestro
```

**Linux:**

```bash
curl -fsSL "https://get.maestro.mobile.dev" | bash
maestro --help
```

**Run a flow:**

```bash
maestro test .maestro\smoke\core-first-launch.yaml -e APP_ID=com.placewell.app
```

---

## 2. Test data strategy

### 2.1 Recommendation: use a hybrid strategy, not a single strategy

Use **two parallel data strategies**:

1. **Live smoke data** for a small number of production-like flows
2. **`MAESTRO_TEST_MODE=true` deterministic fixtures** for the larger regression suite

This is the best balance of:

- production realism
- CI stability
- negative-path coverage
- speed
- low maintenance

### 2.2 Why a pure live-data strategy is not enough

A live-only approach runs into several code-driven limits:

1. `placewell://scan/<id>` skips HMAC but also drops the signature, so `lookupLabel()` cannot fetch metadata for new-label flows.
2. `lookupLabel()` and `lookupOrder()` both depend on the QR service token in `app.config.js`; without a valid `LOOKUP_SECRET`, they degrade to `null`.
3. Error paths like `Order Error`, save failure, and non-PlaceWell raw QR content are hard or impossible to trigger deterministically without a test hook.
4. Existing-label flows become slow if every test has to create seed labels through the UI first.

### 2.3 Category behavior matrix

| Category | Metadata dependency | Default room | Default zone | Step 3 behavior | Save destination |
|---|---|---|---|---|---|
| `spice` | Needs `labelMetadata.freshnessCategory` for best-by suggestion | `Kitchen` | `Lower Cabinets` | Best By + In Use Since + Brand | `LabelRecall` |
| `storage` | No special metadata required | none | none | Contents + Notes | `LabelDetail` |
| `garage` | Category metadata only | `Garage` | `Shelves` | Contents + Notes | `LabelDetail` |

### 2.4 Live test dataset to create in Firestore / QR service

Create one **dedicated Maestro-only order** and never re-use it for real customers.

Recommended order contents:

| Fixture | Why it exists | Required fields |
|---|---|---|
| New spice label | Freshness setup flow | `category=spice`, `label_metadata.freshnessCategory`, default location/zone |
| New storage label | Generic create flow | `category=storage` |
| New garage label | Garage default-location coverage | `category=garage` |
| Second spice label | Recall/refill state variants | `category=spice`, freshness metadata |
| Blank label | Verify BulkImport hides blanks | `is_blank=true` |
| Order QR record | Verify BulkImport skips order-QR labels | `is_order_qr=true` |

Recommended environments:

- **Smoke order:** minimal 3-label order for fast CI
- **Regression order:** larger “full kit” order for bulk-import regression coverage

### 2.5 Environment variables to define

Use environment variables instead of hard-coding IDs into YAML.

**Always define:**

```text
APP_ID=com.placewell.app
```

**Live scan/order fixtures:**

```text
PW_SCAN_NEW_SPICE_URL=https://placewell.app/s/<LABEL_ID>-<SIG>
PW_SCAN_NEW_STORAGE_URL=https://placewell.app/s/<LABEL_ID>-<SIG>
PW_SCAN_NEW_GARAGE_URL=https://placewell.app/s/<LABEL_ID>-<SIG>
PW_SCAN_EXISTING_SPICE_LINK=placewell://scan/<LABEL_ID>
PW_SCAN_EXISTING_STORAGE_LINK=placewell://scan/<LABEL_ID>
PW_ORDER_LINK=placewell://order/<ORDER_ID>
PW_ORDER_ID=<ORDER_ID>
```

**Optional separate regression fixtures:**

```text
PW_ORDER_REGRESSION_LINK=placewell://order/<ORDER_ID>
PW_SCAN_PAST_BEST_BY_SPICE_LINK=placewell://scan/<LABEL_ID>
PW_SCAN_NOT_TRACKED_SPICE_LINK=placewell://scan/<LABEL_ID>
```

**If the live QR service is used in the build:**

```text
LOOKUP_SECRET=<valid service token>
```

### 2.6 Strong recommendation: add `MAESTRO_TEST_MODE=true`, but make it broader than HMAC bypass

**Answer to the user’s question:** yes, add a dedicated `MAESTRO_TEST_MODE=true` flag — but do **not** make it only “skip HMAC.”

A narrow HMAC bypass solves only one problem. The useful version of test mode should provide **deterministic scan injection, local seed data, and fault injection**.

Recommended test-mode capabilities:

| Capability | Why it matters |
|---|---|
| Raw QR injection hook | Lets Maestro simulate any scanned string, including invalid/non-PlaceWell content, without camera hardware |
| Fixture label lookup | Lets new-label flows get category/freshness metadata without live network |
| Fixture order lookup | Lets BulkImport regressions run without `placewell.app` dependence |
| AsyncStorage seeding/reset | Makes existing-label, Home, and Settings scenarios much faster and more stable |
| Fault injection (`lookupLabel`, `lookupOrder`, `saveLabel`) | Required for deterministic error-state coverage |

### 2.7 Recommended test-mode deep links / hooks

The most valuable hooks to add later are:

```text
placewell://maestro/raw-scan?data=<urlencoded raw QR payload>
placewell://maestro/seed?fixture=<fixture-name>
placewell://maestro/reset
placewell://maestro/fail?target=lookupLabel
placewell://maestro/fail?target=lookupOrder
placewell://maestro/fail?target=saveLabel
```

Why these hooks are better than “HMAC bypass only”:

- they can drive **valid** and **invalid** scan inputs
- they let tests cover **non-PlaceWell QR**, **invalid signature**, **network fallback**, **order errors**, and **save failures**
- they reduce the need for brittle OS-camera tricks

### 2.8 Media fixture strategy

For gallery-photo flows, keep a small set of fixture images in:

- `C:\PlaceWell\PlaceWellApp\.maestro\assets\media\`

Use Maestro `addMedia` before opening the image picker.

Recommended fixture set:

- `sample-spice.jpg`
- `sample-storage.jpg`
- `sample-garage.jpg`

### 2.9 Date picker strategy

Native date pickers are among the highest-flake parts of any mobile E2E suite.

Recommended approach:

- **P0/P1**: assert that the date field opens and saves on Android with platform-specific helper subflows
- **P2/manual**: exact iOS spinner-wheel adjustments if needed
- **Fallback**: if Android/iOS date interactions prove unstable, expose a small test-mode helper instead of fighting native-picker variance

---

## 3. `testID` additions needed

### 3.1 Naming rules

Use these selector rules consistently:

- Screen root: `<screen>-screen`
- Primary CTA: `<screen>-<action>-button`
- Inputs: `<screen>-<field>-input`
- Dynamic rows/cards: `<screen>-<entity>-<stable-id>`
- Generic shared modal elements: `pw-modal-*`

Prefer **stable IDs** over text whenever possible:

- label rows: use `label.id`
- room rows: use `room.id`
- zone rows: use `zone.id`
- dynamic list items: use either a stable index or a slugified value

### 3.2 Shared components

| Component | Element needing `testID` | Proposed `testID` |
|---|---|---|
| `App.js` | root loading state | `app-loading-indicator` |
| `PlaceWellModal` | modal root | `pw-modal` |
| `PlaceWellModal` | title | `pw-modal-title` |
| `PlaceWellModal` | message | `pw-modal-message` |
| `PlaceWellModal` | primary button | `pw-modal-primary-button` |
| `PlaceWellModal` | cancel button | `pw-modal-cancel-button` |
| `PlaceWellModal` | backdrop | `pw-modal-backdrop` |
| `DatePickerField` | row wrapper (prop-driven) | `date-field-<name>` |
| `DatePickerField` | iOS modal | `date-field-<name>-modal` |
| `DatePickerField` | iOS cancel | `date-field-<name>-cancel` |
| `DatePickerField` | iOS done | `date-field-<name>-done` |
| `BiDirectionalSlider` | track | `bi-slider-track` |
| `BiDirectionalSlider` | thumb | `bi-slider-thumb` |
| `LabelCard` | root card | `label-card-<labelId>` |
| `RoomFilterDrawer` | drawer root | `home-filter-drawer` |
| `DrawerPullTab` | pull tab | `home-filter-pull-tab` |

### 3.3 `HomeScreen.js`

| Element | Proposed `testID` |
|---|---|
| screen root | `home-screen` |
| filter/menu button | `home-filter-button` |
| shop button | `home-shop-button` |
| settings button | `home-settings-button` |
| empty-state container | `home-empty-state` |
| search input | `home-search-input` |
| search clear button | `home-search-clear-button` |
| recent section | `home-recents-section` |
| recent row | `home-recent-<labelId>` |
| search results container | `home-search-results` |
| carousel scroll view | `home-carousel` |
| carousel card | `home-carousel-card-<labelId>` |
| active filter chip | `home-filter-chip` |
| clear-filter chip/button | `home-filter-clear-button` |
| coming-soon button | `home-coming-soon-button` |
| coming-soon sheet | `home-coming-soon-sheet` |
| scan FAB | `home-scan-fab` |

### 3.4 `RoomFilterDrawer.js`

| Element | Proposed `testID` |
|---|---|
| All Labels row | `drawer-filter-all` |
| Delete All button | `drawer-delete-all-button` |
| room row | `drawer-room-<roomId>` |
| room delete button | `drawer-room-delete-<roomId>` |
| zone row | `drawer-zone-<zoneId>` |
| zone delete button | `drawer-zone-delete-<zoneId>` |
| backdrop | `drawer-backdrop` |

### 3.5 `ScannerScreen.js`

| Element | Proposed `testID` |
|---|---|
| screen root | `scanner-screen` |
| camera view | `scanner-camera-view` |
| close button | `scanner-close-button` |
| instruction text | `scanner-instruction` |
| permission screen | `scanner-permission-screen` |
| allow-camera button | `scanner-allow-camera-button` |
| not-now button | `scanner-not-now-button` |

### 3.6 `LabelFormScreen.js`

| Element | Proposed `testID` |
|---|---|
| screen root | `label-form-screen` |
| dismiss button (keep existing alias too) | `label-form-dismiss-button` |
| progress dot 0-3 | `label-form-step-dot-0` ... `label-form-step-dot-3` |
| name input | `label-form-name-input` |
| photo card / placeholder | `label-form-photo-card` |
| take-photo button | `label-form-take-photo-button` |
| choose-library button | `label-form-photo-library-button` |
| photo preview modal | `label-form-photo-preview` |
| photo viewer modal | `label-form-photo-viewer` |
| photo viewer close | `label-form-photo-viewer-close` |
| room picker trigger | `label-form-room-picker-button` |
| zone picker trigger | `label-form-zone-picker-button` |
| room picker sheet | `label-form-room-picker-sheet` |
| room option | `label-form-room-option-<roomId>` |
| add custom room toggle | `label-form-add-custom-room-button` |
| custom room input | `label-form-custom-room-input` |
| custom room confirm | `label-form-custom-room-confirm` |
| zone picker sheet | `label-form-zone-picker-sheet` |
| zone option | `label-form-zone-option-<zoneId>` |
| add custom zone toggle | `label-form-add-custom-zone-button` |
| custom zone input | `label-form-custom-zone-input` |
| custom zone confirm | `label-form-custom-zone-confirm` |
| best-by field | `label-form-best-by-field` |
| best-by edit CTA | `label-form-best-by-edit-button` |
| opened-date field | `label-form-opened-date-field` |
| brand input | `label-form-brand-input` |
| contents input | `label-form-item-input` |
| item chip | `label-form-item-chip-<index>` |
| item remove | `label-form-item-remove-<index>` |
| add-note card | `label-form-add-note-button` |
| notes input | `label-form-notes-input` |
| footer back | `label-form-back-button` |
| footer next | `label-form-next-button` |
| footer save | `label-form-save-button` |
| discard modal | `label-form-discard-modal` |
| discard keep editing | `label-form-discard-keep-button` |
| discard confirm | `label-form-discard-confirm-button` |

### 3.7 `LabelDetailScreen.js`

| Element | Proposed `testID` |
|---|---|
| screen root | `label-detail-screen` |
| back button | `label-detail-back-button` |
| hero photo/button | `label-detail-photo-button` |
| hero image | `label-detail-photo-image` |
| edit button | `label-detail-edit-button` |
| delete button | `label-detail-delete-button` |
| contents section | `label-detail-contents-section` |
| add-item input | `label-detail-add-item-input` |
| add-item button | `label-detail-add-item-button` |
| item remove button | `label-detail-remove-item-<index>` |
| notes section | `label-detail-notes-section` |
| notes input | `label-detail-notes-input` |
| notes cancel | `label-detail-notes-cancel-button` |
| notes save/done | `label-detail-notes-save-button` |
| add-note card | `label-detail-add-note-button` |

### 3.8 `LabelRecallScreen.js`

| Element | Proposed `testID` |
|---|---|
| screen root | `label-recall-screen` |
| back button | `label-recall-back-button` |
| hero photo/button | `label-recall-photo-button` |
| hero image | `label-recall-photo-image` |
| edit button | `label-recall-edit-button` |
| delete button | `label-recall-delete-button` |
| freshness pill | `label-recall-freshness-pill` |
| best-by row | `label-recall-best-by-row` |
| opened-date row | `label-recall-opened-date-row` |
| brand row | `label-recall-brand-row` |
| note row | `label-recall-note-row` |
| refill CTA | `label-recall-refill-button` |
| refill cancel | `label-recall-refill-cancel-button` |
| refill confirm | `label-recall-refill-confirm-button` |

### 3.9 `BulkImportScreen.js`

| Element | Proposed `testID` |
|---|---|
| screen root | `bulk-import-screen` |
| global room chip | `bulk-import-global-room-button` |
| global zone chip | `bulk-import-global-zone-button` |
| apply-all button | `bulk-import-apply-all-button` |
| track-freshness toggle | `bulk-import-track-freshness-toggle` |
| label row | `bulk-import-label-<labelId>` |
| label room chip | `bulk-import-label-room-<labelId>` |
| label zone chip | `bulk-import-label-zone-<labelId>` |
| create button | `bulk-import-create-button` |
| picker sheet | `bulk-import-picker-sheet` |
| picker none option | `bulk-import-picker-none` |
| picker option | `bulk-import-picker-option-<type>-<id>` |
| add-new row | `bulk-import-picker-add-new-button` |
| add-new input | `bulk-import-picker-add-new-input` |
| add-new confirm | `bulk-import-picker-add-new-confirm` |

### 3.10 `SettingsScreen.js`

| Element | Proposed `testID` |
|---|---|
| screen root | `settings-screen` |
| back button | `settings-back-button` |
| avatar button | `settings-profile-button` |
| Rooms & Zones tab | `settings-tab-rooms` |
| About tab | `settings-tab-about` |
| custom rooms outer toggle | `settings-custom-rooms-toggle` |
| room row | `settings-room-<roomId>` |
| room delete button | `settings-room-delete-<roomId>` |
| custom zones outer toggle | `settings-custom-zones-toggle` |
| zone delete button | `settings-zone-delete-<zoneId>` |
| scan sound switch | `settings-scan-sound-toggle` |
| profile sheet | `settings-profile-sheet` |
| member-name edit button | `settings-profile-name-edit-button` |
| member-name input | `settings-profile-name-input` |
| member-name save | `settings-profile-name-save-button` |
| household-name edit button | `settings-profile-household-edit-button` |
| household-name input | `settings-profile-household-input` |
| household-name save | `settings-profile-household-save-button` |
| copy household code button | `settings-profile-copy-code-button` |

---

## 4. Complete scenario coverage

### Guidance for the full suite

- Prefer **tap-based** flows over gesture-heavy paths when both exist.
- Use the wizard **Back/Next/Save buttons** instead of horizontal swipe gestures.
- Use `placewell://scan/<id>` only for **existing-label** flows.
- Use **signed HTTPS QR URLs** (or a test-mode raw-scan hook) for **new-label** flows that need metadata.
- Tag destructive flows (`delete`, `bulk delete`) as **`destructive`** and always start them from a clean state.

### 4.1 Fresh install / app bootstrap

#### CORE-01 — First launch lands on empty Home
- **User story:** As a first-time user, I want the app to open to a clean Home screen so I know I have not created any labels yet.
- **Steps:**
  1. `launchApp` with `clearState: true` and normal permissions.
  2. Wait for the Home wordmark/root.
  3. Assert the empty-state hint is visible.
  4. Assert the scan FAB is visible.
  5. Assert the search bar and filter button are not visible yet.
- **Expected outcome:** Home loads with no labels, no search UI, and a visible scan entry point.
- **Maestro commands:** `launchApp`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** none.

#### CORE-02 — First launch bootstrap data is visible in Settings/Profile
- **User story:** As a first-time user, I want my local profile/household data to exist automatically without onboarding.
- **Steps:**
  1. Start from a clean install state.
  2. Tap `home-settings-button`.
  3. Assert `About` is visible.
  4. Assert `Rooms & Zones` is absent on a fresh install (no custom entries yet).
  5. Tap `settings-profile-button`.
  6. Assert household name, household code, member name, and role rows are present.
- **Expected outcome:** The app shows auto-generated identity data and hides the custom-room tab on fresh state.
- **Maestro commands:** `launchApp`, `tapOn`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** none.

### 4.2 Scanner entry / deep-link routing

#### SCAN-01 — Scanner permission states from Home
- **User story:** As a user, I want a clear permission message when camera access is denied and a working scanner when it is allowed.
- **Steps:**
  1. Variant A: `launchApp` with `camera: deny`.
  2. Tap `home-scan-fab`.
  3. Assert `scanner-permission-screen`, `scanner-allow-camera-button`, and `scanner-not-now-button`.
  4. Tap `scanner-not-now-button` and assert Home is visible again.
  5. Variant B: relaunch with `camera: allow`.
  6. Tap `home-scan-fab`, assert `scanner-camera-view`, then tap `scanner-close-button`.
- **Expected outcome:** Denied permission shows the explainer screen; allowed permission shows the live scanner.
- **Maestro commands:** `launchApp`, `tapOn`, `assertVisible`, `killApp`.
- **Test data dependencies:** none.

#### SCAN-02 — Signed new-label deep link opens setup (cold + warm variants)
- **User story:** As a user scanning a new label, I want the app to open directly into setup whether the app was closed or already running.
- **Steps:**
  1. Variant A (cold): `killApp`, then `openLink` the signed label URL with `autoVerify: true` for HTTPS.
  2. Assert the label setup wizard appears.
  3. Variant B (warm): `launchApp`, then `openLink` the same signed label URL.
  4. Assert the same setup wizard appears.
- **Expected outcome:** Both cold and warm entry paths reach `LabelSetup` without manual navigation.
- **Maestro commands:** `killApp`, `launchApp`, `openLink`, `assertVisible`, `extendedWaitUntil`.
- **Test data dependencies:** one valid signed new-label URL such as `PW_SCAN_NEW_SPICE_URL` or a test-mode raw-scan hook.

#### SCAN-03 — Existing non-spice scan opens `LabelDetail`
- **User story:** As a returning user, I want re-scanning an existing storage/garage label to reopen its detail screen immediately.
- **Steps:**
  1. Seed/create a non-spice label locally.
  2. `openLink` the existing-label link (`placewell://scan/<id>` is acceptable here).
  3. Assert `label-detail-screen` and the correct label name/location.
- **Expected outcome:** The app bypasses setup and lands on non-spice detail.
- **Maestro commands:** `runFlow`, `openLink`, `assertVisible`, `extendedWaitUntil`.
- **Test data dependencies:** existing locally-created storage/garage label.

#### SCAN-04 — Existing spice scan opens `LabelRecall`
- **User story:** As a returning spice user, I want re-scanning a spice label to take me straight to freshness/recall.
- **Steps:**
  1. Seed/create an existing spice label locally.
  2. `openLink` the existing spice link.
  3. Assert `label-recall-screen`, freshness pill, and label name.
- **Expected outcome:** The app bypasses setup and lands on recall.
- **Maestro commands:** `runFlow`, `openLink`, `assertVisible`, `extendedWaitUntil`.
- **Test data dependencies:** existing locally-created spice label.

#### SCAN-05 — Order deep link opens `BulkImport` (cold + warm variants)
- **User story:** As a user scanning an order QR, I want the app to go straight to the bulk-import review screen whether the app is closed or already open.
- **Steps:**
  1. Variant A (cold): `killApp`, then `openLink` `placewell://order/<ORDER_ID>`.
  2. Assert `bulk-import-screen` and the Set Up Labels header.
  3. Variant B (warm): `launchApp`, then `openLink` the same custom-scheme order link.
  4. Assert the same screen.
- **Expected outcome:** Both entry modes open `BulkImport` and load order labels.
- **Maestro commands:** `killApp`, `launchApp`, `openLink`, `assertVisible`, `extendedWaitUntil`.
- **Test data dependencies:** `PW_ORDER_LINK`; valid `LOOKUP_SECRET` or test-mode fixture order.

### 4.3 Label setup / create-mode wizard

#### SETUP-01 — Create a new spice label
- **User story:** As a spice user, I want setup to suggest freshness info and send me to recall after save.
- **Steps:**
  1. Start from `PW_SCAN_NEW_SPICE_URL` (or test-mode raw scan with signed payload).
  2. On step 0, verify/fill the label name.
  3. Advance to step 1 and optionally skip photo.
  4. Advance to step 2 and assert `Kitchen` and `Lower Cabinets` are preselected.
  5. Advance to step 3 and assert a Best By suggestion card plus today-style In Use Since value.
  6. Optionally enter Brand.
  7. Tap Save.
  8. Assert `label-recall-screen` opens.
- **Expected outcome:** Spice metadata drives defaults and the saved label lands on recall.
- **Maestro commands:** `openLink`, `tapOn`, `inputText`, `assertVisible`, `scrollUntilVisible`.
- **Test data dependencies:** live or test-mode spice fixture with `freshnessCategory` metadata.

#### SETUP-02 — Create a new storage label with photo, contents, and notes
- **User story:** As a storage user, I want to add a photo, assign a location, list contents, and save notes in one setup flow.
- **Steps:**
  1. Open a new storage-label setup flow.
  2. Enter or confirm the label name.
  3. Use `addMedia`, then choose a gallery photo on step 1.
  4. On step 2, choose an existing room and zone.
  5. On step 3, add one or more contents items.
  6. Add a quick note.
  7. Save.
  8. Assert `label-detail-screen` with saved contents/note.
- **Expected outcome:** Non-spice setup persists photo, location, contents, and notes and lands on detail.
- **Maestro commands:** `openLink`, `addMedia`, `tapOn`, `inputText`, `assertVisible`, `runFlow`.
- **Test data dependencies:** new storage label URL or test-mode fixture; gallery media fixture.

#### SETUP-03 — Create a new garage label with `Garage / Shelves` defaults
- **User story:** As a garage user, I want the app to pre-fill the likely garage location and let me save quickly.
- **Steps:**
  1. Open a new garage-label setup flow.
  2. Advance to the location step.
  3. Assert room is `Garage`.
  4. Assert zone is `Shelves`.
  5. Add optional contents/note and save.
  6. Assert `label-detail-screen`.
- **Expected outcome:** Garage labels pre-fill their intended location, including auto-creation of `Shelves` when needed.
- **Maestro commands:** `openLink`, `tapOn`, `assertVisible`, `inputText`.
- **Test data dependencies:** new garage label URL or test-mode fixture.

#### SETUP-04 — Add a custom room and custom zone during setup
- **User story:** As a user, I want to create a brand-new room and zone while setting up a label.
- **Steps:**
  1. Start a storage setup flow.
  2. On the location step, open the room picker.
  3. Tap Add custom room, enter a room name, and confirm.
  4. Assert the zone picker opens; tap Add custom zone, enter a zone name, and confirm.
  5. Save the label.
  6. Open Settings and verify the custom room/zone exist.
- **Expected outcome:** Custom rooms/zones are created, selected, saved, and later visible in Settings.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`, `runFlow`.
- **Test data dependencies:** any new non-spice label flow.

#### SETUP-05 — Dismiss a saveable setup flow with `Save & Exit`
- **User story:** As a user who has already filled the required fields, I want to save directly from the dismiss action instead of losing work.
- **Steps:**
  1. Start a new non-spice setup flow.
  2. Fill a valid name, room, and zone so the label is saveable.
  3. Tap the top-right dismiss button.
  4. Assert the `Save or Discard?` modal.
  5. Tap the primary `Save & Exit` action.
  6. Assert the saved label opens on detail.
- **Expected outcome:** The modal offers save, and choosing save persists the label and exits safely.
- **Maestro commands:** `tapOn`, `assertVisible`, `inputText`.
- **Test data dependencies:** new non-spice label flow.

#### SETUP-06 — Dismiss an incomplete setup flow and keep/discard edits
- **User story:** As a user who is not ready to save, I want a safe way to keep editing or discard partial work.
- **Steps:**
  1. Start a new setup flow and enter partial data only.
  2. Tap dismiss.
  3. Assert the `Discard changes?` modal.
  4. Tap `Keep editing` and assert the form remains.
  5. Repeat and choose `Discard`.
  6. Assert the app exits the form.
- **Expected outcome:** The incomplete flow does not silently disappear.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** any new-label flow.

#### SETUP-07 — Required-field validation blocks Next and Save
- **User story:** As a user, I want clear validation when required setup fields are missing.
- **Steps:**
  1. Start a fresh setup flow.
  2. Tap Next on the name step with no valid name.
  3. Assert a name validation message.
  4. Enter a valid name and advance to location.
  5. Try to advance/save without room/zone.
  6. Assert room/zone validation messages.
- **Expected outcome:** The wizard prevents incomplete required-state progression.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`.
- **Test data dependencies:** any new-label flow.

### 4.4 Label detail (non-spice)

#### DETAIL-01 — Inline contents add/remove auto-save
- **User story:** As a user, I want to update contents inline without opening the full wizard.
- **Steps:**
  1. Open an existing non-spice label detail screen.
  2. Tap the Contents section.
  3. Add a new item and submit.
  4. Assert the screen exits edit mode and the item count increases.
  5. Re-enter contents edit mode.
  6. Remove an item and assert the updated list persists.
- **Expected outcome:** Contents changes auto-save immediately and exit edit mode.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** seeded existing non-spice label.

#### DETAIL-02 — Inline notes cancel/save flow
- **User story:** As a user, I want notes editing to support both cancel and save paths.
- **Steps:**
  1. Open existing non-spice detail.
  2. Tap Add Note (or existing note).
  3. Enter note text and tap Cancel.
  4. Assert the new note is not shown.
  5. Reopen notes, enter text again, and tap Done.
  6. Assert the note is visible on the detail screen.
- **Expected outcome:** Cancel discards draft notes; Done persists them.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** seeded existing non-spice label.

#### DETAIL-03 — Change photo from gallery on detail screen
- **User story:** As a user, I want to change a label photo inline from the detail screen.
- **Steps:**
  1. Seed gallery media with `addMedia`.
  2. Open label detail.
  3. Tap the photo area.
  4. Assert the `Change Photo` modal.
  5. Choose `Photo Library`.
  6. Use an OS-specific subflow to pick the seeded image.
  7. Assert the photo state changes (image visible or placeholder gone).
- **Expected outcome:** The label photo updates without opening full edit.
- **Maestro commands:** `addMedia`, `tapOn`, `assertVisible`, `runFlow`, `extendedWaitUntil`.
- **Test data dependencies:** seeded label; gallery media fixture.

#### EDIT-01 — Full edit from detail returns to updated detail
- **User story:** As a user, I want to open the full edit wizard from detail, change fields, save, and return to detail.
- **Steps:**
  1. Open label detail.
  2. Tap the edit/pencil button.
  3. Change one or more fields (name, room/zone, note, contents).
  4. Save.
  5. Assert the app goes back to detail.
  6. Assert updated values are visible.
- **Expected outcome:** Edit mode reuses the wizard and returns cleanly to the detail screen.
- **Maestro commands:** `tapOn`, `inputText`, `scrollUntilVisible`, `assertVisible`.
- **Test data dependencies:** seeded existing non-spice label.

#### DELETE-01 — Delete non-spice label from detail
- **User story:** As a user, I want to permanently delete a non-spice label from detail with confirmation.
- **Steps:**
  1. Open label detail.
  2. Tap delete.
  3. Assert the destructive modal.
  4. Confirm deletion.
  5. Assert the app returns to Home.
  6. Assert the label is no longer searchable/visible.
- **Expected outcome:** The label is removed locally and no longer appears in Home/search.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`, `inputText`.
- **Test data dependencies:** seeded existing non-spice label; clean-state isolation recommended.

### 4.5 Label recall (spice)

#### RECALL-01 — Recall hero and freshness states
- **User story:** As a spice user, I want the recall screen to immediately tell me whether the spice is fresh, untracked, or past best-by.
- **Steps:**
  1. Open recall on three fixture variants: fresh, not-tracked, and past-best-by.
  2. Assert the hero card loads.
  3. Assert the freshness pill text matches the seed state.
  4. Assert Best By / In Use Since rows are present.
- **Expected outcome:** The recall screen reflects stored freshness state correctly.
- **Maestro commands:** `openLink`, `assertVisible`, `runFlow`.
- **Test data dependencies:** three seeded spice states; test-mode seeding strongly recommended.

#### RECALL-02 — Edit Best By and In Use Since
- **User story:** As a spice user, I want to adjust freshness dates directly from recall.
- **Steps:**
  1. Open recall for a spice label.
  2. Tap the Best By row.
  3. Use platform-specific date-picker helper flow to choose/save a date.
  4. Assert the row updates.
  5. Tap the In Use Since row.
  6. Change/save the date and assert the display updates.
- **Expected outcome:** Both freshness dates are editable inline and persist.
- **Maestro commands:** `tapOn`, `runFlow`, `assertVisible`, `extendedWaitUntil`.
- **Test data dependencies:** seeded spice label; Android/iOS date helper subflows or TM helper.

#### RECALL-03 — Refill CTA cancel + confirm
- **User story:** As a spice user, I want a safe two-step refill action that updates freshness data when I confirm.
- **Steps:**
  1. Open recall.
  2. Tap `I just refilled this`.
  3. Assert the inline confirm row appears.
  4. Tap Cancel and assert the original CTA returns.
  5. Tap the CTA again and confirm refill.
  6. Assert the screen updates and the pending state clears.
- **Expected outcome:** Cancel is non-destructive; confirm updates the recall state and preserves usability.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`, `extendedWaitUntil`.
- **Test data dependencies:** seeded spice label.

#### RECALL-04 — Change photo from gallery on recall screen
- **User story:** As a spice user, I want to update the spice photo from the recall screen.
- **Steps:**
  1. Seed gallery media.
  2. Open recall.
  3. Tap the hero photo area.
  4. Choose `Photo Library` from the modal.
  5. Select the seeded image.
  6. Assert the photo changed.
- **Expected outcome:** Recall supports inline photo updates similar to detail.
- **Maestro commands:** `addMedia`, `tapOn`, `assertVisible`, `runFlow`.
- **Test data dependencies:** seeded spice label; gallery media fixture.

#### EDIT-02 — Full edit from recall returns to updated recall screen
- **User story:** As a spice user, I want to open full edit from recall, change fields, save, and come back to recall.
- **Steps:**
  1. Open recall.
  2. Tap edit.
  3. Change one or more editable fields.
  4. Save.
  5. Assert the app returns to recall.
  6. Assert updated values are visible.
- **Expected outcome:** Spice edit returns to recall, not generic detail.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`, `scrollUntilVisible`.
- **Test data dependencies:** seeded spice label.

#### DELETE-02 — Delete spice label from recall
- **User story:** As a spice user, I want to delete a spice label from recall with confirmation.
- **Steps:**
  1. Open recall.
  2. Tap delete.
  3. Assert destructive confirmation modal.
  4. Confirm delete.
  5. Assert the label is gone and the app returns to Home.
- **Expected outcome:** The spice label is permanently removed locally.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** seeded spice label; destructive isolation.

### 4.6 Bulk import

#### IMPORT-01 — Review order labels, defaults, and hidden blank/order-QR rows
- **User story:** As a user scanning an order, I want to review only real importable labels before creating them.
- **Steps:**
  1. Open the dedicated order link.
  2. Assert `bulk-import-screen` and the header text.
  3. Assert known importable labels are visible.
  4. Assert blank labels and order-QR labels are not rendered.
  5. Assert the global room/zone defaults are populated from the first importable label.
- **Expected outcome:** The review screen only shows importable labels and preloads the expected defaults.
- **Maestro commands:** `openLink`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** dedicated order fixture with visible/importable + hidden rows.

#### IMPORT-02 — Apply global room/zone to all labels
- **User story:** As a user, I want to assign one room/zone pair to all imported labels quickly.
- **Steps:**
  1. Open bulk import.
  2. Change the global room.
  3. Change the global zone.
  4. Tap `Apply to All`.
  5. Assert multiple label rows now show the chosen room/zone.
- **Expected outcome:** Global assignment updates all importable rows.
- **Maestro commands:** `tapOn`, `assertVisible`, `scrollUntilVisible`.
- **Test data dependencies:** order with multiple importable labels.

#### IMPORT-03 — Per-label override plus add-new room/zone
- **User story:** As a user, I want to override one imported label without affecting the rest and create new location values if needed.
- **Steps:**
  1. Open bulk import.
  2. Change one label’s room chip.
  3. Use the picker’s Add New Room path.
  4. Change the same label’s zone chip.
  5. Use Add New Zone.
  6. Assert only that label changed.
- **Expected outcome:** Per-label overrides are isolated and new room/zone values become selectable.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** order fixture with multiple labels.

#### IMPORT-04 — Track-freshness toggle ON/OFF affects created spice data
- **User story:** As a bulk-import user, I want to decide whether spice labels should start with tracked freshness data.
- **Steps:**
  1. Variant A: leave the toggle ON and create all.
  2. Open a created spice label and assert tracked freshness fields are present.
  3. Variant B: reset state, open the order again, toggle OFF, create all.
  4. Open the created spice label and assert it is effectively not tracked.
- **Expected outcome:** The toggle directly changes spice-label freshness initialization.
- **Maestro commands:** `tapOn`, `openLink`, `assertVisible`, `runFlow`.
- **Test data dependencies:** order with at least one spice label carrying freshness metadata.

#### IMPORT-05 — Customize one label in the wizard, return, then create remaining
- **User story:** As a user, I want to fine-tune one imported label before creating the rest.
- **Steps:**
  1. Open bulk import.
  2. Tap one label row.
  3. Complete `BulkImportLabelSetup` with a changed name/location.
  4. Save and return to bulk import.
  5. Assert the row now reflects the saved data.
  6. Create the remaining labels.
- **Expected outcome:** Individually customized labels show saved state and are skipped cleanly during final bulk create.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`, `back` (if needed), `scrollUntilVisible`.
- **Test data dependencies:** dedicated order fixture.

#### IMPORT-06 — Re-scan the same order after setup and hit `All labels already set up`
- **User story:** As a repeat user, I want re-scanning a completed order to tell me nothing new needs to be created.
- **Steps:**
  1. Start from a state where every importable label from the order already exists locally.
  2. Open the same order link again.
  3. Tap Create.
  4. Assert the success modal message is `All labels already set up`.
- **Expected outcome:** The app skips duplicates and reports zero new labels created.
- **Maestro commands:** `openLink`, `tapOn`, `assertVisible`.
- **Test data dependencies:** same order as IMPORT-01 with all labels pre-created.

### 4.7 Home screen

#### HOME-01 — Carousel browse and open label
- **User story:** As a user, I want to browse labels from Home and open one directly.
- **Steps:**
  1. Seed multiple labels in different rooms.
  2. Launch Home.
  3. Assert the carousel is visible.
  4. Swipe left/right through cards.
  5. Tap a non-spice card.
  6. Assert detail opens.
- **Expected outcome:** The carousel is navigable and cards open the right destination.
- **Maestro commands:** `launchApp`, `swipe`, `tapOn`, `assertVisible`.
- **Test data dependencies:** at least 2–3 seeded labels.

#### HOME-02 — Search, clear, and recently viewed behavior
- **User story:** As a user, I want inline search and recent labels to help me find things quickly.
- **Steps:**
  1. Seed multiple labels and open at least one label so it becomes recent.
  2. Return Home.
  3. Focus the search input with an empty query.
  4. Assert the Recently Viewed section appears.
  5. Enter a query.
  6. Wait for debounce and assert matching result(s).
  7. Tap clear and assert the carousel returns.
- **Expected outcome:** Home shows recents on focus, debounced search results on input, and resets cleanly on clear.
- **Maestro commands:** `tapOn`, `inputText`, `extendedWaitUntil`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** seeded labels; at least one label with `lastViewedAt` created in-flow.

#### HOME-03 — Room/zone filter drawer and clear-filter chip
- **User story:** As a user, I want to filter labels by room or zone and clear the filter easily.
- **Steps:**
  1. Seed labels across multiple rooms/zones.
  2. Open the filter drawer.
  3. Choose a room and assert the filter chip appears.
  4. Reopen the drawer and choose a zone.
  5. Assert the filter chip updates to room + zone.
  6. Tap the clear-filter chip and assert all labels return.
- **Expected outcome:** Room and zone filters both work, and clear returns to the full carousel.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`, `scrollUntilVisible`.
- **Test data dependencies:** multi-room seeded label set.

#### HOME-04 — Bulk delete from filter drawer (all / room / zone variants)
- **User story:** As a user, I want to bulk-delete all labels in a scope from the Home filter drawer.
- **Steps:**
  1. Variant A: open drawer and tap Delete All.
  2. Confirm the modal and assert Home is empty.
  3. Variant B: reset state, delete one room’s labels.
  4. Variant C: reset state, delete one zone’s labels.
- **Expected outcome:** Each destructive scope removes only the intended labels.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`, `launchApp` with clean-state resets between variants.
- **Test data dependencies:** clean seeded label sets; destructive isolation.

#### HOME-05 — Coming Soon sheet opens and closes
- **User story:** As a user, I want the Coming Soon teaser to open a clean bottom sheet and close without side effects.
- **Steps:**
  1. Open Home.
  2. Tap the sparkle button.
  3. Assert the Coming Soon sheet title and feature rows.
  4. Close the sheet via backdrop.
  5. Assert Home is visible again.
- **Expected outcome:** The sheet opens/animates cleanly and dismisses safely.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** none.

### 4.8 Settings

#### SETTINGS-01 — `Rooms & Zones` visibility and expansion
- **User story:** As a user, I want the Rooms & Zones tab to appear only when I have custom locations, and I want those groups to expand correctly.
- **Steps:**
  1. Fresh-install variant: open Settings and assert only About is visible.
  2. Custom-data variant: create a custom room/zone in a prior seed/setup flow.
  3. Reopen Settings.
  4. Assert the `Rooms & Zones` tab is now visible.
  5. Expand Custom Rooms and Custom Zones and assert entries render.
- **Expected outcome:** The tab is conditional, and both custom sections expand correctly.
- **Maestro commands:** `tapOn`, `assertVisible`, `assertNotVisible`, `runFlow`.
- **Test data dependencies:** custom room/zone for variant B.

#### SETTINGS-02 — Cannot delete an active room or active zone
- **User story:** As a user, I want the app to protect rooms and zones that still contain active labels.
- **Steps:**
  1. Seed a label inside a custom room/zone.
  2. Open Settings → Rooms & Zones.
  3. Attempt to delete the room.
  4. Assert the `Cannot Delete` modal.
  5. Attempt to delete the zone.
  6. Assert the same protection.
- **Expected outcome:** Active-location deletion is blocked with a clear error modal.
- **Maestro commands:** `tapOn`, `assertVisible`, `runFlow`.
- **Test data dependencies:** seeded active label in custom room/zone.

#### SETTINGS-03 — Scan sound toggle persists across relaunch
- **User story:** As a user, I want my scan-sound preference to persist across app restarts.
- **Steps:**
  1. Open Settings → About.
  2. Toggle scan sound OFF.
  3. Kill/relaunch app.
  4. Return to Settings → About.
  5. Assert the toggle is still OFF.
  6. Toggle it back ON to avoid leaking state into later tests.
- **Expected outcome:** The preference persists in AsyncStorage.
- **Maestro commands:** `tapOn`, `killApp`, `launchApp`, `assertVisible`.
- **Test data dependencies:** none.

#### SETTINGS-04 — Edit profile fields and copy household code
- **User story:** As a user, I want to rename myself/household and copy the household code from the profile sheet.
- **Steps:**
  1. Open the profile sheet.
  2. Edit member name and save.
  3. Edit household name and save.
  4. Tap copy code.
  5. Assert the `Copied!` feedback text.
- **Expected outcome:** Profile edits persist and copy feedback is shown.
- **Maestro commands:** `tapOn`, `inputText`, `assertVisible`.
- **Test data dependencies:** none, though TM seeding can make assertions deterministic.

### 4.9 Error and resilience paths

#### ERR-01 — Non-PlaceWell QR shows Invalid QR modal
- **User story:** As a user, I want a clear error if I scan a QR code that is not a PlaceWell code.
- **Steps:**
  1. Use the raw-scan test hook to inject a non-PlaceWell string such as `https://google.com`.
  2. Assert the Invalid QR modal.
  3. Tap Try Again.
  4. Assert scanner resets.
- **Expected outcome:** The app rejects non-PlaceWell content with the correct modal.
- **Maestro commands:** `openLink`, `assertVisible`, `tapOn`.
- **Test data dependencies:** **TM required** unless a camera-image injection strategy is added later.

#### ERR-02 — Wrong HMAC signature shows Invalid QR modal
- **User story:** As a user, I want corrupted/forged PlaceWell label URLs to be rejected.
- **Steps:**
  1. `openLink` a signed-looking HTTPS URL with a wrong signature.
  2. Assert the Invalid QR modal.
  3. Tap Try Again.
- **Expected outcome:** The app rejects the code before any lookup succeeds.
- **Maestro commands:** `openLink`, `assertVisible`, `tapOn`.
- **Test data dependencies:** none; synthetic bad signature is enough.

#### ERR-03 — Label lookup auth/network failure falls back to generic setup
- **User story:** As a user, I want setup to continue with minimal data if metadata lookup fails after QR validation.
- **Steps:**
  1. Start a valid new-label scan.
  2. Force `lookupLabel` to return `null` via TM fault injection or use a dedicated no-token build.
  3. Assert the setup wizard still opens.
  4. Assert category-driven defaults/freshness hints are absent or generic.
- **Expected outcome:** Setup still works, but it falls back to generic data when metadata lookup fails.
- **Maestro commands:** `openLink`, `assertVisible`, `assertNotVisible`.
- **Test data dependencies:** valid signed label URL plus TM fault injection or dedicated no-token build.

#### ERR-04 — Order not found modal
- **User story:** As a user, I want a clear message when an order QR does not map to any labels.
- **Steps:**
  1. `openLink` a missing/nonexistent order ID.
  2. Assert `Order Not Found` modal.
  3. Dismiss and assert the app remains usable.
- **Expected outcome:** Missing orders do not crash the scanner and show the correct error message.
- **Maestro commands:** `openLink`, `assertVisible`, `tapOn`.
- **Test data dependencies:** missing order ID; live or TM fixture path.

#### ERR-05 — Order lookup exception path shows `Order Error`
- **User story:** As a user, I want an unexpected order-load failure to show a clear retryable error.
- **Steps:**
  1. Force `lookupOrder` to throw/reject via TM fault injection.
  2. Trigger the order path.
  3. Assert `Order Error` modal.
  4. Dismiss and assert scanner state is recoverable.
- **Expected outcome:** Unexpected exceptions surface as `Order Error`, not a crash.
- **Maestro commands:** `openLink`, `assertVisible`, `tapOn`.
- **Test data dependencies:** **TM required**.

#### ERR-06 — Save failure modal from setup/edit/recall
- **User story:** As a user, I want failed saves to show a clear modal instead of silently losing changes.
- **Steps:**
  1. Force `saveLabel` to reject via TM fault injection.
  2. Trigger a save from `LabelForm`, `LabelDetail`, or `LabelRecall`.
  3. Assert the save-failure modal.
  4. Dismiss and verify the screen remains stable.
- **Expected outcome:** Failed persistence shows the proper modal and leaves the app usable.
- **Maestro commands:** `tapOn`, `assertVisible`, `openLink` (for TM hook) if needed.
- **Test data dependencies:** **TM required**.

---

## 5. Scenario addition script design

### 5.1 Recommendation: use **Node.js + commander**

**Recommended stack:** `Node.js + commander + yaml + slugify`

Why this is the best fit here:

- The app repo is already Node/Expo-based.
- The team already has `package.json` and Node tooling.
- Windows support is better than a bash-first solution.
- YAML/JSON manipulation is straightforward.
- An optional LLM integration can be added later without changing the main stack.

**Not recommended:** bash-only solution

- poor Windows ergonomics
- brittle YAML generation
- harder metadata/index maintenance

### 5.2 CLI UX

Proposed commands:

```bash
npm run maestro:add -- --prompt "Test that when a user scans a garage label it shows LabelDetail"
npm run maestro:list
npm run maestro:test -- --id SCAN-03
```

The user should never need to hand-edit YAML.

### 5.3 Script inputs/outputs

**Input:** natural-language prompt, optional flags

Examples:

- `Test that when a user scans a garage label it shows LabelDetail`
- `Create a smoke test for scan sound toggle persistence`
- `Add a regression test for bulk import where track freshness is off`

**Output:**

1. YAML flow file saved to the correct feature folder
2. `scenario-index.yaml` updated
3. optional console summary showing:
   - file path
   - tags
   - env vars required
   - suggested suite (`smoke` vs `regression`)

### 5.4 Recommended architecture

Use a **template-first** generator with optional LLM classification.

#### Step 1 — Intent classification
Map prompt → scenario family:

- scanner
- label-setup
- label-detail
- label-recall
- bulk-import
- home
- settings
- error

#### Step 2 — Template selection
Pick a base template such as:

- `scan-existing-to-detail`
- `scan-existing-to-recall`
- `new-label-setup`
- `bulk-import-create-all`
- `settings-toggle-persistence`
- `error-invalid-signature`

#### Step 3 — Slot filling
Fill placeholders from a scenario/data catalog:

- feature folder
- filename slug
- default tags
- required env vars
- required subflows
- selectors from `selector-catalog.json`

#### Step 4 — YAML render + validation
Render the flow, then validate:

- YAML parse check
- required env var presence check
- file-path collision check
- optional `maestro test` run if a device is attached

### 5.5 Why template-first is better than pure free-form LLM generation

Pure free-form YAML generation will drift quickly when:

- selectors change
- tag rules change
- the team adopts shared subflows
- the app introduces a test-mode seed hook

Template-first generation keeps:

- selectors centralized
- flow shape consistent
- subflow reuse high
- review noise low

The LLM (if used) should only do **classification + variable extraction**, not invent selectors from scratch.

### 5.6 Files the script should own

| File | Purpose |
|---|---|
| `scripts/maestro/add-scenario.mjs` | main CLI entry |
| `scripts/maestro/scenario-catalog.json` | supported intents/templates |
| `scripts/maestro/selector-catalog.json` | canonical testIDs/selectors |
| `.maestro/scenario-index.yaml` | authoritative scenario registry |
| `.maestro/<feature>/<file>.yaml` | generated flow |

### 5.7 `scenario-index.yaml` shape

```yaml
- id: SCAN-03
  title: Existing non-spice scan opens LabelDetail
  file: scanner/SCAN-03_existing-nonspice-to-detail.yaml
  feature: scanner
  tags: [smoke, android]
  requiredEnv:
    - APP_ID
    - PW_SCAN_EXISTING_STORAGE_LINK
  createdFromPrompt: "Test that when a user scans a garage label it shows LabelDetail"
```

### 5.8 Future optional LLM integration

If the team wants an LLM-assisted version later, the prompt context should always include:

- current scenario catalog
- selector catalog
- allowed Maestro commands
- required folder structure
- tag rules
- sample flows

That keeps generation bounded and reviewable.

---

## 6. CI/CD integration plan

### 6.1 Recommended test lanes

Use **two CI lanes**:

1. **Push-to-main smoke lane (P0)**
   - fast
   - Android emulator only
   - ~5–10 highest-signal flows
2. **Nightly / dispatch regression lane (P1)**
   - broader scenario coverage
   - includes destructive flows and TM-only flows

### 6.2 Free-tier approach (no Maestro Cloud cost)

Run Maestro **locally in GitHub Actions** against a local Android emulator.

High-level workflow:

1. checkout repo
2. setup Node and Java 17
3. install npm dependencies
4. install Maestro CLI
5. build/install Android app
6. boot Android emulator
7. run Maestro smoke flows
8. upload `.maestro` artifacts/screenshots on failure

### 6.3 Workflow recommendation for every push to `main`

**Trigger:** `push` to `main`

**Job contents:**

- install Java 17
- install Node 20
- `npm install --legacy-peer-deps`
- install Maestro CLI
- start emulator
- install app build
- run P0 flows only

Recommended smoke set:

- `CORE-01`
- `SCAN-03`
- `SCAN-04`
- `SCAN-05`
- `SETUP-01`
- `SETUP-02`
- `RECALL-03`
- `IMPORT-01`
- `HOME-01`
- `SETTINGS-03`
- `ERR-02`

### 6.4 Suggested GitHub Actions shape

Use either:

- **Option A (recommended):** `reactivecircus/android-emulator-runner` for emulator boot
- **Option B:** `maestro start-device --platform=android ...` if the team wants a Maestro-only stack

Recommended commands inside CI:

```bash
maestro list-devices
maestro test .maestro -e APP_ID=com.placewell.app
```

### 6.5 Artifact strategy

Always upload on failure:

- `.maestro` test output directory
- screenshots
- Maestro logs
- optional app logcat output if captured

This is essential for diagnosing picker/deep-link flakiness.

### 6.6 How to generate EAS test builds for Maestro

Create a **dedicated EAS Maestro profile** instead of reusing production:

Suggested future profile shape:

```json
"maestro-android": {
  "distribution": "internal",
  "developmentClient": false,
  "android": {
    "buildType": "apk"
  },
  "env": {
    "MAESTRO_TEST_MODE": "true"
  }
}
```

Recommended usage:

- **Release-parity/manual lane:** `eas build --profile maestro-android --platform android`
- **Local device smoke:** install the generated APK on emulator/device and run Maestro locally
- **Optional future iOS local lane:** add a separate simulator-focused Maestro profile for Mac-based local testing

### 6.7 Recommended build split

Because the user explicitly wants a **free-tier local-emulator CI lane**, use this split:

#### Every push to `main`
- build locally in CI (or use a locally-produced debug/dev artifact)
- run P0 smoke on Android emulator
- no Maestro Cloud cost

#### Nightly / pre-release
- use the dedicated EAS `maestro-android` APK for closer-to-production validation
- run the broader regression suite

This keeps daily CI cheap while still preserving a release-like lane.

### 6.8 Environment variables in CI

Smoke/regression jobs should pass only what they need.

Examples:

```text
APP_ID=com.placewell.app
PW_ORDER_LINK=placewell://order/<ORDER_ID>
PW_SCAN_NEW_SPICE_URL=https://placewell.app/s/<LABEL>-<SIG>
PW_SCAN_EXISTING_SPICE_LINK=placewell://scan/<LABEL>
PW_SCAN_EXISTING_STORAGE_LINK=placewell://scan/<LABEL>
```

If live QR lookups are used, the **build** also needs:

```text
LOOKUP_SECRET=<secret injected during build>
```

### 6.9 Suggested CI rollout order

1. Get `.maestro/` workspace + testIDs in place
2. Add one clean smoke flow locally
3. Add 5–10 P0 flows
4. Add GitHub Actions push-to-main smoke lane
5. Add TM-only regression flows
6. Add nightly/manual regression lane
7. Add scenario generator script last

---

## 7. Risks and mitigations

| Risk | What breaks | Mitigation |
|---|---|---|
| Screen copy changes | Text-based selectors fail | Use `testID`/`id` selectors as primary, text only as fallback |
| `testID` removed or duplicated | Flows become ambiguous or fail immediately | Maintain a selector catalog and add a PR checklist item for E2E-impacting selector changes |
| `placewell://scan/<id>` used for new-label setup | Category/freshness defaults disappear because metadata lookup returns `null` | Use signed HTTPS scan URLs or TM raw-scan fixture injection for new-label flows |
| Missing `LOOKUP_SECRET` in build | `lookupLabel()`/`lookupOrder()` return `null`, bulk import/new-label metadata paths degrade | Separate live-smoke vs test-mode lanes; make build env explicit |
| Live `placewell.app` network flakiness | CI failures unrelated to UI code | Keep live network only in a small smoke subset; run most regressions in TM fixture mode |
| Native gallery/camera UI changes by OS version | Photo flows become flaky | Use `addMedia` + OS-specific helper subflows; keep physical camera capture manual-only unless later stabilized |
| Native date pickers vary across Android/iOS | Best By / In Use Since flows become flaky | Use platform helper subflows; fall back to TM helper if needed |
| Gesture-heavy components (BiDirectionalSlider, drawers, sheets) | Swipe/tap timing flakiness | Prefer button/tap paths where available; add explicit testIDs; use `extendedWaitUntil` after animations |
| Destructive flows leak state into later tests | Random downstream failures | Tag destructive flows and always relaunch with `clearState: true` |
| Generated identity/profile data is random | Exact-text assertions fail | Assert presence via testIDs, not exact generated names |
| Settings file comments/tests are stale | Team may plan tests for non-existent Archived UI | Explicitly exclude Archived until it is reintroduced in live navigation/render |
| iOS physical-device constraints | Full parity automation is hard in Linux CI | Make Android emulator the official CI lane; keep iOS smoke local/manual until a Mac lane is worth the cost |

### Additional mitigation recommendations

1. **Add a test-mode raw-scan hook before writing negative scanner flows.** It unlocks the hardest error cases immediately.
2. **Keep smoke small.** Do not put gallery/date-picker/manual-heavy flows in every-push CI.
3. **Use one clean-state scenario per file.** Avoid mega-flows that create a long chain of failures.
4. **Tag every flow by dependency class.** Example: `live-network`, `test-mode`, `destructive`, `manual`.
5. **Treat Home / Settings / BulkImport seeds as reusable subflows.** This reduces the chance of diverging setup logic.

---

## Recommended phased rollout after approval

### Phase 0 — Instrumentation
- add shared `testID`s
- add `.maestro/` workspace skeleton
- add `selector-catalog.json`
- add `MAESTRO_TEST_MODE` plumbing design

### Phase 1 — P0 smoke suite
- first-launch Home
- existing storage scan → detail
- existing spice scan → recall
- order scan → bulk import review
- spice create flow
- storage create flow
- recall refill flow
- scan sound persistence
- invalid signature error

### Phase 2 — P1 regression suite
- custom rooms/zones
- full detail/recall edit/delete flows
- bulk import overrides + create variants
- Home filter/search/delete flows
- profile-edit flows
- deterministic error/fault-injection flows

### Phase 3 — Generator + CI polish
- scenario generator CLI
- scenario index file automation
- GitHub Actions smoke lane
- nightly/manual regression lane
- artifact/log improvements

---

## Final recommendation

The highest-value plan for PlaceWell is:

1. **Build the suite in `PlaceWellApp\.maestro\`**
2. **Use a hybrid data strategy**: small live smoke + larger `MAESTRO_TEST_MODE` regression suite
3. **Add stable `testID`s before writing flows**
4. **Start with Android emulator CI on every push to `main`**
5. **Treat raw scan injection, local seeding, and fault injection as first-class test infrastructure**, not one-off hacks

That path gives PlaceWell a realistic smoke lane, a deterministic regression lane, and a future-proof way to add new scenarios without hand-authoring YAML.
