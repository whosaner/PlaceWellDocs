# Adding a New Category to PlaceWell

> This guide covers **every** config-driven touchpoint across the PlaceWell
> ecosystem. Follow each section to add a category end-to-end — from order
> creation through PDF generation to the mobile app.

---

## Architecture Overview

PlaceWell is split across four repositories:

| Repo | Role | Key config file(s) |
|------|------|---------------------|
| **PlaceWellUI** | Order form & pipeline (FastAPI) | `app/config.py`, `data/<category>.csv` |
| **PlaceWellQRService** | QR allocation & lookup (FastAPI) | `app/allocate.py`, `app/lookup.py` |
| **PlaceWellPdfGenerator** | PDF label sheet renderer | `placewell_generator/generator.py` |
| **PlaceWellApp** | Mobile app (React Native / Expo) | `src/data/labelConfig.js`, `src/components/placeholders/` |

The category string (e.g. `"spice"`) flows through the entire pipeline:

```
PlaceWellUI (order form)
  → PlaceWellQRService (allocate — stores category in Firestore)
    → PlaceWellPdfGenerator (renders PDF sheets)
    → PlaceWellApp (scans QR → lookup → gets category → drives UI)
```

---

## 1. PlaceWellUI — Order Pipeline

### 1a. Register the category in `app/config.py`

Three things to update:

```python
# 1) CATEGORY_CONFIG — drives item skeleton generation
CATEGORY_CONFIG = {
    "spice": {
        "blank_count": 6,       # Extra blank labels per order
        "csv_file": "spice.csv",  # Item names CSV in data/ folder
    },
    # ➕ Add your new category here:
    "pantry": {
        "blank_count": 4,
        "csv_file": "pantry.csv",
    },
}

# 2) CONTENT_CATEGORIES — populates the order form dropdown
CONTENT_CATEGORIES = [
    {"value": "spice",  "label": "Spice",  "enabled": True},
    # ➕ Add:
    {"value": "pantry", "label": "Pantry", "enabled": True},
]
```

### 1b. Create the item names CSV

Add a CSV file at `data/<category>.csv` with one item name per line:

```
data/pantry.csv
───────────────
Flour
Sugar
Rice
Pasta
...
```

This CSV is loaded by `order_builder.py` → `load_items_from_csv()`.
Each name becomes a label skeleton with a globally-incrementing `item_id`
(e.g. `pantry_flour_001`, `pantry_sugar_002`, …).

### 1c. Size dimensions (shared across all categories)

The `SIZE_DIMENSIONS` dict in `app/order_builder.py` maps size codes to
physical dimension strings. This is **category-agnostic** — all categories
share the same size options:

| Size code | Dimensions |
|-----------|------------|
| `S` | `1.5in x 2in` |
| `M-round` | `1.5in x 1.5in` |
| `M-rect` | `2in x 1.5in` |
| `L` | `2.5in x 1.75in` |

No changes needed here unless you're adding a new physical size.

---

## 2. PlaceWellQRService — Allocation & Lookup

**No code changes needed.** The QR Service is category-agnostic.

It stores whatever `category`, `label_size`, and `label_dim` values the UI
pipeline sends during allocation, and returns them verbatim on lookup.

Firestore document fields per label:

| Field | Type | Example |
|-------|------|---------|
| `id` | string | `A7KC3F` |
| `order_id` | string | `hussain_20260501_143022` |
| `item_id` | string | `pantry_flour_001` |
| `is_blank` | boolean | `false` |
| `label_name` | string | `Flour` |
| `category` | string | `pantry` |
| `label_size` | string | `S` |
| `label_dim` | string | `1.5in x 2in` |
| `status` | string | `active` |
| `scan_count` | int | `0` |

---

## 3. PlaceWellPdfGenerator — PDF Rendering

**No code changes needed.** The generator is also category-agnostic.

It filters items by `label_size` per render pass (one sheet per size) and
has a legacy fallback for orders without `label_size` fields. The header
displays `content_category.title()` automatically.

---

## 4. PlaceWellApp — Mobile App

This is where the most config changes are needed. There are **three
config-driven systems** that reference category:

### 4a. Label form behavior — `src/data/labelConfig.js`

This file controls what happens when a user scans a label of a given
category. Add an entry to `CATEGORY_CONFIG`:

```javascript
const CATEGORY_CONFIG = {
  spice: {
    hideContents: true,         // Hide the "Contents" list on the form
    defaultRoom: 'Kitchen',     // Auto-select this room
    defaultZone: 'Upper Cabinets', // Auto-select this zone
    placeholder: 'spiceJar',   // Placeholder illustration key (see 4b)
  },
  // ➕ Add your new category:
  pantry: {
    hideContents: false,        // Show contents list
    defaultRoom: 'Kitchen',
    defaultZone: 'Pantry Shelf',
    placeholder: 'pantryJar',  // Must match registry key in 4b
  },
};
```

**Config fields explained:**

| Field | Type | Effect |
|-------|------|--------|
| `hideContents` | boolean | When `true`, the "Contents" step hides the item list and only shows a notes field |
| `defaultRoom` | string \| null | Auto-selects (or creates) this room when the label form opens |
| `defaultZone` | string \| null | Auto-selects (or creates) this zone under the matched room |
| `placeholder` | string \| null | Key into the placeholder registry (see 4b). `null` = no illustration |

Categories not listed fall back to `DEFAULT_CONFIG` (all fields visible,
no defaults, no placeholder).

### 4b. Placeholder illustrations — `src/components/placeholders/`

This is a **three-step** process to add a category-specific illustration
that appears when the user hasn't taken a photo.

#### Step 1: Add SVG asset files

Place SVG files in `assets/`:

```
assets/pantry_small.svg
assets/pantry_medium.svg
assets/pantry_large.svg
```

SVG files are imported as React components via `react-native-svg-transformer`
(configured in `metro.config.js`). Each file should be a self-contained SVG
with no external dependencies.

> **Tip:** Keep gradient IDs unique within each file (e.g. prefix with the
> category name) to be safe, although each `<Svg>` element creates an
> isolated scope in react-native-svg.

#### Step 2: Create a placeholder component

Create `src/components/placeholders/PantryJarPlaceholder.js`:

```javascript
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

import SmallJar from '../../../assets/pantry_small.svg';
import MediumJar from '../../../assets/pantry_medium.svg';
import LargeJar from '../../../assets/pantry_large.svg';

// Map label_size code → SVG component
const JAR_VARIANTS = {
  S:         { Component: SmallJar,  svgWidth: 140, svgHeight: 196, textTop: '62%', fontSize: 13 },
  'M-round': { Component: MediumJar, svgWidth: 150, svgHeight: 240, textTop: '58%', fontSize: 14 },
  'M-rect':  { Component: MediumJar, svgWidth: 150, svgHeight: 240, textTop: '58%', fontSize: 14 },
  L:         { Component: LargeJar,  svgWidth: 160, svgHeight: 304, textTop: '55%', fontSize: 15 },
};

const DEFAULT_VARIANT = JAR_VARIANTS['M-round'];

const SIZE_PRESETS = {
  full: { scale: 1.0 },   // LabelFormScreen, LabelDetailScreen
  tile: { scale: 0.55 },  // HomeScreen tiles (RoomSection)
  mini: { scale: 0.3 },   // Search results (LabelCard)
};

const PantryJarPlaceholder = ({ labelName, labelSize, size = 'full' }) => {
  const variant = JAR_VARIANTS[labelSize] || DEFAULT_VARIANT;
  const preset = SIZE_PRESETS[size] || SIZE_PRESETS.full;
  const { Component, svgWidth, svgHeight, textTop, fontSize } = variant;

  const displayWidth = Math.round(svgWidth * preset.scale);
  const displayHeight = Math.round(svgHeight * preset.scale);
  const displayFontSize = Math.max(7, Math.round(fontSize * preset.scale));
  const maxChars = size === 'mini' ? 8 : size === 'tile' ? 10 : 14;
  const displayName = labelName
    ? (labelName.length > maxChars ? labelName.substring(0, maxChars - 1) + '…' : labelName)
    : null;

  return (
    <View style={[styles.container, { width: displayWidth, height: displayHeight }]}>
      <Component width={displayWidth} height={displayHeight} />
      {displayName && (
        <Text style={[styles.labelText, { top: textTop, fontSize: displayFontSize }]} numberOfLines={1}>
          {displayName}
        </Text>
      )}
    </View>
  );
};

// ... styles (same pattern as SpiceJarPlaceholder.js)

export default PantryJarPlaceholder;
```

