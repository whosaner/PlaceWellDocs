# Production Algorithm Baseline vs Experimental Design POC

Generated: 2026-10-28

## Open these two files

### 1. Current production-algorithm behavior

`01_PRODUCTION_ALGORITHM_BASELINE.pdf`

This file uses the current local PlaceWellPdfGenerator execution path:

```text
render_label_sheets()
  -> compute_layout()
  -> render_cell()
  -> _draw_name()
  -> _draw_separator()
  -> _draw_qr()
```

It temporarily registers SL573 and SL522 template dictionaries in memory. No
production source/configuration file is changed.

### 2. Experimental design alternatives

`02_EXPERIMENTAL_DESIGN_CONCEPTS.pdf`

This file explores behavior that production does not currently implement:

- Maximum two-line fitting
- Per-style base/minimum sizes
- Balanced two-line breaks
- SL573 horizontal layout
- 0.75- and 1.0-inch QRs
- Four-module quiet zones
- Ink/Navy and framed/frameless treatments

## Reproducibility scope

The production baseline uses the current local PdfGenerator working tree at
the time of generation:

- Git HEAD: `38e5ead`
- The working tree already contained uncommitted font/style/generator changes
  before this POC.

The baseline therefore represents the current local algorithm under
discussion, including the current five style definitions. It should not be
described as a byte-for-byte reproduction of a previously deployed server
unless that working tree is first committed/deployed.

## Temporary template inputs

Both scenarios use official SheetLabels geometry.

### Scenario A: `AS_IS_RECT_SIZE`

- Base size: 11.5 pt
- Minimum: 5 pt
- Purpose: show what happens if the nearest existing rectangle typography
  values are copied unchanged.

### Scenario B: `LARGE_TEMPLATE_START`

- SL573 base: 56 pt
- SL522 base: 64 pt
- Minimum: 5 pt
- Purpose: use a plausible large-label template base while retaining the exact
  current production fitter.

These values are experimental configuration inputs. The rendering algorithm is
production code.

## Direct answers to the design questions

### Does the current algorithm calculate a larger font from the larger printable area?

**No.**

It begins at `template["base_font_size_pt"]` and only reduces the size when
content does not fit. It never increases the configured base size to use
additional space.

The `AS_IS_RECT_SIZE` pages demonstrate this clearly: every font remains at
11.5 pt on the 4 x 3 and 4 x 5 labels, leaving most of the label empty.

Adding a larger physical template therefore requires an explicit new
`base_font_size_pt`.

### Does the current algorithm use the official template area?

**Yes, once the template geometry is configured.**

- `compute_layout()` derives the cells from configured dimensions, margins,
  and gaps.
- `render_cell()` receives those dimensions.
- `_draw_name()` calculates its name zone from cell dimensions, inset,
  separator, QR size, and QR clearance.

The generator does not download/read SheetLabels PDFs at runtime. For this
baseline, temporary template dictionaries use geometry verified from the
downloaded official PDFs.

### Is the production baseline exactly the current algorithm?

**Yes for the rendering path and current style behavior.**

It uses the actual production functions without replacing wrapping or QR
logic.

**No as a deployed configuration claim.**

SL573 and SL522 are registered only in memory for the POC, and their base sizes
are candidate inputs that do not yet exist in production configuration.

### Is the experimental POC exactly the current algorithm?

**No.**

It is a design exploration built on real fonts/styles and official geometry,
but uses a stricter custom fitter and experimental layout/QR choices.

### What happens to the experimental POC?

