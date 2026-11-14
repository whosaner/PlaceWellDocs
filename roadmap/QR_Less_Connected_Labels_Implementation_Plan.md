# QR-Less Connected Labels - Implementation Plan

Date: 2026-11-11

Status: Service, PDF, operator UI/compiler, and Shopify parser deployed to Linode
on 2026-11-11. Shopify theme `167591018582` was published on 2026-11-12,
including the approved smart-label copy and weatherproof messaging.
Remaining product phases require owner approval.

Release: `plain-qr-20261112T004130Z` (UTC). Server rollback archives are under
`/opt/placewell-release-backups/plain-qr-20261112T004130Z`. UI/QR health, live
mode contracts, and both public preview layouts were verified without allocating
test orders. Customer/physical testing and full mixed-order fulfillment remain pending.

### First component: QR service

Owner-approved naming is `plain` (default) and `qr`, replacing the proposed
customer-facing Smart/Standard distinction. QR service support is implemented
and deployed to Linode on 2026-11-11:

- Allocation accepts request-level `label_mode` and persists it on every named,
  blank, Order QR, and order record.
- Allocation, individual lookup, and order-item responses expose the mode.
- Both modes preserve existing identities, signed URLs, and issued metadata.
- Older records without the field read as `qr`; new omitted values use `plain`.
- Matching operator UI now explicitly sends `plain`/`qr` to registration and
  production. Deploy the three matching components together.

### Second component: PDF generator prerequisite

Implemented after owner approval; deployed to Linode on 2026-11-11:

- Explicit `plain` and `qr` production orders reuse the Standard and Smart print
  profiles, respectively.
- Plain named labels have no individual QR or QR-separator underline. Writable
  blank treatment is unchanged.
- Both new modes require one allocated Order QR on the manifest, outside
  physical sheet capacity. Plain item URLs may be absent or retained internally.
- Plain manifest copy explains optional app use, Home/Search retrieval, card
  retention, and metadata-only re-import.
- Canonical preflight/profile lookup accepts the new mode names.
- Existing `smart`/`standard` inputs and omitted generator mode retain their
  behavior; compiler schemas, registry advertisements, and previews are unchanged.
- Generated legacy and canonical sheets match their existing print profiles.
  Physical print/scan approval remains outstanding.

### Third component: operator UI integration

Implemented after owner approval; deployed to Linode on 2026-11-11:

- Spice and Storage forms default to Plain and offer QR as the alternative.
- Both modes preserve metadata and allocate named labels, included blanks, and
  one non-printing Order QR; canonical orders fill all physical positions.
- Allocation and PDF generation receive the explicit selected mode. Missing or
  mismatched allocation mode confirmation fails visibly.
- QR-size controls apply only to QR legacy profiles.
- Form capability mapping does not mutate the generator registry. Shopify
  previews/configuration and compiler profile names remain unchanged.

App alignment, full Shopify fulfillment, media, and physical sign-off remain pending.

### Fourth component: SKU compiler alignment

Implemented after owner approval; deployed to Linode on 2026-11-11:

- Compiler controls, rationale, review packs, proof filenames, and bundle
  instructions use Plain/QR wording. Preview and reset defaults are Plain.
- Both profiles are still generated and validated; QR/separator controls remain
  available only in the QR profile.
- Internal compiler API and runtime JSON retain `standard`/`smart` keys. No SKU
  schema migration, allocation, or Firestore writes are introduced.

### Fifth component: Shopify parser and review alignment

Implemented after owner approval; deployed to Linode on 2026-11-11:

- The review-only importer accepts `plain`/`qr` and normalizes explicit older
  `standard`/`smart` values without changing their physical-layout meaning.
- Missing modes default to Plain with an operator-review warning. Order mode
  consistency is checked after normalization.
- The review page shows Plain/QR; exact names, casing, sheet composition, and
  production-approval checks are preserved.
- The shared storefront preview boundary maps normalized modes to existing
  renderer profiles, without allocation or Firestore access.
- The Shopify theme and the reviewed-import-to-production handoff are not
  changed in this component.

### Sixth component: Shopify theme mode alignment

Implemented after owner approval; pushed to QA theme `167591018582`
on 2026-11-11 and published by the owner on 2026-11-12:

- Round, Rectangle, and Square templates explicitly select Plain. Liquid
  defaults and the merchant-only mode setting use `plain`/`qr`.
- Preview requests and version-4 cart configurations carry the explicit mode.
- Compatible older merchant/cart values retain their physical meaning.
  Mismatched and unidentified cart layouts are blocked with visible guidance,
  rather than silently converted.
