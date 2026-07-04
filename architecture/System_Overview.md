# PlaceWell System Overview

PlaceWell is a five-project ecosystem that turns printed QR labels into a local-first home organization product. The mobile app is the customer-facing experience, the QR service is the trust and lookup layer, the operator UI creates orders, the PDF generator renders production-ready sheets, and the admin tool keeps shared configuration aligned across projects.

## Ecosystem at a glance

| Project | Primary role | Key outputs / dependencies |
|---|---|---|
| **PlaceWellApp** | React Native + Expo mobile app for scan, setup, recall, search, and management | Scans PlaceWell QR labels, validates HMAC offline, optionally looks up metadata from PlaceWellQRService, stores user inventory locally |
| **PlaceWellQRService** | FastAPI service for QR allocation, lookup, and scan redirects | Allocates label IDs, stores QR records in Firestore, serves `/s/` scan URLs, returns label metadata to the app |
| **PlaceWellUI** | FastAPI operator form for building print orders | Collects label names and template choices, calls QR allocation, builds order payloads, triggers PDF generation |
| **PlaceWellPdfGenerator** | Python library for rendering print-ready PDFs | Generates label sheets and manifest PDFs from the order payload built by PlaceWellUI |
| **PlaceWellAdmin** | Local configuration manager across the ecosystem | Updates shared template/style/category config in sibling repos so App, UI, and PDF generation stay in sync |

## End-to-end production flow

```text
PlaceWellAdmin
  | updates shared templates, styles, categories
  v
PlaceWellUI
  | operator selects category, template, style, footer, and per-label overrides
  | calls POST /api/qr/allocate
  v
PlaceWellQRService
  | allocates LABELIDs and QR URLs
  | writes qr_codes + orders records
  v
Firestore
  | stores allocation records for lookup, redirect, and order import
  ^
  |
PlaceWellQRService returns QR URLs to PlaceWellUI
  |
  v
PlaceWellPdfGenerator
  | renders label sheet PDF + manifest PDF
  v
Printed PlaceWell labels and order QR
```

## End-to-end scan and recall flow

```text
Physical PlaceWell label
  |
  | QR encodes https://placewell.app/s/{LABELID}-{SIGNATURE}?n={name}
  v
Phone camera or in-app scanner
  |
  +--> Installed app path:
  |      PlaceWellApp opens via deep link / universal link / app link
  |      -> validates HMAC offline
  |      -> optionally calls QRService lookup for metadata enrichment
  |      -> opens setup for new labels or recall/detail for existing labels
  |
  +--> Browser path:
         placewell.app/s/... hits PlaceWellQRService
         -> server redirects to PlaceWell deep link target
         -> if app is not installed, web landing/fallback can send user to store download flow
```

## Project-to-project relationships

### 1. PlaceWellApp -> PlaceWellQRService -> Firestore
- The app treats the QR as the gateway into the product.
- It performs **offline HMAC verification first** so counterfeit or malformed labels can be rejected immediately.
- When online, it can call the QR service to fetch label metadata such as label name, category, and physical SKU.
- The QR service reads and writes allocation data in Firestore; the app itself remains local-first for user-managed inventory data in v1.

### 2. PlaceWellUI -> PlaceWellPdfGenerator
- PlaceWellUI is the operator-facing order builder.
- It gathers category presets, per-label names, template selection, style options, footer options, and any blanks needed to fill a sheet.
- It requests QR allocation from PlaceWellQRService, then builds a complete order dictionary.
- That order dictionary is passed directly into PlaceWellPdfGenerator, which outputs two PDFs per order: a printable label sheet and a manifest.

### 3. PlaceWellAdmin across all projects
- PlaceWellAdmin is the control plane for shared configuration.
- Template edits update PDF layout definitions and UI template options together.
- Style edits update typography/color configuration used by rendered labels and operator choices.
- Category edits update operator dropdowns and mobile-app category behavior so newly generated labels scan into the correct experience.

## QR URL format and deep-link strategy

### QR URL format

```text
https://placewell.app/s/{LABELID}-{SIGNATURE}?n={name}
```

| Part | Meaning |
|---|---|
| `https://placewell.app/s/` | Public scan endpoint hosted by PlaceWellQRService |
| `{LABELID}` | Short unique label identifier |
| `{SIGNATURE}` | Short HMAC-derived checksum used by the app for offline authenticity checks |
| `?n={name}` | Optional pre-printed label name hint |

