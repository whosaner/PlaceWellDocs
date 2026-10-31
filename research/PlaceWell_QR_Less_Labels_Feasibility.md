# PlaceWell Labels Without Individual QR Codes - Feasibility and Change Audit

Research date: 2026-10-24

Status: Read-only audit. No implementation changes were made.

## Executive conclusion

PlaceWell's current order pipeline is identity-first:

- Every named label receives a six-character ID and signed URL.
- Every allocated blank receives an ID and URL.
- The Order QR receives an ID and URL.
- Every allocation becomes a Firestore `qr_codes` record before the PDF is
  rendered.
- The PDF validator requires a `qr_url`.
- The physical cell renderer always reserves and draws a QR zone.

There are several meaningfully different "QR-less" products:

1. **Visual-only labels** with no digital identity or app relationship.
2. **Clean-face connected labels** with one Order QR for bulk import but no
   individual printed QR.
3. **Mixed products** where some labels have individual QRs and others do not.
4. **Hidden identities** retained internally but not printed.

The simplest coherent MVP is **Model A: visual-only labels**, sold as a
separate non-app product.

The strongest connected alternative is **Model B: one Order QR plus clean-face
labels**, with importable order items stored at the order level instead of
wasting individual QR identities.

Model C (mixed) should not be the first QR-less product because it creates the
most customer and fulfillment confusion.

## 1. Verified current assumptions

### Order composition

Current PlaceWellUI:

- Calculates sheet capacity from physical named labels.
- Adds one metadata-only Order QR.
- Adds blanks to fill the selected sheet capacity.
- Allocates the full item list through PlaceWellQRService.
- Sends allocated `qr_url` values to PdfGenerator.
- Supports one selected physical template per operator order.

Current default compositions:

| SKU | Physical positions | Default names | Default blanks |
|---|---:|---:|---:|
| `round-1.5` | 30 | 26 | 4 |
| `rect-portrait` | 20 | 16 | 4 |
| `square-1.75` | 20 | 16 | 4 |

Current UI discrepancy:

- Python/PDF logic correctly excludes the Order QR from physical sheet
  capacity.
- The browser preview currently includes it in a sheet/count calculation.
- Correct this before introducing additional product modes.

### Allocation and Firestore

PlaceWellQRService currently allocates one identity for every request item:

- Generates a unique six-character ID.
- Computes a signed URL.
- Writes one `qr_codes` document.
- Associates it with the order.
- Maintains per-code scan counters/status.

The order document is a summary. `GET /api/qr/order/{order_id}` retrieves item
details by querying all matching `qr_codes` records; it does not currently
read an embedded order item list.

This is why an Order-QR-only connected product cannot simply stop allocating
individual records without changing the order schema/retrieval path.

### PDF assumptions

Current PdfGenerator behavior:

- Validator requires an HTTPS `qr_url` for every item.
- Named label: name + separator + QR.
- Allocated blank: separator + QR, no name.
- Blank without QR: completely empty position.
- A QR-less named layout does not exist.
- A writable/styled QR-less blank does not exist.
- `_draw_blank_underline()` exists but is currently unused.

Current label QR:

- 0.5 x 0.5 inch including quiet zone
- Error correction M
- Two-module quiet zone
- Vector CMYK K-only output

### App assumptions

Current app entry paths:

- Individual label scan -> setup/detail/recall.
- Order QR -> Bulk Import.

After Order QR import, local records can be opened from Home/search and edited
without scanning again. Therefore, an Order-QR-only product is technically
possible if the service returns stable item IDs and the existing order
response shape.

Limit:

- A clean-face physical label cannot identify which app record to open.
- Duplicate names increase ambiguity.
- Reinstall/import restores issued metadata, not prior local notes, photos,
  rooms, freshness, or user edits.

## 2. Product model comparison

## Model A - Visual-only labels

Definition:

- No individual QR.
- No Order QR.
- No QRService allocation.
- No Firestore identity.
- No app relationship.

Can do:

- Named decorative labels.
- Writable blanks.
- Existing physical sizes, fonts, and colors.
- Straightforward reprints/replacements.
- No backend, app, signing, or scan-analytics cost.

Cannot do:

- Scan-to-setup or scan-to-recall.
- Bulk import.
- App notes/photos/freshness tied to the product.
- Restore/locate a record from the physical label.
- Use "smart label" or connected-product promises.

Commercial implication:

- Sell as a clearly separate visual/decorative product.
- Packaging should not tell the buyer to scan or download the app for these
  labels.

Architecture impact:

