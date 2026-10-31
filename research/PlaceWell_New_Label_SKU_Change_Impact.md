# PlaceWell New Physical Label SKU - Cross-Project Change Impact

Research date: 2026-10-24

Status: Read-only audit. No implementation changes were made.

Related sourcing research:

`Docs\research\SheetLabels_Box_Tote_SKU_Research.md`

## Executive conclusion

The minimum path for adding one larger box/tote label SKU is concentrated in:

1. **PlaceWellPdfGenerator** - register and calibrate the exact SheetLabels
   geometry.
2. **PlaceWellUI** - expose the identical internal SKU and capacity, validate
   it before allocation, and send it into the order/PDF pipeline.
3. **Tests, documentation, and physical qualification** - prove layout,
   printing, scanning, and adhesion.

The current QR Service and Firestore are already SKU-agnostic. The mobile app
also preserves an unknown SKU and falls through to category fallback artwork.
Therefore, a new app release, stock-art release, Admin feature, SpiceJarRenderer
master, or Shopify product is not required for the minimum internal production
path if:

- the new labels use `image_key = null`; and
- they use an existing `storageBox` or `genericContainer` placeholder.

The largest operational risk is allocation order: PlaceWellUI currently
allocates permanent QR identities before PDF rendering. A bad template or
capacity mismatch can therefore create Firestore records for an unusable
physical sheet. UI validation and synthetic PDF proofing must happen before
production allocation.

## 1. Input from the SheetLabels research

Verified shortlist:

| Vendor SKU | Size | Sheet capacity | Likely PlaceWell internal slug example |
|---|---:|---:|---|
| SL522-XW | 4 x 5 rounded rectangle | 4 | `tote-4x5` |
| SL573-XW | 4 x 3 rounded rectangle | 6 | `tote-4x3` |
| SL1437-XW | 2.5 x 2.5 square | 12 | `tote-square-2.5` |
| SL128-XW | 3.5 round | 6 | `round-3.5` |
| SL517-XW | 6.5 x 4.5 rounded rectangle | 2 | `tote-6.5x4.5` |

The examples above are not approved names. Freeze one stable internal slug
before allocating any production records.

Recommended identity rule:

- Internal semantic ID: stable PlaceWell slug such as `tote-4x5`.
- Vendor SKU: separate `vendor_sku`, e.g. `SL522-XW`.
- Vendor/material can change later without renaming already-issued PlaceWell
  records.

For each chosen template, freeze:

- Width and height
- Shape and corner radius
- Letter-sheet dimensions
- Top, bottom, left, and right margins
- Horizontal and vertical gaps
- Intended rows and columns
- Official labels per sheet
- Vendor SKU and official URL
- Material code
- Inner-frame decision
- Typography and minimum readable font size

## 2. End-to-end field contract

| Layer | Field |
|---|---|
| UI / Python / Firestore / API | `label_sku` |
| Mobile JavaScript | `labelSku` |
| PDF order template list | `skus_included` |
| Firestore order summary | `template_skus` |
| Stock semantic identity | `imageKey|labelSku|quantity` |
| Shopify preview config | currently `sku`; future bridge must translate it |

The internal slug becomes durable data. Do not rename it after allocation:

- App-issued metadata is preserved once non-null.
- Firestore records retain the original string.
- Stock-art semantic keys include the SKU.
- Old and new app binaries may continue seeing the value.

## 3. Minimum versus full-fidelity scope

### Minimum production SKU

Required:

- PdfGenerator template registry and tests
- PlaceWellUI template registry and validation
- Generic storage/custom metadata
- QR Service round-trip tests
- App compatibility tests
- Physical print/scan/adhesion qualification
- Central documentation

Not required:

- New mobile binary
- New stock artwork
- New SpiceJarRenderer master
- PlaceWellAdmin code
- Shopify product

### Full-fidelity commercial SKU

Optional additions:

