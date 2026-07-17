# PlaceWell Unified Roadmap

Last updated: 2026-07-17

**Single source of truth** for the PlaceWell ecosystem (app, QR service, UI, PDF generator, admin, business). This file consolidates the former `PlaceWellApp/docs/roadmap/ROADMAP.md`, which has been removed.

---

## Shipped ✅ (condensed)

Completed work, grouped. Kept brief on purpose — this roadmap is forward-looking.

- **App experience** — 4-step label wizard; QR scan → lookup → route (LabelSetup / LabelDetail / LabelRecall / BulkImport); bulk import from Order QR (global + per-label room/zone, add-new inline); inline editing on Recall (photo, Best By, In Use Since) and Detail (photo, contents, notes); spice freshness (Best By, In Use Since, refill history); room/zone filter drawer; search; home carousel with correct-label refresh + filter reset; custom branded modals; scan sound + haptics; Coming Soon panel; recently scanned.
- **Platform** — QR Service on Linode (allocate / lookup / order / scan) backed by Firestore + HMAC-signed URLs; per-label SKU-driven presets across UI → QR → PDF → app; Order QR bulk load + Firestore order record; split scan analytics (`camera_scan_count` / `app_scan_count`, both non-blocking); **scan landing page (7 server-rendered states, App Links / Universal Links)**; `assetlinks.json` (incl. Play signing cert) + `apple-app-site-association` deployed.
- **Build / ops** — iOS + Android production builds via EAS; **secrets split & moved to EAS** (ALLOCATE vs read-only LOOKUP; HMAC + LOOKUP as EAS secrets, `app.config.js` reads at build time); **production PW monogram icon set** (iOS, Android adaptive w/ gradient background, splash); **cold-start deep-link fix** (leading-slash App Link path routing); Maestro E2E scaffolding (Phase 0 testIDs + Phase 1 smoke suite + scenario generator).
- **Docs / tooling** — consolidated `Docs/` repo; `DOC_CATALOG.md`; `Project_Checkout_Guide.md`; `deploy.ps1` moved into version control (`Docs/deployment/`); Etsy launch plan.

---

## In Progress 🔄

- **Latest build verification** — iOS (TestFlight) + Android (Play internal testing) of the build containing the cold-start deep-link fix and new icons. Verify with `PlaceWellApp/VERIFICATION_CHECKLIST.txt` (focus: Section B cold-start camera scan).

---

## Pre-Launch — must-have before public release

1. **Privacy Policy** — host at `placewell.app/privacy`; add `privacyPolicyUrl` to `app.json`. Required by App Store + Play Store.
2. **App Store screenshots** — min 6.7" iPhone (1290×2796): Home carousel, Scanner, Label Setup, Recall.
3. **Play Store listing** — create default store listing (name, short/full description, 512×512 icon at `PlaceWellApp/assets/playstore-icon.png`, 1024×500 feature graphic, ≥2 phone screenshots). Required for production track (not internal testing).
4. **Google Play service account** — finish permission grant so automated `eas submit --platform android` works (currently falls back to manual AAB upload).
5. **placewell.app root landing page** — public marketing page at the domain root (AASA + assetlinks already deployed).
6. **Print labels — real-world test** — print every style × template and validate scan on real containers.
7. **Product photography for Etsy** — 10 shots (see `Docs/etsy/Etsy_Launch_Plan.md`).
8. **Etsy listing on BeNiralu** — content ready; needs photos to go live.

---

## High Priority

1. **Deferred Deep Linking** ⭐ — after install from a scan, remember the original QR and route straight to LabelSetup / BulkImport (today the user must re-scan). See detailed options below.
2. **Maestro E2E — Phase 2** — Phase 0 (testIDs) + Phase 1 (smoke) shipped. Remaining: regression suite, `MAESTRO_TEST_MODE` fault-injection hooks, GitHub Actions CI lane. See `Docs/maestro/`.
3. **iOS WidgetKit Extension** — native Swift one-tap scan widget (`placewell://scan`).
4. **Etsy/Shopify store integration** — in-app link into storefront.

---

## Deferred (revisit after Expo SDK 55+ upgrade)