- Primarily PlaceWellUI + PdfGenerator.
- QRService and app remain untouched.
- Shopify, fulfillment, photography, and product copy still require work.

## Model B - Clean-face connected kit with one Order QR

Definition:

- Individual labels have no printed QR.
- One durable Order QR imports all labels into the app.
- Imported records are later accessed from Home/search.

Can do:

- Bulk-create local records.
- Preserve printed name, category, SKU, artwork key, defaults, and freshness
  category.
- Support app photos, notes, rooms/zones, freshness, edits, and search.
- Re-import issued metadata on another installation using the Order QR.

Cannot do:

- Scan an individual physical label to open its exact record.
- Reliably disambiguate duplicate names from the physical object.
- Restore prior device-local user data on another device.
- Produce meaningful individual scan counters.

Fulfillment requirements:

- Print Order QR on the manifest/insert.
- Consider a second durable "Keep this card" copy.
- Verify the QR belongs to the exact item list.
- Support must be able to resend/recover the Order QR without exposing private
  customer data.

Recommended customer language:

- "One-time kit import"
- "Clean-face connected labels"
- "Open labels later from Home or search"

Do not promise "scan any label."

## Model C - Mixed QR and QR-less labels

Definition:

- Some physical labels have an individual QR.
- Some are clean-face/order-only or visual-only.
- One order may contain both.

Benefits:

- Premium/essential items can retain direct scan-to-recall.
- Decorative or low-priority labels can remain clean.
- Supports tiered customer choices.

Risks:

- Highest customer confusion.
- Hard to know which physical label should scan.
- Per-label fulfillment/QC complexity.
- Replacement identities become difficult.
- Analytics become incomparable without identity-mode dimensions.

Recommendation:

- Do not launch as the first QR-less offering.
- If pursued later, begin with order-level or sheet-level mode, not arbitrary
  per-row mixing.

## Model D - Hidden identity not printed

Useful only when hidden identity serves a real workflow:

- Order QR import.
- Identity code on release liner/backing.
- Replacement mapping.
- Internal QC/manufacturing.
- Future NFC or another physical identifier.

Not useful when:

- Every label consumes an ID, signed URL, Firestore record, scan counters, and
  backup obligation but the customer never receives any way to use it.

## 3. Can this be only a UI/PDF change?

### Model A: yes for the production backend

PlaceWellUI can bypass QR allocation and send visual-only items to an updated
PdfGenerator.

Still required outside those projects:

- Shopify product/catalog
- Fulfillment/QC
- Product photography
- Documentation/copy
- Printer qualification

### Model B/C pilot: technically yes, but inefficient

A short-lived pilot can:

1. Allocate all current IDs and records.
2. Keep the Order QR.
3. Pass `render_qr: false` to selected PDF cells.
4. Hide separator/QR visually.

This preserves current app bulk import, but each QR-less label still consumes:

- ID
- Signed URL
- Firestore `qr_codes` document
- Counters that can never increment
- Backup/retention obligation
- Public `/s/` identity never given to the customer

Acceptable only as a small, capped market test with the inefficiency clearly
documented.

### Production Model B/C: service schema change recommended

Recommended order schema:

#### Order-level

- `schema_version: 2`
- `product_mode: visual_only | order_import | individual_qr | mixed`
- `physical_label_count`
- `named_physical_count`
- `blank_physical_count`
- `individual_qr_count`
- `order_only_count`
- `order_qr_count`
- Embedded importable `items[]`, or an order-items subcollection if future
  order size requires it

#### Item-level

- `identity_mode: none | order_only | printed_qr`
- `record_id`: stable app/import key
- `label_id`: only for `printed_qr`
- `qr_url`: nullable; only for printed QRs and the Order QR
- Existing printed metadata fields
- QR rendering derived from identity mode

Recommended storage:

- `none`: no Firestore item and no app import
- `order_only`: stored in order import data, no `qr_codes` document
- `printed_qr`: order item plus current `qr_codes` document
- Order QR: one functional signed record/token

Backward compatibility:

- Missing mode fields default to today's `printed_qr`.
- Order lookup reads schema-v2 items first and current `qr_codes` query as a
  schema-v1 fallback.
- Current response can remain app-compatible by returning `id = record_id`.

Security:

- Current timestamp-like order IDs are predictable.
- A dedicated `/o/{order_id}` link should not replace the signed Order QR
  without a random signed order token or equivalent authorization.

## 4. Required changes by project

## PlaceWellUI

Required:

- Add a clearly labeled product/connectivity mode.
- Hide QR-size controls for QR-less modes.
- Add product and item identity modes in order construction.
- Make Order QR conditional:
  - A: none
  - B: one
  - C: configured mix
