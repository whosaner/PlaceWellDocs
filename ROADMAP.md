# PlaceWell — Unified Product Roadmap

This roadmap covers all PlaceWell projects: App, PDF Generator, UI, and QR Service.

---

## Pre-Launch (Must-Haves)

### 1. Apple Developer Account & App Store Upload
**Status:** WIP — enrollment in progress.
Enroll in Apple Developer Program ($99/yr), configure app signing, build production IPA, submit to App Store review.

### 2. Upload App to Google Play
**Status:** Not started.
Register Google Play Developer account ($25 one-time), build production AAB, configure store listing, submit for review.

### 3. Print Labels — All Styles — Real-World Test
Print physical labels for every style × template combination. Apply to actual containers. Test QR scanning in real conditions (angles, lighting, curved surfaces, distance).

### 4. Product Photographs for Listings
Professional-quality photos of labels on real containers for Etsy/Shopify listings and app store screenshots. Multiple angles, lifestyle shots, close-ups showing QR detail.

### 5. Marketing Content for Etsy Listings
Write compelling product descriptions, bullet points, FAQs, and SEO-optimized tags for each label style/template listing on Etsy.

### 6. placewell.app Landing Page + Universal Links
**Priority: HIGH — required before go-live.**

The domain currently only serves the QR API. Before app store launch, it needs:

**Landing page (root `/`):**
- PlaceWell branding, tagline, product screenshots
- "Download on the App Store" + "Get it on Google Play" buttons
- Brief value proposition / how it works section

**Universal Links (iOS):**
- Host `/.well-known/apple-app-site-association`:
  ```json
  { "applinks": { "apps": [], "details": [{ "appID": "TEAMID.com.placewell.app", "paths": ["/s/*"] }] } }
  ```

**App Links (Android):**
- Host `/.well-known/assetlinks.json`:
  ```json
  [{ "relation": ["delegate_permission/common.handle_all_urls"], "target": { "namespace": "android_app", "package_name": "com.placewell.app", "sha256_cert_fingerprints": ["YOUR_SIGNING_KEY_HASH"] } }]
  ```

**Fallback for uninstalled users:**
- `/s/{labelId}` in a browser → "This label belongs to a PlaceWell home. Download the app to view it." + store buttons

### 7. Order Summary Endpoint (QR Service)
Add a `POST /api/qr/order-summary` endpoint that stores a summary of each order in Firestore (separate `orders` collection). Captures order metadata (order_id, style, category, label count, timestamps) for analytics, customer support, and order history lookup.

---

## High Priority

### 8. Comprehensive Testing Framework (All Projects)

**PlaceWellApp (React Native/Expo):**
- **Unit tests** — Jest for utility functions (hmac, identity, storage, search)
- **Component tests** — React Native Testing Library (BiDirectionalSlider, LabelCard, SwipeToConfirm)
- **Integration tests** — Full screen flows (scan → create → view → edit → archive)
- **E2E tests** — Detox or Maestro for automated UI testing
- **Multi-device matrix** — iPhone SE through Pro Max, Pixel 7, Galaxy Fold; iOS 16+, Android 12+

**PlaceWellUI (FastAPI):**
- **Unit tests** — pytest for order_builder, config, sheet computation
- **API tests** — httpx/TestClient for form submission, PDF download, error cases
- **Template rendering tests** — verify HTML for different template/color combinations

**PlaceWellPdfGenerator (Python):**
- **Unit tests** — pytest for text wrapping, QR generation, layout math
- **Visual regression tests** — golden screenshot comparison (pixel diff)
- **Parameterized tests** — all style × template × color combinations produce valid PDFs

**PlaceWellQRService (FastAPI):**
- **Unit tests** — pytest for URL validation, signature verification, label lookup
- **API tests** — TestClient for all endpoints (allocate, lookup, scan redirect)
- **Load tests** — k6 or artillery for throughput under concurrent scans

### 9. Etsy/Shopify Store Integration (App)
In-app link to the PlaceWell store so users can purchase labels directly. Deep link or embedded webview to storefront.

### 10. iOS WidgetKit Extension (App)
Native Swift widget for one-tap scan. Requires `expo prebuild`, Xcode Widget Extension target, PlaceWell branding wrapper around `placewell://scan` deep link.

### 11. End-to-End Integration Test
Automated pipeline test: UI form submission → QR Service allocation → PDF generation → verify output PDFs contain correct QR URLs and label names.

---

## TODO (Pending from Recent Work)

### 12. App: Carousel UX Improvement
The label carousel (horizontal scroll of all labels) needs better visual feel — spacing, snap behavior, or card styling. Needs design discussion.

### 13. Admin v2: File Uploads
Extend PlaceWellAdmin to support:
- **Font upload** — copy TTF to `fonts/`, register in FONT_REGISTRY
- **CSV preset upload** — copy to `PlaceWellUI/data/`, register in CATEGORY_CONFIG
- **Placeholder image** — copy PNG to app assets, generate component, register in `placeholders/index.js`

### 14. Trim spice.csv
Reduce from 24 to 20 base spice names. Waiting on decision of which 4 to remove.

### 15. Edit Category in PlaceWellAdmin
Add edit functionality for categories (currently only Add is supported; Edit exists for templates and styles).

---

## Medium Priority

### 16. Household Sharing (App)
Multiple household members view/manage the same labels. Cloud sync (Supabase), invite codes, role-based access (owner vs member).
**Dependencies:** Cloud backend, identity system (householdId groundwork in place).