- New stock-art artwork for every supported content
- New app bundled fallback illustration
- New Shopify product/configurator format
- New PlaceWellAdmin Add Spice guidance
- New product media, fit guide, care copy, pricing, and fulfillment mapping

## 4. PlaceWellPdfGenerator

This is the first required code project.

### Required minimum changes

| File/symbol | Change | Why |
|---|---|---|
| `placewell_generator/config/sheet_templates.py`, `SHEET_TEMPLATES` | Add the exact internal SKU, display name, vendor SKU/URL, physical dimensions, shape, corner radius, Letter-sheet margins/gaps/capacity, frame policy, and typography. | This registry is the PDF allowlist and physical source of truth. |
| Same template entry | Set `draw_outer_edge: False`. Set the inner-frame flag explicitly. | Production policy avoids frames on the die-cut boundary because registration drift makes them straddle. |
| Same template entry | Set SKU-specific `base_font_size_pt` and `min_font_size_pt`. | Existing values are tuned for much smaller labels. |
| `placewell_generator/layout_engine.py`, `compute_layout` | Add tests/invariant that derived rows x columns equals declared `labels_per_sheet`. | The renderer derives capacity from geometry while UI stores a literal capacity. |
| `placewell_generator/validator.py` | Add valid/invalid SKU tests; registry addition supplies validation. | Unknown SKUs must fail before rendering. |
| `placewell_generator/generator.py`, `_get_template_items` | Review and test mixed-SKU behavior. Reject partially tagged orders instead of falling back to all printable items. | Current fallback can duplicate items into the wrong SKU in a malformed mixed order. |
| `renderer/cell.py` | Decide whether global QR/text layout is visually appropriate for a much larger label or add per-template layout values. | A 4 x 5 label using small-label placement may look empty/unbalanced. |
| `renderer/label_sheet.py` | Verify header/page-number positions against narrow top/bottom margins. | Header/footer text must not overlap die-cut labels. |

Snapshot references:

- Template registry: `sheet_templates.py:12-117`
- Layout: `layout_engine.py:39-76`
- Validation: `validator.py:34-52, 105-109`
- Template item routing: `generator.py:98-105, 167-199`
- Cell composition: `renderer/cell.py:57-80`
- Sheet header/footer: `renderer/label_sheet.py:84-109`

Line numbers are snapshot references and will drift after edits.

### QR geometry

Current QR defaults:

- 0.5 x 0.5 inch overall
- Error correction M
- Two-module quiet zone
- Vector CMYK K-only output

Relevant files:

- `placewell_generator/config/qr.py`
- `renderer/cell.py`, `_draw_qr`
- `renderer/qr_builder.py`

Do not change the QR size merely because the new label is larger. Preserve
0.5 inch unless a separate print/scan experiment approves a new physical size.

### Existing misleading QR-size option

`PlaceWellUI/app/config.py` offers 0.4- and 0.5-inch choices and the order
contains `qr_size_in`, but the PDF renderer currently ignores the field and
always uses `QR_DEFAULTS["size_in"]`.

Before adding another SKU:

- Either remove/disable 0.4 inch and present 0.5 inch as fixed; or
- deliberately wire a tested per-order/per-template override into the
  renderer.

Do not represent the current UI option as functional.

### Text and blank behavior

`renderer/cell.py` currently:

- wraps dynamically;
- reduces font size in 0.5-point steps;
- stops at each template's minimum;
- can create multiple lines;
- renders an allocated blank with QR but no name;
- leaves a blank with no QR completely empty.

Decide:

- Maximum name lines
- Minimum readable tote-label font
- Placement for short versus long names
- Whether writable blank labels need an underline
- Whether the larger label adds category/secondary text

`_draw_blank_underline()` currently exists but is not called.

### Frame/corner behavior

- Keep the outer frame off.
- `inner_border_inset_px` is currently treated as points, not pixels.
- Inner corner radius is derived from the vendor corner radius minus the inset.
- Non-round background fills are rectangular rather than rounded clipping
  paths.