- **Firebase Analytics activation** — `@react-native-firebase` conflicts with Expo SDK 54 New Architecture. Wrapper already in place (`src/utils/analytics.js`); zero app code changes needed on activation.

---

## Roadmap Features (detailed, forward-looking)

### 1. Deferred Deep Linking ⭐ PRIORITY
When a user scans a label (`/s/`) or order QR (`/o/`) without the app, they see the download page; after install they must scan again. Deferred deep linking would route them directly on first launch.

- **Recommended: app.smler.io (Smler)** — purpose-built Firebase Dynamic Links replacement. Free tier 10k clicks + 25k installs/mo; RN SDK (TS) confirmed in docs; flat pricing ($0 / $129 mo). ⚠️ Verify npm package + Expo managed compatibility after signup (test in prebuild first).
- **Fallback: Branch.io** — mature RN SDK, community Expo plugin (Branch disclaims support); enterprise MMP, $199–499+/mo.
- **DIY (no vendor):** Android Install Referrer + iOS Universal Links + clipboard (~2–3 days). Firebase Dynamic Links is NOT an option (deprecated Aug 2025).
- **Steps:** sign up → verify SDK → embed Smler link in `/s/` + `/o/` fallback pages → handle `onDeepLink` on first launch → route to LabelSetup/BulkImport → test scan→install→correct screen on both platforms.

### 2. AI Quantity Vision
3D jar scan with content-level markers (measuring-cup style), periodic quantity tracking, low-stock notifications. High complexity — brainstorm phase.

### 3. Brand Jar Image Catalog
Curated catalog of jar/container brand images (Ball Mason, Weck, OXO, Penzeys, etc.) to pick from instead of a photo/default. Editable on Label Setup (photo step), Bulk Import (per-label), LabelDetail, LabelRecall. Requires: hosted catalog (CDN/bundled), browser UI, `brandImageId` on the storage schema.

### 4. Multi-Photo Labels (up to 3)
Allow up to 3 photos per label (angles, contents, on-shelf). Hero shows first photo w/ swipeable carousel. Affects LabelFormScreen, LabelDetail, LabelRecall, and storage schema (`photoUris: string[]`).

---

## Coming Soon (surfaced in the app)

- **Household Sharing** — shared homes, multi-person access.
- **Advanced Search** — richer search incl. future photo intelligence.
- **Expiry Reminders** — proactive freshness/date notifications.
- **Auto Replenishment** — reorder when items run low.

---

## Medium Priority

1. Household Sharing (cloud sync, invite codes, roles)
2. Expiration / Date Alerts (badges, filters, local notifications)
3. Activity Log (per-label history; needs shared households)
4. Custom Fields (user-defined metadata)
5. Export / Backup (CSV or PDF)
6. Voice Search
7. AI-Powered Search (text + photo understanding)
8. Dark Mode
9. Label Templates in-app (pre-built presets)
10. Order Service — order tracking (orderId, numLabels, sku, status)
11. Settings — user profile display
12. Placeholder images — StorageBox & Generic (waiting on assets)

### Admin (PlaceWellAdmin)
- CSV table editor frontend
- Edit category
- Admin v2: file uploads (fonts, CSVs, placeholder images)

---

## Low Priority

1. Camera enhancements (multi-photo capture, flash, crop)
2. Batch operations (multi-select move/archive/delete)
3. Quantity tracking (+/- counter)
4. Room/Zone deletion — bulk reassignment when spaces still contain labels

---

## Tabled (deferred by decision)

- **Autosave** — no timeline.
- **Drag-and-drop labels in BulkImport** — Approach A approved, execution deferred.

---

## Future / Premium & Business Growth

- **NFC Labels** — premium tap-to-open hardware labels.
- **Auto Replenishment — AI Inventory Scanner** — AI scanning of real products/packaging (V2 post-launch).
- **New label categories** — garage, kids, laundry, office, bathroom (V1 post-launch).
- **Shopify store for PlaceWell** — dedicated storefront.
- **Sell physical labels directly** — pre-printed shipped packs.
- **New Home-Owner Kit** — curated boxed sets for move-in gifting / builder partnerships.