- Product-page source copy explains QR-free labels and optional app setup
  through the Order QR, without a customer mode choice.
- Product titles and collection copy advertise Weatherproof Smart Spice Labels.
- Shopify-hosted descriptions/media, browser/variant QA, full fulfillment,
  and physical product approval remain separate gates.

### Seventh component: single-line-item Shopify production handoff

Owner approved the small single-line-item scope on 2026-11-12. Implemented and
deployed to Linode with the matching PDF generator. Release backup:
`/opt/placewell-release-backups/shopify-handoff-20261113T020106Z`.
Deployed source hashes, UI health, the sample, and non-mutating single/multiple
review behavior were verified without allocating a test order.

- Review remains non-mutating. One approved configuration exposes an explicit
  Confirm & Generate PDFs action with purchased quantity and operator confirmation.
- Production revalidates the submitted configuration and preserves exact names,
  casing, styles, colors, complete sheets, blanks, and Plain/QR mode.
- A generator opt-in preserves imported physical positions without changing
  legacy manual-order sorting. Quantity repeats complete sheet sets.
- One registration and manifest Order QR cover the resulting order. The current
  single-batch handoff is limited to 498 physical labels.
- A persistent production record blocks duplicate generation and retains the
  allocated order before rendering. Automatic retry/reprint, multi-line-item
  production, and the Order History screen remain deferred.
- A synthetic configuration is linked from the operator importer; explicitly
  generating it creates real Firestore records, while reviewing does not.

## 1. Product and architecture foundation

Offer one customer-facing product: physical labels without individual printed
QR codes, with optional PlaceWell app use included through an Order QR.

The initial implementation should combine the existing QR-free Standard print
profiles with the existing connected order registration and bulk-import flow.
Do not equate QR-free printing with absence of a digital record.

Recommended architecture:

- Retain stable issued IDs and metadata for named labels and writable blanks.
- Retain an order record and one functional signed Order QR per fulfillment
  order, covering its actual purchased contents.
- Keep current per-label Firestore records and app-compatible IDs initially.
  Moving items into a new collection or embedded order schema is not required.
- Separate order connectivity from print layout in the application contracts.
  The service uses `label_mode: plain | qr`, defaulting to `plain`, for the
  physical-label distinction. PDF production now accepts those explicit values;
  internal compiler profiles retain `standard | smart`; operator selectors and
  new Shopify configurations use `plain | qr`. Registration is explicit
  through the allocation call; do not make QR-free rendering skip that call.
  A separate connectivity field is not needed for this first component.
- Use the QR-free print profile for the new product. Individual QR layouts may
  remain internally available, but are not a customer-facing purchase choice.
- Existing signed per-item URLs can remain internal allocation artifacts in
  the first release. Their removal is not a prerequisite for this pivot.
- Keep personal names, photos, contents, locations, and freshness edits local
  to the device. Order re-import is not personal-data backup or cloud sync.

No existing customer migration is required according to the owner. Do not
delete development data or remove existing routes as part of this work.

Approval gate: agree on this product and architecture before implementation.

## 2. Decisions to resolve one at a time

Resolve each decision separately before implementing its dependent phase.

1. Approve the product and architecture in section 1.
2. Writable-blank import is owner-approved: include every blank in Order QR
   setup as an editable `Blank1` through `BlankN` entry using its issued ID.
   These app-only names do not change the physical printed label. This replaces
   the earlier recommendation for a separate delayed activation entry point.
3. Approve the app's primary navigation action. Recommendation: keep an
   explicitly labeled Order QR import action and emphasize Home/search for
   everyday retrieval. Do not imply that the camera recognizes label text.
4. Plain named labels have no individual QR and no QR-separator underline
   (owner-approved 2026-11-11). Remaining design approval covers name placement,
   typography, frames, and blank treatment for each launch SKU. Writable-blank
   frames or writing guides are independent of the removed QR separator.
5. Approve the Order QR delivery/recovery approach. Recommendation: a durable
   keep-card/insert plus an operator-supported way to resend the same import
   link. A customer portal or automated email integration is separate scope.

Numbering uses the complete fixed issued blank set, before local duplicate
filtering, ordered by immutable item ID with issued label ID as fallback and
tie-break. No local order-history or separate blank-activation UI is required.

## 3. Shared contracts and order integrity

Before feature edits, define representative payloads for connected QR-free
Spice and Storage orders, including duplicate names, blanks, multiple sheets,
and multiple Shopify line items.

Required invariants:

