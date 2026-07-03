# PlaceWell Unified Roadmap

This roadmap consolidates the active app, infrastructure, operator, PDF, and business-track documentation for the full PlaceWell ecosystem.

## Completed ✅

### Product and app experience
- **Custom Modal Dialogs** — native alerts replaced with branded themed modals.
- **Bulk Import Flow** — order QR scanning imports many labels at once with defaults and per-label overrides.
- **Room Filter Drawer / Floating Panel** — labels can be browsed by Room → Zone from a drawer-style grouped view.
- **Archive All / Delete All** — bulk label-management actions added to the app.
- **Coming Soon Panel** — in-app preview sheet for upcoming capabilities.
- **Recently Scanned** — recent label access is tracked and surfaced on the home screen.
- **Scan Confirmation Sound** — successful scans play audio feedback in addition to haptics.
- **Widget / Quick Action (partial)** — deep link `placewell://scan` is wired and Android shortcut support exists; iOS widget still remains open.

### Cross-project platform work
- **Per-Label Configuration & SKU-Driven Presets** — rich CSV-driven defaults now flow across UI, QR Service, PDF generation, and app setup.
- **Order QR Bulk Load** — order QR prints on the sheet and bulk-creates labels in the app on first scan.
- **Order QR Scan Routing Fix** — order scans now resolve into the bulk-import flow instead of single-label setup.
- **Label SKU Migration** — `label_sku` replaced legacy size fields across services.
- **PDF Rendering Fixes** — crop mark removal, border updates, round-label spacing fixes, filename cleanup, and manifest improvements.
- **Font Weight Upgrade** — Josefin Sans moved from thin to regular for readability.

### Individual project milestones
- **QR Service** — deployed on Linode with allocation, lookup, order, and scan-redirect endpoints backed by Firestore.
- **PlaceWellUI** — operator form built with per-label table, template selection, color picker, blanks handling, and footer options.
- **PlaceWellPdfGenerator** — 3-layer rendering architecture with label sheet + manifest output is fully working.
- **PlaceWellAdmin** — local config manager built with template/style/category editing and CSV CRUD support.
- **Mobile App Core** — wizard flow, QR lookup, search, room/zone management, archive/restore, device identity, and order import are in place.
- **Finalize Styles, Fonts, Label Sizes** — baseline design stack and template set are locked.

## In Progress 🔄

- **Apple Developer Account & App Store Upload** — enrollment is in progress.

## Coming Soon (currently surfaced in the app)

- **Household Sharing** — shared homes and multi-person access.
- **Advanced Search** — richer search, including future photo intelligence.
- **Expiry Reminders** — proactive freshness/date notifications.
- **Auto Replenishment** — future reorder and replenishment workflows.

## Pre-Launch (must-have before go-live)

1. **Apple Developer Account & App Store Upload** — finish enrollment, signing, production build, and App Store submission.
2. **Google Play Upload** — register the Play developer account, build the Android release bundle, and submit the store listing.
3. **Print Labels — Real-World Test** — print every style/template combination and validate scan performance on real containers.
4. **Product Photographs for Listings** — create polished photography for Etsy, Shopify, and app-store visuals.
5. **Marketing Content for Etsy Listings** — finalize descriptions, FAQs, bullets, and SEO tags.
6. **placewell.app Landing Page + Universal Links + App Links** — add the root landing page plus `apple-app-site-association` and `assetlinks.json` support.
7. **Order Service / Order Tracking** — maintain high-level order records for analytics, support, reprints, and reporting.

## High Priority

1. **Comprehensive Testing Framework** — expand unit, integration, API, template-rendering, and end-to-end coverage across all projects.
2. **Etsy/Shopify Store Integration in the App** — direct users from the mobile app into the storefront.
3. **iOS WidgetKit Extension** — complete the native iOS scan widget path.
4. **End-to-End Integration Test** — automate the UI → QR Service → PDF generation pipeline verification.

## Pending from Recent Work

1. **Placeholder Images — StorageBox & Generic** — waiting on image assets.
2. **Settings — User Profile Display** — surface OS-captured identity info in app settings.
3. **Carousel UX Improvement** — refine spacing, snap feel, and overall visual polish.
4. **Admin: CSV Table Editor Frontend** — build the in-browser table editor on top of the existing API.
5. **Admin v2: File Uploads** — support font, CSV preset, and placeholder-image uploads.
6. **Edit Category in PlaceWellAdmin** — bring category editing to parity with template and style editing.

## Medium Priority

1. **Household Sharing** — cloud sync, invite flows, and role-based access.
2. **Activity Log** — per-label history once shared households exist.
3. **Voice Search** — speech-driven label search.
4. **AI-Powered Search** — search labels by text and photo understanding.
5. **Expiration / Date Alerts** — badges, filters, and local notifications.
6. **Custom Fields** — user-defined metadata on labels.
7. **Export / Backup** — CSV or PDF export and restore flows.
8. **Dark Mode** — a complete alternate theme.
9. **Label Templates in App** — pre-built presets for common use cases.

## Low Priority

1. **Camera Enhancements** — multi-photo support, flash, crop UX, and in-app camera controls.
2. **Batch Operations** — multi-select move/archive/delete flows beyond the existing all-at-once actions.
3. **Quantity Tracking** — simple inventory counters for consumables.
4. **Room/Zone Deletion — Bulk Reassignment** — guided cleanup when spaces still contain labels.

## Future / Premium Tier

1. **NFC Labels** — premium hardware labels for tap-to-open behavior.

## Post-Launch

### V1 post-launch
- **New Label Categories** — expand beyond spice into garage, kids, laundry, office, bathroom, and related presets.
- **Shopify Store for PlaceWell** — dedicated storefront and direct customer relationship layer.

### V2 post-launch
- **Auto Replenishment — AI Inventory Scanner** — use AI-assisted scanning of real products, packaging, and handwriting to grow toward inventory management.

## Longer-Term Business Growth

1. **Sell Physical Labels Directly** — build fulfillment around pre-printed shipped label packs.
2. **New Home-Owner Kit** — curated boxed sets for move-in gifting and builder partnerships.
