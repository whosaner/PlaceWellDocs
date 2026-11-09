# PlaceWell SKU Template Compiler - Version 1 Specification

Status: Approved scope, implementation not started

Last updated: 2026-10-30

## 1. Purpose

PlaceWell needs to add physical label SKUs regularly without introducing
one-off typography, QR, geometry, and repository changes for every template.

Version 1 creates a repeatable SheetLabels-template compiler:

```text
Official SheetLabels PDF + operator product inputs
                         |
                         v
PlaceWellPdfGenerator compiler/calculation/rendering engine
                         |
                         v
One deterministic recommended configuration
                         |
                         v
Production-renderer proofs and validation metrics
                         |
                         v
Operator customizes and regenerates until satisfied
                         |
                         v
Downloadable canonical SKU bundle and exact project-change instructions
```

PlaceWellPdfGenerator owns all calculations and rendering. PlaceWellUI owns
the authenticated dashboard workflow. The tool never edits repositories,
allocates QR identities, creates Shopify products, or deploys code.

## 2. Approved Version 1 decisions

- SheetLabels official one-page vector PDFs only.
- Schema is vendor-neutral so later vendor adapters remain possible.
- Official PDF orientation is used as-is.
- No content rotation or alternate orientation.
- One canonical versioned SKU JSON definition is the source of truth.
- PlaceWell SKU is suggested but editable while still a draft.
- Every physical SKU contains both required customer-order profiles:
  - Smart: individual QR on every named and blank label.
  - Standard: no QR on named or blank labels.
- Smart/Standard is selected per customer order, never as SKU identity.
- Every remaining sheet position becomes a writable framed blank.
- No unused/print-nothing position exists.
- Tool produces one deterministic dual-profile recommendation.
- All proofs use the production renderer only.
- Guided controls and bounded Advanced Settings allow regeneration.
- No saved draft history or in-tool version comparison.
- Operator compares downloaded bundles manually.
- Exported bundle includes timestamped `README.md` and `manifest.json`.
- Bundle contains exact project/path/action instructions but applies nothing.
- Physical print/scan/adhesion testing is tracked by an exported checklist,
  not by dashboard workflow.

## 3. Explicit Version 1 non-goals

- Non-SheetLabels vendors
- Raster-only, manually drawn, multipage, Legal, or A4 templates
- Rotated content or multiple orientation profiles
- Multiple ranked candidates
- Side-by-side draft comparison
- Saved revisions, history, revert, archive, or audit log
- Multi-user review/approval roles
- Natural-language configuration editing
- Drag-and-drop layout editing
- Arbitrary uploaded fonts or artwork
- Multiple text fields, subtitles, icons, or images
- Smart and Standard positions mixed within one order/sheet
- Order-QR-only clean-face connected products
- Hidden identities, NFC, or alternate QR types
- Automatic vendor URL fetching or price/order integration
- Shopify product creation
- Repository edits, patches, Git, pull requests, commits, or deployment
- Firestore or QRService allocation calls
- Customer/order data
- Physical-test evidence upload or automated production certification

## 4. Architecture and ownership

### 4.1 PlaceWellPdfGenerator owns

- Canonical SKU schema and typed models
- SheetLabels PDF security inspection
- Vector geometry extraction
- Geometry normalization and tolerance rules
- Deterministic recommendation policy
- Production name fitting
- Smart/Standard and named/blank render behavior
- QR calculations and vector rendering
- Layout zones, frames, separators, and writable blank treatment
- Machine validation
- Production render plans
- Proof PDFs and raster previews
- Fit/QR/layout metrics
- Canonical SKU JSON
- Bundle README, manifest, checksums, and project-action manifest
- CLI/module façade

### 4.2 PlaceWellUI owns

- Authenticated portal entry
- Strict same-origin validation for state-changing requests
- Wizard pages and browser state
- Safe upload limits
- Temporary workspace lifecycle
- Calling the PdfGenerator compiler façade
- Displaying the extracted rows, columns, and labels-per-sheet count
- Guided controls and Advanced Settings
- Preview/artifact delivery
- Regenerate and Reset to Recommendation
- Final ZIP streaming
- Cleanup

