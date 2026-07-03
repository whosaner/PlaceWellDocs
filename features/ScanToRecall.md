# Scan-to-Recall

## Section 1: Spec

**Status:** Implementation-ready, with 4 open decisions flagged in §3.
**Stack:** React Native 0.81.5 / Expo SDK 54, AsyncStorage, React Navigation. iOS + Android parity required for every screen and interaction.
**Companion visual:** `placewell_scan_to_recall_mockup.html` — bulk import, capture (predefined + custom), and the recall screen in all three freshness states.

---

### 1. Intent (one paragraph)

The physical label is the moat; this feature is what makes the app worth opening twice. When a customer decants spices into uniform jars, they throw away everything the original packaging told them — best-by date, brand, when it was opened. **The jar shows the name; the app remembers everything else.** Scan a label at the moment of doubt and get instant freshness status, best-by, age, brand, and notes. A "Refilled" action resets the clock and quietly learns the user's burn rate.

**Scope reality:** per-label scanning already works and lands the user on the label detail screen. This feature is a **data-model + screen upgrade on existing plumbing**, not new scan infrastructure. It is v1, not v2.

**Explicitly out of scope for v1** (the data model must not block them, but do not build them now): reorder / replenishment (reminder + one-tap reorder), packaging-barcode autofill, whole-home search. All three are downstream consumers of the same stored data.

---

### 2. Locked decisions

1. Freshness data lives in **structured fields**, not the freeform note.
2. **Predefined vs custom is a hard branch.** Predefined labels carry a known identity → shelf-life intelligence. Custom labels have no identity → manual entry only, no suggestions.
3. **Freshness status** has three states: `Fresh`, `Use soon`, `Past` (plus a neutral `Not tracked` when no best-by exists).
4. **Burn rate is computed**, never user-entered. Graceful empty state until enough data.
5. **Auto-save is continuous and persists without "Done"** (see §10). "Done" is closure, not a save gate.
6. **v1 persists locally** (AsyncStorage). Firestore is read-only in v1; writing enrichment back to Firestore is a v2 change.
7. Destructive actions (delete) **always require explicit confirm** — never auto-committed.

---

### 3. OPEN decisions (resolve before/while building)

- **A — Where freshness capture lives.** Dedicated wizard step ("Still good?") between Location and Note, **or** folded into the Note screen as an extra section. The mockup shows the dedicated-step version. *Recommendation: dedicated step for first-run delight; trades one extra screen.*
- **B — What "Done" means.** Purely cosmetic closure, **or** sets a `setupComplete` flag enabling later nudges ("3 labels still need a photo") and finished/unfinished sorting. *Recommendation: set the flag — cheap, and useful later.*
- **C — Best-by population model (confirm).** Auto-suggest from shelf-life table with **one-tap confirm / Edit override** (mockup shows this). *Recommendation: confirm this model.*
- **D — Shelf-life table values.** The starter table in §5 needs Hussain's review before it ships.

---

### 4. Data model

Extends the existing label record. New fields in **bold**.

| Field | Type | Notes |
|---|---|---|
| `id` | string | existing |
| `labelId` | string | existing — the scanned QR id |
| `name` | string | existing — pre-filled from label; never persist empty (§10) |
| `photoUri` | string\|null | existing |
| `room` / `zone` | string | existing |
| `note` | string | existing — freeform only; expiration no longer lives here |
| **`category`** | string\|null | resolved for predefined (e.g. `ground_spice`); `null` for custom |
| **`openedDate`** | ISO date\|null | defaults to first-scan date for predefined; optional for custom |
| **`bestByDate`** | ISO date\|null | suggested (predefined) or user-set; nullable |
| **`bestBySource`** | `'suggested'`\|`'user'`\|`null` | track whether the user confirmed/overrode the suggestion |
| **`brand`** | string\|null | optional |
| **`shelfLifeDays`** | number\|null | from table for predefined; `null` for custom |
| **`refillHistory`** | ISO timestamp[] | each "Refilled" appends; drives burn rate |
| **`burnRateDays`** | number\|null | **computed**, never written by the user; null until enough data |
| **`setupComplete`** | boolean | only if decision B = flag |
| `inferred_confidence` | number | existing — keep; surfaces low- vs high-confidence category inference |