- Keep physical capacity based only on physical labels.
- Branch allocation:
  - A: no QRService call
  - B: schema-v2 order items + one Order QR
  - C: allocate only `printed_qr` items
- Update QR client cardinality/URL mapping to allow nullable per-item URLs.
- Correct current browser capacity/count discrepancy.

Snapshot references:

- `app/templates/form.html:15-211, 668-675`
- `app/order_builder.py:162-324`
- `app/main.py:159-296`
- `app/qr_client.py:22-96`

Mixed mode:

- Prefer per-order or per-sheet selection.
- Per-row selection materially increases fulfillment risk.

Tests:

- All modes
- Named and blank behavior
- Exact physical/allocated/order-only counts
- Capacity boundaries
- Old payload defaults
- QRService not called for Model A

## PlaceWellQRService

### Model A

No runtime change; UI does not call the service.

### Production Model B/C

Required:

- Add schema-v2 item identity modes.
- Generate stable order-only record IDs.
- Allocate QR IDs only for `printed_qr`.
- Store/import order-only items at the order level.
- Serve schema-v2 items from order lookup.
- Retain schema-v1 query fallback.
- Define order-level counters separately from per-code scan counters.
- Keep existing `/s/*` behavior unchanged.

Snapshot references:

- `app/allocate.py:58-304`
- `app/order.py:177-263`
- `app/lookup.py:36-149`
- `app/scan.py:445-535`
- `app/firestore.py:70-74`
- `app/pages.py:116-145`

Fixtures/tests:

- Visual-only order
- Order-only connected kit
- Mixed order
- Duplicate names
- Blanks
- Old schema fallback
- Count semantics

## PlaceWellPdfGenerator

Required for every QR-less model:

- Validator requires `qr_url` only when QR rendering is expected.
- Cell renderer supports explicit layouts:
  - Named with QR
  - Named without QR
  - QR blank
  - Writable QR-less blank
  - Unused sheet position
- QR-less name zone does not reserve QR geometry.
- Separator is conditional or removed.
- Existing blank underline is activated/replaced for writable blanks.
- Per-template QR-less typography/layout values.
- Sort/count physical items independently from QR state.
- Manifest behavior is product-mode-aware:
  - A: no app/Order QR instruction
  - B: explicit kit-import instruction
  - Current QR product: unchanged

Snapshot references:

- `validator.py:67-113`
- `renderer/cell.py:21-80, 150-395`
- `config/sheet_templates.py`
- `generator.py:72-195`
- `renderer/header.py:300-359`
- `renderer/label_sheet.py:15-74`

Tests:

- No QR modules/operators in QR-less cells
- Named QR-less layout
- Writable blank vs unused position
- Mixed pages
- Manifest modes
- All three physical templates
- Long/short names and every font/color

## PlaceWellApp

### Model A

No functional code change. The product has no app relationship.

Ensure app/store/commerce language does not imply the visual-only product
works with the app.

### Model B

Core plumbing can work if order lookup preserves stable IDs and response shape.

Recommended changes:

- Parse/persist `product_mode` and `identity_mode`.
- Preserve identity mode as issued metadata.
- Bulk Import explains that clean-face labels are reopened from Home/search.
- Home/scanner copy stops claiming every label can be scanned.
- Preserve mode through setup/save.
- Consider QR-less bundled artwork variants if existing fallback art depicts a
  decorative QR area.

Snapshot references:

- `src/services/qrService.js:107-140`
- `src/data/storage.js:14, 67-90, 373-452`
- `src/screens/BulkImportScreen.js`
- `src/screens/LabelFormScreen.js`
- `src/screens/HomeScreen.js`
- `src/screens/ScannerScreen.js`
- `assets/fallback/geometry.json`

Tests:

- Order-only IDs through import/save/edit/search/archive/delete
- Photos and freshness
- Duplicate names
- Reinstall/re-import behavior
- Copy/UX distinction

No new native dependency is required.

## PlaceWellAdmin

No mandatory change for MVP. Current Admin is not the authoritative template
writer.

Long-term shared configuration could validate product modes, SKU suffixes,
capacities, and cross-project alignment.

## PlaceWell-StockImageMasters

No mandatory change. Stock masters feed app artwork, not physical label QR
rendering.

Change only if app illustrations must visibly distinguish connected QR labels
from clean-face/order-only labels.

## PlaceWell-SpiceJarRenderer

No mandatory change for the same reason.

## Shopify theme

Required for any customer-facing QR-less offering.