### 4.3 Shared boundary

PlaceWellUI imports only public PdfGenerator compiler APIs and typed models. It
must not recalculate:

- Geometry
- Capacity
- Font fitting
- Safe zones
- QR module size
- Frame/separator bounds
- Recommendations
- Validation results

## 5. Current implementation gaps

### 5.1 Configuration

Current PdfGenerator behavior is split between:

- Active `placewell_generator/config/` package
- Dead/shadowed `placewell_generator/config.py`

The dead module contains stale, incompatible defaults and must be removed
after a compatibility search.

Current physical templates are hardcoded in:

`placewell_generator/config/sheet_templates.py`

Each dictionary combines geometry, capacity, typography, frame, and separator
values without schema version, source provenance, product mode, or lifecycle.

### 5.2 Typography

Current behavior:

```python
base_size = template["base_font_size_pt"] * style_scale
```

The renderer starts at that configured base and only shrinks. It does not grow
text to use a larger label.

Existing rectangle sizing copied to SL522 therefore remains 11.5 pt and is too
small. The current renderer can also produce more than two lines and shrink to
5 pt.

### 5.3 QR

Current QR settings are global:

- 0.5-inch footprint
- ECC M
- Two-module quiet zone
- Vector DeviceCMYK 0/0/0/100

PlaceWellUI currently records `qr_size_in`, but the cell renderer ignores it.

### 5.4 Blank and Standard behavior

Current `render_cell()`:

- Blank without QR: renders nothing.
- Blank with QR: frame/separator/QR but no writable treatment.
- Named label: always reserves and renders separator/QR.

Current validator requires every item to have an HTTPS `qr_url`. Standard
labels and Standard writable blanks cannot validate or render.

### 5.5 Layout geometry

Current layout derives rows/columns with binary floating-point floor math and
does not assert derived capacity against declared capacity.

Raw SL522 PDF coordinates produce approximately `1.9999999999999996` columns,
which floors to one. The compiler must preserve explicit official cell boxes,
use decimal/rational normalization, and validate capacity directly.

### 5.6 Existing working-tree baseline

At specification time, PdfGenerator and PlaceWellUI have pre-existing
uncommitted work, including font/style and portal/import changes.

Before implementation:

1. Identify the authoritative deployed/approved revision.
2. Separate and commit or explicitly reject existing unrelated work.
3. Capture legacy rendering goldens from a clean, tagged baseline.
4. Do not mix compiler refactoring with unapproved legacy visual changes.

## 6. Operator workflow

```text
1. Open SKU Template Compiler from PlaceWellUI portal
2. Upload one official SheetLabels PDF
3. Tool extracts and validates geometry
4. Operator confirms only the parsed rows x columns = labels-per-sheet count
5. Operator completes product fields
6. Tool computes Smart and Standard recommendations together
7. PdfGenerator immediately creates cautious default artifacts and Smart/Standard sample crops
8. Review mode offers Accept and Download Bundle or Request Revision
9. Revision mode shows Advanced Settings beside the sticky generator mock
10. Preview Your Changes performs a lightweight sample-only PdfGenerator render
11. Generate Revised Artifacts runs complete validation and returns to Review
12. Repeat revision or accept the latest full artifact set
13. Tool returns the complete ZIP response
14. Browser receives the ZIP, then explicitly deletes the workspace
```

No configuration persists after expiry/download. If the explicit post-download
DELETE fails, bounded TTL cleanup remains the fallback. Refresh intentionally
loses the wizard state.

## 7. Operator inputs

### 7.1 Required upload

| Field | Rule |
|---|---|
| Official SheetLabels PDF | One PDF, one page, maximum 10 MiB |

### 7.2 Identity and product fields

| Field | Rule |
|---|---|
| Internal PlaceWell SKU | Suggested by tool; editable; unique lowercase kebab-case; 3-64 characters |
| Display name | 3-100 characters |
| Vendor template ID | `SL` followed by digits |
| Official product URL | HTTPS SheetLabels URL; recorded but never fetched |
| Product category | Existing approved PlaceWell category/custom value |
| Default named-label count | 1 through extracted sheet capacity |
| Target reading distance | Supported bounded values, initially 2/4/6/8 feet |
| Target QR scan distance | Applies to the required Smart profile |
| Enabled font styles | Registered PlaceWell fonts only |
| Enabled colors | Approved PlaceWell palette only |
| Stress-test names | Fixed compiler corpus plus optional operator additions |

