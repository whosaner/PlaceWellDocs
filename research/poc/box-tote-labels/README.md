# Box/Tote Label Typography and QR POC

Created: 2026-10-28

Status: Production-algorithm baseline plus experimental proof set. No
PlaceWellUI or PdfGenerator production configuration was changed.

## Open first

1. `01_PRODUCTION_ALGORITHM_BASELINE.pdf`
2. `02_EXPERIMENTAL_DESIGN_CONCEPTS.pdf`
3. `COMPARISON_FINDINGS.md`

The baseline answers what the current generator algorithm does. The
experimental file explores possible future design changes.

## Experimental-design purpose

The experimental set tests:

- All five existing PlaceWell font styles
- SL573-XW 4 x 3 typography in vertical and horizontal layouts
- SL522-XW 4 x 5 typography in a vertical layout
- Short, medium, and long names
- Ink versus PlaceWell Navy
- Inset frame versus frameless treatment
- 0.5-, 0.75-, and 1.0-inch QR footprints
- Current two-module versus proposed four-module quiet zones
- Exact placement against downloaded official SheetLabels templates

## Official template sources

### SL573-XW

- Official template:
  `C:\PlaceWell\Label Templates\SL573-XW 4x3\SL573-XW_Official_Template.pdf`
- Source metadata:
  `C:\PlaceWell\Label Templates\SL573-XW 4x3\SOURCE.md`
- Verified geometry:
  `C:\PlaceWell\Label Templates\SL573-XW 4x3\verified_geometry.json`

Verified:

- US Letter page
- 4 x 3-inch cells
- 2 columns x 3 rows
- 6 labels per sheet
- 0.1875-inch side margins
- 1-inch top/bottom margins
- 0.125-inch horizontal gap
- No vertical gap

### SL522-XW

- Official template:
  `C:\PlaceWell\Label Templates\SL522-XW 4x5\SL522-XW_Official_Template.pdf`
- Source metadata:
  `C:\PlaceWell\Label Templates\SL522-XW 4x5\SOURCE.md`
- Verified geometry:
  `C:\PlaceWell\Label Templates\SL522-XW 4x5\verified_geometry.json`

Verified:

- US Letter page
- 4 x 5-inch cells
- 2 columns x 2 rows
- 4 labels per sheet
- Approximately 0.156-inch side margins
- 0.5-inch top/bottom margins
- Approximately 0.188-inch horizontal gap
- No vertical gap

The official SL522 vector template corrected an earlier manually transcribed
0.125-inch side-margin value. The official PDF is the source of truth.

## Generated files

### Consolidated comparison

- `01_PRODUCTION_ALGORITHM_BASELINE.pdf`
- `02_EXPERIMENTAL_DESIGN_CONCEPTS.pdf`
- `COMPARISON_FINDINGS.md`

### Production-algorithm baseline