---

### 5. Shelf-life reference table — **CONFIGURABLE, never hardcoded inline**

Per the framework rule (layout/values derived from configuration, never hardcoded), this is a single config map keyed by `category`, values in **days**. Starter values below are **defaults to refine (decision D)**, not authoritative.

```text
ground_spice     ~730    (2 yr)
whole_spice      ~1460   (4 yr)
dried_herb       ~545    (1.5 yr)
ground_chili     ~730
seeds            ~1095   (3 yr)
salt             null    (effectively indefinite → no best-by suggested)
baking_powder    ~365
baking_soda      ~730
extract          ~1460
```

Rules: if `shelfLifeDays` is `null` (e.g. salt), suggest **no** best-by and show status `Not tracked`. The mapping from predefined SKU → `category` is itself a config table (reuse the existing LLM-classification output written at label-generation time where available).

---

### 6. Freshness status logic — **CONFIGURABLE thresholds**

Inputs: `bestByDate`, today's date. Constant: `USE_SOON_WINDOW_DAYS` (config; start at **45**).

```text
if bestByDate == null            -> "Not tracked"   (neutral; show "add a best-by" affordance)
else if today > bestByDate       -> "Past"          (terracotta)
else if (bestByDate - today) <= USE_SOON_WINDOW_DAYS -> "Use soon" (amber)
else                             -> "Fresh"         (green)
```

Accent colors map to existing tokens: Fresh = `#5C9A6B`, Use soon = `--amber #C9A66B`, Past = `--terra #C4785A`.

---

### 7. Burn-rate logic

- On every **"Refilled today"**: append `today` to `refillHistory`; set `openedDate = today`.
- Compute: with N timestamps there are N−1 intervals. `burnRateDays = mean(consecutive interval diffs)`.
- Constant `MIN_REFILLS_FOR_RATE` (config; start at **2** timestamps = 1 interval to show a tentative rate; consider 3 for a confident one).
- Empty state (below threshold): *"Refill a couple of times and I'll learn your pace."*
- Populated: *"You usually refill this about every X."* (humanize: weeks if <90d, else months.)
- v1: **display only.** This value is the input the v2 reorder feature will consume — do not wire reorder now.

---

### 8. Flows

#### 8.0 Bulk import — order QR (where the flow begins)
Scanning the **order QR** lands on the "Set Up Labels" screen, which bulk-creates all labels in the order. For scan-to-recall, the Apply-to-All block carries a **"Track freshness · auto best-by"** toggle:
- **On** (recommended default for predefined-only orders): at "Apply to All / Create", every **predefined** label receives `openedDate = today` and an auto-suggested `bestByDate` from the shelf-life table. **Custom** labels in a mixed order are skipped (no identity → no suggestion).
- **Off:** labels are created without freshness; users can add it later via per-label setup.
- Row interactions use the corrected pattern (Option 1): `▾` chips quick-edit room/zone in place; the trailing `›` (whole-row tap) opens that label's full setup. Chip taps must `stopPropagation` so they don't also trigger row navigation.

This means a 28-jar order can be fully freshness-tracked on first scan with zero per-label work — the per-label freshness step (§8.1) then only matters for overrides.

