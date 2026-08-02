# PlaceWell Unified Roadmap

Last updated: 2026-07-31

**Single source of truth** for the PlaceWell ecosystem (app, QR service, UI, PDF generator, admin, business). Everything — launch status, shipped work, the prioritized backlog (the former separate todo list is folded in here), and detailed feature notes — lives in **this one file**. Nothing scattered.

To re-prioritize: edit the **Priority** column in the Master Priority List. Allowed values are your call — suggested scale: `High` · `Medium` · `Low` · `Deferred` · `Future` · `Tabled`. The values below are pre-filled from the prior roadmap buckets; change them freely.

---

## Launch Status 🚀

- **App Store (iOS)** — build **21** (v1.0.0) submitted; **Waiting for Review** (2026-07-30).
- **Google Play (Android)** — version code **14** (v1.0.0) submitted to the production track; **in review**.
- Both auto-release on approval (Play: managed publishing off; App Store: automatic release).
- Store-listing assets, App-Review demo QR codes, and screenshots live in `Docs/release/store-listing/`.

---

## Shipped ✅ (condensed)

Completed work, grouped. Kept brief on purpose — this roadmap is forward-looking.

- **Launch (App Store + Play)** — production submissions of both apps (v1.0.0); paste-ready store listings (App Store + Play); **App Privacy / Data Safety = "Data Not Collected"**; content ratings (4+/Everyone), target audience 18+, sign-in / app-access + export-compliance declarations; **App Review demo access** via production-signed deterministic QR fixtures + combined review sheet (`Docs/scripts/seed-test-fixtures.ps1`); App Store screenshots (1290×2796); privacy policy live (`placewell.app/privacy`); **Google Play service-account permission fixed** (automated `eas submit --platform android` works); root landing page + AASA/assetlinks deployed.
- **App experience** — 4-step label wizard; QR scan → lookup → route (LabelSetup / LabelDetail / LabelRecall / BulkImport); bulk import from Order QR (global + per-label room/zone, add-new inline); inline editing on Recall (photo, Best By, In Use Since) and Detail (photo, contents, notes); spice freshness (Best By, In Use Since, refill history); room/zone filter drawer; search; home carousel with correct-label refresh + filter reset; custom branded modals; scan sound + haptics; Coming Soon panel; recently scanned. Plus the iOS photo-capture round: instant PHPicker, native ActionSheet chooser, deterministic retake, photo-card sizing.
- **Platform** — QR Service on Linode (allocate / lookup / order / scan) backed by Firestore + HMAC-signed URLs; per-label SKU-driven presets across UI → QR → PDF → app; Order QR bulk load + Firestore order record; split scan analytics (`camera_scan_count` / `app_scan_count`, both non-blocking); **scan landing page (7 server-rendered states, App Links / Universal Links)**; `assetlinks.json` (incl. Play signing cert) + `apple-app-site-association` deployed.
- **Build / ops** — iOS + Android production builds via EAS; **secrets split & moved to EAS** (ALLOCATE vs read-only LOOKUP; HMAC + LOOKUP as EAS secrets, `app.config.js` reads at build time); **production PW monogram icon set** (iOS, Android adaptive w/ gradient background, splash); **cold-start deep-link fix** (leading-slash App Link path routing); Maestro E2E scaffolding (Phase 0 testIDs + Phase 1 smoke suite + scenario generator).
- **Docs / tooling** — consolidated `Docs/` repo; `DOC_CATALOG.md`; `Project_Checkout_Guide.md`; `deploy.ps1` + `seed-test-fixtures.ps1` in version control (`Docs/scripts/`); Etsy launch plan.

---

## 🎯 Next Up (agreed batch, in order — set 2026-08-02)

The active batch, sequenced. Full rows are in the Master Priority List (Priority = `Next 1..5`); scope in Feature Details.

1. **#10 Real jar photos (default image)** — quick visual win; one-component swap in `CategoryPlaceholder`, keyed by existing category/SKU. Low–Med, SDK-agnostic — ship first.
2. **#12 Guided jar capture (quantity fill markers)** — fully specced (`Docs/specs/PlaceWell_GuidedCapture_Spec.md`); manual fill scale, **no AI**; square-normalizes photos app-wide. Medium.
3. **#11 Multi-photo (up to 3)** — extends the photo system from #12. Medium.
4. **#9 Firebase Analytics** — batch with the **Expo SDK 55 upgrade**; plan: `Docs/roadmap/SDK55_Upgrade_And_Analytics_Plan.md`. Medium.
5. **#13 Home sharing** — biggest lift (local-first → cloud accounts, opt-in). High.