Do not copy an existing corner setting without a physical proof.

### PdfGenerator tests

Add:

- Exact rows/columns/capacity
- First and last cell coordinates
- Bounds against official margins
- Outer-frame absence and inner-frame decision
- Long/short name goldens
- Font-floor readability
- Blank behavior
- Header/page-number clearance
- One-sheet and overflow boundaries
- Fully tagged mixed-SKU behavior
- Fail-fast partially tagged mixed orders
- Exact vector K-only QR output

Update export utilities only if they must support the new format:

- `export_individual_labels.py`
- `extract_labels_from_pdf.py`
- `LABEL_EXPORT_WIKI.md`

## 5. PlaceWellUI

This is the second required code project.

### Required minimum changes

| File/symbol | Change | Why |
|---|---|---|
| `app/config.py`, `LABEL_TEMPLATES` | Add the same internal SKU, operator label, vendor SKU, capacity, and default named count. | Drives form options, blanks, catalog filtering, and PDF payload. |
| `app/main.py`, `get_category_items` | Define how many defaults appear for the chosen category/SKU. | Unknown templates currently receive all catalog rows. |
| `app/order_builder.py` | Replace the silent unknown-template capacity fallback with explicit rejection. | Unsupported SKUs can otherwise receive a plausible capacity. |
| `app/main.py`, `submit_order` | Validate the selected template before skeleton building or QR allocation. | Prevent orphan allocation records when a template is invalid. |
| `app/templates/form.html` | Verify automatic option display and capacity wording. | Operator entry point. |
| `form.html` hidden/default template handling | Replace hardcoded `round-1.5`/30 fallback with registry data or fail closed. | Hidden fallback can mask form errors. |
| `form.html`, `updateSheetInfo` | Stop counting the metadata-only Order QR as a physical label position. | Browser summary currently disagrees with backend/PDF logic. |

Snapshot references:

- `app/config.py:83-87`
- `app/main.py:94-105, 158-280`
- `app/order_builder.py:154-177`
- `app/templates/form.html:42-50, 364-371, 665-676`

### Category/fallback handling

Minimum recommended product metadata:

- Category: `storage` or an explicitly supported `custom`
- `image_key: null`
- Placeholder: `storageBox` or `genericContainer`

Current risk:

- Top-level content categories include `custom`.
- Per-row form categories are hardcoded to `spice`, `storage`, and `garage`.
- A custom row can silently follow an unintended spice path.

Fix the row-category source or add `custom`, then verify the emitted metadata.

### Optional storage/tote preset

The UI already supports SKU-specific CSV override naming:

```text
data/<category>_<label-sku>.csv
```

Optional work:

- Add/update storage category config.
- Add `data/storage.csv` or a SKU-specific file.
- Define default names, locations, placeholders, and named/blank counts.

This is not needed for manually entered custom labels.

### UI tests

Add:

- Candidate capacity and sheet boundaries
- Order QR excluded from physical capacity
- Named/default blank composition
- Form display and hidden-default behavior
- Unknown SKU rejected before allocation
- Storage/custom fallback metadata
- `image_key = null` when no exact stock tuple exists
- Browser summary equals backend/PDF capacity

## 6. PlaceWellQRService and Firestore

### Minimum runtime result: no code change

The service already treats `label_sku` as optional arbitrary text:

- Allocation stores it.
- Order summaries aggregate it into `template_skus`.
- Lookup/order responses return it unchanged.
- No SKU allowlist or Firestore migration is required.

Representative snapshot references:

- `app/allocate.py:58-75, 257-299`
- `app/lookup.py:33-43, 134-145`
- `app/order.py:176-192, 232-247`

Pinned stock-art validation requires an exact manifest tuple only when
`image_key` is non-null. A generic-fallback label is valid without stock art.

### Recommended tests

