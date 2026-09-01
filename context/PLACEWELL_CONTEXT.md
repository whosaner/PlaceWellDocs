# PlaceWell - Canonical Product and Technical Context

Last updated: 2026-09-01

## Purpose and authority

This is the single canonical orientation document for PlaceWell. It is written
for team members and AI assistants that need to understand the product,
business direction, implemented system, current release state, and roadmap
before recommending work.

Project `README.md` files are short entry points for setup and links. Detailed
cross-project documentation belongs in `C:\PlaceWell\Docs`. Repository-local
agent guides and implementation notes may remain beside code when they are
specific to that repository.

When documents conflict:

1. Current source code and production configuration define implemented
   behavior.
2. `Docs\release\Release_Validation_Checklist.md` defines current release
   status.
3. `Docs\roadmap\ROADMAP.md` defines agreed priorities.
4. Feature specifications define detailed behavior within their scope.
5. This file provides the broad, current synthesis.

## Product

PlaceWell combines physical QR-coded labels with a local-first mobile
organization system. A customer places a label on a spice jar, pantry
container, storage bin, drawer, basket, or similar object. Scanning the label
opens a digital record containing information that cannot fit on the physical
label.

Core value:

- Premium physical labels remain useful and attractive without the app.
- QR scanning connects a physical container to its digital record.
- Users can quickly remember what something is, where it belongs, and what is
  stored inside.
- No account is required for the current product.
- Personal inventory data stays on the user's device.

The initial commercial focus is design-forward spice, pantry, and home-storage
labels sold through the existing BeNiralu business. Longer-term opportunities
include broader label categories, gifting kits, direct storefronts, and B2B
homebuilder or realtor programs.

## Current stage

- PlaceWell version 1.0.0 is publicly available on both Google Play and the
  Apple App Store.
- Version 1.1.0 was built and physically validated on Android and iPhone.
- Android version code 18 was submitted for production review on 2026-08-31.
- iOS build 27 was submitted for App Store review on 2026-08-31.
- Google Play managed publishing is off and iOS automatic release is enabled,
  so approved updates publish automatically.
- There are currently no customer label orders in Firestore; production
  records are controlled test fixtures.
- The version 1.1.0 release adds the completed stock-artwork system and related
  reliability improvements.

Always check `Docs\release\Release_Validation_Checklist.md` for status changes
after this date.

## Ecosystem

| Repository | Role |
|---|---|
| `PlaceWellApp` | React Native/Expo customer app for scan, setup, recall, search, bulk import, photos, and freshness tracking |
| `PlaceWellQRService` | FastAPI trust and metadata service for allocation, signed scan URLs, lookup, redirects, and order retrieval |
| `PlaceWellUI` | Internal FastAPI operator interface for composing label orders and selecting templates |
| `PlaceWellPdfGenerator` | Python library that renders printable label sheets and order manifests |
| `PlaceWellAdmin` | Local control plane for shared category, template, and style configuration |

Central documentation is in the separate `PlaceWellDocs` repository mounted at
`C:\PlaceWell\Docs`.

## End-to-end order flow

1. An operator creates an order in PlaceWellUI.
2. The UI resolves category defaults, SKU selection, printed names, and stock
   `image_key` values.
3. PlaceWellQRService allocates globally unique six-character label IDs and
   stores label and order metadata in Firestore.
4. The service returns signed QR URLs.
5. PlaceWellPdfGenerator creates the printable labels and order manifest.
6. The physical labels are printed and delivered.
7. The customer scans individual labels or an Order QR in PlaceWellApp.

## Mobile application

### Stack

- Expo SDK 54
- React Native 0.81.5
- React 19.1
- React Navigation 7
- AsyncStorage for structured local data
- Expo FileSystem for durable app-owned user photos and stock-artwork cache
- Expo Camera and Image Picker for scanning and photos
- EAS Build and EAS Submit for store binaries

The app currently has 31 Jest suites and 423 tests.

### Main experiences

- First-launch guidance and camera permission flow
- In-app QR scanner
- New-label setup wizard
- Existing-label detail and recall
- Spice freshness, best-by, in-use-since, brand, notes, and refill history
- Home carousel, recently viewed labels, search, and room/zone filters
- Custom user photos
- Order QR bulk import with global and per-label room/zone choices
- Settings for rooms, zones, archived labels, scan sound, and app information

### Local data ownership

User-managed records are stored locally:

- Current label name
- User photo
- Contents and notes
- Room and zone
- Freshness dates and refill history
- App preferences