Current theme assumes:

- Every PlaceWell product is QR-enabled.
- Each label connects to a digital record.
- Preview always shows a faux QR.
- No product/connectivity mode exists.

Required:

- Add product/connectivity family.
- Use separate products or unmistakable variants.
- Remove/condition faux QR preview.
- Add stable fulfillment SKU suffixes.
- Persist product mode through cart/editing.
- Add real QR-less photography.
- Add mode-specific title, SEO, FAQ, instructions, and claims.
- Update product templates and size/fit guide.
- Ensure future Commerce Bridge passes product mode.

Separate Shopify products are safer than subtle variants because they allow
clear titles, photography, pricing, SEO, and support expectations.

## Deployment and operations

### Model A

Deploy:

1. PdfGenerator bundled into UI deployment.
2. PlaceWellUI.
3. Shopify theme/catalog.
4. Fulfillment assets.

No QRService or app deployment.

### Model B/C

Deploy additively:

1. QRService schema-v2 support with old behavior as default.
2. Deterministic fixtures.
3. PlaceWellUI/PdfGenerator behind an operator flag.
4. Internal orders and physical proofs.
5. App mode/copy support.
6. Shopify exposure.
7. Documentation/privacy/store collateral.

Never remove or reinterpret existing `/s/*` behavior.

## 5. Visual design implications

Removing the QR frees approximately 0.66 inch of vertical composition when QR
and clearance/separator space are included.

### Round 1.5

- Remove separator.
- Center name vertically.
- Increase normal font size.
- Retain long-name reduction.
- Keep the approved no-ring design.
- Use only restrained optional motifs.

### Rectangle 1.25 x 2.125

- Use larger centered name typography.
- Optionally add a restrained category/subtitle.
- Retain the inset inner frame.
- Do not leave the old QR zone visibly empty.

### Square 1.75

- Center the name with balanced whitespace.
- Optional small icon/category line is feasible.
- Retain inset frame.

### Blank labels

Separate three concepts:

1. Allocated QR blank.
2. Writable visual blank.
3. Unused sheet position.

Do not overload the current `is_blank` flag for all three.

### Optional physical icons/art

No current print-asset registry exists. App stock artwork is not a print-safe
physical-label asset library.

Icons require:

- Dedicated print asset registry
- Provenance/licensing
- Per-SKU safe zones
- Print/CMYK validation
- Shopify preview
- Name-collision tests

## 6. Business and UX risks

### Product confusion

Suggested product-family distinction:

- **PlaceWell Scan Labels** - individual QR on every label
- **PlaceWell Connected Kit** - clean-face labels plus one Order QR
- **PlaceWell Visual Labels** - no app identity

Final names are owner decisions.

### Lost Order QR

Model B depends on one artifact:

- Put it on the manifest.
- Consider a second durable insert.
- Mark it "Keep this card."
- Define support recovery.

### App expectation

Current language implies every label scans. Model B needs explicit guidance
that records reopen from Home/search.

### Upgrade path

A visual-only label cannot become individually scannable through software
alone. It requires:

- Replacement QR label
- Separate QR sticker
- Hidden/backing code
- Future NFC/identifier

Do not promise a software-only upgrade.

### Replacement and support

- Model A: straightforward visual reprint.
- Model B: digital record persists, but duplicate/renamed labels can be
  ambiguous.
- Model C: exact identity preservation is operationally complex.

### Pricing

- Model A should be compared with premium visual-label products.
- Model B retains some app value but lacks individual scan-to-recall.
- Model C can support tiers but is difficult to explain.

### Analytics

- A: commerce/order analytics only.
- B: Order QR/import analytics only.
- C: individual scan metrics for only part of the order.

Dashboards need product/identity mode to avoid misleading comparisons.

## 7. Recommended MVPs

## Simplest: Model A visual-only

- Separate product
- No QRService call
- No Firestore identities
- No Order QR
- Dedicated QR-less PDF layout
- Separate Shopify products/SKUs/photography
- Non-app packing/QC manifest
- Explicit named/writable blank behavior

Advantages:

- Smallest architecture change
- No wasted backend records
- Easiest rollback
- Simple replacements

Disadvantage:

- Not a connected PlaceWell product

## Preferred connected alternative: Model B

- One signed Order QR
- Order-contained importable item records
- Stable order-only `record_id`
- No individual label IDs, signatures, URLs, counters, or `qr_codes`
- Current-compatible order response
- Home/search used for later recall
- Product-specific onboarding and packaging

Advantages:

- Clean physical appearance
- Retains app organization value
- Avoids wasteful hidden identities