Material code is not a compiler input.

### 7.3 Fixed stress corpus

At minimum:

```text
TOOLS
WINTER CLOTHES
HOLIDAY DECORATIONS
CHRISTMAS TREE DECORATIONS
CHILDRENS WINTER CLOTHING
GARAGE SPORTS EQUIPMENT
```

No customer names or production-order data may be submitted.

## 8. Locked extracted fields

The operator confirms but cannot edit:

- Vendor: SheetLabels
- Source SHA-256
- US Letter page size
- Page rotation/orientation
- Label width and height
- Label orientation
- Shape and extracted corner radius
- Cell bounding boxes
- Rows and columns
- Capacity
- Margins and gaps
- Position order
- Vendor template ID after extraction/confirmation
- No content rotation
- No outer die-line frame
- Actual Size / 100 percent requirement

Changing geometry requires a new official PDF upload.

## 9. Product-mode and blank behavior

Exactly the extracted capacity is rendered. Named positions come first;
remaining positions are writable framed blanks.

| Label type | Named position | Remaining blank |
|---|---|---|
| Smart | Name + individual QR | Writable frame + individual QR |
| Standard | Name, no QR | Writable frame, no QR |

Rules:

- No unused position.
- No print-nothing state.
- Smart QR data is mandatory.
- Standard QR data is forbidden.
- Standard name layout uses the larger no-QR safe area.
- Standard separator defaults off and may not imply a QR zone.
- Order QR metadata never consumes a physical label position.

Compiler proofs use synthetic non-production QR payloads. The compiler never
calls PlaceWellQRService.

## 10. Guided customization

Version 1 presents simple intent-based controls:

- Text too small / too large
- Reduce / increase letter spacing
- Long names wrap poorly
- QR too small / too large (Smart only)
- Move name up / down
- Move QR up / down (Smart only)
- Frame lighter / heavier
- Separator on / off (Smart only)
- Change default font/color
- Reset to Recommendation
- Preview Changes after artifacts reveal a concrete issue

Each control maps to bounded production configuration fields. Configuration
changes mark the preview stale and disable bundle download until regeneration.

## 11. Advanced Settings

Advanced Settings remain collapsed until Request Revision. Revision mode uses
a desktop two-column layout with settings on the left and a sticky
PdfGenerator-rendered mock on the right; narrow screens stack vertically.
Clicking a mock region scrolls to and highlights its primary control. Profile
and font changes preserve the accumulated draft.

All operator-facing floating-point values display at most two decimal places.
The accumulated draft may contain edits for multiple fonts. Preview Your
Changes uses a lightweight PdfGenerator operation to update sample crops and
fit metrics only. It never replaces full artifacts or makes the draft
bundle-eligible. Generate Revised Artifacts performs complete validation and
atomically replaces the Review Pack, Actual Size proofs, configuration, and
artifact baseline.

Sample label text is limited to 100 characters and is never canonical runtime
data. PdfGenerator includes it as additional proof evidence for every enabled
font and returns exact resolved lines, size, utilization, overflow status, and
Smart/Standard label crops.

Typography, name-zone, and frame adjustments are shared across Smart and
Standard. Their recommended defaults also use one conservative
Smart-constrained profile so both modes remain identical and bundle-valid.
QR and separator adjustments are Smart-only.

### Typography

- Template base font size
- Per-style font scale
- Per-style letter spacing
- Minimum font size
- Maximum lines: 1-3; the fitter uses a third line only when needed
- Line-spacing multiplier
- Name-zone horizontal/vertical padding
- Case behavior: style default or preserve

### Writable frame

- Frame inset
- Frame line weight
- Inner corner radius
- Writing-zone padding

Blank labels use an open framed writing area with no horizontal writing
guides. The writable frame cannot be disabled.

