# PlaceWell Unified Roadmap

Last updated: 2026-08-09

**Single source of truth** for the PlaceWell ecosystem (app, QR service, UI, PDF generator, admin, business). Everything — launch status, shipped work, the prioritized backlog (the former separate todo list is folded in here), and detailed feature notes — lives in **this one file**. Nothing scattered.

To re-prioritize: edit the **Priority** column in the Master Priority List. Allowed values are your call — suggested scale: `High` · `Medium` · `Low` · `Deferred` · `Future` · `Tabled`. The values below are pre-filled from the prior roadmap buckets; change them freely.

---

## Launch Status 🚀

- **Google Play (Android)** — ✅ **LIVE on Production** (version code **15**, v1.0.0) — approved & published **2026-08-09**; public listing at `play.google.com/store/apps/details?id=com.placewell.app`. Cleared two rejections en route: invalid demo QR (corrected to the `-84A3` sign-in URL) and the foreground-service permission declaration (removed via `android.blockedPermissions`).
- **App Store (iOS)** — build **21** **REJECTED 2026-08-10** under **Guideline 5.1.1(iv)** (camera pre-permission screen: the "Allow Camera Access" CTA + a "Not now" delay button). **Fixed on `main` (commit `bbb7a09`):** button renamed to "Continue" (always proceeds to the OS request), "Not now" replaced with a top-left close (✕), and an "Open Settings" fallback when previously denied. **Next: rebuild iOS (build 23, bundles the camera fix + an intermittent scan-sound fix `cf56fd4` [retained audio player, respects the silent switch]) + resubmit + reply to the reviewer.** (The earlier EU DSA trader-status hold was cleared 2026-08-06.)
- Auto-release on approval (Play: managed publishing off — already auto-published; App Store: automatic release).
- Store-listing assets, App-Review demo QR codes, and screenshots live in `Docs/release/store-listing/`.

---

## Shipped ✅ (condensed)

Completed work, grouped. Kept brief on purpose — this roadmap is forward-looking.

- **Launch (App Store + Play)** — production submissions of both apps (v1.0.0); paste-ready store listings (App Store + Play); **App Privacy / Data Safety = "Data Not Collected"**; content ratings (4+/Everyone), target audience 18+, sign-in / app-access + export-compliance declarations; **App Review demo access** via production-signed deterministic QR fixtures + combined review sheet (`Docs/scripts/seed-test-fixtures.ps1`); App Store screenshots (1290×2796); privacy policy live (`placewell.app/privacy`); **Google Play service-account permission fixed** (automated `eas submit --platform android` works); root landing page + AASA/assetlinks deployed; **`support@placewell.app` inbound email forwarding live** (Namecheap free forwarding → niralu.53@gmail.com — makes the privacy-policy / store contact address deliverable).
- **App experience** — 4-step label wizard; QR scan → lookup → route (LabelSetup / LabelDetail / LabelRecall / BulkImport); bulk import from Order QR (global + per-label room/zone, add-new inline); inline editing on Recall (photo, Best By, In Use Since) and Detail (photo, contents, notes); spice freshness (Best By, In Use Since, refill history); room/zone filter drawer; search; home carousel with correct-label refresh + filter reset; custom branded modals; scan sound + haptics; Coming Soon panel; recently scanned. Plus the iOS photo-capture round: instant PHPicker, native ActionSheet chooser, deterministic retake, photo-card sizing.
- **Platform** — QR Service on Linode (allocate / lookup / order / scan) backed by Firestore + HMAC-signed URLs; per-label SKU-driven presets across UI → QR → PDF → app; Order QR bulk load + Firestore order record; split scan analytics (`camera_scan_count` / `app_scan_count`, both non-blocking); **scan landing page (7 server-rendered states, App Links / Universal Links)**; `assetlinks.json` (incl. Play signing cert) + `apple-app-site-association` deployed.
- **Build / ops** — iOS + Android production builds via EAS; **secrets split & moved to EAS** (ALLOCATE vs read-only LOOKUP; HMAC + LOOKUP as EAS secrets, `app.config.js` reads at build time); **production PW monogram icon set** (iOS, Android adaptive w/ gradient background, splash); **cold-start deep-link fix** (leading-slash App Link path routing); Maestro E2E scaffolding (Phase 0 testIDs + Phase 1 smoke suite + scenario generator).
- **Docs / tooling** — consolidated `Docs/` repo; `DOC_CATALOG.md`; `Project_Checkout_Guide.md`; `deploy.ps1` + `seed-test-fixtures.ps1` in version control (`Docs/scripts/`); Etsy launch plan.

---

## 🎯 Next Up (agreed batch, in order — re-prioritized 2026-08-09)

The active batch, sequenced. Full rows are in the Master Priority List (Priority = `Next 1..4`); scope in Feature Details.