- Allocate/lookup/order round-trip with an arbitrary future SKU.
- Verify `orders.template_skus`.
- Candidate SKU with null `image_key`.
- Exact stock tuple only if full stock artwork is added.
- Deterministic candidate fixture for released-app validation.

Fixture expectations currently hardcode the three existing SKUs and must be
updated only if the shared release fixture intentionally adds the candidate.

### Count caveat

The allocation summary currently counts the named Order QR as a named label
while also counting it as an Order QR. Acceptance criteria must distinguish:

- Allocated records
- Printable physical labels
- Named customer labels
- Blank customer labels
- Metadata-only Order QR

## 7. PlaceWellApp

### Minimum runtime result: generally no code change

The app already:

- Maps `label_sku` to `labelSku`.
- Persists arbitrary SKU strings.
- Preserves issued metadata.
- Uses exact SKU keys for remote stock lookup.
- Falls through safely when no descriptor exists.

Representative snapshot references:

- `src/services/qrService.js:49-65, 121-139`
- `src/screens/ScannerScreen.js:132-145`
- `src/data/storage.js:68-91, 397-449`
- `src/services/labelEnrichment.js:5-39`
- `src/services/stockImageService.js:424-479, 1053-1070`
- `src/components/LabelArtwork.js:38-118`

### Fallback behavior

The bundled registry contains only the current SKU-specific jar assets.

- Unknown SKU plus spice placeholder falls back to the round-1.5 jar art.
- `storageBox` uses storage art.
- `genericContainer` uses generic art.

Therefore:

- A tote/storage SKU works in current binaries when it carries storage/generic
  placeholder metadata.
- A new spice SKU without stock art may misleadingly show the round fallback.

Do not globally change unknown-spice behavior without reviewing compatibility
with legacy records.

### Recommended tests

- Map candidate SKU unchanged from lookup/order response.
- Persist candidate SKU and preserve it as issued metadata.
- Bulk import storage/generic labels with null image key.
- Released production binary:
  - Online lookup
  - Offline after save
  - Order QR bulk import
  - Search/detail/recall
  - No crash or blank art

### Optional app-specific bundled illustration

Only if generic storage art is insufficient:

- Add new fallback source/config.
- Extend fallback build inputs.
- Regenerate generated artwork/geometry.
- Register exact SKU.
- Update bundle/artwork/text-overlay tests.
- Run full app validation.
- Ship a new EAS binary.

## 8. PlaceWell-StockImageMasters

### Minimum result: no change

Null-image-key labels do not need a stock manifest entry.

### Full remote-art path

Current release assumptions are explicitly three SKUs and 78 assets:

- `scripts/export_stock_images.py`
- `verify_release_inputs.py`
- `tests/test_export_stock_images.py`

For 26 contents across four SKUs, the expected total becomes 104 active
semantic assets.

Required full-art work:

1. Add 26 candidate-SKU PNG masters and sidecars.
2. Add `release-config/jars/<new-sku>.json`.
3. Update provenance/checksums.
4. Add the SKU to exporter and verifier.
5. Replace/derive fixed 78 counts.
6. Add crop/canvas/text geometry goldens.
7. Extend immutable filename validation.
8. Increment the manifest revision.
9. Rebuild release inputs.
10. Retain all previous immutable WebPs.
11. Deploy the identical manifest to Firebase and Linode.

Manifest readers in the UI, service, and app are already data-driven.

## 9. PlaceWell-SpiceJarRenderer

### Minimum result: no change

### Full stock-art path

The renderer discovers jar configs dynamically. Full-fidelity work would add:

- `assets/jars/<new-sku>/jar-master.png`
- `config/jars/<new-sku>.json`
- Calibrated container/interior polygons
- Label mask and text area
- 26 rendered spice outputs
- Active-SKU tests and geometry checks

A tote/box SKU may not conceptually belong in a spice-jar renderer. Skip this
project if the app should show only generic storage imagery.

## 10. PlaceWellAdmin

