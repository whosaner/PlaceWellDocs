# PlaceWell Unified Roadmap

Last updated: 2026-07-11

This roadmap consolidates the active app, infrastructure, operator, PDF, and business-track documentation for the full PlaceWell ecosystem.

---

## Completed ✅

### Product and app experience
- **Custom Modal Dialogs** — native alerts replaced with branded themed modals.
- **Bulk Import Flow** — order QR scanning imports many labels at once with defaults and per-label overrides.
- **Room Filter Drawer / Floating Panel** — labels can be browsed by Room → Zone from a drawer-style grouped view.
- **Archive All / Delete All** — bulk label-management actions added to the app.
- **Coming Soon Panel** — in-app preview sheet for upcoming capabilities.
- **Recently Scanned** — recent label access is tracked and surfaced on the home screen.
- **Scan Confirmation Sound** — successful scans play audio feedback in addition to haptics.
- **Scan-to-Recall (Spice Freshness)** — full freshness tracking for spice labels: Best By, In Use Since, burn rate, refill history, and LabelRecallScreen.
- **Inline Editing — LabelRecallScreen** — hero photo, Best By, and In Use Since editable directly without going through the wizard.
- **Inline Editing — LabelDetailScreen** — hero photo, contents, and notes editable inline for non-spice labels.
- **Save & Exit in Discard Dialog** — users can save mid-wizard without completing all steps.
- **HomeScreen Carousel Refresh** — always shows correct label and breadcrumb after edits; filter resets on return.
- **Pre-defined Room/Zone Dropdowns** — PlaceWellUI operator form uses linked dropdowns matching app defaultRooms.js.
- **Category Dropdown — PlaceWellUI** — per-row category is now a dropdown (Spice/Storage/Garage) with cascading location/zone defaults.

### Cross-project platform work
- **Per-Label Configuration & SKU-Driven Presets** — rich CSV-driven defaults flow across UI, QR Service, PDF generation, and app setup.
- **Order QR Bulk Load** — order QR prints on the sheet and bulk-creates labels in the app on first scan.
- **Firestore Order Record** — order-level metadata written atomically alongside qr_codes on every allocation.
- **Scan Analytics** — `camera_scan_count` (browser/camera) and `app_scan_count` (in-app scanner) tracked separately per label.
- **Firebase Analytics Wrapper** — 10 events instrumented with graceful Expo Go no-op; deferred Firebase activation to Expo SDK 55+.
- **Manifest Simplification** — counts/freshness removed; label names list kept for customer verification.
- **PDF Rendering Fixes** — crop mark removal, border updates, round-label spacing fixes, filename cleanup.
- **Font Weight Upgrade** — Josefin Sans moved from thin to regular for readability.

### Individual project milestones
- **QR Service** — deployed on Linode with allocation, lookup, order, and scan-redirect endpoints backed by Firestore.
- **PlaceWellUI** — operator form with per-label table, template selection, color picker, blanks handling, footer options, and linked room/zone/category dropdowns.
- **PlaceWellPdfGenerator** — 3-layer rendering architecture with label sheet + manifest output fully working.
- **PlaceWellAdmin** — local config manager with template/style/category editing and CSV CRUD support.
- **Mobile App Core** — wizard flow, QR lookup, search, room/zone management, archive/restore, device identity, and order import.
- **Documentation Consolidation** — all docs centralized at `C:\PlaceWell\Docs\` with architecture, deployment, design, features, setup, release, and roadmap sections.
- **Etsy Launch Plan** — full listing content, pricing, tags, photo shot list, and step-by-step checklist at `C:\PlaceWell\Docs\etsy\`.

### Production builds ✅ (2026-07-09)
- **iOS build** — EAS production build complete (v1.0.0 build 9), submitted to TestFlight.
- **Android build** — EAS production build complete (v1.0.0 build 2), AAB uploaded to Play Console internal testing.

---

## In Progress 🔄

- **TestFlight internal testing** — iOS build in TestFlight, awaiting internal test completion before App Store review submission.
- **Google Play internal testing** — Android AAB uploaded; add testers and install on Pixel device.

---

## Pre-Launch — Must-have before public release

1. **Privacy Policy** — host at placewell.app/privacy. Required by both App Store and Play Store. Add `privacyPolicyUrl` to `app.json`.
2. **App Store screenshots** — minimum 6.7" iPhone (1290×2796). Screens: Home carousel, Scanner, Label Setup, Recall. Upload in App Store Connect.
3. **Move secrets to EAS** — `hmacSecret` and `qrServiceToken` still in `app.json` extra. Run `eas secret:create` for both and update `qrService.js` to read from `Constants.expoConfig.extra`.
4. **Final production icon + splash** — placeholder assets in place. Replace with professional design before App Store submission. Use AI prompt at `C:\PlaceWell\Docs\etsy\PlaceWell_App_Icon_AI_Prompt.txt`.
5. **Print Labels — Real-World Test** — print every style/template combination and validate scan on real containers.
6. **Product photography for Etsy** — 10 shots listed in `C:\PlaceWell\Docs\etsy\Etsy_Launch_Plan.md`.
7. **Etsy listing on BeNiralu** — all content ready in Etsy_Launch_Plan.md; needs photos to go live.
8. **placewell.app Landing Page** — root landing page + `apple-app-site-association` + `assetlinks.json` for universal/app links.

---

## Deferred — Come back after Expo SDK 55+ upgrade

1. **Firebase Analytics activation** — `@react-native-firebase` conflicts with Expo SDK 54 New Architecture. Deferred to SDK 55+. Analytics wrapper already in place; zero app code changes needed. See `src/utils/analytics.js`.

---

## High Priority

1. **E2E Testing — Maestro CLI** — research complete, free stack recommended. Maestro CLI (Expo Go compatible) + AWS Device Farm free tier.
2. **Google Play Service Account** — set up for automated `eas submit --platform android` in future builds.
3. **iOS WidgetKit Extension** — native Swift widget for deep link `placewell://scan`.
4. **Etsy/Shopify Store Integration** — direct users from mobile app into storefront.