#### Step 3: Register the component

Add the import and registry entry in `src/components/placeholders/index.js`:

```javascript
import SpiceJarPlaceholder from './SpiceJarPlaceholder';
import PantryJarPlaceholder from './PantryJarPlaceholder';  // ➕

const PLACEHOLDER_REGISTRY = {
  spiceJar: SpiceJarPlaceholder,
  pantryJar: PantryJarPlaceholder,  // ➕ key must match labelConfig.js
};
```

#### How it all connects

```
User scans QR → lookupLabel() returns category
  → CategoryPlaceholder receives category prop
    → getCategoryConfig('pantry') → { placeholder: 'pantryJar' }
      → PLACEHOLDER_REGISTRY['pantryJar'] → PantryJarPlaceholder
        → Renders the SVG with label name overlay
```

`CategoryPlaceholder` is already integrated into all four views:
- `LabelFormScreen` — photo step (size `full`)
- `LabelDetailScreen` — detail view (size `full`)
- `RoomSection` — HomeScreen tiles (size `tile`)
- `LabelCard` — search results (size `mini`)

**No screen files need to change when adding a new category.**

### 4c. QR Service client — `src/services/qrService.js`

**No changes needed.** The `lookupLabel()` function returns whatever
`category`, `labelSize`, and `labelDim` the QR Service provides. It is
category-agnostic.

---

## Quick Checklist

When adding a new category (e.g. `"pantry"`), here is the minimum set of
changes across all repos:

| # | Repo | File | Change |
|---|------|------|--------|
| 1 | PlaceWellUI | `app/config.py` | Add to `CATEGORY_CONFIG` and `CONTENT_CATEGORIES` |
| 2 | PlaceWellUI | `data/pantry.csv` | Create item names CSV |
| 3 | PlaceWellApp | `src/data/labelConfig.js` | Add category entry with `placeholder` key |
| 4 | PlaceWellApp | `assets/pantry_*.svg` | Add SVG illustration files (small/medium/large) |
| 5 | PlaceWellApp | `src/components/placeholders/PantryJarPlaceholder.js` | Create placeholder component |
| 6 | PlaceWellApp | `src/components/placeholders/index.js` | Register in `PLACEHOLDER_REGISTRY` |

**No changes needed in:**
- PlaceWellQRService (category-agnostic store)
- PlaceWellPdfGenerator (category-agnostic renderer)
- Any screen file in PlaceWellApp (config-driven via `CategoryPlaceholder`)

---

## File Reference

```
PlaceWellUI/
├── app/
│   ├── config.py              ← Category registry, dropdown options, sizes
│   ├── order_builder.py       ← Item skeleton generation, SIZE_DIMENSIONS
│   └── qr_client.py           ← Sends category to QR Service
└── data/
    └── spice.csv              ← Item names for the spice category

PlaceWellQRService/
└── app/
    ├── allocate.py            ← Stores category, label_size, label_dim
    └── lookup.py              ← Returns category, label_size, label_dim

PlaceWellPdfGenerator/
└── placewell_generator/
    └── generator.py           ← Filters by label_size per render pass

PlaceWellApp/
├── assets/
│   ├── spice_small.svg        ← SVG illustrations (one per size variant)
│   ├── spice_medium.svg
│   └── spice_large.svg
├── metro.config.js            ← SVG transformer config
└── src/
    ├── data/
    │   └── labelConfig.js     ← Category → form behavior + placeholder key
    ├── components/
    │   ├── CategoryPlaceholder.js  ← Config-driven wrapper (all screens use this)
    │   └── placeholders/
    │       ├── index.js       ← Placeholder registry
    │       └── SpiceJarPlaceholder.js  ← Spice jar SVG wrapper
    ├── screens/
    │   ├── LabelFormScreen.js      ← Uses CategoryPlaceholder + getCategoryConfig
    │   ├── LabelDetailScreen.js    ← Uses CategoryPlaceholder
    │   └── ScannerScreen.js        ← Passes category from QR lookup
    └── services/
        └── qrService.js           ← lookupLabel() returns category
```