Firestore is not a cloud backup for this personal inventory. Reinstalling the
app, clearing app data, or moving to another device does not restore local
inventory in the current version.

Android may restore AsyncStorage through automatic system backup after a
reinstall. For a genuinely clean test installation, clear PlaceWell's app
storage from Android settings.

### Issued metadata

The following values originate from the printed-label/order pipeline:

- `id`
- `printedLabelName`
- `category`
- `labelSku`
- `imageKey`
- Default location, zone, placeholder, and freshness category

Once non-null issued metadata is saved locally, normal user edits do not
replace it. Older or incomplete local records can request missing values from
PlaceWellQRService.

Deleting a Firestore record does not delete a label already saved on the same
app installation. It does prevent reliable enrichment, new-device setup, and
Order QR retrieval until the server record is restored.

## QR identity, trust, and lookup

Printed label URL:

```text
https://placewell.app/s/{LABEL_ID}-{SIGNATURE}?n={optional-name}
```

- `LABEL_ID` is six characters from the visually unambiguous PlaceWell
  alphabet.
- `SIGNATURE` is a four-character uppercase HMAC-derived value.
- The signature lets the app reject malformed or counterfeit signed URLs
  offline.
- The optional name is a display hint, not authoritative inventory data.
- Secrets and signing keys must never appear in documentation or prompts.

Scan behavior:

1. Parse and validate the PlaceWell URL.
2. Verify the HMAC signature locally when the signed HTTPS URL is available.
3. Look for the label in local app storage.
4. If it exists locally, open Recall or Detail even if the server is
   unavailable.
5. If it is new, perform a best-effort metadata lookup and open Label Setup.
6. If the record is an Order QR, fetch its order and open Bulk Import.

PlaceWellQRService stores two Firestore collections:

- `qr_codes`: issued label identity, order association, printed metadata,
  status, and aggregate scan counters.
- `orders`: order-level counts, categories, templates, status, and metadata
  used by bulk import.

User-entered photos, contents, notes, rooms, zones, and freshness records are
not stored in these collections.

## Stock artwork

Version 1.1.0 includes remote stock artwork for 26 spices across three label
SKUs, for 78 rendered assets in the initial release.

Supported SKUs:

- `round-1.5`
- `rect-portrait`
- `square-1.75`

`PlaceWellUI\data\spice.csv` is the catalog source for stable `image_key`
values. Keys match the renderer's spice identifiers one-to-one and are
resolved upstream from printed names. The app never guesses an image key from
an editable local name.

Artwork identity:

```text
imageKey | labelSku | quantity
```

The initial catalog uses the manifest's default quantity. Quantity-specific
artwork is a future expansion.

### Distribution and cache

- A static manifest and immutable, content-hashed WebP files are published
  byte-identically to Firebase Hosting and the Linode release store.
- The app downloads from the manifest's HTTPS base URL.
- The operator UI and QR service validate pinned releases from
  `/opt/placewell-stock/current`.
- Image content is accepted only after HTTP success, WebP MIME sanity, complete
  body download, and final SHA-256 verification against the manifest asset ID.
- Cache writes use a same-directory temporary file followed by atomic rename.
- Manifest ETag handling and last-known-good manifest storage support offline
  reuse.
- Downloads use bounded retries, four-transfer visible-first concurrency, and
  in-flight request deduplication.
- Cached stock images live in persistent app-owned storage and are excluded
  from native backups.

### Unified artwork precedence

Every visible app surface uses `LabelArtwork` and the same precedence:

1. Available user photo
2. Verified cached/downloaded stock artwork
3. Bundled category/SKU fallback artwork

Printed label text is rendered consistently over stock and bundled artwork.
Custom user photos use cover sizing and do not receive the stock label overlay.

Removing a user photo reveals stock artwork again. A missing manifest, offline
connection, failed download, corrupt cached bitmap, unavailable photo file, or
unknown `image_key` falls through safely without crashing or leaving a blank
screen.

## Production infrastructure

- Public domain: `placewell.app`
- Linode hosts PlaceWellQRService, the operator UI, and scan landing/redirect
  behavior behind Apache.
- Firestore stores issued QR and order metadata.
- Firebase Hosting serves the immutable stock-artwork package.
- EAS builds and signs iOS and Android applications.
- App Store Connect and Google Play distribute production builds.
- Universal Links and Android App Links connect HTTPS scans to the installed
  app.

Production credentials are managed through environment files, EAS
environments, platform credential stores, and service-account configuration.
Never copy `.env` files, service-account JSON, certificates, API keys, HMAC
values, or store credentials into an AI context packet.

## Deterministic release testing