### Smart QR

- QR footprint within compiler-approved bounds
- Recommendation uses a production-shaped PlaceWell scan URL and selects the
  largest two-to-four-module quiet zone that still meets the configured
  distance's physical module-size floor.
- Name-to-QR clearance
- QR position within fixed orientation
- Separator enabled
- Separator width/weight

Locked:

- ECC M
- Vector modules
- K-only CMYK foreground
- White background/quiet zone
- No logo inside QR

## 12. Browser/workspace state

Recommended states:

```text
empty
uploading
extracted
confirmed
recommending
recommended
previewing
preview_ready
dirty
finalizing
downloaded
```

Rules:

- Browser owns current draft JSON.
- Draft typography edits are retained per font while shared layout/frame and
  Smart-only QR/separator edits remain accumulated across selector changes.
- Server stores only short-lived uploaded/generated artifacts.
- No localStorage or IndexedDB.
- No revision/history list.
- No side-by-side comparison.
- No server database.
- Refresh/server restart invalidates the workspace.
- Missing/expired workspace responses clear stale browser state and explain
  that the official template must be re-uploaded.
- The UI states the 30-minute idle and 2-hour maximum workspace lifetime.
- A configuration hash binds preview, metrics, and bundle.
- The successfully previewed font style IDs are part of bundle freshness.
- Editing after preview returns the wizard to `dirty`.
- Finalize with a stale hash fails with HTTP 409.

## 13. PlaceWellUI routes and files

### Routes

| Method | Route | Purpose |
|---|---|---|
| GET | `/sku-template-compiler` | Authenticated wizard shell |
| POST | `/api/sku-template-compiler/extract` | Upload/extract official PDF |
| POST | `/api/sku-template-compiler/recommend` | Compute one recommendation |
| POST | `/api/sku-template-compiler/preview-sample` | Render lightweight authoritative sample crops |
| POST | `/api/sku-template-compiler/preview` | Validate/regenerate current config |
| GET | `/api/sku-template-compiler/artifacts/{workspace_id}/{artifact_token}` | Serve allowlisted preview artifact |
| POST | `/api/sku-template-compiler/bundle` | Revalidate and return complete ZIP body |
| DELETE | `/api/sku-template-compiler/workspaces/{workspace_id}` | Reset/cleanup |

### Existing files changed

| File | Change |
|---|---|
| `app/main.py` | Include compiler router only |
| `app/templates/portal.html` | Add active compiler card without overwriting existing portal work |
| `app/config.py` | Workspace root, limits, TTL, concurrency, allowed-Origin config |
| `app/auth.py` | Reuse explicit auth dependency on every compiler route |
| `app/static/style.css` | Add namespaced compiler styles |
| Deployment requirements/config | Add runtime directory and dependency installation |

Do not implement compiler code in the existing large `form.html` or reuse the
current persistent PDF download route.

### New files

```text
app/sku_compiler_routes.py
app/sku_compiler_service.py
app/compiler_workspace.py
app/templates/sku_template_compiler.html
app/static/sku_template_compiler.js
tests/test_sku_compiler_routes.py
tests/test_sku_compiler_upload_security.py
tests/test_sku_compiler_bundle.py
tests/js/sku_template_compiler.test.mjs
```

## 14. PdfGenerator package design

Recommended new package:

```text
placewell_generator/
  schemas/placewell-sku-template-v1.schema.json
  schemas/placewell-dual-mode-sku-v1.schema.json
  sku/
    __init__.py
    models.py
    errors.py
    extractor.py
    normalizer.py
    recommender.py
    compiler.py
    validator.py
    render_plan.py
    metrics.py
    proofs.py
    bundle.py
    service.py
    cli.py
  skus/
    round-1.5.json
    rect-portrait.json
    square-1.75.json
```

Retain legacy `generate_pdf()` and `generate_pdfs()` wrappers during migration.

### Public façade

```python
extract_sheetlabels_template(pdf_bytes, source_metadata) -> ExtractionResult
recommend_dual_mode_definition(request) -> DualModeRecommendationResponse
apply_template_adjustments(profile, recommendation, adjustments) -> SkuTemplate
render_template_preview(request) -> PreviewResponse
build_dual_mode_bundle(request) -> BundleResponse
get_compiler_capabilities() -> CompilerCapabilities
```