**Sequencing note:** the SDK 55 upgrade (needed for #9) is disruptive — do it before #10–12 (build on the new SDK) OR ship #10 first (SDK-agnostic) then upgrade. ⚠️ **#9 and #13 both require updating App Store + Play privacy declarations** (from "Data Not Collected").

---

## Master Priority List

Everything open, in one table (todos + roadmap, de-duplicated). ⭐ = deeper write-up in **Feature Details** below.

| # | Item | Area | Priority | Notes |
|---|---|---|---|---|
| 1 | Print labels — real-world test (every style × template on real containers) | Business | High | Validate physical product + scan on real jars/bins |
| 2 | Product photography for Etsy (10 shots) | Business | High | See `Docs/etsy/Etsy_Launch_Plan.md` |
| 3 | Etsy listing go-live (content ready) | Business | High | Blocked on #2 photos |
| 4 | `support@placewell.app` email forwarding | Ops | Low | Namecheap forward → niralu.53@gmail.com (~2 min); makes the address in the privacy policy deliver |
| 5 | Deferred Deep Linking ⭐ | App | High | scan→install→route straight to LabelSetup/BulkImport (today: re-scan needed) |
| 6 | Maestro E2E — Phase 2 | Testing | High | regression suite + `MAESTRO_TEST_MODE` fault injection + GitHub Actions CI |
| 7 | iOS WidgetKit one-tap scan widget | App | High | native Swift `placewell://scan` |
| 8 | Etsy/Shopify in-app storefront link | App/Business | High | in-app link into storefront |
| 9 | Firebase Analytics activation ⭐ | Ops | **Next 4** | Batch with Expo SDK 55 upgrade — **plan: `Docs/roadmap/SDK55_Upgrade_And_Analytics_Plan.md`**. + google-services.json (Android); **must update store privacy on activation** |
| 10 | Real jar photos as default image ⭐ | App | **Next 1** | Swap default SVG placeholder for real jar photos in the central `CategoryPlaceholder`, keyed by existing category/SKU. Low–Med. NOT a hosted catalog/picker. |
| 11 | Multi-Photo Labels (up to 3) ⭐ | App | **Next 3** | hero + swipeable carousel; `photoUris: string[]`; extends #12's capture |
| 12 | Guided jar capture — quantity fill markers ⭐ | App | **Next 2** | Manual fill scale (Full/¾/½/¼/Low) via guided camera + square-normalized image. **No AI/OCR.** Spec: `Docs/specs/PlaceWell_GuidedCapture_Spec.md` |
| 13 | Household Sharing | App | **Next 5** | cloud sync, invite codes, roles (opt-in — keep local-first default); **changes privacy declarations**; shown in Coming Soon panel |
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
- **Option 1:** upgrade to Expo SDK 55+ and re-add `@react-native-firebase/app` + `analytics` (conflict fixed there).
- **Option 2:** replace with `expo-firebase-analytics` (Expo ecosystem, no AppDelegate changes).
- **Steps:** npm install the package → update `app.json` plugins → add `google-services.json` (Android) + upload `GoogleService-Info.plist` to EAS again → **update store privacy declarations**.

### #10 — Real jar photos as default image
Replace the default SVG jar/container illustrations with **real jar photos**, keyed by the existing `category` / `labelSku` / `placeholder` logic (the same mechanism used today to pick an illustration by size). Central change in `src/components/CategoryPlaceholder.js` (used by Home, cards, LabelDetail, LabelRecall, LabelForm) — swap the SVG render for an `Image`, plus add the photo assets. **Low–Med effort; the selection plumbing already exists.** NOT a hosted brand catalog / picker UI (that heavier idea is dropped for now). Asset prep: consistent jar photos on a clean Porcelain-Sky-friendly background, one per SKU size.

### #11 — Multi-Photo Labels (up to 3)
Allow up to 3 photos per label (angles, contents, on-shelf). Hero shows first photo w/ swipeable carousel. Affects LabelFormScreen, LabelDetail, LabelRecall, and storage schema (`photoUris: string[]`).

### #12 — Guided jar capture (quantity fill markers)
**Full spec + mockup: `Docs/specs/PlaceWell_GuidedCapture_Spec.md` + `placewell-guided-capture-mockup.html`.** A guided camera screen that replaces the raw photo picker for jars: a shape-agnostic staging zone frames the jar, the user taps an ordinal **fill level** (Full / ¾ / ½ / ¼ / Low) styled as a measuring scale, and the capture is center-cropped to a fixed **1080×1080 square** (fixes tile mismatch app-wide). **No computer vision, OCR, or 3D — every value is user-set.** Tech: `expo-camera` (already used) + `expo-image-manipulator` (⚠️ removed earlier — re-add for the square crop); no new native deps. Data: `imageUri`, `fillLevel` (enum), `capturedAt`. **3 open design decisions** in spec §9 (default fill, fifth-bucket wording, when the level is set). The earlier "AI 3D quantity vision" moonshot (auto-detected levels, consumption-rate notifications) is deferred separately — this specced **manual** version is v1.

---

## Related docs

- **SDK 55 + analytics plan: `Docs/roadmap/SDK55_Upgrade_And_Analytics_Plan.md`** (#9)
- Guided jar capture spec: `Docs/specs/PlaceWell_GuidedCapture_Spec.md` + mockup (#12)
- Build & submit: `Docs/release/iOS_Android_Build_Guide.md`, `Release_Validation_Checklist.md`, `PlaceWellApp/VERIFICATION_CHECKLIST.txt`
- Store listing + review assets: `Docs/release/store-listing/`
- E2E testing: `Docs/maestro/`, `PlaceWellApp/scripts/maestro/README.md`
- Business: `Docs/etsy/Etsy_Launch_Plan.md`
- Architecture: `Docs/architecture/System_Overview.md`