The QR-service fixture seeder provides reusable fixed-ID test data:

- The default `maestro` set supports automated smoke flows.
- The `mixed-stock` set creates `mixed_stock_test_kit` with 15 importable
  labels plus one Order QR.
- The mixed order contains five labels per SKU: three stock-art spices, one
  storage fallback, and one generic fallback.
- Reseeding atomically recreates the same IDs and signed URLs after Firestore
  test-data cleanup.

The reusable mixed QR pack is generated outside source control at:

```text
C:\PlaceWell\StockImageMixedTestPack-v2
```

Store reviewers receive deterministic setup and Order QR instructions.

## Reliability and offline principles

- Local labels must remain usable without a network connection.
- Network metadata enrichment is best-effort.
- Missing server records must not delete local labels.
- Missing artwork must resolve to a bundled fallback.
- User photos must be copied out of temporary picker storage before saving.
- Replacing or deleting photos must remove only app-owned files.
- Async operations use bounded retries rather than permanent failure ledgers.
- The app must never crash because a QR lookup, manifest, image, or cache write
  is unavailable.

## Closed decisions

Do not reopen these decisions without an explicit product reason:

- QR rather than NFC or Data Matrix for the primary physical label.
- Six-character IDs with short HMAC signatures.
- Local-first personal inventory with no required account in the current
  product.
- Firestore for issued label/order metadata.
- Server-owned `image_key`; the app does not infer artwork from editable text.
- Immutable, content-addressed WebP stock assets.
- Firebase Hosting for app artwork downloads and Linode for pinned internal
  release validation.
- One shared `LabelArtwork` component for all app image surfaces.
- User photo overrides stock artwork; removing it restores stock artwork.
- Etsy/BeNiralu is the initial sales channel.
- Firebase Analytics remains inactive until the planned Expo SDK upgrade and
  corresponding privacy declarations.

## Current priorities

Release operations come first:

1. Monitor Android and iOS version 1.1.0 reviews and verify public availability.
2. Keep release documentation current after every store status change.
3. Enable Firestore point-in-time recovery, scheduled backups, and delete
   protection before customer label allocation.

Product and business priorities remain subject to owner approval:

- Real-world printing and scan testing across every physical label style/SKU
- Product photography and Etsy listing launch
- Deferred deep linking after app installation
- Maestro regression coverage and CI
- Guided jar capture and quantity markers
- Multi-photo labels
- Household sharing and optional cloud synchronization
- Expo SDK 57 upgrade followed by Firebase Analytics activation
- Additional label categories and direct/B2B sales channels

See `Docs\roadmap\ROADMAP.md` for the prioritized backlog. Do not silently
reorder roadmap items.

## Collaboration rules

- Follow feedback -> plan -> approval -> execution.
- Present one decision, question, or plan section at a time.
- Distinguish shipped behavior from proposals and roadmap ideas.
- Investigate existing implementations and documentation before designing a
  replacement.
- Preserve unrelated working-tree changes.
- Update central documentation with significant implementation or release
  changes.
- Never claim on-device behavior is complete without physical validation.
- Include the required Copilot co-author trailer in commits made by Copilot.

## Canonical document map

| Need | Document |
|---|---|
| Find documentation | `C:\PlaceWell\Docs\DOC_CATALOG.md` |
| Product/technical orientation | `C:\PlaceWell\Docs\context\PLACEWELL_CONTEXT.md` |
| Architecture and data flow | `C:\PlaceWell\Docs\architecture\System_Overview.md` |
| Current roadmap | `C:\PlaceWell\Docs\roadmap\ROADMAP.md` |
| Release status | `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md` |
| App setup | `C:\PlaceWell\Docs\setup\App_Setup.md` |
| Design system | `C:\PlaceWell\Docs\design\Design_System.md` |
| Stock-artwork contract | `C:\PlaceWell\Docs\roadmap\Stock_Image_Implementation_Plan.md` |
| Store collateral | `C:\PlaceWell\Docs\release\store-listing\` |
| Deployment and operations | `C:\PlaceWell\Docs\deployment\` |
| App-specific coding workflow | `C:\PlaceWell\PlaceWellApp\agents\workflow.md` |

## Suggested AI briefing

Upload this file together with the roadmap, system overview, and current
release checklist. Then instruct the assistant:

> Treat the uploaded PlaceWell documents as authoritative. First summarize the
> product, implemented architecture, current release state, closed decisions,
> and roadmap. Clearly separate shipped functionality from future plans. Do
> not propose implementation until you understand the existing constraints.
> Ask one focused clarification at a time and never request or reproduce
> secrets.
