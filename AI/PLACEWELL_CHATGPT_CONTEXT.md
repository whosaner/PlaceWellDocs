# PlaceWell - ChatGPT Context Packet

Snapshot date: 2026-10-22

## 1. Purpose

This is a sanitized, self-contained briefing for an external AI assistant. It
explains PlaceWell's product, business model, implemented architecture,
physical-label system, current release state, closed decisions, and active
constraints.

This packet intentionally omits credentials, secret values, private customer
data, financial records, and server login details.

When this packet conflicts with current source code or production
configuration, the current implementation wins. Release status must be checked
against live stores or the applicable store console when exact status matters.

## 2. Product summary

PlaceWell combines premium physical QR-coded labels with a local-first mobile
home-organization app.

A customer applies a label to a spice jar, pantry container, storage bin,
drawer, basket, moving box, or similar object. The physical label remains
useful and attractive on its own. Scanning its QR code opens a digital record
for information that cannot fit cleanly on the label:

- Current name
- Photo
- Contents and notes
- Room and zone
- Freshness dates
- Brand
- Refill history

Core value:

- Connect a physical container to a useful digital record.
- Make stored items easy to identify and recall.
- Avoid requiring an account for the current product.
- Keep personal household inventory on the user's device.
- Preserve a calm, design-forward physical and digital experience.

The commercial focus is spice, pantry, and home-storage labels sold through
the BeNiralu/PlaceWell business. Etsy remains an established channel. A
PlaceWell Shopify storefront is being prepared as a direct storefront.
Broader categories, gifting kits, and B2B programs are longer-term
opportunities.

## 3. Current release state

### Mobile app

- The current source marketing version is `1.2.0`.
- Apple publicly lists PlaceWell version `1.2.0`, released on 2026-09-18.
- The Google Play listing is public, but Google's public listing does not
  expose the installed production version. Verify the exact Android production
  version in Play Console when it matters.
- Version 1.2.0 introduced the guided onboarding described below.
- The 1.2.0 release was physically sanity-tested on both iOS and Android.
- The release test baseline was 32 Jest suites and 443 passing tests.

### Guided onboarding shipped in 1.2.0

- When Home has no labels, a spotlight points to the Scan button and asks the
  user to scan a PlaceWell Order Label.
- "Got it" dismisses that hint for the current empty episode.
- The hint re-arms when Home has labels and later becomes empty again.
- Each Order QR import shows a three-step walkthrough:
  1. Apply a shared room and zone to the order.
  2. Customize an individual label.
  3. Create the labels.
- Skip or Finish dismisses the walkthrough for that import.
- The next order import shows it again.
- Guided-hint dismissal is in memory; it is not a permanent AsyncStorage
  completion flag.

### Dated release documents

Some central release/roadmap files still describe the 1.0/1.1 rollout. Treat
their historical build numbers and review status as dated unless they have a
newer update date. The version-specific 1.2.0 collateral is under:

`Docs\release\store-listing\v1.2.0\`

## 4. System ecosystem

### Core projects

| Project | Responsibility |
|---|---|
| `PlaceWellApp` | Expo/React Native customer app: scan, setup, recall, search, photos, freshness, room/zone organization, and Order QR bulk import |
| `PlaceWellQRService` | FastAPI trust and metadata layer: QR allocation, signed scan URLs, metadata lookup, redirects, and order retrieval |
| `PlaceWellUI` | Internal FastAPI operator interface for composing label orders and selecting category, template, style, and overrides |
| `PlaceWellPdfGenerator` | Python library that renders print-ready label sheets and order manifests |
| `PlaceWellAdmin` | Local control plane for shared category, template, and style configuration |

### Supporting projects

| Project/folder | Responsibility |
|---|---|
| `PlaceWell-StockImageMasters` | Prepared stock-artwork source/release assets and deterministic dual-target release packaging |
| `Shopify\placewell-shopify-theme` | PlaceWell direct-storefront theme and release tooling |
| `Docs` | Cross-project documentation repository and source catalog |

## 5. End-to-end order lifecycle

1. An operator composes an order in PlaceWellUI.
2. The UI resolves category defaults, physical label SKU, printed name,
   selected style, and stock `image_key`.
3. PlaceWellQRService allocates globally unique six-character label IDs.
4. The service signs label URLs and writes issued metadata to Firestore.
5. The service returns label/order data to the operator workflow.
6. PlaceWellPdfGenerator renders label-sheet and manifest PDFs.
7. The labels are printed and delivered.
8. The customer scans an individual label or Order QR in PlaceWellApp.

## 6. Mobile application

### Current stack

- Expo SDK 54
- React Native 0.81.5
- React 19.1
- React Navigation 7
- AsyncStorage for structured local records/preferences
- Expo FileSystem for app-owned photos and stock-artwork cache
- Expo Camera and Image Picker
- EAS Build and EAS Submit

### Main implemented experiences

- Empty-home scan guidance
- In-app QR scanner
- Native-camera Universal/App Link handling
- New-label setup wizard
- Existing-label detail and recall
- Spice freshness, best-by, in-use-since, brand, notes, and refill history
- Home carousel and recently viewed labels
- Search and room/zone filters
- Custom user photos
- Remote stock artwork with bundled fallbacks
- Order QR bulk import with global and per-label customization
- Recurring three-step bulk-import walkthrough
- Settings for rooms, zones, archived labels, scan sound, and app information

### Local-first ownership

The following user-managed data is local to the mobile device:

- Current label name
- User photo
- Contents and notes
- Room and zone
- Freshness dates and refill history
- App preferences

Firestore is not a backup of this personal inventory. Reinstalling the app,
clearing app data, or moving to another device does not reliably restore it.
Android system backup may restore some AsyncStorage state, so a clean Android
test should explicitly clear app storage.

### Issued metadata

The order/printing pipeline owns issued metadata such as:

- `id`
- `printedLabelName`
- `category`
- `labelSku`
- `imageKey`
- Default location, zone, placeholder, and freshness category

The app may enrich older/incomplete local records from PlaceWellQRService.
Deleting a Firestore record does not delete an already-saved local label, but
it can break new-device setup, metadata enrichment, and Order QR retrieval.

## 7. QR identity, trust, and runtime routes

### Printed URL contract

Individual label URLs use:

```text
https://placewell.app/s/{LABEL_ID}-{SIGNATURE}?n={optional-name}
```

- `LABEL_ID` is six characters from a visually unambiguous alphabet.
- `SIGNATURE` is a short uppercase HMAC-derived value.
- The optional name is a display hint, not authoritative personal inventory.
- The app validates a signed HTTPS URL offline before trusting it.
- Signing/lookup secret values must never appear in AI prompts or docs.

Order QRs can resolve from an issued `/s/` record marked as an order or from a
supported dedicated `/o/` route, then open Bulk Import.

### Scan flow

1. Parse the URL.
2. Validate the signed label URL when available.
3. Check local storage for an existing record.
4. Existing local record: open Recall/Detail even if the network is down.
5. New record: perform best-effort metadata lookup, then open Label Setup.
6. Order record: fetch the order and open Bulk Import.

### `placewell.app` is a permanent compatibility surface

Existing printed labels and released mobile binaries depend on the apex domain.
The following paths must remain operational:

| Path | Responsibility |
|---|---|
| `/s/*` | Printed issued-label links, including Order QR records, plus scan landing/redirect behavior |
| `/o/*` | Supported dedicated Order QR links |
| `/api/qr/lookup/*` | Mobile label metadata lookup |
| `/api/qr/order/*` | Mobile Order QR retrieval |
| `/.well-known/apple-app-site-association` | iOS Universal Links |
| `/.well-known/assetlinks.json` | Android App Links |
| `/privacy` | Store-listed privacy policy |

The root `/` may become a Shopify storefront, but repointing the whole apex
domain directly to Shopify without path-aware routing would break labels,
bulk imports, released app binaries, and native link verification.

Safest storefront architecture:

- Shopify at `www.placewell.app`.
- Keep the apex QR/API service.
- Redirect normal root/storefront traffic to `www`.
- Preserve the routes above at the apex.

If Shopify must appear at the exact apex, use an edge router/reverse proxy that
keeps the QR/API/well-known paths on the current service and sends other paths
to Shopify.

At this snapshot, the deployed Apple association file claims all paths. Before
a storefront is placed on the same host, narrow Universal Link ownership to
the actual QR routes so ordinary product pages do not attempt to open the app.

Also preserve email DNS records so `support@placewell.app` continues working.

## 8. Physical labels and print system

### Current physical templates

| Template | Physical size | Capacity per Letter sheet | Current frame treatment |
|---|---:|---:|---|
| `round-1.5` | 1.5 in diameter | 30 | No outer circle and no inner circle |
| `rect-portrait` | 1.25 x 2.125 in | 20 | Outer die-cut frame removed; inset inner frame retained |
| `square-1.75` | 1.75 x 1.75 in | 20 | Outer die-cut frame removed; inset inner frame retained |

The die-cut-edge frames were removed because ordinary printer and die-cut
registration drift caused them to straddle the label edge or visually expose
off-center placement.

### Production label QR geometry

- Overall QR footprint: 0.5 x 0.5 in (12.7 x 12.7 mm)
- The stated footprint includes the quiet zone.
- Quiet zone: 2 modules on each side
- Error correction: M
- Output: vector modules
- Foreground: CMYK 0/0/0/100 (black-only toner request)
- Same physical QR size across all three label SKUs
- The 35-character signed sample URL used for current size testing (without an
  optional name query) resolves to a version-3, 29 x 29 QR grid
- At 0.5 in with the quiet zone included, that sample's module is approximately
  0.385 mm; longer optional name queries can require a larger matrix

Current experiments are testing whether the same production URL remains
reliably scannable at 0.1-0.5 in. Those tests are experiments, not a shipped QR
size change. Do not claim a smaller production size until physical print tests
establish a reliable floor.

### Printer findings

- QR codes are emitted as explicit K-only vector artwork to avoid composite
  black toner buildup while keeping colored label text.
- A Xerox C320 test produced no scuff marks, warping, or smudging using Color,
  Label paper, Main tray, Actual Size, and Adobe Reader.
- Printer results depend on media, feed path, driver, scaling, and registration.
  Physical validation is required before changing production geometry.

## 9. Stock artwork

The stock-artwork system provides rendered artwork for 26 spices across three
SKUs (78 initial assets).

Supported SKUs:

- `round-1.5`
- `rect-portrait`
- `square-1.75`

Stable `image_key` values originate upstream in the operator/catalog workflow.
The app does not guess an image key from a user-editable label name.

Artwork precedence on all mobile surfaces:

1. Available user photo
2. Verified cached/downloaded stock artwork
3. Bundled category/SKU fallback

Stock assets are immutable, content-addressed WebP files. The app validates
downloads before accepting them, uses atomic cache writes, supports
last-known-good manifest reuse, retries bounded failures, and falls back safely
when offline or when an asset is missing/corrupt.

The production manifest is hosted separately from `placewell.app`, so a
Shopify apex-domain change does not move the stock-artwork host.

## 10. Infrastructure and data

- `placewell.app`: QR routes, API routes, scan landing behavior, deep-link
  association files, and privacy policy
- Linode: PlaceWellQRService and internal operator services behind a web server
- Firestore: issued QR and order metadata
- Firebase Hosting: immutable stock-artwork package
- EAS: iOS/Android build and signing
- App Store Connect and Google Play: mobile distribution
- Shopify: planned direct storefront

PlaceWellApp does not connect directly to Firestore. The QR service is the
trust/metadata boundary.

## 11. Privacy and security model

- No required user account in the current product.
- Personal inventory, notes, photos, locations, and freshness records remain
  local to the device.
- Firestore contains issued-label/order metadata, not the user's household
  inventory.
- No advertising SDK or cross-app tracking.
- Firebase Analytics remains inactive pending an approved SDK/privacy update.
- Network enrichment is best-effort; existing local labels remain useful
  offline.

Never expose:

- HMAC/signing values
- Lookup/allocation/API tokens
- `.env` files
- Service-account JSON
- Store credentials
- Certificates, provisioning profiles, or signing keys
- SSH/server credentials
- Customer/order exports
- Financial records

## 12. Reliability principles

- Existing local labels must remain usable offline.
- Metadata lookup failure must not delete or block a local label.
- Missing artwork must fall through to a bundled fallback.
- User photos must be copied into app-owned storage before persistence.
- Replacing/deleting photos must only remove app-owned files.
- Async network/cache operations use bounded retries.
- A QR lookup, image fetch, cache write, or manifest failure must not crash the
  app.
- Printed QR routes must remain backward-compatible indefinitely.

## 13. Closed decisions

Do not reopen these without an explicit product reason:

- QR, not NFC or Data Matrix, is the primary physical-label technology.
- Six-character IDs plus short HMAC-derived signatures.
- Local-first personal inventory with no required account.
- Firestore for issued label/order metadata.
- Server-owned `image_key`; no artwork inference from editable text.
- Immutable, content-addressed WebP stock assets.
- One shared mobile artwork component and precedence model.
- User photo overrides stock artwork; removing it reveals stock/fallback art.
- Production label QRs remain high-contrast vector K-only artwork.
- Existing `placewell.app` printed routes are permanent compatibility
  contracts, regardless of storefront hosting.
- Analytics stays inactive until the SDK/privacy work is explicitly approved.

## 14. Active priorities and open work

Current work should be confirmed with the owner before reprioritization. The
most relevant active themes are:

1. Launching the PlaceWell Shopify storefront without breaking apex-domain
   QR/API/deep-link routes.
2. Real-world printing and scan testing across all label styles/SKUs and
   candidate QR sizes.
3. Keeping release/store status and central documentation current.
4. Firestore backup, point-in-time recovery, scheduled exports, and delete
   protection before real customer allocations scale.
5. Product photography and commerce launch work.
6. Expanded Maestro regression coverage and CI.
7. Deferred deep linking after installation.
8. Guided jar capture/quantity markers.
9. Multi-photo labels.
10. Optional household sharing/cloud synchronization while preserving a
    local-first default.
11. Expo SDK upgrade followed by separately approved analytics activation.
12. New label categories and B2B/gifting opportunities.

Do not silently reorder priorities from `Docs\roadmap\ROADMAP.md`; ask the owner
when the dated roadmap and current conversation differ.

## 15. Known uncertainties

- Exact current Android production version must be checked in Play Console;
  the public Play page does not expose it reliably.
- Some release and roadmap docs still contain 1.0/1.1 historical status.
- Shopify storefront work exists, but this packet does not claim the storefront
  is already live at the apex.
- Small-QR size testing is ongoing; 0.5 in remains the production QR footprint.
- Current customer-order/production Firestore volume was not re-verified for
  this snapshot.

An AI assistant must label these as uncertainties rather than guess.

## 16. Source map

| Need | Internal source |
|---|---|
| Canonical internal context | `Docs\context\PLACEWELL_CONTEXT.md` |
| Documentation catalog | `Docs\DOC_CATALOG.md` |
| System architecture | `Docs\architecture\System_Overview.md` |
| Current roadmap snapshot | `Docs\roadmap\ROADMAP.md` |
| Release collateral | `Docs\release\store-listing\` |
| Mobile implementation | `PlaceWellApp` |
| QR service implementation | `PlaceWellQRService` |
| Operator order workflow | `PlaceWellUI` |
| Label geometry/rendering | `PlaceWellPdfGenerator` |
| Shared configuration | `PlaceWellAdmin` |
| Stock masters | `PlaceWell-StockImageMasters` |
| Storefront work | `Shopify\placewell-shopify-theme` |

## 17. Instructions for the AI assistant

- Separate implemented, tested, experimental, planned, and uncertain facts.
- Ask one focused clarification at a time.
- Follow feedback -> plan -> approval -> execution.
- Do not propose implementation before understanding existing constraints.
- Preserve the local-first and no-required-account model unless explicitly
  asked to change it.
- Treat physical labels and printed URLs as long-lived compatibility surfaces.
- Do not invent store status, production validation, measurements, or secrets.
- If source access is available, inspect before recommending replacement.
- Never request or reproduce credentials or private data.