- Print layout, product family, and order connectivity are independent.
- Each physical named label and blank has a stable digital ID.
- Physical-label counts exclude the Order QR.
- The Order QR resolves to the exact fulfilled item set, including purchased
  quantities and all supported line items.
- Printed names and customer-editable names remain distinct.
- Category, SKU, artwork key, and freshness metadata survive registration and
  import unchanged, with the existing Spice/Storage boundaries preserved.
- Customer previews never register orders or allocate identities.
- Reprinting or retrying the same fulfillment does not issue a different set of
  digital IDs. Use a persistent allocation result and an order/input
  fingerprint; reject conflicting reuse rather than silently overwrite it.
- If PDF generation fails after registration, retry rendering against the
  existing allocation. Do not allocate a replacement set on each attempt.
- Retain existing allocation authorization, signed Order QR validation, and
  lookup protections. An ordinary Shopify order number is not an import token.

Define new-request defaults explicitly. Do not globally reinterpret every
historical `standard` payload as connected. Handle existing development carts
by explicit configuration version/routing rules.

Deliverable: agreed payload examples and focused contract tests in the
existing project test suites, not a new contract-management service.

## 4. Backend production path

Dependencies: sections 1 and 3 approved.

### PlaceWellQRService

- Extend registration metadata with the agreed connectivity distinction.
- Reuse stable IDs, issued item metadata, the order association, and signed
  Order QR resolution.
- Add safe allocation retry/reuse behavior and mismatch reporting.
- Keep order responses compatible with app bulk import; expose any order or
  connectivity fields needed for blank activation and app messaging.
- Distinguish item records from an Order QR in counts/reporting. Do not present
  unused individual scan counters as the new product's engagement measure.
- Preserve issued data for delayed activation and define recovery/retention
  expectations. Confirm backups and a recovery procedure before customer
  allocations; do not assume documented backup steps are already enabled.

### PlaceWellPdfGenerator

- Allow a connected order to render QR-free physical labels while including a
  real Order QR on its manifest/insert.
- Update validation: require the Order QR for connected orders, but do not
  require or draw individual QRs in QR-free label profiles.
- Select manifest content from connectivity, not solely from `label_mode`.
- Reuse Standard profiles and production name fitting for both legacy spice
  SKUs and canonical storage SKUs.
- Plain named labels must not render the QR-separator underline. Preserve the
  separate approved writable-blank treatment.
- Keep the Order QR out of paid sheet positions and retain writable blanks.
- Preserve paired PDF publication and explicit failure reporting.
- Keep previews QR-free and allocation-free, with watermarks and the
  actual-size calibration guide.

### PlaceWellUI

- Separate registration/connectivity controls from layout selection.
- Remove the Standard branch's automatic loss of connected metadata.
- Build named items, physical blanks, and the non-printing Order QR for the
  new connected product.
- Preserve artwork validation, category-specific defaults, print preflight,
  allocation mapping, and consistent counts.
- Offer re-render/resend of existing registered orders without reallocating.

Acceptance gate: produce connected QR-free Spice and Storage orders with a
working Order QR, correct metadata, correct label counts, and repeatable IDs.

## 5. Mobile import and retrieval

Dependencies: agreed blank/navigation decisions and backend response contract.

- Preserve existing Order QR scanning, app links, and bulk-import setup.
- Include writable blanks in the existing import review, room/zone selection,
  individual setup, and bulk save as editable numbered records.
- Keep blank-origin metadata and empty printed names across subsequent edits.
  Do not prefetch stock artwork or auto-apply freshness metadata for blanks.
  Reopening a saved entry uses edit mode; re-import never creates another copy.
- Preserve duplicate named labels as distinct records by ID, never by name.
- Add `printedLabelName` to text search alongside the existing editable name,
  contents, notes, room, and zone matches.
- Ensure repeat imports preserve existing customer names, photos, contents,
  rooms/zones, freshness data, and archived records.
- Update onboarding, empty states, scanner instructions, and help text to
  explain "import your order, then find labels in Home or search."
- Preserve offline access after import and complete issued metadata at import
  so ordinary retrieval does not depend on scanning an individual label.
- Keep the current user-photo/stock/fallback precedence. Update artwork and
  overlay geometry only where required to match the approved new label face.

Numbered blank import is implemented in app source; installed iOS/Android
sign-off and an updated app build remain pending. App commit `78a9291` on `main`
passes the full regression suite (463 tests across 32 suites).
The Shopify sample now imports
60 records (four named labels and 56 writable blanks), excluding the Order QR.
Verify numbering on repeat/partial imports, blank room/zone setup, renaming,
personal photos/contents, archived-record preservation, and offline retrieval.
Printed-name search and QR-bearing stock photography remain deferred.
A fresh installation restores issued metadata only, not prior personal edits.