### Deep-link strategy
- **Primary scan route:** all printed labels use the same `/s/` URL format.
- **Installed app:** iOS Universal Links and Android App Links route PlaceWell URLs into the mobile app when available.
- **Offline trust check:** the app verifies the HMAC-derived signature locally before it trusts the scan.
- **Online enrichment:** after local validation, the app can call the QR service to fetch metadata and order information.
- **Fallback behavior:** if the app is not installed, the web endpoint can send the user to a download/landing experience and eventually back into the app through deferred deep linking.

## Firestore schema

### `qr_codes` collection

```json
{
  "id": "YEYC26",
  "order_id": "placewell_20250523_001",
  "item_id": "spice_basil_003",
  "is_blank": false,
  "label_name": "Basil",
  "category": "spice",
  "label_sku": "round-1.5",
  "created_at": "Timestamp",
  "status": "active",
  "camera_scan_count": 0,
  "app_scan_count": 0,
  "last_scanned_at": null
}
```

### `orders` collection

```json
{
  "order_id": "placewell_20250523_001",
  "content_category": "spice",
  "username_prefix": "placewell",
  "total_labels": 24,
  "named_label_count": 23,
  "blank_label_count": 1,
  "order_qr_count": 1,
  "template_skus": ["round-1.5"],
  "freshness_category_counts": {"ground_spice": 12},
  "named_label_count_by_category": {"spice": 23},
  "status": "allocated",
  "created_at": "Timestamp",
  "schema_version": 1
}
```

## Key design decisions

1. **Local-first mobile inventory:** user-managed inventory data lives in the app so setup and recall remain useful even without a backend session.
2. **Physical label as gatekeeper:** valid printed labels are the entry point to creating or recalling a PlaceWell record.
3. **Short signed QR URLs:** QR codes stay compact enough for physical labels while still carrying an authenticity signal.
4. **Offline validation, online enrichment:** the app can reject bad codes immediately and only depends on the network for richer metadata.
5. **Separate order and label records:** Firestore stores per-label allocation in `qr_codes` and higher-level batch/order facts in `orders`.
6. **Shared config, not duplicated logic:** templates, styles, and categories are managed centrally through PlaceWellAdmin so UI, PDFs, and app behavior stay aligned.
7. **One server, isolated internal services:** Apache fronts public traffic while QR Service and UI run on internal localhost ports.

## Analytics

### Scan tracking (Firestore — `qr_codes` collection)

Each label document tracks two scan counters:

| Field | Incremented by | When |
|---|---|---|
| `camera_scan_count` | PlaceWellQRService `/s/` redirect | Physical QR scan via phone camera → browser |
| `app_scan_count` | PlaceWellQRService `/api/qr/lookup/` | In-app scanner scan |

Both use Firestore's atomic `fs.Increment(1)` — safe under concurrent scans. Writes are best-effort and do not block the user-facing response.

### Firebase Analytics (PlaceWellApp — `src/utils/analytics.js`)

The app uses a Firebase Analytics wrapper that is a **silent no-op in Expo Go** and activates automatically in production EAS builds where Firebase is configured.

| Event | Trigger |
|---|---|
| `scanner_opened` | User opens the in-app scanner |
| `label_scanned` | Every QR scan — params: `label_id`, `label_category`, `is_rescan` (0/1) |
| `label_created` | Label saved in create mode — params: `has_photo`, `has_location`, `is_spice` |
| `label_edited` | Label saved in edit mode |
| `label_deleted` | Delete confirmed on LabelRecall or LabelDetail screen |
| `label_refilled` | Refill confirmed on LabelRecall screen — param: `freshness_category` |
| `freshness_date_set` | User manually sets a Best By date |
| `home_label_opened` | Label card tapped on HomeScreen |
| `bulk_import_started` | Order QR scan triggers bulk import flow |
| `bulk_import_completed` | All labels created — params: `created_count`, `skipped_count` |

### Production activation (EAS build)

Firebase Analytics is installed but not active until a production build is created:

1. Add `google-services.json` (Android) to the project root
2. Add `GoogleService-Info.plist` (iOS) to the project root
3. Add `@react-native-firebase/app` to `app.json` plugins
4. Run `eas build` — all 10 events will flow into Firebase Analytics automatically

No app code changes are needed for activation.