---

## Tabled (deferred by decision)

- **Autosave** — deferred, no timeline.
- **Drag-and-drop labels in BulkImport** — Approach A approved, execution deferred.

---

## Coming Soon (surfaced in the app)

- **Household Sharing** — shared homes and multi-person access.
- **Advanced Search** — richer search including future photo intelligence.
- **Expiry Reminders** — proactive freshness/date notifications.
- **Auto Replenishment** — future reorder and replenishment workflows.

---

## Medium Priority

1. **Household Sharing** — cloud sync, invite flows, role-based access.
2. **Expiration / Date Alerts** — badges, filters, and local notifications.
3. **Activity Log** — per-label history once shared households exist.
4. **Custom Fields** — user-defined metadata on labels.
5. **Export / Backup** — CSV or PDF export and restore.
6. **Voice Search** — speech-driven label search.
7. **AI-Powered Search** — search by text and photo understanding.
8. **Dark Mode** — complete alternate theme.
9. **Label Templates in App** — pre-built presets for common use cases.

---

## Low Priority

1. **Camera Enhancements** — multi-photo, flash, crop UX.
2. **Batch Operations** — multi-select move/archive/delete.
3. **Room/Zone Deletion — Bulk Reassignment** — guided cleanup when spaces still contain labels.

---

## Roadmap Feature

1. **Deferred Deep Linking** ⭐ PRIORITY — when a user scans a PlaceWell label or order QR without the app installed, they are shown a download page. After installing, they currently must scan the label again manually. Deferred deep linking would remember the original QR and route them directly to LabelSetup or BulkImport on first launch. Applies to both label QRs (`/s/`) and order QRs (`/o/`). Options under evaluation: Branch.io (free tier), app.smler.io, or a custom server-side continuation token. Firebase Dynamic Links is NOT an option (deprecated 2025). Decision pending research.

2. **AI Quantity Vision** — 3D jar scan with content level markers (measuring cup-style), periodic quantity tracking, low-stock notifications. High complexity — brainstorm phase.

3. **Brand Jar Image Catalog** — provide a curated catalog of jar/container brand images (e.g. Ball Mason, Weck, OXO, Costco, Penzeys) for users to pick from instead of using a photo or the default placeholder. App provides a sensible default based on label category; user can browse and select a matching brand image. Editable on:
   - **Label Setup Screen** (Step 1 — Photo step)
   - **Bulk Import Screen** (per-label override)
   - **LabelDetailScreen** (inline, replacing the photo tap)
   - **LabelRecallScreen** (inline, replacing the hero photo tap)
   Requires: building and hosting a jar image catalog (CDN or bundled assets), catalog browser UI component, per-label `brandImageId` field in storage schema.

4. **Multi-Photo Labels (up to 3 images)** — allow users to add up to 3 photos per label instead of the current single photo. Useful for showing the jar from multiple angles, showing the contents, or showing the label on the shelf. The hero card would show the first photo with a swipeable carousel for additional photos. Affects: LabelFormScreen (Photo step), LabelDetailScreen, LabelRecallScreen (hero card), and local storage schema (`photoUris: string[]` replacing `photoUri: string`). Max 3 photos to keep storage and performance manageable.

---

## Future / Premium Tier

1. **NFC Labels** — premium hardware labels for tap-to-open behavior.

---

## Post-Launch

### V1 post-launch
- **New Label Categories** — expand beyond spice into garage, kids, laundry, office, bathroom.
- **Shopify Store for PlaceWell** — dedicated storefront and direct customer relationship.

### V2 post-launch
- **Auto Replenishment — AI Inventory Scanner** — AI-assisted scanning of real products and packaging.

---

## Longer-Term Business Growth

1. **Sell Physical Labels Directly** — fulfillment around pre-printed shipped label packs.
2. **New Home-Owner Kit** — curated boxed sets for move-in gifting and builder partnerships.