`recommend_template()` and `build_template_bundle()` remain internal/legacy
single-profile tools. Production registration and CLI bundle output require
the aggregate dual-mode definition.

## 15. Canonical SKU schema

Root structure:

```json
{
  "$schema": "placewell-dual-mode-sku-v1.schema.json",
  "schema_version": "1.0",
  "identity": {},
  "source": {},
  "geometry": {},
  "supported_modes": ["smart", "standard"],
  "profiles": {
    "smart": {},
    "standard": {}
  },
  "compiler": {}
}
```

### Identity

```json
{
  "internal_sku": "large-box-4x5",
  "display_name": "Large Box Label 4x5",
  "category": "storage",
  "default_named_count": 4
}
```

No material code.

### Source

```json
{
  "vendor": "SheetLabels.com",
  "vendor_template_id": "SL522",
  "official_product_url": "https://...",
  "source_filename": "SL522_Official_Template.pdf",
  "source_sha256": "...",
  "retrieved_at_utc": "2026-10-30T14:42:18Z",
  "page_count": 1,
  "extraction_profile": "sheetlabels-vector-v1"
}
```

The SHA-256 is derived automatically. It proves which exact source PDF created
the bundle and supports reproducibility/change detection.

### Geometry

Canonical units are PDF points. Store:

- Page MediaBox/CropBox
- Rotation
- Label width/height/shape/corner radius
- Exact cell boxes
- X and top-origin Y arrays
- Rows/columns/capacity
- Margins/gaps
- Raw extraction hash
- Recorded normalization calculations

Explicit cell boxes are authoritative. Do not derive capacity with floored
binary floats.

### Product profiles

The canonical definition requires exactly two profiles, `smart` and
`standard`. Each profile contains its own physical targets, typography,
resolved layout zones, QR policy, frame, separator, stress validation, and
configuration hash. Identity, source, geometry, enabled fonts/colors, and
default named count must match across profiles.

### Typography

Per style:

- Font ID and packaged font file
- Case transform
- Base size
- Minimum size
- Scale
- Letter spacing
- Maximum lines
- Line spacing
- Overflow policy
- Approved colors

V1 overflow policy is error/warning for operator adjustment, not silent tiny
text or uncontrolled truncation.

### Layout zones

Store label-relative point boxes:

- Safe bounds
- Named text zone
- Writable blank zone
- QR zone for Smart
- Separator bounds
- Die-edge clearance

### QR

Smart configuration:

- Enabled
- Footprint
- Quiet-zone modules
- ECC M
- K-only vector foreground
- White background
- URL policy

Standard:

```json
{"enabled": false}
```

### Compiler metadata

- Compiler version
- Schema version
- Renderer algorithm version
- Recommendation policy version
- Dependency versions
- Source/configuration hashes
- UTC generation time

No UI revision history belongs in canonical SKU JSON.

## 16. SheetLabels extraction and normalization

### Accepted source

- `%PDF-` file
- Exactly one page
- US Letter 612 x 792 points within tolerance
- Rotation 0
- Unencrypted
- Vector die paths
- No JavaScript, launch/open actions, embedded files, AcroForm, or XFA

### Extraction

1. Hash original bytes.
2. Security-preflight PDF structure.
3. Enumerate closed stroked vector paths.
4. Exclude page border, footer text, and singleton decoration.
5. Cluster congruent repeated die boxes.
6. Cluster X and top-origin Y positions.
7. Sort row-major.
8. Derive rows/columns/capacity/margins/gaps.
9. Validate bounds/non-overlap/uniformity.
10. Preserve raw coordinates.
11. Normalize only within strict tolerance and record every adjustment.

### Tolerances

- Page size: 0.1 point
- Coordinate clustering: 0.05 point
- Uniform size: max 0.05 point or 0.01 percent
- Grid closure: 0.1 point
- Rational snap increment: 1/32 inch (2.25 points)
- Rational snap tolerance: 0.05 point