1. **#10 Real jar photos (default image)** — quick visual win; one-component swap in `CategoryPlaceholder`, keyed by existing category/SKU. Low–Med, SDK-agnostic. **Blocked on user-provided jar images.** Ship first.
2. **#12 Guided jar capture (quantity fill markers)** — fully specced (`Docs/specs/PlaceWell_GuidedCapture_Spec.md`); manual fill scale, **no AI**; square-normalizes photos app-wide. Re-adds `expo-image-manipulator`. Medium.
3. **#13 Household Sharing** — biggest lift (local-first → cloud accounts/sync, opt-in; keep local-first default). ⚠️ changes privacy declarations. High effort.
4. **#9 Firebase Analytics** — batch with the **Expo SDK 57 upgrade** (do the upgrade first); plan: `Docs/roadmap/SDK57_Upgrade_And_Analytics_Plan.md`. Medium.

**Deferred from this batch:** #11 Multi-photo (up to 3) — extends #12's capture; will ride along with / after #12 rather than as its own slot.

**Sequencing / timing notes:**
- ⚠️ **iOS build 21 is still in store review** — per our workflow, hold app-code changes (#10/#12) until it's approved/live to avoid a mid-review rebuild.
- **#10 needs your jar images** before coding can finish.
- **#9 requires the SDK 57 upgrade** (3-SDK jump) — do that first; #9 is placed last deliberately.
- ⚠️ **#9 and #13 both require updating App Store + Play privacy declarations** (from "Data Not Collected").

---

## Master Priority List

Everything open, in one table (todos + roadmap, de-duplicated). ⭐ = deeper write-up in **Feature Details** below.

| # | Item | Area | Priority | Notes |
|---|---|---|---|---|
| 1 | Print labels — real-world test (every style × template on real containers) | Business | High | Validate physical product + scan on real jars/bins |
| 2 | Product photography for Etsy (10 shots) | Business | High | See `Docs/etsy/Etsy_Launch_Plan.md` |
| 3 | Etsy listing go-live (content ready) | Business | High | Blocked on #2 photos |
| 5 | Deferred Deep Linking ⭐ | App | High | scan→install→route straight to LabelSetup/BulkImport (today: re-scan needed) |
| 6 | Maestro E2E — Phase 2 | Testing | High | regression suite + `MAESTRO_TEST_MODE` fault injection + GitHub Actions CI |
| 7 | iOS WidgetKit one-tap scan widget | App | High | native Swift `placewell://scan` |
| 8 | Etsy/Shopify in-app storefront link | App/Business | High | in-app link into storefront |
| 9 | Firebase Analytics activation ⭐ | Ops | **Next 4** | Batch with Expo SDK 57 upgrade — **plan: `Docs/roadmap/SDK57_Upgrade_And_Analytics_Plan.md`**. + google-services.json (Android); **must update store privacy on activation** |
| 10 | Real jar photos as default image ⭐ | App | **Next 1** | **Drop-in swap** of the 3 transparent-PNG placeholders (`spiceJar`, `storageBox`, `genericContainer`) for user-provided proper jar photos — same PNG + name-overlay convention, **one image per category** (`labelSku` unused). Update each `BASE_WIDTH/HEIGHT` + overlay `top %` to match the new art; remove dead `assets/spice_*.svg`; refresh stale `Adding_A_Category.md` (still describes the old SVG approach). Blocked on user-provided images; hold code changes until iOS is out of review. Low effort. |
| 11 | Multi-Photo Labels (up to 3) ⭐ | App | Medium | hero + swipeable carousel; `photoUris: string[]`; extends #12's capture — **deferred from the Next batch 2026-08-09** (will ride along with / after #12) |
| 12 | Guided jar capture — quantity fill markers ⭐ | App | **Next 2** | Manual fill scale (Full/¾/½/¼/Low) via guided camera + square-normalized image. **No AI/OCR.** Spec: `Docs/specs/PlaceWell_GuidedCapture_Spec.md` |
| 13 | Household Sharing | App | **Next 3** | cloud sync, invite codes, roles (opt-in — keep local-first default); **changes privacy declarations**; shown in Coming Soon panel |
| 14 | Expiry / Date Reminders | App | Medium | badges, filters, local notifications; shown in Coming Soon panel |
| 15 | Activity Log (per-label history) | App | Medium | needs shared households |
| 16 | Custom Fields (user-defined metadata) | App | Medium | |
| 17 | Export / Backup (CSV or PDF) | App | Medium | |
| 18 | Voice Search | App | Medium | |
| 19 | AI-Powered / Advanced Search (text + photo) | App | Medium | shown in Coming Soon panel |
| 20 | Dark Mode | App | Medium | app is light-only today (`userInterfaceStyle: light`) |
| 21 | In-app Label Templates (presets) | App | Medium | |
| 22 | Order tracking service (orderId, numLabels, sku, status) | QR service | Medium | |
| 23 | Settings — user profile display | App | Medium | |
| 24 | Placeholder images — StorageBox & Generic | App | Medium | waiting on assets |
| 25 | Admin — CSV table editor frontend | Admin | Medium | |
| 26 | Admin — edit category | Admin | Medium | |
| 27 | Admin v2 — file uploads (fonts, CSVs, placeholder images) | Admin | Medium | |
| 28 | Camera enhancements (multi-photo capture, flash, crop) | App | Low | |
| 29 | Batch operations (multi-select move/archive/delete) | App | Low | |
| 30 | Quantity tracking (+/- counter) | App | Low | |
| 31 | Room/Zone deletion + bulk reassignment | App | Low | when spaces still contain labels |
| 32 | Autosave | App | Tabled | no timeline |
| 33 | Drag-and-drop labels in BulkImport | App | Tabled | Approach A approved, execution deferred |
| 34 | NFC Labels (tap-to-open hardware) | Business | Future | premium |
| 35 | Auto Replenishment — AI inventory scanner | App | Future | V2; shown in Coming Soon panel |
| 36 | New label categories (garage, kids, laundry, office, bathroom) | App | Future | V1 post-launch |
| 37 | Shopify storefront for PlaceWell | Business | Future | dedicated storefront |
| 38 | Sell physical labels directly (pre-printed packs) | Business | Future | |
| 39 | New Home-Owner Kit (boxed gifting sets) | Business | Future | move-in gifting / builder partnerships |
| 40 | Strip unused `SYSTEM_ALERT_WINDOW` permission (Android) | Ops | Low | React Native pulls "display over other apps" into the release manifest; PlaceWell doesn't use overlays. Remove via `android.blockedPermissions` (same mechanism as the foreground-service fix). Verify in the AAB after rebuild. |
| 41 | Firestore backups + disaster recovery | Ops | High | Real label IDs are random (`secrets.choice`) and live ONLY in Firestore — deleting `qr_codes` with no backup permanently orphans every not-yet-activated physical label (camera scans return "not a PlaceWell code"). Enable PITR + daily/weekly scheduled backups + `--delete-protection` on `placewell-prod-60ef3` `(default)`; retain allocation data/PDFs as an independent second copy. Runbook: `Docs/deployment/Firestore_Backup_And_DR_Runbook.md` |
| 42 | Per-label remote stock images ⭐ | App/Ops | High | Serve the existing 78 product renders through a static, content-hashed manifest on **Firebase Hosting**, keyed by server-owned `image_key` + `labelSku` + quantity and cached in app-owned storage. Five PNG fallbacks (3 SKU + 2 category) with generated geometry have landed; remote export/hosting, key rename/backfill, enrichment, cache service, and shared `LabelArtwork` migration remain. Authoritative plan: `Docs/roadmap/Stock_Image_Implementation_Plan.md` |

---

## Post-launch reminder ⚠️

When **#9 Firebase Analytics** is activated, update BOTH stores' privacy declarations from "Data Not Collected" to declare the analytics data (App activity, Diagnostics, Device IDs) **before** shipping that build. Flagged in `Docs/release/store-listing/AppStore_PasteReady.txt` and `Play_Data_Safety_AnswerSheet.txt`.

---

## Feature Details ⭐

### #5 — Deferred Deep Linking
When a user scans a label (`/s/`) or order QR (`/o/`) without the app, they see the download page; after install they must scan again. Deferred deep linking would route them directly on first launch.

- **Recommended: app.smler.io (Smler)** — purpose-built Firebase Dynamic Links replacement. Free tier 10k clicks + 25k installs/mo; RN SDK (TS) confirmed in docs; flat pricing ($0 / $129 mo). ⚠️ Verify npm package + Expo managed compatibility after signup (test in prebuild first).
- **Fallback: Branch.io** — mature RN SDK, community Expo plugin (Branch disclaims support); enterprise MMP, $199–499+/mo.
- **DIY (no vendor):** Android Install Referrer + iOS Universal Links + clipboard (~2–3 days). Firebase Dynamic Links is NOT an option (deprecated Aug 2025).
- **Steps:** sign up → verify SDK → embed Smler link in `/s/` + `/o/` fallback pages → handle `onDeepLink` on first launch → route to LabelSetup/BulkImport → test scan→install→correct screen on both platforms.

### #9 — Firebase Analytics activation
`@react-native-firebase` conflicts with Expo SDK 54 New Architecture + Swift AppDelegate. Wrapper already in place (`src/utils/analytics.js`); **zero app code changes** needed on activation.
- **Option 1:** upgrade to Expo SDK 57 (current stable) and re-add `@react-native-firebase/app` + `analytics` (conflict fixed from SDK 55+).
- **Option 2:** replace with `expo-firebase-analytics` (Expo ecosystem, no AppDelegate changes).
- **Steps:** npm install the package → update `app.json` plugins → add `google-services.json` (Android) + upload `GoogleService-Info.plist` to EAS again → **update store privacy declarations**.

### #10 — Real jar photos as default image
Replace the default SVG jar/container illustrations with **real jar photos**, keyed by the existing `category` / `labelSku` / `placeholder` logic (the same mechanism used today to pick an illustration by size). Central change in `src/components/CategoryPlaceholder.js` (used by Home, cards, LabelDetail, LabelRecall, LabelForm) — swap the SVG render for an `Image`, plus add the photo assets. **Low–Med effort; the selection plumbing already exists.** NOT a hosted brand catalog / picker UI (that heavier idea is dropped for now). Asset prep: consistent jar photos on a clean Porcelain-Sky-friendly background, one per SKU size.

### #11 — Multi-Photo Labels (up to 3)
Allow up to 3 photos per label (angles, contents, on-shelf). Hero shows first photo w/ swipeable carousel. Affects LabelFormScreen, LabelDetail, LabelRecall, and storage schema (`photoUris: string[]`).

### #12 — Guided jar capture (quantity fill markers)
**Full spec + mockup: `Docs/specs/PlaceWell_GuidedCapture_Spec.md` + `placewell-guided-capture-mockup.html`.** A guided camera screen that replaces the raw photo picker for jars: a shape-agnostic staging zone frames the jar, the user taps an ordinal **fill level** (Full / ¾ / ½ / ¼ / Low) styled as a measuring scale, and the capture is center-cropped to a fixed **1080×1080 square** (fixes tile mismatch app-wide). **No computer vision, OCR, or 3D — every value is user-set.** Tech: `expo-camera` (already used) + `expo-image-manipulator` (⚠️ removed earlier — re-add for the square crop); no new native deps. Data: `imageUri`, `fillLevel` (enum), `capturedAt`. **3 open design decisions** in spec §9 (default fill, fifth-bucket wording, when the level is set). The earlier "AI 3D quantity vision" moonshot (auto-detected levels, consumption-rate notifications) is deferred separately — this specced **manual** version is v1.

### #42 — Per-label remote stock images
Evolve #10's placeholder art into a **remote, per-label product catalog** (later
per-quantity-level), driven by the owner's constraint: **add a new catalog item without an
app-store release.**
- **Verified scale:** 26 catalog items × 3 SKUs = **78 rendered masters**. Quantity expansion remains a later phase.
- **Architecture:** static manifest + immutable content-hashed **WebP q95** on Firebase Hosting; ordinary HTTPS fetch; app-owned `documentDirectory` cache; no Firebase SDK or per-image API.
- **Identity:** server-owned `image_key`, established `label_sku`, and `imageKey|labelSku|quantity` semantic lookup. The app never derives an art key from editable text.
- **Fallback:** five PNGs ship in the app — 3 SKU jars plus storage-box and generic-container — with generated geometry and offline label-name overlay.
- **App seam:** one `LabelArtwork` component owns user photo → cached/downloaded stock → bundled fallback across all surfaces.
- **Current status:** the five-asset fallback foundation landed in `PlaceWellApp` commit `745581d`; remote export/hosting, server rename/backfill, cache service, enrichment, and full `LabelArtwork` migration remain.
- **Authoritative implementation spec: `Docs/roadmap/Stock_Image_Implementation_Plan.md`** (answers lookup/offline/caching/fallback/versioning/consistency; Phase 0 is a blocking server-side key reconciliation).
- **Original research (scale math, URL/manifest schema, perf/memory, citations):** `Docs/roadmap/Jar_Image_Strategy_Research.md`.

---

## Related docs

- **SDK 57 + analytics plan: `Docs/roadmap/SDK57_Upgrade_And_Analytics_Plan.md`** (#9)
- **Stock jar image implementation plan (authoritative): `Docs/roadmap/Stock_Image_Implementation_Plan.md`** (#42)
- Jar image strategy research (partially superseded): `Docs/roadmap/Jar_Image_Strategy_Research.md` (#42, extends #10/#12)
- Guided jar capture spec: `Docs/specs/PlaceWell_GuidedCapture_Spec.md` + mockup (#12)
- Build & submit: `Docs/release/iOS_Android_Build_Guide.md`, `Release_Validation_Checklist.md`, `PlaceWellApp/VERIFICATION_CHECKLIST.txt`
- Store listing + review assets: `Docs/release/store-listing/`
- E2E testing: `Docs/maestro/`, `PlaceWellApp/scripts/maestro/README.md`
- Business: `Docs/etsy/Etsy_Launch_Plan.md`
- Architecture: `Docs/architecture/System_Overview.md`
