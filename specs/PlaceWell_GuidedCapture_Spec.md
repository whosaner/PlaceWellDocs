# PlaceWell — Guided Jar Capture
*Spec & requirements · in-app camera capture with manual fill marker*
*Palette: Porcelain Sky (in-app surface). OCR / auto-detection: out of scope for v1.*

---

## 1. What this is

A guided camera screen that replaces the raw photo picker for jar labels. It does three things and nothing more:

1. Frames the jar with a **shape-agnostic staging zone**.
2. Lets the user set an **approximate fill level** by tapping a measuring-style scale.
3. Normalizes the result to a **fixed square image** that drops cleanly into any app tile.

No computer vision, no OCR, no fill auto-detection. Every value is user-set. The screen captures a *bucket*, it does not fake a measurement.

---

## 2. Locked design decisions (from our working session)

**Staging zone, not a jar silhouette.** The overlay is a neutral rounded-rectangle staging area with a "center your jar, fill ~⅔ of the frame" hint — never a jar-shaped cutout. Jars vary in shape and size; matching a contour reintroduces the exact variability we're avoiding. The zone *positions*; it does not measure.

**Fill marker is an ordinal tap scale, styled as a measuring scale.** Ticks: Full / ¾ / ½ / ¼ / Low. The user taps the bucket that matches what they see. The measuring-cup styling (a fill rising to the selected level) is visual warmth; the value is a tap, not an alignment against the jar. This keeps the screen fully shape-agnostic and honest.

**Output normalized to a fixed square canvas.** Every capture composites to one square size regardless of jar aspect ratio. This kills the tile-mismatch problem (portrait spice jar vs. landscape tote) at the source and guarantees drop-in interchangeability across every tile slot in the app.

---

## 3. Capture flow

1. User taps the camera action on LabelForm (or an empty tile photo slot).
2. Camera opens to the capture screen: live feed + staging zone + fill scale.
3. User frames the jar inside the zone and taps the fill level on the scale.
4. User taps **Capture**. Image is center-cropped to the square canvas.
5. **Review** screen: square image + chosen fill level, both adjustable (Retake / change level).
6. **Add details** hands the image URI + fill level back to LabelForm as pre-filled, editable fields.

LabelForm stays the source of truth. The capture screen writes nothing to Firestore directly — consistent with the app's editable-layer model.

---

## 4. Data captured

| Field | Type | Source | Notes |
|---|---|---|---|
| `imageUri` | string | camera | square-normalized local URI |
| `fillLevel` | enum | tap scale | one of `FILL_LEVELS` |
| `capturedAt` | ISO timestamp | device | feeds last-updated / future recall |

---

## 5. Config surface (framework-first)

Everything below is a named variable. No hardcoded values anywhere in the capture module.

| Variable | Default | Framework rule vs. per-category |
|---|---|---|
| `FILL_LEVELS` | `['Full','¾','½','¼','Low']` | **Framework rule** — one global scale. Could be per-category (liquids continuous, whole spices coarse); recommend against for v1 — an ordinal bucket is all recall/reorder logic ever needs. |
| `DEFAULT_FILL` | `'¾'` | Framework rule. See open items — could be "unset/required." |
| `FILL_REQUIRED` | `false` | Framework rule. Open item. |
| `CAPTURE_CANVAS` | `1080 × 1080` | Framework rule. |
| `STAGING_ZONE` | `{ widthPct: 78, heightPct: 60, cornerRadius: 20 }` | **Framework rule** — single adaptive zone. Jar-shape presets (tall/standard/squat) are a phase-2 nicety, not v1. |
| `palette` | Porcelain Sky tokens | **Flagged decision** — Style AB is a one-block swap if in-app surfaces are ever re-skinned. |

---

## 6. Brand & visual (Porcelain Sky)

- Live camera feed underneath; **all chrome is frosted-glass Porcelain Sky floating on top** (`glass rgba(255,255,255,0.42)`, border `0.62`). No expo-blur — rgba simulation only.
- Staging-zone corner ticks and the active fill tick in **amber `#C9A66B`**. Capture button is the amber 58–64 pill with amber glow, matching the tab-bar scan button so the two camera entry points feel like one system.
- Type: zone hint in **Libre Baskerville italic**; scale labels and micro-hints in **DM Mono uppercase**; screen title in **Cormorant Garamond 600**. Wordmark unchanged (Place·italic amber W·ell).

---

## 7. Cross-platform requirements

- `useSafeAreaInsets` for the top bar and bottom capture cluster — no hardcoded padding.
- `overflow: 'hidden'` on the staging-zone container so corner ticks and the rounded mask render correctly on Android.
- No expo-blur anywhere.
- Review-screen note field (if surfaced) inherits LabelForm's existing `Platform.OS` / `KeyboardAvoidingView` rules.

---

## 8. Tech

- **expo-camera**, not react-native-vision-camera. With OCR dropped there is no live-frame processing, so the simpler capture-then-crop path is correct — and it sidesteps the vision-camera V5 / EAS Build (Xcode) breakage currently affecting SDK 54.
- Square crop via **expo-image-manipulator** after capture.
- No new native dependencies; nothing that collides with the Firebase native libs.

---

## 9. Open items (need your call)

1. **Default fill level** — pre-set to ¾, or force the user to choose (`FILL_REQUIRED: true`)?
2. **Fifth bucket wording** — "Low" vs "Empty" vs "¼ and under." Which reads right for a recall/reorder signal?
3. **When the fill level is set** — during framing, or only on the review screen? Current default: visible and settable during framing, confirmed on review.