Disadvantages:

- No individual scan-to-recall
- Schema/service/app/copy work
- Lost Order QR and duplicate-name risks

## Defer Model C

Do not launch mixed mode until customers understand existing QR labels and a
clean-face product. If pursued, use order-level or sheet-level selection first.

## 8. Ordered implementation plan

1. **Lock product definition**
   - A, B, or both
   - Product names/promise
   - Individual scan availability
   - Order QR placement/recovery
   - Named and blank behavior
   - Pricing and replacement policy

2. **Define additive schema**
   - Product mode
   - Identity mode
   - Count semantics
   - Stable record IDs
   - Missing fields default to current behavior

3. **Fix current capacity/count discrepancies**
   - Align browser, Python, allocation, and PDF meanings.

4. **Implement PdfGenerator layouts**
   - All SKUs, fonts, colors, name lengths, blank types, manifest modes.

5. **Implement PlaceWellUI orchestration**
   - Mode selection
   - Conditional allocation
   - Physical capacity independent of identity allocation

6. **For B/C, implement QRService schema v2**
   - Order-contained items
   - Conditional QR allocation
   - Schema-v1 fallback

7. **Create deterministic fixtures**
   - Visual-only
   - Order-only
   - Mixed
   - Duplicate names
   - Blank cases

8. **Validate app**
   - Import, save, search, edit, photos, freshness, archive/delete,
     reinstall/re-import, lost Order QR.

9. **Implement Shopify representation**
   - Products, variants/SKUs, configuration schema, preview, cart editing,
     photography, copy, and fulfillment.

10. **Physically qualify**
    - All templates, repeated sheet runs, actual materials, toner, adhesion,
      registration, and stacking.

11. **Pilot**
    - Operator feature flag
    - Internal orders
    - Small customer cohort

12. **Update docs/privacy/store collateral**
    - Only after product behavior is selected and validated.

## 9. Rollout and rollback

Rollout:

- Default absent mode to `printed_qr`.
- Deploy QRService before clients sending new modes.
- Hide QR-less modes behind an operator flag.
- Verify expected Firestore writes.
- Preserve generated PDFs and order item snapshots.
- Keep current QR product unchanged.

Rollback:

- Disable operator/Shopify product.
- Continue serving existing schema-v2 orders.
- Never delete order-only data.
- Preserve `/s/*`.
- Revert QR-less PDF selection without removing additive service support.

## 10. Privacy, listing, and documentation impact

Current app/commerce copy often implies all PlaceWell labels are individually
QR-coded. Product-family language must qualify that claim.

Model A:

- No app privacy change because it does not use the app/service.

Model B:

- May not require a new store privacy category if it stores the same issued
  metadata and analytics remains inactive.
- Privacy language should accurately describe order-only metadata.
- Do not send Shopify customer names, addresses, emails, or order PII to
  QRService.
- Custom printed label names can contain personal text; avoid absolute
  "non-personal metadata" claims.

Update as applicable:

- Store descriptions
- Shopify product copy/FAQ
- Reviewer instructions
- Privacy policy
- Architecture/context docs
- Operator/fulfillment guides
- Support scripts

## 11. Owner decisions required before coding

1. Is the offering app-free Model A or connected Model B?
2. Is individual scan-to-recall intentionally unavailable?
3. How will that limitation be communicated?
4. Are named and blank labels both QR-less?
5. Is a QR-less blank writable or completely unprinted?
6. Is mixed mode required at launch?
7. If mixed, selection per order, sheet, or label?
8. Where does the Order QR live?
9. Is it duplicated?
10. What happens if it is lost?
11. Separate Shopify products or variants?
12. Product names and fulfillment SKU suffixes?
13. What replaces the QR area?
14. Typography-only or icons/art?
15. Must replacements preserve exact digital identity?
16. Are hidden IDs retained for a defined use or eliminated?
17. Is a capped hidden-ID pilot acceptable?
18. Must the app visually flag clean-face/order-only records?
19. What order-size ceiling determines embedded items vs subcollection?
20. Is a visual-only product compatible with the PlaceWell brand promise?

## 12. Final recommendation

Make the first decision at the product level:

- If the goal is simply beautiful labels without digital behavior, choose
  **Model A** and keep it explicitly separate.
- If the goal is a cleaner physical design that still participates in
  PlaceWell, choose **Model B** and invest in the order-level schema rather than
  silently allocating unused per-label identities.

Do not begin with mixed mode, and do not treat "hide the QR in the PDF" as the
complete production architecture.
*** End of File