SL522 normalization:

- Raw left margin 11.232 -> 11.25 points
- Raw gap 13.518 -> 13.5 points
- Explicit origins become 11.25 and 312.75 points

Capacity derives from extracted die boxes/origin clusters, not floor division.

## 17. Deterministic recommendation

Same inputs, source bytes, compiler version, and policy version must yield the
same canonical JSON, metrics, and visual content.

Recommendation flow:

```text
extract geometry
resolve reading/scan targets
load registered font capabilities
calculate Smart safe/QR zones and Standard no-QR zones
fit fixed stress corpus through both production profiles
select largest valid settings within each profile's physical floors
materialize one aggregate recommendation
validate both profiles and their aggregate hash
render both production-proof families
collect metrics
```

No alternate/proof-only text fitter, QR renderer, or layout engine may exist.
Order generation and proofs consume the same `RenderPlan`.

## 18. Rendering matrix

| Type | Variant | Rendering |
|---|---|---|
| Smart | Named | Background, configured inner frame, name, optional separator, vector QR |
| Smart | Blank | Background, mandatory writable frame/lines, vector QR |
| Standard | Named | Background, configured inner frame, name using no-QR safe zone |
| Standard | Blank | Background, mandatory writable frame/lines, no QR |

Rules:

- Render exactly capacity positions.
- Named first, blanks after.
- No omitted positions.
- No content rotation.
- No outer die-line frame.
- Standard QR fields are errors.
- Missing Smart QR fields are errors.
- Proof QR data is deterministic and synthetic.

## 19. Proofs and metrics

### Proofs

- The dashboard presents one annotated Complete Review Pack first.
- A cover/index and Smart/Standard section dividers make the sequence explicit.
- Every review page identifies only its Smart/Standard profile, clear proof
  purpose, PlaceWell font name, color name/swatch, readable operator-local
  timestamp, and one concise inspection instruction.
- The review pack embeds content-only, official-dieline, typography/stress,
  writable-blank, and Smart QR-size proofs without changing their renderers.
- The sequence is cover/index; Smart full-sheet, dieline, blank, and selected
  QR candidates; Standard full-sheet, dieline, and blank; then one shared
  representative typography page per enabled font.
- Separate clean Smart and Standard Actual Size PDFs remain available for
  physical printing; annotations never contaminate production artwork.
- The pack shows one representative typography page per enabled font and only
  decision-useful QR candidates. PdfGenerator machine-validates the complete
  stress corpus before bundling; detailed intermediate proof files and raster
  previews are intentionally not packaged.

### Metrics

Per style/name/position:

- Requested and final point size
- Line count and rendered lines
- Text bounding box
- Width/height utilization
- Minimum die clearance
- Overflow/truncation status
- QR version/module count/module physical size
- Quiet-zone size
- QR/frame/separator bounds
- Position index/coordinates
- Aggregate worst case
- Warnings/errors

The dashboard gives each aggregate metric a readable label, formatted value,
and explanation. Metrics do not prove physical scan/readability.

## 20. Generate/regenerate workflow

Version 1 has no history.

1. Recommendation automatically generates the cautious default artifact set.
2. Operator reviews the Review Pack, Actual Size proofs, and generated sample.
3. Accept immediately, or enter Revision mode.
4. Draft edits leave the current full artifacts unchanged.
5. Preview Your Changes updates only the sample mock and fit metrics.
6. Generate Revised Artifacts performs complete validation and returns to Review.
7. Accept the latest full artifact set or request another revision.

The browser supplies its current UTC offset, which is preserved as a fixed
offset for that generation. The Review Pack visibly records a readable
operator-local timestamp without seconds or milliseconds on every annotated
page. Clean Actual Size proof filenames and PDF metadata include the same
timestamp without printing it onto label stock. Technical manifests retain UTC
ISO time.

## 21. Bundle contract

Example filename:

```text
large-box-4x5_2026-10-30_09-42-18_CDT.zip
```

Contents:

```text
README.md
manifest.json
generated/PlaceWellPdfGenerator/<internal-sku>.json
proofs/<sku>-review-pack.pdf
proofs/<sku>-smart-actual-size.pdf
proofs/<sku>-standard-actual-size.pdf
checklists/physical-print-scan.md
```