- It is retained in `experimental-design-concepts\`.
- It is clearly labeled non-production.
- It remains useful for deciding which production improvements are justified.
- Rejected concepts can later move to `archive\`.
- Chosen concepts must be regenerated from actual modified production code
  before release.

Nothing is deleted merely because the baseline now exists.

## Measured production-baseline results

Machine-readable measurements:

- `production-algorithm-baseline\baseline_metrics.json`
- `production-algorithm-baseline\baseline_metrics.csv`

### Scenario A: copied 11.5-point size

Across both templates and all five styles:

- Final size remains 11.5 pt.
- Every test name remains one line.
- No name is truncated.
- The result is far too small for the approved 6-8-foot viewing target.

This proves the algorithm does not auto-scale upward.

### Scenario B: proposed large base, current fitter

#### SL573 - base 56 pt

| Style | Observed final-size range | Maximum lines |
|---|---:|---:|
| Josefin Sans | 27-56 pt | 3 |
| Editorial Serif | 39.5-56 pt | 2 |
| Modern Sans | 38-56 pt | 2 |
| Mono Spec | 34.5-56 pt | 3 |
| Classic Script | 41.5-56 pt | 2 |

Key result:

- Editorial, Modern, and Script keep long names to two lines in the tested
  vertical production layout.
- Josefin and Mono can produce three lines.
- Josefin's existing 0.20-em spacing drives `HOLIDAY DECORATIONS` down to
  27 pt.

#### SL522 - base 64 pt

| Style | Observed final-size range | Maximum lines |
|---|---:|---:|
| Josefin Sans | 27-60 pt | 3 |
| Editorial Serif | 55-64 pt | 3 |
| Modern Sans | 51.5-64 pt | 3 |
| Mono Spec | 36.5-64 pt | 3 |
| Classic Script | 56.5-64 pt | 3 |

Key result:

- The extra label height does not give names more horizontal width; both
  labels remain 4 inches wide.
- Long three-word names can therefore still become three lines.
- SL522 provides more vertical breathing room but does not solve width-driven
  wrapping by itself.

No sample truncated because the current 5-point minimum allows the algorithm
to keep shrinking. A production-readable minimum must be configured and
validated physically.

## Questions answered by the production baseline

1. **Can the current algorithm place content on both official templates?**
   Yes.

2. **Does `compute_layout()` reproduce official capacity?**
   Yes after using normalized SL522 values of 0.15625-inch side margins and a
   0.1875-inch gap. Feeding the raw PDF's rounded point values caused a
   floating-point floor-to-one-column error.

3. **Can existing small-template font sizes be reused?**
   No; they remain tiny because the algorithm never grows them.

4. **Can all five styles render?**
   Yes technically, but they do not produce equivalent physical hierarchy
   from one shared base size.

5. **Are per-style scales likely needed?**
   Yes, especially for Josefin, Mono, and differences in cap height.

6. **Does the current algorithm enforce two lines?**
   No. Three-line results occur.

7. **Does the current algorithm preserve the 6-8-foot readability target?**
   Not by itself. A readable minimum and an operator warning/failure policy are
   needed.

8. **What QR does the current baseline use?**
   Current production 0.5 inch, ECC M, two-module quiet zone.

9. **Does current code support rotated SL522 5 x 4 content?**
   Not as a template/layout property today. Rotation is physically possible,
   but requires an explicit layout/orientation implementation or a separate
   rendering path.

## Questions answered by the experimental POC

1. Whether a strict maximum of two lines is visually preferable.
2. Whether per-style base/minimum sizes improve consistency.
3. Whether SL573 should use vertical or horizontal composition.
4. Whether 0.75 or 1.0 inch improves arm's-length scanning.
5. Whether a four-module quiet zone should replace the current two modules for
   the new SKUs.
6. Whether Ink or Navy is the preferred default.
7. Whether inset-frame or frameless composition is preferable.
8. Which experimental changes are worth implementing in production.

The current experimental set does not yet include rotated 5 x 4 SL522 pages.
That should be generated only after baseline review confirms whether rotation
is still desired.

## Smallest likely production changes

Based on the first comparison, the minimum likely changes are:

1. Add official SL573/SL522 template entries.
2. Set large-template base sizes explicitly.
3. Define readable minimums substantially above 5 pt.
4. Add per-style scale/spacing overrides for the new templates.
5. Decide whether to enforce a two-line maximum and operator warning.
6. Keep current 0.5-inch QR unless physical QR testing approves 0.75/1.0.

Horizontal layout, rotation, larger QR, four-module quiet zone, and strict
two-line fitting are optional design enhancements, not prerequisites for
rendering the new templates.

## How to compare the two files

1. Open `01_PRODUCTION_ALGORITHM_BASELINE.pdf`.
2. Review Scenario A first: this is why old 11.5-point template sizing cannot
   be copied.
3. Review Scenario B by font and name length.
4. Open `02_EXPERIMENTAL_DESIGN_CONCEPTS.pdf`.
5. Compare the same fonts/names against the strict two-line concepts.
6. Print both at Actual Size before deciding based on screen previews.
*** End of File