Located under `production-algorithm-baseline\`:

- `SL573_Production_Algorithm_Baseline.pdf`
- `SL522_Production_Algorithm_Baseline.pdf`
- Matching `_DIELINE_OVERLAY.pdf` files
- `baseline_metrics.json`
- `baseline_metrics.csv`

These files call the current `render_label_sheets`, `render_cell`,
`_draw_name`, and `_draw_qr` path with temporary in-memory templates.

### Experimental design concepts

Located under `experimental-design-concepts\`:

#### Typography/layout

- `SL573-XW_Typography_Layout_POC.pdf` - seven content-only pages
- `SL522-XW_Typography_Layout_POC.pdf` - five content-only pages

#### QR size

- `SL573-XW_QR_Size_POC.pdf`
- `SL522-XW_QR_Size_POC.pdf`

#### Die-line overlays

Every POC PDF has a matching `_DIELINE_OVERLAY.pdf`.

The overlays combine the generated content with the actual official
SheetLabels vector template. They are for calibration/inspection only.

#### PNG previews

Selected POC pages are rendered as PNGs in the experimental folder for screen review.
Screen previews are not a substitute for Actual Size printing.

## Font styles

The POC uses the current production style definitions:

1. Josefin Sans
2. Editorial Serif / Cormorant Garamond
3. Modern Sans / Jost
4. Mono Spec / DM Mono
5. Classic Script

Existing case rules and letter spacing are preserved in this first proof.
Point sizes are experimental per-SKU starting values, not production values.

Test names:

- `TOOLS`
- `WINTER CLOTHES`
- `HOLIDAY DECORATIONS`

The experimental renderer prefers one line, uses at most two lines, and
reduces font size only to the experimental per-style minimum. `BELOW MIN` in a
cell means the content still did not satisfy the fit target at that minimum.

## Initial findings

### All five fonts are technically usable

Every current PlaceWell font renders correctly in the larger templates.
Technical compatibility is not the same as physical readability; all five
still require printed 6-8-foot review.

### SL573 vertical is the stronger general layout

The vertical layout gives the name almost the full 4-inch width and preserves
a familiar PlaceWell name -> separator -> QR hierarchy.

It fits most samples at the proposed minimums. The long Josefin sample falls
below the current experimental minimum because Josefin preserves the existing
0.20-em letter spacing.

### SL573 horizontal is conditional, not universal

The horizontal name-left/QR-right layout uses the landscape shape well for
short names. It becomes restrictive for medium/long names because the name
zone is only about 2.1 inches wide.

The first proof flags below-minimum cases for:

- Josefin
- Editorial Serif
- Modern Sans
- Mono Spec
- Classic Script

depending on name length.

Do not adopt the horizontal layout globally unless:

- it is restricted to short names;
- the QR moves or shrinks;
- the divider/name proportions change; or
- a smaller physical name floor is approved after distance testing.

### Josefin needs a new-SKU letter-spacing decision

The current 0.20-em spacing is a strong brand treatment on small labels but
consumes substantial width on long large-label names.

The POC shows a below-minimum long-name case on both templates. A second proof
should test smaller per-SKU spacing (for example 0.10-0.14 em) before lowering
the physical font-size floor.

### QR sizes

The QR pages compare:

| Footprint | Quiet zone | Role |
|---|---:|---|
| 0.5 inch | 2 modules | Current production control |
| 0.75 inch | 4 modules | Recommended candidate |
| 1.0 inch | 4 modules | Maximum-reliability comparison |

All three fit easily on both templates. Selection must be based on actual XW
prints scanned on iOS and Android at the approved 1-2-foot target.

### Frame and color

The final typography page compares:

- Ink with inset frame
- PlaceWell Navy with inset frame
- Ink frameless
- PlaceWell Navy frameless

The outer die-cut frame remains absent in every concept.

## How to print

### Content-only POCs

Use for label-stock design testing:

1. Open in Adobe Reader.
2. Select the intended printer.
3. Paper size: US Letter.
4. Print at **Actual Size / 100 percent**.
5. Disable Fit, Shrink, Scale, and borderless enlargement.
6. Use the validated label-media/tray settings.

### Die-line overlays

Use for plain-paper alignment inspection:

1. Print at Actual Size on plain paper.
2. Hold against a real blank sheet or the official template.
3. Confirm every generated element stays inside its die line.

Do **not** print the die-line overlay onto sellable label stock; the official
cut outlines and SheetLabels footer are intentionally visible.

## Required physical review

For each template:

- Print typography pages at Actual Size.
- View names at 2-3 feet and 6-8 feet.
- Scan every QR size at 6-12 inches and 1-2 feet.
- Test iOS and Android.
- Test straight-on and moderate angles.
- Test bright and ordinary closet/garage lighting.
- Verify first/middle/last positions on each sheet.
- Record registration, toner, curl, scuffing, and adhesion separately.

## Decisions after the first print

1. SL573 vertical only, horizontal only for short names, or revised horizontal.
2. Default font and whether every style remains customer-selectable.
3. Per-style base/minimum point sizes.
4. Josefin per-SKU letter spacing.
5. 0.75 versus 1.0-inch QR.
6. Four-module quiet zone approval.
7. Inset frame versus frameless.
8. Ink versus PlaceWell Navy default.
9. Final long-name policy and operator warning behavior.