### README requirements

README records:

- Internal SKU and high-level machine-validation status
- Geometry rows, columns, and capacity
- Smart/Standard validation status
- Source template ID and shortened fingerprint
- Physical qualification status
- Numbered proof review, copy, test, deploy, verify, and rollback steps
- Exact complete JSON source and destination paths
- Runtime registry discovery behavior
- Minimal bundle contents and roles

### manifest.json

Include:

- Bundle schema/version
- Local and UTC times
- Source/config/profile hashes
- High-level machine-validation and physical-qualification status
- Each member path, MIME type, size, SHA-256, and role

No secrets, environment values, credentials, customer data, absolute server
paths, or real QR identities.

## 22. Installation behavior

The bundle contains one complete runtime file:

```text
generated/PlaceWellPdfGenerator/<internal-sku>.json
```

Copy the whole file into `placewell_generator/skus`; never merge its contents
into registry code or another SKU. Existing generic registry and renderer tests
cover discovered canonical definitions, so the bundle does not generate tests
or project-change manifests. The UI, QR Service, App, and Shopify receive no
bundle files.

The one-time UI order-flow branch discovers PdfGenerator production
capabilities, bypasses QR allocation for Standard SKUs, and allocates every
physical position for canonical Smart SKUs. Future Smart and Standard SKUs
are therefore configuration-driven.

## 23. Existing SKU migration

Migrate:

- `round-1.5`
- `rect-portrait`
- `square-1.75`

Process:

1. Freeze/tag authoritative production baseline.
2. Generate immutable legacy-approved canonical JSON.
3. Preserve every effective geometry/style/QR/frame value.
4. Keep legacy order JSON adapter and filenames.
5. Capture semantic and visual goldens.
6. Route one existing SKU at a time through new render plans.
7. Require equivalence before cutover.

Regression matrix:

- Every current SKU/style
- Short/medium/long/multiword names
- Case-sensitive and long unbroken names
- Named Smart label
- Smart blank
- Capacity -1 / exact / +1
- First/last position
- Overflow sheet
- Order QR exclusion
- Frame/ring behavior
- CMYK QR stream
- Manifest and filenames

Compare render-plan JSON, cell coordinates, QR matrix hash, text placement, page
counts, and approved raster thresholds.

## 24. Security and temporary storage

- Parse uploads offline; never fetch operator URLs.
- Hash before parsing.
- Max 10 MiB; one PDF/page.
- Reject encryption, scripts/actions, attachments, forms, external references.
- Use pinned `pikepdf` for preflight and PyMuPDF for vector extraction/overlay.
- Only registered fonts.
- Strict SKU and output filename patterns.
- Random workspace IDs and fixed artifact tokens.
- Workspace directory mode 0700; files 0600; umask 077.
- No user paths in storage/ZIP.
- Prevent traversal and ZIP slip.
- Compiler routes require explicit operator auth.
- State-changing routes require Apache Basic Auth and strict Origin checks.
- Original upload is never served inline.
- No PDF/request bodies in logs.
- Cleanup after download/reset/failure, 30-minute idle, two-hour maximum.

## 25. Testing

### PdfGenerator

- Schema required/forbidden fields
- Smart/Standard matrix
- SKU validation
- Source/hash validation
- Geometry extraction and tolerance
- Capacity invariant and SL522 float regression
- Font fit, line limit, floor, overflow
- QR metrics and K-only stream
- Named/blank render matrix
- Proof/overlay generation
- Bundle exact members/hashes/README
- Deterministic recompilation
- Filename/path safety
- Legacy golden equivalence

Fixtures:

- Hash-pinned internal official SL573/SL522 PDFs, subject to redistribution
  policy
- Synthetic vector fixtures with same geometry for committed tests
- Negative encrypted/multipage/raster/rotated/ambiguous/overlap cases

### PlaceWellUI