### 17. Activity Log (App)
Per-label history ("Cinnamon updated by Mom 2 days ago"). Valuable once Household Sharing is live.
**Dependencies:** Household Sharing (#16).

### 18. Voice Search (App)
Search labels using voice commands via device speech-to-text.

### 19. AI-Powered Search (App)
Enhanced search that analyzes label names, notes, AND photos using vision AI. Example: "red holiday decorations" surfaces labels whose photos contain red ornaments.
**Dependencies:** Cloud backend or on-device ML, photo indexing pipeline.

### 20. Expiration/Date Alerts (App)
Optional date picker on label form ("Expires" / "Remind me"). Enables badges, filter/sort by expiry, local push notifications. Ideal for pantry items, medications.

### 21. Custom Fields (App)
User-defined metadata per label. Examples: "Brand", "Serial Number", "Priority", "Fragile".

### 22. Export/Backup (App)
Export all labels as CSV or PDF. Manual backup + restore. Trust signal for local-only apps.

### 23. Dark Mode (App)
Dark variant of the gradient system. Theme toggle in Settings + alternate color palette.

### 24. Label Templates (App)
Pre-built configurations for common use cases (Pantry Staples, Garage Tools, Holiday Decor). Pre-filled contents/suggestions on label creation.

---

## Low Priority

### 25. Camera Enhancements (App)
- Multiple photos per label (up to 5-8, swipeable carousel)
- In-app camera controls (flash, grid, aspect ratio)
- Auto-enhance for dark spaces
- Annotation/markup on photos
- Better crop UX

### 26. Batch Operations (App)
Multi-select labels to move, archive, or delete in bulk. Useful when reorganizing rooms.

### 27. Quantity Tracking (App)
+/- counter per label ("how many left"). Most relevant for pantry/bulk storage.

### 28. Room/Zone Deletion — Bulk Reassignment (App)
"Reassign & Delete" flow when removing a room with active labels. Subsumed by Batch Operations if done first.

---

## Future / Premium Tier

### 29. NFC Labels (Hardware + App)
Premium labels with NFC tags. Tap phone → no camera needed. Faster, works in dark spaces. NFC stickers cost ~$0.10-0.30 each.

---

## V1 Post-Launch

### 30. New Label Categories (PDF Generator + App)
Categories beyond spice: garage, kids' room, laundry, office, bathroom. New templates, category-specific placeholders, suggested contents.

### 31. Shopify Store for PlaceWell
Dedicated Shopify storefront. Custom branding, subscription options, bundle pricing, direct customer relationships.

---

## V2 Post-Launch

### 32. Auto Replenishment — AI Inventory Scanner (App)
Use LLM-powered vision to scan any item and add it to inventory. Supports hand-written labels, manufacturer barcodes, and SKU text on product packaging. Enables "running low" alerts and one-tap reorder flows.

---

## Longer Term / Business Growth

### 33. Sell Physical Labels (Direct)
Pre-printed physical labels with QR codes already applied. Fulfillment pipeline: generate QR batch → print on premium stock → ship to customer.

### 34. New Home-Owner Kit
Curated physical product — box of pre-printed labels in various styles for someone moving into a new home. Welcome card with app download QR.

---

## Completed ✅

### Finalize Styles, Fonts, Label Sizes
Locked down: Josefin Sans Regular (default), 3 label templates (round-1.5, rect-portrait, rect-landscape), 3-layer config system (template × QR × style).

### "Coming Soon" Panel (App)
Bottom sheet accessible from HomeScreen floating button. Shows upcoming features to keep users engaged.

### Recently Scanned (App)
Labels track `lastAccessedAt`. Home screen shows recently accessed labels. `touchLabel()` updates timestamp on each scan/view.

### Widget / Quick Action (App) — Partial
Deep link `placewell://scan` → opens ScannerScreen. Android app shortcut configured. iOS WidgetKit extension still pending.

### Scan Confirmation Sound (App)
Audio feedback on successful scan via `sound.js` + expo-av. Complements existing haptic feedback.

### PDF Generator — Built
3-layer architecture (template × QR × style), 2-PDF output (labels + manifest), conditional footer, letter-spacing-aware text fitting, dynamic font sizing. Fully working.

### PlaceWellUI — Built
FastAPI operator form: comma-separated label names, radio template selection, auto-blank computation, collapsible color picker, footer toggle with branding + discount fields.

### QR Service — Deployed
Live on Linode at placewell.app. Allocation, lookup, and scan-redirect endpoints. Firestore backend. HMAC-signed QR URLs. Schema uses `label_sku`.

### Mobile App — Core Complete
4-step wizard (Name→Photo→Location→Contents), category-based field config, CategoryPlaceholder illustrations, QR Service lookup integration, full-text search, room/zone management, archive/restore, device+household identity.

### PlaceWellAdmin — Built
Web-based local config manager (`run.bat` → browser form at localhost:8500). Add/Edit templates, styles, and categories without touching code. Auto-commits changes across sibling projects.

### Label SKU Migration — All Services
Replaced `label_size`/`label_dim` with unified `label_sku` across App, QR Service, UI, and PDF Generator. Single schema field flows end-to-end.

### PDF Rendering Fixes
Disabled crop marks (pre-die-cut sheets), removed blank label underlines, improved round label text centering, compact comma-separated manifest item list, added outer+inner border for rect labels, fixed doubled filename prefix.

### Order QR Bulk Load
New `/api/qr/order/{orderId}` endpoint, Order QR printed on manifest, app scans once to bulk-create all labels locally. Idempotent, skips blanks and archived labels.

### Font Weight Upgrade
Josefin Sans upgraded from Thin (100) to Regular (400), text color from muted grey to near-black for readable labels.