#### 8.1 First-scan capture — predefined
Fields on the freshness step (decision A determines whether it's its own screen):
- **Opened** — date, defaults to **Today**.
- **Best by** — auto-suggested = `openedDate + shelfLifeDays`, rendered as a confirm card with **Edit** (decision C). Sets `bestBySource = 'suggested'`; if user edits, `'user'`.
- **Brand** — optional text.
All fields auto-save per §10. Nothing here is required.

#### 8.2 First-scan capture — custom
Same screen, but `category = null` → **no suggestion**. Opened / Best by are plain optional date pickers; Brand optional. Do not display shelf-life intelligence.

#### 8.3 Re-scan → Recall display (the payoff screen)
Scanning a label routes to the label **detail** screen (single scrollable screen — this is also the "edit" target, distinct from the first-run wizard). Layout top → bottom:
1. Back / breadcrumb (`Scanned · {name}`) / overflow.
2. Hero: photo (or jar placeholder), `room › zone`, name, **freshness status pill**.
3. Info rows: Best by, Opened (relative, e.g. "13 months ago"), Brand, Note (only rows that have data).
4. Burn-rate line (empty state or learned).
5. Primary action: **"Refilled today"** (accent shifts to terracotta in `Past` state).

Render all four status states per the mockup (`Fresh` / `Use soon` / `Past` / `Not tracked`).

#### 8.4 Refill loop
"Refilled today" → optimistic update → `openedDate = today`, append `refillHistory`, recompute `burnRateDays`, recompute status. For **predefined**, also re-suggest `bestByDate = today + shelfLifeDays` (a new jar = a fresh shelf life). **Open sub-decision:** does refill auto-update best-by silently, or surface a one-tap confirm? *Recommendation: auto-update for predefined, with an undo toast.*

---

### 9. Auto-save spec (applies to all capture fields, §10 detail)

Triggers: **on blur**, **on step-advance**, **debounced ~`AUTOSAVE_DEBOUNCE_MS` (config, start 800ms)** while typing, and **on `AppState` → background**. Persists to local store immediately; **does not require "Done."** Name has an **empty-value fallback** (revert to last non-empty; trim whitespace). A subtle "Saved ✓" indicator appears only *after* a commit, not permanently.

---

### 10. Cross-platform notes (iOS + Android)

- Use a cross-platform date picker; the native picker presentation differs by `Platform.OS` — wrap it.
- `onBlur` fires on keyboard dismiss on both platforms; `AppState` change ('active' → 'background') is the resilience flush for OS suspension.
- Use `useSafeAreaInsets` for the detail screen and any bottom sheet.
- Status pills, dashed/rounded borders: apply the existing Android `overflow:hidden` pattern.

---

### 11. Acceptance criteria (agent checklist)

- [ ] Bulk import "Track freshness" toggle applies auto best-by to all predefined labels at once and skips custom labels.
- [ ] Scanning an individual label opens the detail screen with the correct freshness state.
- [ ] Best-by is auto-suggested for predefined labels and absent for custom; salt-type (null shelf life) shows `Not tracked`.
- [ ] Expiration is captured in `bestByDate`, **not** in `note`.
- [ ] All four status states render with correct token colors and copy.
- [ ] "Refilled today" updates openedDate, appends history, recomputes burn rate and status, and (predefined) re-suggests best-by.
- [ ] Burn rate shows the empty state below `MIN_REFILLS_FOR_RATE` and a humanized interval above it.
- [ ] Every capture field auto-saves on blur / debounce / background and survives app kill without "Done."
- [ ] Empty name never persists; whitespace trimmed.
- [ ] `USE_SOON_WINDOW_DAYS`, `AUTOSAVE_DEBOUNCE_MS`, `MIN_REFILLS_FOR_RATE`, and the shelf-life table are all config constants, not inline literals.
- [ ] Delete (if present) requires explicit confirm.
- [ ] Identical behavior verified on iOS and Android.

---

### 12. Future hooks (do not build, but don't block)

- **Reorder (v2):** consumes `burnRateDays` + `bestByDate` → "running low?" nudge + one-tap reorder via the user's chosen retailer (customer-driven; affiliate deep-link, no auto-subscribe API exists). Reminder + one-tap is the right first step.
- **Barcode autofill (v2):** scan original packaging → prefill brand + best-by.
- **Whole-home search (v2/v3):** the recall data, queried across all labeled items.

## Section 2: Developer Guide

> **Feature scope:** Spice category labels only (v1).
> Other categories get zero changes until explicitly extended.

---

### What this feature does

When a customer decants spices into uniform jars, the original packaging is thrown away — best-by date, brand, when it was opened. The jar shows the name; the app remembers everything else.

Scan a spice label → see freshness status (Fresh / Use soon / Past), best-by date, how long ago you opened it, brand, and a burn-rate estimate that learns from how often you refill. Tap "Refilled today" to reset the clock.

---

### Architecture overview

```text
PlaceWellUI (operator form)
  → sends freshness_category per label at order time
  → PlaceWellQRService (stores freshness_category in Firestore)
    → returns label_metadata.freshnessCategory on QR scan
    → PlaceWellApp:
        qrService.js (receives labelMetadata)
          → labelMetadata.js (parses with spice parser)
          → freshness.js (computes status, burn rate, humanized strings)
          → LabelFormScreen (Still good? capture step — Phase 2)
          → LabelRecallScreen (recall view — Phase 3)
```

---

### New label data model fields

These are added to every label record in AsyncStorage when a spice label is saved. All fields are optional / nullable — existing labels without them behave exactly as before.

| Field | Type | Description |
|---|---|---|
| `freshnessCategory` | `string\|null` | Sub-category from QR Service (e.g. `"ground_spice"`) |
| `openedDate` | `string\|null` | ISO date when the jar was opened (`YYYY-MM-DD`) |
| `bestByDate` | `string\|null` | ISO date for best-by (`YYYY-MM-DD`) |
| `bestBySource` | `'suggested'\|'user'\|null` | Whether the user confirmed or overrode the suggestion |
| `brand` | `string\|null` | Optional brand name (e.g. `"Penzeys"`) |
| `refillHistory` | `string[]` | ISO timestamps, one per "Refilled today" tap (oldest first) |
| `burnRateDays` | `number\|null` | Computed mean days per refill. Never written by user. |
| `setupComplete` | `boolean` | Set to `true` by `saveLabel()` on every explicit save |

---

### Config constants

All tunable values are exported from `src/utils/freshness.js`. **Change them there** — never hardcode them in screen or component files.

| Constant | Default | Meaning |
|---|---|---|
| `USE_SOON_WINDOW_DAYS` | `45` | Days before best-by to enter "Use soon" (amber) state |
| `MIN_REFILLS_FOR_RATE` | `2` | Min refill timestamps before burn rate is displayed |
| `SHELF_LIFE_BY_FRESHNESS_CATEGORY` | see below | Shelf life per spice sub-category, in days |

#### Shelf-life table (starter values)

```js
// From src/utils/freshness.js — SHELF_LIFE_BY_FRESHNESS_CATEGORY
ground_spice:  730   // ~2 years
whole_spice:   1460  // ~4 years
dried_herb:    545   // ~1.5 years
ground_chili:  730   // ~2 years
seeds:         1095  // ~3 years
salt:          null  // indefinite — no best-by suggested
baking_powder: 365   // ~1 year
baking_soda:   730   // ~2 years
extract:       1460  // ~4 years
```

`null` means the category is effectively indefinite — the app will show status `"not_tracked"` and never suggest a best-by date.

---

### Freshness status states

| Status | Condition | Color token | UI label |
|---|---|---|---|
| `fresh` | `bestByDate` > today + `USE_SOON_WINDOW_DAYS` | `#5C9A6B` (green) | Fresh |
| `use_soon` | `bestByDate` ≤ today + `USE_SOON_WINDOW_DAYS` | `colors.amber` | Use soon |
| `past` | `bestByDate` < today | `colors.terracotta` | Past best-by |
| `not_tracked` | `bestByDate` is null | neutral | Not tracked |

---

### Key source files

```text
PlaceWellApp/
├── src/
│   ├── utils/
│   │   └── freshness.js          ← ALL freshness logic (pure functions + config)
│   ├── data/
│   │   ├── labelMetadata.js      ← Per-category parser registry for QR Service response
│   │   └── labelConfig.js        ← Category UI config (room defaults, placeholder, hints)
│   ├── services/
│   │   └── qrService.js          ← Passes label_metadata through on lookupLabel + lookupOrder
│   └── screens/
│       ├── LabelFormScreen.js    ← Phase 2: "Still good?" step for spice (Step 3)
│       └── LabelRecallScreen.js  ← Phase 3: Recall view (freshness pill, info rows, refill CTA)
```

---

### Backend requirements

Both backend repos must be updated for the feature to work end-to-end. See the commit history in each repo for the exact changes.

#### PlaceWellQRService

**What changed:** `label_metadata` object is now returned on label lookup and order responses when `freshness_category` is set in Firestore.

**Firestore field added:** `freshness_category` (string|null) — set by the order pipeline at allocation time.

#### PlaceWellUI

**What changed:**
- `data/spice.csv` has a new `freshness_category` column (classified per spice)
- The per-label operator table has a "Freshness Cat." dropdown to override per row
- The allocation payload now includes `freshness_category` per item

---

### Adding a new freshness category

When you want to track freshness for a new spice type (or a future non-spice category), follow these steps:

#### Step 1 — Add to the shelf-life table (`src/utils/freshness.js`)

```js
export const SHELF_LIFE_BY_FRESHNESS_CATEGORY = {
  // existing entries...
  vanilla_bean: 730,   // ~2 years — ➕ add here
};
```

#### Step 2 — Classify it in `data/spice.csv` (PlaceWellUI)

Add the new `freshness_category` value to the relevant rows in the CSV, or have the operator set it via the dropdown in the order form.

#### Step 3 — Firestore / QR Service (optional)

If the new category needs to be set server-side at allocation time, update the order pipeline (PlaceWellUI) to include it in the allocation request payload. The QR Service stores and returns it transparently.

#### Step 4 — For a brand-new content category (e.g. `"medication"`)

If you're adding freshness tracking to a category that isn't `"spice"`:

1. Add a new parser to `src/data/labelMetadata.js`:
```js
const PARSERS = {
  spice: parseSpiceMetadata,
  medication: parseMedicationMetadata,
};

function parseMedicationMetadata(raw) {
  return {
    freshnessCategory: typeof raw.freshnessCategory === 'string'
      ? raw.freshnessCategory : null,
  };
}
```

2. The rest of the freshness logic (`freshness.js`) is category-agnostic — just make sure the new `freshnessCategory` values are added to `SHELF_LIFE_BY_FRESHNESS_CATEGORY`.
3. Gate any new UI on `label.category === 'medication'` consistently across `LabelFormScreen`, `LabelRecallScreen`, and `BulkImportScreen`.

---

### Testing

Freshness pure functions are fully unit-tested:

```text
src/utils/__tests__/freshness.test.js
```

Run with:

```bash
npx jest freshness --no-coverage
```

When adding a new freshness category, add a test case to `getShelfLifeDays` and `suggestBestByDate` in that file.

---

### Implementation phases

| Phase | What | Status |
|---|---|---|
| Backend | QR Service + PlaceWellUI — add `freshness_category` field | ✅ done |
| Phase 1 | Data layer — freshness utils, parser, storage fields | ✅ done |
| Phase 2 | Capture — date picker + LabelFormScreen "Still good?" step | 🔜 next |
| Phase 3 | Display — LabelRecallScreen + LabelDetailScreen restructure | 🔜 |
| Phase 4 | Bulk — BulkImportScreen "Track freshness" toggle | 🔜 |