## 6. Shopify configuration and fulfillment

Dependencies: shared contracts and backend production path.

- Route the single customer-facing product to the QR-free connected contract.
  Remove Smart/Standard purchase choices wherever present; internal historical
  modes need not be deleted.
- Update configuration generation, parsing, cart restoration/editing, and
  preview requests together.
- Preserve exact print-ready text, line breaks, font/color choices, sheet
  composition, quantities, and predefined-name snapshots through fulfillment.
- The single-line-item handoff in component seven connects reviewed imports to
  production after explicit operator confirmation. Complete multi-line-item
  production and retry/reprint recovery before calling the full workflow complete.
- Support the actual launch catalog's line-item combinations and purchased
  quantities under the correct fulfillment order. Do not silently flatten
  different SKUs/styles or generate unrelated import cards for one order.
- Keep the Shopify order reference separate from the import identity.
- Update product, app, how-it-works, FAQ, story, size-guide, preview, and
  relevant cart copy. Remove promises to scan individual physical labels.
- Keep the existing approved-origin, public preview route and domain routing
  contracts intact.

Acceptance gate: a configured cart can be edited, purchased/test-ordered,
reviewed, registered, printed, and imported with the same names and quantities.

### Storage storefront expansion: approved requirements

Status: product-page planning; no new Shopify product, checkout discount, or
theme changes have been published for this expansion.

- Position the new `sl522-template` product as **Storage Labels for Boxes &
  Totes**, covering home organization and moving rather than moving alone.
  The canonical SL522-XW geometry is 4 by 5 inches portrait, four labels per
  sheet. Its internal display name currently says `5x4-rect`; customer-facing
  dimensions must match the verified geometry.
- Use one product page with Kids Room, Garage, Basement, and Custom choices.
  Room presets are name sets, not separate physical SKUs or product pages.
- Product specifications and presets must be data-driven. Separate purpose
  (Spice, Storage, future categories) from size/shape. Adding a supported SKU
  should require catalog/configuration data and media, not a layout redesign.
  Genuinely new customization features can still require code.
- Presets and Custom share one editable multi-sheet workspace: browse numbered
  sheets, rename individual labels, add sheets, and delete any individual sheet
  including the first. Cleared names become writable blanks, not fewer paid
  physical labels. Preview, cart edits, sheet counts, and fulfillment must
  reflect the same final configuration.
- **Approved price: USD $10.53 per sheet**, for both presets and Custom.
  A three-sheet starter set is $31.59; six sheets are $63.18 before shipping,
  taxes, and discounts. Other existing product prices are outside this change.
- A future minimum-spend checkout discount can use Shopify's native amount-off
  order discounts. Its qualifying subtotal and discount amount/percentage
  have not been chosen: do not activate a rule or invent either value.
  Shopify's minimum-purchase amount excludes shipping and taxes.
- The earlier $21.53-first-sheet/$10-additional-sheet pricing is superseded.
  Its cross-cart discount-app, Shopify Plus, and custom draft-order-checkout
  investigations are no longer prerequisites for this product.
- Review the new product page before collection integration, then address the
  homepage separately. Do not publish a live storefront redesign as part of
  planning this page.

Approved initial name sets (12 labels / three sheets each before editing):

- **Kids Room:** Toys; Building Blocks; Stuffed Animals; Dolls & Figures;
  Books; Puzzles; Board Games; Arts & Crafts; Dress-Up; School Supplies;
  Seasonal Clothes; Keepsakes.
- **Garage:** Hand Tools; Power Tools; Hardware; Cords & Cables;
  Painting Supplies; Car Care; Gardening Supplies; Cleaning Supplies;
  Sports Gear; Camping Gear; Bike Accessories; Outdoor Toys.
- **Basement:** Holiday Decor; Seasonal Decor; Gift Wrap; Party Supplies;
  Seasonal Clothes; Extra Bedding; Guest Linens; Keepsakes; Photo Albums;
  Craft Supplies; Travel Gear; Spare Household Items.

## 7. Physical product, artwork, and photography

Dependencies: physical design approval before final asset production.

- Print QR-free proofs for every launch SKU at Actual Size.
- Approve physical typography, placement, frames, blank usability, and adhesion
  on representative jars/containers.
- Create an asset inventory covering theme files, Shopify-hosted product
  media, mobile stock/fallback art, screenshots, composites, and launch assets.