- Authentication on every route and Origin checks on state changes
- Portal card
- Upload size/type/security
- Extract/recommend/preview/bundle lifecycle
- Smart/Standard conditional controls
- Dirty/stale preview behavior
- Reset to recommendation
- Workspace expiry/cleanup
- Artifact-token containment
- Complete bundle-body delivery followed by explicit browser DELETE; failed
  finalization or interrupted receipt preserves the workspace for retry
- JavaScript state/serialization tests using Node `node:test`
- Full SL573/SL522 Smart/Standard integration tests

## 26. Deployment and rollback

PlaceWellUI currently bundles PdfGenerator. Continue deploying compatible
versions together.

Required deployment improvements:

- Install both UI and PdfGenerator requirements explicitly.
- Pin/test compiler dependencies.
- Create restricted compiler runtime directory.
- Configure upload/workspace/concurrency/time limits.
- Apply Apache request-size limit.
- Keep artifacts behind authenticated FastAPI routes.
- Prefer versioned release directories and a `current` symlink.

No database migration is required.

Rollback:

1. Disable compiler portal/route.
2. Point UI/PdfGenerator to prior release.
3. Verify health and existing order generation.
4. Delete temporary workspaces.
5. Existing downloaded bundles remain operator-owned.

Retain legacy `generate_pdf()` / `generate_pdfs()` until migration equivalence
is proven.

## 27. Implementation phases

### Phase 0 - baseline and repository hygiene

- Resolve existing dirty working trees.
- Identify deployed revision.
- Capture/tag existing production output.
- Freeze legacy goldens.

### Phase 1 - canonical domain/schema

- Remove dead config module after compatibility search.
- Add typed schema/models/errors.
- Add legacy-approved JSON for current SKUs.
- Add compatibility loader/facade.

### Phase 2 - SheetLabels extraction

- Security preflight.
- Vector extraction.
- Exact cell boxes.
- Decimal normalization/tolerance.
- SL573/SL522 fixtures and negative cases.

### Phase 3 - production render plans

- Pure render-plan model.
- Smart/Standard named/blank matrix.
- Writable framed blanks.
- Per-SKU/per-style typography and QR policy.
- Structured metrics.

### Phase 4 - renderer integration

- Make order rendering and proofs consume same plan.
- Lazy font loading.
- Deterministic clock/PDF metadata.
- Atomic output and sanitized filenames.

### Phase 5 - recommendation/proofs/bundle

- Deterministic recommendation.
- Guided-adjustment inputs.
- Proofs/overlays/previews.
- README/manifest/change bundle.
- Compiler CLI/façade.

### Phase 6 - PlaceWellUI dashboard

- Authenticated portal card/router.
- Upload/workspace/Origin enforcement.
- Wizard and controls.
- Preview delivery.
- Complete ZIP delivery followed by explicit workspace cleanup.

### Phase 7 - existing SKU migration

- Regression/golden comparison.
- Cut over one SKU at a time.
- Preserve rollback path.

### Phase 8 - production-order discovery

- Make PlaceWellUI order forms discover canonical generator capabilities.
- Remove duplicate UI physical-template registry.
- Enable generic Smart and Standard production branches.

## 28. Acceptance criteria

Version 1 is complete when:

1. SL573 and SL522 official PDFs extract deterministically.
2. SL522 normalized geometry derives exactly 2 x 2 / four labels.
3. Smart and Standard named/blank proofs use production renderer only.
4. All remaining positions are writable framed blanks.
5. No Standard proof contains QR modules.
6. Every Smart proof uses vector K-only QR.
7. Same input/config/version yields equivalent canonical content and metrics.
8. Existing production SKUs pass approved regression goldens.
9. UI duplicates no compiler calculation.
10. Regenerate invalidates stale preview/bundle.
11. Exported README includes local/UTC timestamps, inputs, calculations,
    adjustments, outputs, metrics, validation, and comparison instructions.
12. Change manifest lists exact project/file/action/test/deploy/rollback steps.
13. No repository, Git, QRService, Firestore, Shopify, or deployment action is
    performed.
14. Upload/artifact routes pass security tests.
15. Temporary workspaces are cleaned.
16. Unit and integration suites pass.
17. Physical qualification checklist is included and clearly remains manual.
*** End of File