### Minimum result: no change

Current source is primarily an Add Spice guidance tool rather than a true
template-writing control plane. It hardcodes three stock SKUs.

Full stock-art support would update the Add Spice guidance/path validation.
Building a real "Add Template" Admin workflow would be a separate feature that
coordinates UI/PDF registries and safe previews.

## 11. Shopify theme

### Minimum internal printable SKU: no change

Shopify is not yet the operator order pipeline. Its configuration is currently
preview-oriented.

### Commercial launch work

The theme currently hardcodes three formats across:

- `sections/placewell-label-product.liquid`
- `sections/placewell-size-guide.liquid`
- Product template JSON files
- `PLACEWELL_DEPLOYMENT_NOTES.md`

To sell the new format:

1. Add format -> internal SKU/capacity/dimensions mapping.
2. Add a product setting and template JSON.
3. Add the correct preview aspect ratio and CSS.
4. Add a box/tote fit guide.
5. Add product media and photography.
6. Add material, surface, care, and adhesion copy using only validated claims.
7. Add pricing, variants, and fulfillment mapping.
8. Ensure the future Commerce Bridge maps Shopify `sku` to backend
   `label_sku`.

Do not launch marketing claims before the selected material passes target
surface tests.

## 12. Documentation and shared artifacts

Update when implementation begins:

- `Docs/context/PLACEWELL_CONTEXT.md`
- `Docs/architecture/System_Overview.md`
- `Docs/setup/Adding_A_Category.md`
- `Docs/testing/PlaceWell_Printer_Label_Brother_Test.md`
- `Docs/release/Release_Validation_Checklist.md`
- `Docs/deployment/Stock_Image_Deployment.md` if stock art changes
- `Label Templates/SheetLabels SKUs.txt`
- Official candidate template/spec artifact under `Label Templates`

`Docs/setup/Adding_A_Category.md` is not sufficient as the only guide for this
work; parts of it predate current stock-art and fallback behavior.

## 13. Backward and forward compatibility

| Scenario | Current behavior/requirement |
|---|---|
| Old records without `label_sku` | Continue with category/default fallback; no migration required |
| Existing Firestore records | Unchanged |
| Released app receives unknown SKU | Stores it; storage/generic fallback works |
| New SKU without stock entry | Remote descriptor is null; bundled fallback is used |
| Old PDF generator receives new SKU | Rejects it; retain PDFs and deploy UI/PDF together |
| Mixed orders | Service supports them; PDF needs fully tagged items; current UI creates one template per order |
| Cache keys | Content hash avoids collision; semantic identity includes SKU |
| Stock rollback | Firebase and Linode manifests must roll back together |
| App rollback | Avoid making minimum SKU depend on a new binary |
| SKU renamed after allocation | Unsafe; freeze slug first |
| UI/PDF rollback | Roll back together because template contract is duplicated |

## 14. Ordered implementation plan

### Phase 0 - Freeze physical contract

1. Choose the SheetLabels SKU/material after adhesion testing.
2. Freeze the PlaceWell internal slug.
3. Record all official geometry and capacity.
4. Decide:
   - Inner frame
   - Typography
   - Blank treatment
   - Category/placeholder
   - Default named count
   - Mixed-SKU scope

Acceptance:

- One approved physical-contract table with no unresolved geometry fields.

### Phase 1 - PDF template and synthetic validation

1. Add the PdfGenerator template.
2. Add exact geometry/capacity/frame/text/QR tests.
3. Generate PDFs with non-production test data.
4. Print plain-paper overlays against official stock.

Acceptance:

- Exact layout tests pass.
- Every cell aligns at 100 percent scale.
- No production identities have been allocated.

### Phase 2 - UI enablement

1. Add the matching UI template.
2. Validate the template before allocation.
3. Remove silent unknown-capacity fallback.
4. Correct browser Order QR capacity math.
5. Make storage/custom fallback metadata reliable.
6. Add UI/order-builder tests.