- Review the 10 prepared product-gallery photos across Round, Rectangle, and
  Square. Replace or reshoot QR-bearing product imagery as appropriate.
- Rebuild affected hero, format, fit-guide, app, and lifestyle composites.
  Check label images inside phone screens as well as foreground jars.
- Reuse accurate backgrounds, branding, unaffected imagery, and page structure.
  A full-store redesign or entirely new photography shoot is not assumed.
- Prefer real approved labels for close-up product photography. Any edited
  composite must accurately depict the final printed design.
- Update Shopify-hosted media as well as theme fallbacks, including collection
  thumbnails and mobile/desktop variants.
- If app stock masters change, regenerate content-addressed assets and paired
  Firebase/Linode releases through the existing pipeline; do not overwrite
  immutable deployed image content.
- Produce and physically verify the final Order QR insert with optional-app,
  keep-card, reinstall limitations, and support/recovery instructions.

Acceptance gate: no launch asset or customer instruction depicts individual QR
functionality that the delivered product does not provide.

## 8. Validation and rollout

Dependencies: backend, app, storefront, physical assets, and owner approvals.

Use existing targeted tests during development, then the existing project
suites and Shopify Theme Check for release. No new test framework is required.

Required scenarios:

- Spice and Storage; legacy and canonical SKUs; named labels and blanks.
- Duplicate names, renamed digital records, and original printed-name search.
- Capacity boundaries, multiple sheets, quantities, and supported mixed
  Shopify line items with different print settings.
- Allocation retry, mismatched order reuse, render failure, and reprint.
- Repeat/partial import, archived items, blank activation, and offline recall.
- Preview success/failure without any allocation or Firestore writes.
- Installed/uninstalled app Order QR flows and delayed activation.
- Support recovery of the same Order QR; fresh-install metadata-only behavior.
- Actual-size prints and signed Order QR scanning on physical iOS/Android
  devices. Unit tests alone are not physical sign-off.

Rollout sequence:

1. Deploy compatible backend changes without changing the live storefront.
2. Validate deterministic new-product fixtures end to end.
3. Build and physically validate the mobile update; complete store release.
4. Complete physical product/media approval and unpublished Shopify theme QA.
5. Confirm the released app supports the full advertised workflow.
6. Publish the new storefront/product only after explicit owner approval.
7. Fulfill a complete internal test order and verify support/reprint procedures
   before opening customer fulfillment.

Document rollback to the prior code/theme and pause fulfillment on failure.
Preserve already issued records and import routes during rollback.

Update canonical context, roadmap, architecture, deployment notes, release
checklists, store collateral, and the sanitized AI packet with the approved
product model and actual rollout state.

## 9. Explicitly deferred

- OCR, camera text search, image recognition, and automatic object matching.
- Accounts, household sharing, cloud backup, and device synchronization.
- Firestore collection redesign merely to remove the word `qr`.
- Deleting old routes or every internal Smart profile.
- Automated Shopify webhooks, customer accounts, or email delivery unless
  separately approved; the operator-confirmed fulfillment bridge is required.
- New analytics SDKs or a changed personal-data collection model.
- Unrelated app, theme, compiler, or infrastructure refactors.

## Baseline evidence used for this plan

- `PlaceWellUI\app\main.py`: before this implementation, Standard cleared
  defaults, omitted the Order QR, and skipped allocation. The approved operator
  integration above replaces that path with connected Plain/QR.
- `PlaceWellPdfGenerator\placewell_generator\validator.py`: Standard forbids
  per-item URLs and Order QR records.
- `PlaceWellPdfGenerator\placewell_generator\renderer\header.py`: manifest
  content currently branches on label mode.
- `PlaceWellQRService\app\allocate.py` and `app\order.py`: current issued-record
  allocation and query-based order retrieval.
- `PlaceWellApp\src\screens\BulkImportScreen.js` and `src\data\storage.js`:
  blanks are excluded; records deduplicate by ID; printed-name search is absent.
- `Shopify\placewell-shopify-theme\assets\pw-label-configurator.js`: current
  version-4 configuration, mode routing, previews, and cart restoration.
- `PlaceWellUI\app\templates\shopify_import.html`: review is non-mutating;
  component seven adds explicit single-line-item production.
- Representative prepared gallery, product cutout, and kitchen/app composite:
  individual QRs are baked into both physical product and phone imagery.

The 2026-10-24 QR-less feasibility audit is historical supporting research.
Its claims about missing Standard rendering are superseded by current code.