Deploy UI and PdfGenerator together.

Acceptance:

- UI and PDF capacities match exactly.
- Invalid templates allocate nothing.

### Phase 3 - Service/app compatibility validation

Can run in parallel after the slug is frozen:

- QR allocation/lookup/order round-trip test
- Candidate deterministic fixtures
- Unknown-SKU app persistence/fallback tests
- Released-binary scan/import/offline tests

Acceptance:

- Existing released app handles the candidate safely without a new binary.

### Phase 4 - Physical production qualification

1. Print one candidate sheet.
2. Print three consecutive sheets.
3. Print ten consecutive sheets.
4. Scan representative first/middle/last positions.
5. Measure registration drift.
6. Test toner, curl, jams, transfer, warping, and output stacking.
7. Test adhesion on real plastic/cardboard surfaces at multiple dwell times.

Acceptance:

- Documented printer, QR, media, and adhesion pass.

### Phase 5 - Optional full fidelity

Parallel after physical/art approval:

- New renderer master/config and 26 outputs
- 104-entry StockImageMasters release
- New app bundled illustration
- Admin guidance expansion
- Shopify product/template/media/size guide

### Phase 6 - Deployment and rollback

1. Deploy UI/PDF together.
2. Smoke-test form, allocation, and PDF.
3. Deploy paired stock manifests only if stock art changed.
4. Seed deterministic candidate fixtures.
5. Validate released app binaries.
6. Build a new app only if app code/assets changed.
7. Publish Shopify product only after fulfillment mapping exists.
8. Record rollback revisions and retain generated PDFs.

## 15. Physical acceptance checklist

### Sheet/PDF

- Official template and measured stock agree.
- Letter size and Actual Size/100 percent.
- Derived pitch equals label dimension plus gap.
- Rows x columns equals declared capacity.
- First/last cells stay inside official margins.
- Header/footer do not overlap labels.
- No outer die-cut frame.
- Inner frame explicitly approved or disabled.
- 0.5-inch vector K-only QR.
- Long names remain inside approved zones.
- Font floor remains readable.
- Blanks match the product promise.
- Order QR remains off paid label-sheet positions.
- Overflow uses every cell exactly once.
- Mixed SKU items print only under their own SKU.

### Printer/media

- One, three, and ten consecutive sheets
- Registration across the full sheet
- Representative QR scan positions
- Curl, scuff, transfer, warping, jams, and stacking
- Controlled media/tray/scaling settings

### Adhesion

- Exact PP/PE tote and cardboard surfaces
- Cleaned and normal-use samples
- Flat and textured panels
- 24-hour, 72-hour, and 7-day checks
- Edge lift, bubbling, sliding, residue, and handling
- Temperature/humidity exposure appropriate to the product

## 16. Project order and parallelism

Critical path:

```text
SheetLabels selection/adhesion
  -> internal SKU freeze
  -> PdfGenerator geometry/tests
  -> PlaceWellUI registry/pre-allocation validation
  -> UI/PDF deployment
  -> physical production qualification
```

Parallel after slug freeze:

- QR Service compatibility tests/fixtures
- Mobile unknown-SKU/fallback tests
- Documentation preparation

Parallel after physical/art approval:

- Stock-art/renderer work
- App-specific bundled art
- Shopify product/media/configuration
- Admin guidance

## 17. Final recommendation

Implement the first box/tote SKU as a **generic storage label**:

- Choose one physically qualified SheetLabels template.
- Use `storage` plus `storageBox` or `genericContainer`.
- Keep `image_key = null`.
- Preserve the existing 0.5-inch QR.
- Avoid a new app release and stock-art expansion for the first pilot.
- Add full-fidelity art and Shopify commercialization only after the physical
  SKU proves useful.

This minimizes code scope while testing the actual product risk: print
registration, scan reliability, tote/box adhesion, and customer usefulness.
*** End of File
