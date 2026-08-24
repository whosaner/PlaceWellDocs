# Stock Image — Implementation Plan (Roadmap #42)

*Authoritative implementation spec for per-label stock images.*
*Created 2026-08-14. Revised 2026-08-14 (rev 2) after a full design review.*
*Revised 2026-08-14 (rev 3): category-agnostic naming, label-name overlay geometry.*
*Revised 2026-08-14 (rev 4): resolves 5 blocking flaws from an adversarial design review.*
*Revised 2026-08-15 (rev 5): measured delivery sizes, deterministic text containment,
and the implemented five-asset bundled fallback.*
*Revised 2026-08-20 (rev 7): paired Firebase/Linode publication for server-side consumers.*

*Supersedes `Jar_Image_Strategy_Research.md`, which was written before the art was produced
and before the key contract was verified. Where the two disagree, **this document wins**.*

> **Revision 2 changed several decisions from revision 1.** Hosting moved from Linode to
> Firebase Hosting; `spice_key` was renamed `image_key`; `jarSku` was corrected to
> `labelSku`; the manifest gained `defaultQuantity` and a 3-part lookup key; the bundled
> manifest snapshot was dropped; `expo-image`'s managed cache was replaced with an
> app-owned cache in `documentDirectory`. Sections 4, 5, 10 and 11 are new or rewritten.

> **Revision 3** removes "jar"/"spice" from all implementation-facing names (§7), since the
> mechanism must serve future categories, and adds the label-name overlay design that rev 2
> omitted: §4.6 (geometry), D15–D17, and BC-32…BC-40. **D16 reverses rev 2**: the overlay
> now renders the *printed* label name, not the user's editable one.

> **Revision 4** applies the outcome of an adversarial design review (GPT-5.6 Sol) that found
> five blocking flaws in rev 3. Adds **D18–D23**, **§4.7** (the bundled fallback),
> **§9.1** (why capture-at-creation is not enough), and **BC-41…BC-48**; restates **BC-11**,
> **BC-12**, **BC-26**, **BC-35**; corrects **Q3**, **Q7**, and the **Q8 cost model**.
>
> | # | Flaw in rev 3 | Resolution |
> |---|---|---|
> | 1 | `CategoryPlaceholder`'s API cannot carry `imageKey`/`photoUri`/`printedLabelName`/`quantity`, and the photo ternary is duplicated at 5 call sites, so BC-10 is unenforceable | D18 — new `LabelArtwork` |
> | 2 | `imageKey`/`printedLabelName` can be missed by deep-link and transient-failure creation paths; Firestore cannot repair already-local AsyncStorage records | D19 + §9.1 — write-once demand-driven enrichment |
> | 3 | "Correct pixels on the first committed frame" is unachievable (async native decode) and untestable in Jest | D20 + BC-11 restated, BC-41–BC-43 |
> | 4 | BC-12 contradicted itself and raced BC-26; a screen-lifetime latch spans the whole wizard | D21 — explicit re-resolve boundaries |
> | 5 | D13 (no bundled manifest) broke Q3's offline "placeholder + name" promise | D22/D23 + §4.7 — geometry travels with the artwork |
>
> Two factual corrections: the Spark free tier covers only **~620 full-catalog downloads/month**
> and **disables Hosting** rather than billing; and `rect-portrait` is narrower but **not**
> lower than both other SKUs (its `centerY` sits between them).
>
> The same review raised twelve further MAJOR findings. Rev 5 resolves M2/M3; rev 6 resolves
> every Phase-2 finding. M9 remains deliberately deferred to Phase 3 and M11 belongs to the
> Phase-1 release workflow — see §14.

> **Revision 5** replaces the square/lossless delivery assumption with measured,
> content-cropped assets; replaces iOS-only `adjustsFontSizeToFit` with a deterministic
> glyph-width contract and hard clipping; and records the bundled fallback delivered by
> `PlaceWellApp` commits `745581d` and `78f5150`. Adds **D24–D26** and **BC-50…BC-59**. D12 and D23 are
> revised. M2/M3 and risk 9/10 are resolved or narrowed in §13–§14.
>
> **Revision 6** resolves the remaining Phase-2 architecture findings: semantic lookup is
> separated from immutable asset identity; manifest/image writes are verified and atomic;
> retry classes, in-flight deduplication, cache retention, missing-photo fallback, and
> repurposed-label behaviour are explicit. Downloaded art remains in `documentDirectory`
> and is excluded from device backup with native configuration. Active objects are never
> evicted; they change only when the server manifest publishes a new content hash.
>
> **Revision 7** keeps Firebase Hosting as the mobile delivery CDN and adds an exact-byte
> Linode mirror for the UI and QR Service. One release transaction publishes the same
> Firebase-oriented manifest and immutable WebPs to both targets; Linode consumers ignore
> `baseUrl`, resolve `file` locally, and follow an atomic `current` pointer.

---

## 0. What changed since the research document

The research doc planned for art that did not yet exist. The art now exists, and
verification against the real catalog produced these corrections:

| Research doc assumed | Actual verified state |
|---|---|
| 28 spices, `3 × 28 = 84` images to produce | **26 spices, 78 images already rendered** and approved |
| Keys would "just match" | **Only 21 of 28 matched.** 7 CSV rows had no art; 5 art files had no CSV row |
| Per-spice art generation is the main work | Art is **done**. The work is the **key contract**, hosting, and app resolution |

The renderer that produced the art is `C:\PlaceWell\spice-jar-renderer-code-assets`
(deterministic, offline, config-driven; `RELEASE_INVENTORY.md` records the approved set).
The rendered output currently lives at `C:\PlaceWell\Images\<labelSku>\<imageKey>\<quantity>\`.

---

## 1. Verified key mismatch (the blocking finding)

Comparing the 26 renderer art IDs (`config/spices/*.json`) against the 28 rows then in
`PlaceWellUI\data\spice.csv`:

| Result | Count | Items |
|---|---:|---|
| Exact match | 21 | basil, bay-leaves, black-pepper, chili-flakes, chili-powder, cinnamon, cloves, coriander, cumin, curry-powder, dill, garlic-powder, ginger, nutmeg, onion-powder, oregano, paprika, rosemary, sage, thyme, turmeric |
| CSV row with **no art** | 7 | allspice, cardamom, cayenne, fennel-seeds, mustard-seeds, star-anise, white-pepper |
| Art with **no CSV row** | 5 | cayenne-pepper, fennel, mustard-seed, italian-seasoning, salt |

Additional findings:

- **The app stores no art key at all.** `storage.js` persists `name`, `category`,
  `labelSku`, `placeholder`, `freshnessCategory` — nothing identifying the contents.
- **The QR service had no key field.** `lookup.py` returned `label_sku` and
  `label_metadata: { freshnessCategory }` only.
- **`SpiceJarPlaceholder.js` ignores `labelSku`** and renders one bundled PNG
  (`assets/spice-jar-large-transparent.png`, 1200×1920, 83 KB) for every SKU.

Had the resolver shipped against a slug derived from the user's text, **25% of spices would
have 404'd.**

---

## 2. Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **Renderer art IDs are the canonical key.** The CSV is rewritten to match. | The art names are the product names published on the Etsy store. |
| D2 | **The catalog is exactly the 26 entries that have art.** | Guarantees 1:1 coverage; no orphans on either side. |
| D3 | **The server owns the key. The app never derives it.** | Renames, typos, translations and re-branding stay safe. |
| D4 | **Static manifest + immutable content-hashed URLs.** No per-image lookup API. | Cacheable, offline-tolerant, zero server load. |
| D5 | **Publish one exact-byte release to Firebase Hosting and Linode.** The mobile app uses Firebase; UI/QR server consumers use `/opt/placewell-stock/current`. | Firebase remains the replicated delivery CDN. The Linode mirror avoids server-side CDN dependence and provides a shared immutable local root without creating a second manifest. |
| D6 | **The label name is overlaid at runtime, never baked into the image.** | One bare image serves every physical label with the same art identity; the immutable printed name is composed from label metadata without multiplying cached files. |
| D7 | **Stock art is derived state, never stored on the label.** | Photo add/remove needs no revert logic. |
| D8 | **Field is `image_key` / `imageKey`** *(revised — was `spice_key`)*. | The mechanism was never spice-specific; `load_items_from_csv` is already category-parameterised. |
| D9 | **SKU field is `label_sku` / `labelSku`** *(never `jarSku` or `product_sku`)*. | Already the established name in all three codebases (22 files). |
| D10 | **Lookup key is `imageKey\|labelSku\|quantity`** — 3-part from day one. | Phase 3 fill levels then require no schema or resolver change. |
| D11 | **Manifest declares `defaultQuantity`**; the app substitutes it. | One line, server-controlled; avoids duplicating all 78 entries or per-entry aliases. |
| D12 | **Export content-cropped lossy WebP at quality 95 with alpha quality 100** *(revised — rev 4 said lossless 720×720)*. | Measured q95 preserves transparency and costs less than the old uncropped lossless plan while delivering more useful object pixels. Delivery dimensions are per-SKU and non-square; see D24. |
| D13 | **No bundled manifest snapshot** *(revised)*. | A manifest without image bytes solves nothing offline; it only adds a build-sync artifact. |
| D14 | **The app owns its image cache in `documentDirectory`.** | `cacheDirectory` is OS-purgeable; a managed library cache cannot be queried synchronously, which would break the no-flicker contract. |
| D15 | **The cached file is the bare image with a blank label. The composite is never cached.** | One file serves every label using that key/SKU. Baking the name would put it in the cache key, multiply storage by distinct names, force a rewrite on any change, and rasterise text that should stay crisp at every size. |
| D16 | **The overlay shows the name printed on the physical label — not the user's editable name** *(revised — rev 2 said the opposite)*. | The image exists to help the user recognise a physical object. The printed text cannot change, so rendering an edited name would depict a jar that does not exist. |
| D17 | **`printedLabelName` is persisted on the label at creation and never written by an app-side edit.** | The server's `label_name` is visible exactly once — during the first lookup. Every later scan resolves locally by `label_id` and never contacts the server. |
| D18 | **A new `LabelArtwork` component owns the whole precedence chain** (photo → stock → fallback) and takes explicit fields, not a label record. `CategoryPlaceholder` is unchanged and becomes the bottom rung. | The `photoUri ? <Image> : <CategoryPlaceholder>` ternary is currently duplicated at 5 call sites, so precedence is decided *before* `CategoryPlaceholder` is reached and BC-10 is unenforceable. Explicit fields because `LabelFormScreen` has no saved label object — it assembles from route params, `originalLabel`, and live wizard state. |
| D19 | **Metadata enrichment is write-once and demand-driven.** `imageKey`, `printedLabelName`, and `labelSku` are nullable; a repair pass fills `null → value` only and never overwrites. | Capture is currently opportunistic and never repaired. See §9.1 — deep-link and transient-failure paths can leave even new labels permanently keyless. |
| D20 | **No visible swap, ever — including the decode window.** Reserved empty space is shown until pixels are ready. | RN `<Image>` decodes even `file://` sources asynchronously, so "correct pixels on the first committed frame" is unachievable by any implementation. Blank → art is not a swap; placeholder → art is. |
| D21 | **Resolution is latched *within* a re-resolve boundary and re-resolved *at* one.** Boundaries are screen focus and wizard step change. | A screen-lifetime latch is wrong on two counts: React Navigation keeps screens mounted for a whole session, and the wizard's steps are slides inside one screen. |
| D22 | **Geometry travels with the artwork it describes.** Downloaded art uses manifest geometry; bundled art uses a bundled constant. | Removes the last dependency between the offline fallback and the network. Preserves D13 exactly, because geometry for *stock* art is never needed without stock art. |
| D23 | **The bundled fallback is five transparent PNGs:** 3 SKU-accurate empty jars keyed by `labelSku`, plus `storage-box` and `generic-container` keyed by category. | This completes first-class fallback coverage for every current product category. Blank/unknown labels may use it permanently, so it cannot be treated as a temporary loading graphic. See §4.7. |
| D24 | **Delivery is content-cropped and contain-fitted into an 800 × 1080 physical-pixel envelope, never upscaled.** Geometry is renormalised onto the crop. | 800 × 1080 is the largest measured art surface (`HomeScreen` at 430 pt and 3×). Transparent margins were consuming resolution without improving fidelity; wide category art also proved that “1080 px tall” cannot be a universal rule. |
| D25 | **Text fitting is deterministic and platform-independent.** Use a generated uppercase glyph advance-width table, greedy word wrapping, an inscribed `safeWidth`, a legibility floor, ellipsis, and a hard-clipped box. Never depend on `adjustsFontSizeToFit`. | React Native declares `adjustsFontSizeToFit` in `TextPropsIOS`; it silently provides no containment guarantee on Android. The round sticker's declared box is 4.3% too wide at its binding edge. |
| D26 | **Bundled artwork is normalised into a 240 pt square and contain-fitted without stretching.** `full`/`wizard` = 240 pt, `tile` = 120 pt, `mini` = 52 pt. | The new category art is landscape (1.053 and 1.168) while jars range from 0.411 to 0.712. Keeping the old 150 × 240 footprint would make category art roughly half the jars' visual weight; `mini` must fit the actual 52 pt thumbnail rather than depend on clipping. |
| D27 | **Semantic lookup and cached asset identity are separate.** `imageKey\|labelSku\|resolvedQuantity` selects a manifest entry; the entry's full lowercase SHA-256 is the immutable `assetId` and object filename. | A semantic key may intentionally point to new art tomorrow. Keying disk files by the semantic key would keep serving stale bytes after a manifest update. |
| D28 | **Manifest and image writes are last-known-good, integrity-checked, and atomic.** Download to a same-directory temporary file, validate completely, then rename and update the index/pointer. | A partial Android download or malformed manifest must never become a permanent cache hit or replace a usable catalog. |
| D29 | **Network/HTTP failures and local-storage failures have separate state machines.** URL backoff records only remote failures; disk-full, permission, cancellation, and local I/O never poison an asset URL. | A future retry cannot repair a broken permission, while freeing storage can immediately repair disk-full. Combining them would suppress valid downloads for the wrong reason. |
| D30 | **One module-global in-flight map and a four-transfer priority semaphore own all image downloads.** The map is keyed by `assetId`; visible/wizard work precedes bulk warming. | Simultaneously mounted surfaces must share one verified write, and bulk import must not consume every transfer slot. |
| D31 | **Active stock objects are retained, not LRU-evicted.** The cache prunes only temporary/orphan files and objects referenced by neither the active nor previous last-known-good manifest. A 64 MiB safety ceiling rejects additional warming rather than deleting active art. | The catalog is small and the product requirement is download once, then change only when the server publishes a new content hash. |
| D35 | **The stock-art directory is excluded from iCloud and Android Auto Backup with native configuration.** This requires a development/production build; Expo Go is not the release-validation environment for this feature. | Persistent downloaded content should not consume backup quota or restore stale CDN objects onto another installation. |
| D32 | **Only a usable user photo participates in precedence.** New photos are copied atomically into app-owned storage; startup builds a synchronous availability index; native load errors re-resolve without leaving a blank surface. | A non-null picker cache URI can point to a missing file and currently wins resolution even though it cannot render. |
| D33 | **Repurposed labels can explicitly disable stock contents art without rewriting historical identity.** Add `artworkMode: "auto" | "fallback"` (default `auto`). `fallback` bypasses remote stock art but retains the physical `printedLabelName` on the SKU/category fallback. | `imageKey`, `labelSku`, and `printedLabelName` remain immutable facts about the issued label. A custom user photo remains the explicit way to depict repurposed contents. |
| D34 | **Artwork layout dimensions are explicit inputs, not discovered by a first-render `onLayout`.** The shared renderer receives the documented 240/120/52 point square preset and computes contain-fit synchronously. | Measuring after commit would move the overlay and violate the no-visible-swap contract. Orientation creates a new focus/layout boundary. |

> **Firestore is not a hosting option.** It is a document database; binaries do not belong in
> documents. The real comparison was Firebase **Hosting** (a CDN for static files) — not
> Cloud Storage, which is an object store needing token URLs and per-download egress.

---

## 3. Reconciled catalog (26 entries)

`spice.csv` goes from 28 rows to 26 and gains an explicit `image_key` column.

**Renames (3)** — these also change printed label text, since the CSV drives the PDF:

| Old `label_name` | New `label_name` | `image_key` | `freshness_category` |
|---|---|---|---|
| Cayenne | Cayenne Pepper | `cayenne-pepper` | `ground_chili` (unchanged) |
| Fennel Seeds | Fennel | `fennel` | `seeds` (unchanged) |
| Mustard Seeds | Mustard Seed | `mustard-seed` | `seeds` (unchanged) |

**Additions (2)** — art exists, no CSV row:

| `label_name` | `image_key` | `freshness_category` |
|---|---|---|
| Italian Seasoning | `italian-seasoning` | `dried_herb` |
| Salt | `salt` | `salt` (valid; `null` shelf life in `freshness.js`) |

**Removals (4):** Allspice, Cardamom, Star Anise, White Pepper.

> The art config's `category` field (`powder`, `whole`, `blend`, `flakes`, `dried-herb`) is a
> **rendering hint for the renderer** and is *not* the freshness category. The two are
> independent; `freshness_category` values are unchanged by this work.

---

## 4. Architecture

### 4.1 Hosting

The mobile app uses Firebase Hosting static files. **No Firebase SDK is used to fetch
them** — they are public CDN assets retrieved with an ordinary HTTPS GET. No auth, tokens,
or rules are required.

```
https://<project-id>.web.app/stock-images/manifest.v1.json
https://<project-id>.web.app/stock-images/img/<file>.webp
```

The plain `web.app` URL is used for now; a custom domain (`img.placewell.app`) can be added
later by changing only `baseUrl` in the manifest — no app change.

The same manifest bytes and every immutable WebP are also published to:

```text
/opt/placewell-stock/releases/<lowercase-manifest-sha256>/
/opt/placewell-stock/current -> releases/<lowercase-manifest-sha256>
```

UI and QR Service consumers ignore the Firebase `baseUrl` and resolve each manifest
entry's `file` under `current/img/`. Publication is paired: stage and verify Linode,
deploy and fully verify a Firebase preview channel, re-verify Linode, activate
`current` with rollback armed, then promote the verified preview to Firebase live.
No environment-specific manifest is generated.

### 4.2 Manifest

```jsonc
{
  "schemaVersion": 1,
  "manifestRevision": 7,
  "generatedAt": "2026-08-14T17:20:00Z",
  "rendererVersion": "0.9.0",
  "baseUrl": "https://<project-id>.web.app/stock-images/img/",

  "quantities": ["almost-full"],
  "defaultQuantity": "almost-full",

  // Delivered dimensions + transformed geometry are per SKU. Export crops every
  // master to its alpha content box and renormalises geometry onto that crop.
  "skus": {
    "round-1.5": {
      "canvas": { "width": 740, "height": 1080 },
      "label": {
        "shape": "rectangle",
        "centerX": 0.50065, "centerY": 0.51232,
        "width": 0.38421, "height": 0.08957,
        "safeWidth": 0.36851,
        "rotationDegrees": 0
      },
      "typography": {
        "fontId": "CormorantGaramond_600SemiBold",
        "fontWeight": 600,
        "lineHeight": 1.22,
        "letterSpacingEm": 0.14,
        "color": "#4A6070",
        "verticalAlign": "center",
        "includeFontPadding": false,
        "allowFontScaling": false,
        "minimumFontSize": 6,
        "maxLines": 2,
        "textAlign": "center",
        "textTransform": "uppercase"
      }
    },
    "square-1.75": { "canvas": {}, "label": {} },
    "rect-portrait": { "canvas": {}, "label": {} }
  },

  // Flat composite key: imageKey|labelSku|quantity — one lookup, no nested null checks.
  "images": {
    "turmeric|round-1.5|almost-full": {
      "displayName": "Turmeric",
      "file": "turmeric__round-1.5__almost-full.a91f3c.webp",
      "w": 740, "h": 1080,
      "bytes": 187612,
      "sha256": "<full-file-sha256>"
    }
  }
}
```

Notes:

- **`label.text` from the sidecar is deliberately dropped.** The user's own label name is
  drawn at runtime; ours would be wrong after any rename.
- Geometry travels with the manifest entry, so art and overlay can never desynchronise.
- `fontId` is the app's existing bundled display face,
  `CormorantGaramond_600SemiBold`, loaded by `App.js` through
  `@expo-google-fonts/cormorant-garamond`. It identifies both the runtime face and its
  generated glyph advance-width table. Export fails if either artifact is absent.
- Approx. 12–15 KB for 78 entries; one request.

### 4.3 Image URLs

```text
{baseUrl}{imageKey}__{labelSku}__{quantity}.{contentHash}.webp
```

Immutable by construction: different bytes produce a different hash, therefore a different
URL. There is no cache-busting step and no purge step.

One content-cropped variant per SKU, **lossy WebP q95 with alpha quality 100** (D12/D24).
The export contain-fits into 800 × 1080 physical pixels and never upscales. Current measured
delivery dimensions are 740 × 1080 (`round-1.5`), 743 × 1044 (`square-1.75`), and
385 × 937 (`rect-portrait`). The 1254² authoring canvas is never shipped.

### 4.4 `firebase.json` cache headers

```jsonc
{
  "hosting": {
    "public": "public",
    "headers": [
      {
        "source": "/stock-images/img/**",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      },
      {
        "source": "/stock-images/manifest.v1.json",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=300, must-revalidate" }
        ]
      }
    ]
  }
}
```

Images are public and unauthenticated — generic product art containing no user data. Adding
auth would break caching for no security benefit.

### 4.5 App-side components

| Module | Responsibility |
|---|---|
| `stockImageService` | The **only** code that fetches, caches, and resolves. Owns the manifest cache, the image cache, the in-memory index, and the failure ledger. |
| `LabelArtwork` | The only screen-facing artwork component. Owns photo → stock → bundled fallback and the re-resolve latch. |
| `LabeledStockImage` | Renders image + label-name overlay using manifest geometry. |
| `LabelTextOverlay` | Shared geometry + glyph-table fitter used by both downloaded stock art and bundled fallback art. This is the only implementation of BC-50…BC-55. |
| `CategoryPlaceholder` | Existing bundled-fallback resolver. Becomes the bottom rung under `LabelArtwork`; screens no longer decide precedence before calling it. |

**No screen ever builds a URL or calls `fetch` for art.**

---

### 4.6 Label name overlay

The renderer emits a **blank** label (`"mode": "dynamic"`) plus normalised geometry. The app
draws the name at render time as a native `<Text>` node. Nothing is baked (D15).

#### 4.6.1 Delivered geometry differs materially

| SKU | centerX | centerY | width | height |
|---|---:|---:|---:|---:|
| `round-1.5` | 0.50065 | 0.51232 | 0.38421 | 0.08957 |
| `square-1.75` | 0.55184 | 0.56289 | 0.39662 | 0.12612 |
| `rect-portrait` | 0.50781 | 0.54412 | **0.52114** | 0.13383 |

These values are the original sidecar geometry transformed onto each alpha-content crop.
They are deliberately different from the 1254² authoring values. All three retain
`rotationDegrees: 0`, `maximumLines: 2`, `textAlign: center`, and
`textTransform: uppercase`.

Do not compare the transformed widths to infer physical sticker size: each denominator is a
different crop width. Geometry must be consumed with the matching delivered canvas
(BC-33/BC-50).

#### 4.6.2 Step 1 — contain-fit

Delivered art and containers may both be non-square. Letterboxing is always in play, so the
label box must be derived from the **rendered image rectangle**, never the container (BC-32).

```
scale     = min(containerW / canvasW, containerH / canvasH)
renderedW = canvasW × scale       originX = (containerW − renderedW) / 2
renderedH = canvasH × scale       originY = (containerH − renderedH) / 2
```

#### 4.6.3 Step 2 — normalised geometry → container coordinates

```
boxX = originX + (centerX − width  / 2) × renderedW
boxY = originY + (centerY − height / 2) × renderedH
boxW = width  × renderedW
boxH = height × renderedH
```

**Resolution invariance.** `canvas` is consumed only for its **aspect ratio** — its absolute
size cancels out. A proportional resolution change cannot move the box:

```
canvas 740×1080: scale = min(258/740, 348/1080) = 0.3222
rendered = 238.4 × 348

canvas 370×540:  scale = min(258/370, 348/540) = 0.6444
rendered = 238.4 × 348
```

Identical. Cropping is different: it changes the canvas aspect and therefore requires
renormalising geometry once during export (BC-50). The manifest always records the delivered
dimensions and transformed geometry, never the authoring canvas.

**Worked example** — `round-1.5` in the recall hero card (258 × 348 pt):

```
scale     = min(258/740, 348/1080) = 0.3222
rendered  = 238.4 × 348      originX = 9.8      originY = 0
boxX = 9.8 + (0.50065 − 0.38421/2) × 238.4 = 83.3
boxY = 0   + (0.51232 − 0.08957/2) × 348   = 162.7
boxW = 0.38421 × 238.4 = 91.6
boxH = 0.08957 × 348   = 31.2
```

#### 4.6.4 Step 3 — text fitting

`adjustsFontSizeToFit` is forbidden: React Native declares it in `TextPropsIOS`, so it
cannot be the Android containment contract.

The export emits an uppercase glyph advance-width table for `fontId` (roughly 70 glyphs,
1–2 KB). Runtime fitting is pure arithmetic:

1. Apply `textTransform` and disable OS scaling (`allowFontScaling={false}`).
2. Use `safeWidth`, not raw `label.width`. For an ellipse, export computes the narrowest
   available chord at the text box's top/bottom edge. For `round-1.5`, transformed
   `safeWidth` is `0.36851` vs raw width `0.38421`.
3. Seed size from `boxH / lineHeight`, then greedily wrap at spaces using glyph advances,
   fixed tracking, and `lineHeight`. Never split a word.
4. Decrease size in deterministic 0.1 pt increments until width, height, and `maxLines` fit.
5. If the legibility floor is reached, use fewer lines where that helps; then ellipsize.
   At a size where no readable glyph can fit, suppress the overlay.
6. Render inside a hard-clipped (`overflow: hidden`) box. This is the final containment
   guarantee even for an unsupported glyph, emoji, malformed metrics, or RTL input.
7. Apply `rotationDegrees`. It is `0` for current assets but remains part of the schema.

Because every value derives from normalised geometry, the overlay lands in the same place
relative to the artwork at **every** size preset (BC-34).

#### 4.6.5 Which name is drawn

Precedence (D16):

```
① printedLabelName      server-provided, immutable — the physical truth
② manifest displayName  catalog name for that imageKey (pre-backfill labels)
③ user's name           blanks / handwritten labels, where nothing was printed
```

Rung ③ is correct for blank labels specifically: nothing was printed, the user wrote on the
label themselves, so their name *is* the closest thing to physical truth.

Editing a label's name in the app changes headings, search, and sorting — **never the image**
(BC-36).

### 4.7 The bundled fallback *(new in rev 4)*

#### 4.7.1 It is not an edge case

Blank labels, the 4 discontinued spices, and anything outside the 26-item catalog have **no
`imageKey` and will never receive stock art**. For those labels the bundled asset is not a
temporary offline state — it is the *permanent, only* artwork they will ever have. It must be
designed as a first-class rendering, not a degradation.

#### 4.7.2 Five assets cover both identity axes (D23)

The bundled set has two lookup axes:

- `round-1.5`, `square-1.75`, `rect-portrait` — selected by immutable `labelSku`.
- `storage-box`, `generic-container` — selected by category/placeholder when no SKU applies.

Unknown keys resolve to `generic-container`; a missing/unknown jar SKU resolves to
`round-1.5`. Resolution always returns drawable art.

#### 4.7.3 Each carries a blank white label patch

The current asset draws text straight onto glass. Rendering the fallback jars *with* a blank
white label instead buys three things:

1. Text sits on white and is legible over any background.
2. The fallback reuses the **exact per-SKU geometry** of the real art — one geometry table,
   not two.
3. Fallback → stock becomes visually continuous: same jar, same label, same position; only
   the contents appear.

An empty transparent jar carries no identifying information at all, so the overlaid name is
the entire content of that image — which is why rung ③ of §4.6.5 matters more than it looks.

#### 4.7.4 Geometry travels with the artwork (D22)

| Artwork source | Geometry source |
|---|---|
| Downloaded stock image | Manifest entry for that `labelSku` |
| Bundled fallback | `assets/fallback/geometry.json`, shipped beside the five PNGs |

There is no reachable state with art but no geometry: stock art can only exist if the
manifest that named its URL was fetched, and BC-47 forbids evicting that manifest while the
art survives. Bundled art and bundled geometry version together with the binary, so they
cannot skew. **D13 therefore stands unchanged** — rev 2's rejection of a bundled manifest was
about image bytes, and geometry for stock art is never needed without stock art.

#### 4.7.5 Delivered assets and validation *(implemented in rev 5)*

`PlaceWellApp` commit `745581d` replaces the three legacy placeholders with this set;
`78f5150` adds the shared deterministic overlay, generated glyph metrics, QR bounds, and
exact surface-size contract:

| Key | Axis | Delivered pixels | PNG |
|---|---|---:|---:|
| `round-1.5` | SKU | 740 × 1080 | 697 KB |
| `square-1.75` | SKU | 743 × 1044 | 832 KB |
| `rect-portrait` | SKU | 385 × 937 | 468 KB |
| `storage-box` | category | 800 × 760 | 975 KB |
| `generic-container` | category | 800 × 685 | 451 KB |

Total: **3.34 MB for five assets**, down from **4.18 MB for three** legacy assets.

The deterministic build script is `PlaceWellApp\scripts\build-fallback-artwork.py`. It:

1. crops each 1254² authoring canvas to its alpha content box;
2. contain-fits it into 800 × 1080 physical pixels without upscaling;
3. renormalises the label geometry onto that crop;
4. measures the category assets' clear text area above their baked-in QR;
5. computes elliptical `safeWidth`; and
6. writes PNGs plus `assets/fallback/geometry.json`.

The current script is crop/scale-idempotent when re-run against its own output. A
**Release-reproducible byte-for-byte output is now enforced** by `PlaceWellApp` commit
`1da8016`. The five source PNGs and three jar configs live under `artwork-sources/`;
`provenance.json` pins Python, Pillow, NumPy, the font package, and every input SHA-256.
`npm run artwork:check` performs an isolated rebuild and requires every committed PNG,
geometry record, and glyph-metrics artifact to be byte-identical. The app suite now contains
**326 tests across 25 suites**, including focused coverage for asset identity, dimensions,
key resolution, ellipse/QR containment, geometry positioning, glyph sanitization and
metrics, whole-word wrapping, ellipsis, clipping, legibility suppression, and contain-fit.
It does not execute the external release build pipeline.

**Why PNG:** these files are the final offline rung; a decode failure has no lower fallback.
PNG costs 3.34 MB but is universal. WebP q95 would be much smaller, but remains reserved for
downloaded stock art until iOS decode is proven.

**Sizing:** D26 is implemented: full/wizard = 240 pt, tile = 120 pt, and mini = 52 pt.
`LabelRecallScreen` uses full artwork, and `CategoryPlaceholder` no longer adds vertical
padding that could crop the 240 pt fallback on a narrow device.

**The baked-in sample QR is retained** as decorative realism on the 78 masters and all five
bundled fallbacks. It is never presented as scannable. The category text boxes deliberately
stop above it; the round sticker uses its inscribed `safeWidth`. The ellipse constraint is
already generated and regression-tested. Phase 1 must also emit category `qrBounds` into
`geometry.json`; only then can QR non-intersection become a stable release assertion rather
than a one-time visual measurement.

---

## 5. Behaviour contracts

Numbered, individually testable. Test suites in §11 reference these IDs.

### 5.1 Startup and blocking

| ID | Contract |
|---|---|
| **BC-01** | No art fetch is awaited before the splash screen hides. `initializeStorage()` completes without any network call for art. |
| **BC-02** | No `setInterval`, `expo-background-fetch`, or `AppState` listener is registered for art. All fetching is demand- or mount-driven. |

### 5.2 Manifest lifecycle

| ID | Contract |
|---|---|
| **BC-03** | The manifest is fetched on first actual need, and prefetched (unawaited) on `LabelFormScreen` and `BulkImportScreen` mount. |
| **BC-04** | A `200` manifest is accepted only when it is `application/json`, UTF-8 JSON no larger than 256 KiB, its deployment-generated SHA-256 digest matches, every schema/reference/URL/hash/byte/geometry field validates, and `manifestRevision` is monotonic. A lower revision, or the same revision with different bytes, is rejected. |
| **BC-05** | Subsequent fetches send `If-None-Match`. A `304` succeeds only when the stored snapshot still validates locally. If it is missing/corrupt, perform one unconditional GET. A validated replacement is committed temp → rename → current-pointer; the previous snapshot remains last-known-good until then. |
| **BC-06** | A cached manifest is used indefinitely while offline. Stale always beats absent. |
| **BC-07** | An unrecognised `schemaVersion` causes the manifest to be ignored — treated as absent, never a crash. |
| **BC-08** | Manifest fetch failure resolves to the built-in placeholder. No crash, no error dialog, no blocked UI. |
| **BC-09** | Manifest failure persists one global `retryNotBefore` for 15 minutes or a longer valid `Retry-After`. All callers and cold starts honour it; no startup request is forced. A stale validated manifest remains usable while revalidation is suppressed. |

### 5.3 Resolution

| ID | Contract |
|---|---|
| **BC-10** | Precedence is exactly: usable indexed `photoUri` → verified active stock object when `artworkMode = "auto"` → built-in fallback. `artworkMode = "fallback"` bypasses stock. |
| **BC-11** | When art is cached, `LabelArtwork` selects its **final source URI synchronously during the first render** — no `await`, no loading state — and never changes `source` for that label thereafter. *(Restated in rev 4: the rev-2 wording, "correct image on the first frame", is unachievable — see D20.)* |
| **BC-12** | Resolution is latched **within a re-resolve boundary** and re-resolved **at** one. Boundaries are screen focus and wizard step change. A visible image is never swapped in place inside a boundary. |
| **BC-13** | `quantity: "default"` resolves via `manifest.defaultQuantity`. |
| **BC-14** | A miss on the exact quantity falls back to `defaultQuantity`, then to the placeholder. |
| **BC-15** | A null or unknown `imageKey` (blanks, order QRs, non-spice categories) resolves to the placeholder as a **normal branch**, not an error. |
| **BC-16** | Identical semantic inputs resolve to the same active descriptor `{assetId, geometryId, file, bytes}` across every size preset. Disk objects are keyed only by `assetId`, never by the semantic lookup key or label name. |

### 5.4 Image download and cache

| ID | Contract |
|---|---|
| **BC-17** | The download URL is exactly `baseUrl + file` from the manifest entry. |
| **BC-18** | Images use `stock-images/tmp/<assetId>.<nonce>.part` and `stock-images/objects/<assetId>.webp` under app-owned persistent storage, never `cacheDirectory`. A write commits only after HTTP 200, `image/webp`, exact manifest byte count, maximum 2 MiB, and SHA-256 = `assetId`; then same-directory rename precedes the object-index update. |
| **BC-19** | A verified retained object matching the active manifest triggers **zero** network calls. Eviction or integrity invalidation permits re-download. |
| **BC-20** | Remote failures render the fallback and update a ledger keyed by canonical asset URL. Local disk/permission/I/O failure and caller cancellation create no URL-ledger entry. |
| **BC-21** | Remote failure classes are exact: network/DNS/TLS/15 s timeout/408/5xx are transient; 429 is transient with `Retry-After`; 403 is terminal for the current `manifestRevision`; 404/410 are permanent for that URL; content-type/byte/hash mismatch is integrity-terminal for that asset identity. Transient attempts become eligible in a different session, then after 1 h, 6 h, and 24 h for attempt 4+. Success clears the record. |
| **BC-22** | `Retry-After` applies to 429/503. Numeric seconds are accepted; an HTTP-date is measured from the response `Date` header, not device time; valid delays clamp to 60 s–24 h. Invalid/missing values use normal backoff. |
| **BC-23** | A changed content hash produces a new URL, which is absent from the ledger and therefore fetched normally — self-healing after a corrected deploy. |
| **BC-24** | There is **no startup sweep** that retries all previously failed images. |
| **BC-60** | A module-global `Map<assetId, Promise>` is populated before the first `await`; all callers share that promise. It is removed in `finally` only when still current. Consumer unmount does not cancel shared work. |
| **BC-61** | Exactly four image transfers may run. Visible and wizard requests have priority over bulk warming; bulk cannot reserve all slots. |
| **BC-62** | Verified objects referenced by the active or previous last-known-good manifest are never evicted. Before warming, unreferenced objects are pruned; if retained objects plus the candidate exceed 64 MiB, warming is skipped without deleting active art. A visible on-demand request may still replace the obsolete object for that same semantic key after a new hash is published. |
| **BC-63** | Startup index warm-up removes `.part` files, orphan/malformed objects, missing-file index rows, objects referenced by neither retained manifest, and unreferenced ledger rows. A native stock decode error invalidates and removes only the corrupt object. |
| **BC-64** | Disk-full performs one unreferenced-object cleanup pass and one write retry, then enters a 15-minute process storage cooldown. Permission failure disables writes for the process lifetime. Neither changes URL backoff, and neither evicts active art. |
| **BC-69** | iOS marks the stock-art directory excluded from iCloud backup; Android backup rules exclude the same directory from cloud and device-transfer backup. Release validation inspects both generated native configurations. |

### 5.5 Prefetch

| ID | Contract |
|---|---|
| **BC-25** | `LabelFormScreen` mount triggers a manifest prefetch; it is not awaited and does not block render. |
| **BC-26** | Advancing from the Name step resolves the key and starts the image prefetch. While that prefetch is in flight the Photo step renders **reserved empty space**, not the fallback. The fallback appears only on prefetch failure or after a **2 s** timeout, and then latches until the next boundary. |
| **BC-27** | `BulkImportScreen` mount warms the whole `orderLabels` set. Pressing Create promotes the same deduplicated requests and waits until they settle or **5 s**, whichever comes first, while displaying “Preparing your labels…”. Creation then proceeds automatically and unfinished requests continue without cancellation. |
| **BC-28** | The batch dedupes by `assetId` (N labels → M unique objects) and skips verified retained objects or null keys. |
| **BC-29** | Batch work uses the shared exact four-transfer semaphore and lower priority than visible/wizard requests. |
| **BC-30** | Batch partial failure is tolerated: successes are cached, failures are ledgered, no error UI, no retry storm. While a known stock asset is pending, the correct fallback shape is dimmed under a loading indicator; failure restores the normal fallback. Offscreen native bitmap warming times out inconclusively after **2 s**, retaining the verified WebP so the visible image remains the final decode authority. |
| **BC-31** | Stock art is warmed **even when the user sets their own photo**, so a later removal reveals it instantly with no fetch. |

### 5.6 Label name overlay

| ID | Contract |
|---|---|
| **BC-32** | The label box is computed from the **rendered image rectangle** (after contain-fit letterboxing), never from the raw container. Asserted with a deliberately non-square container. |
| **BC-33** | Geometry and typography come from the manifest/bundled geometry record. No position, size, font metric, or fitting threshold is hardcoded in a screen component. |
| **BC-34** | For a given SKU, the overlay's position relative to the image is identical across all size presets (`full`/`wizard`/`tile`/`mini`) when normalised. |
| **BC-35** | All three SKUs produce distinct, correct boxes from the same code path. For a 258 × 348 pt container, independent literal goldens are: round `(85.22041, 162.70218, 87.86916, 31.17036)`, square `(92.72426, 173.94084, 98.22955, 43.88976)`, portrait `(92.85829, 166.06734, 74.51690, 46.57284)`, tolerance ±0.01 pt. Tests must not derive expectations with the runtime/export helper. |
| **BC-36** | Editing `name` does not alter the overlay while `printedLabelName` exists. When it is absent, `name` is the documented final fallback and may change the overlay. |
| **BC-37** | Overlay name precedence is exactly `printedLabelName` → manifest `displayName` → `name`. |
| **BC-38** | `printedLabelName` is written once at creation (from `lookupLabel` or `lookupOrder`) and is never mutated by any app-side edit path. |
| **BC-39** | The cache key excludes the name. Two labels with different names but the same `imageKey\|labelSku\|quantity` share **one** cached file and issue **one** download. |
| **BC-40** | Jest asserts `textTransform`, `textAlign`, `maximumLines` and `rotationDegrees` wiring. Android and iOS release-smoke screenshots independently prove native clipping/alignment using forced two-line and nonzero-rotation fixtures; platform baselines allow at most 0.5% changed pixels in the artwork region. |
| **BC-50** | Exporting a content crop renormalises `centerX`, `centerY`, `width`, `height`, `safeWidth`, and any mask bounds onto the delivered canvas. Golden values are asserted independently from runtime fixtures. |
| **BC-51** | `round-1.5` uses `safeWidth = 0.36851` on the delivered crop. Its raw width (`0.38421`) is proven to cross the ellipse; the safe box is proven to remain inside at both horizontal edges. |
| **BC-52** | Android and iOS use the same glyph advance-width table and greedy wrapping algorithm. `adjustsFontSizeToFit` is absent from the implementation. |
| **BC-53** | `allowFontScaling` is false; `fontId`, weight, line height, tracking, colour, vertical alignment, and `includeFontPadding` match the geometry record. |
| **BC-54** | At the legibility floor, fitting reduces line count before ellipsizing. If one readable glyph cannot fit, the overlay is suppressed. |
| **BC-55** | The label box has `overflow: hidden`; no name, including one long token, emoji, unsupported glyphs, or RTL text, can paint outside it. |

### 5.7 Startup, decode, and enrichment *(new in rev 4)*

| ID | Contract |
|---|---|
| **BC-41** | The cache index is warmed inside `App.js` `prepare()` **before** `setAppReady(true)`, so no screen ever mounts with a cold index. This is the only art work permitted before the splash hides, and it touches disk only — never the network (preserves BC-01). |
| **BC-42** | During the native decode window, `LabelArtwork` renders **reserved empty space** of the correct dimensions — never the fallback, never a layout shift. |
| **BC-43** | Prefetch warms the **decoded bitmap**, not just the file, by rendering the cached file once into an offscreen 1×1 `<Image>`. |
| **BC-44** | Enrichment fills `null → value` only. Given a label with a non-null `imageKey`, `printedLabelName`, or `labelSku`, no enrichment path may overwrite it. Enforced centrally in `saveLabel`, not per caller. |
| **BC-45** | Enrichment synthesises the HMAC signature locally via `computeSignature(labelId)` and reuses the existing `/api/qr/lookup/{id}-{sig}` endpoint. A label first seen via `placewell://scan/ID` (no signature) is still enriched. |
| **BC-46** | `printedLabelName` is captured from the QR URL's `?n=` parameter with **no network call** on the standard scan path. |
| **BC-47** | The manifest cache is **never evicted while any image it references remains cached**, so no reachable state has art without geometry. |
| **BC-48** | With no manifest and no network, a label still renders its resolved SKU/category bundled fallback **with its name**, using bundled geometry (D22, D23). |
| **BC-49** | The computed box is identical for two proportionally equivalent canvas sizes at the same container size. `canvas` is consumed for aspect ratio only; resolution changes cannot move the overlay. Cropping is separately covered by BC-50. |
| **BC-56** | The bundled registry contains exactly five drawable keys: 3 SKU keys and 2 category keys. Unknown category → `generic-container`; unknown/missing jar SKU → `round-1.5`. |
| **BC-57** | Every bundled file is PNG, lies within 800 × 1080, and is never stretched or upscaled by the build. The release pipeline pins source checksums, jar configs, Python, Pillow and NumPy versions; only that pinned pipeline must reproduce byte-identical files and geometry. |
| **BC-58** | Full/wizard fallback art contain-fits 240 pt, tile 120 pt, and mini 52 pt. Wide category art fits by width, tall jar art by height; no wrapper clips an oversized fallback. |
| **BC-59** | Category geometry includes explicit `qrBounds`. The label rectangle and QR exclusion rectangle have an empty intersection for both category assets. |
| **BC-65** | A saved photo URI is persisted only after an atomic copy into app-owned photo storage. Startup builds a synchronous availability index; missing/unreadable paths are treated as null before precedence selection. |
| **BC-66** | `onError` before a photo's first `onLoad` marks it unusable for the session and resolves stock/fallback from reserved space. An error after `onLoad` keeps the current boundary latched and invalidates the photo for the next boundary. |
| **BC-67** | `artworkMode` defaults to `auto`. `fallback` bypasses remote stock art without clearing or rewriting `imageKey`, `labelSku`, or `printedLabelName`; saving this setting is a re-resolve boundary. |
| **BC-68** | Artwork box size is synchronously known from the preset. Runtime `onLayout` is not used to establish initial overlay geometry. Rotation/orientation begins a new layout boundary. |

---

## 6. Answers to the original design questions

### Q1 — The lookup service

A static manifest plus deterministic URLs, not an API. A per-request endpoint would add
latency, a failure mode, and server load for content that changes a few times a year. The QR
service's only new responsibility is **returning `image_key`** on lookup and order responses.

### Q2 — Service unavailable / image not found

Failure is structural, not exceptional (BC-08, BC-15, BC-20). Every level is guaranteed to
render, and the last one is compiled into the binary, so **no reachable state leaves the app
with nothing to draw.**

### Q3 — Offline

| Scenario | Result |
|---|---|
| Offline, art seen before | Cached art, full fidelity (BC-19) |
| Offline, never seen, manifest cached | Resolved SKU/category fallback + name |
| Offline, never seen, no manifest | Resolved SKU/category fallback + name (BC-48) |
| Offline, blank/unknown label | Resolved bundled fallback + name — **permanently**, §4.7.1 |

The manifest is served stale indefinitely while offline (BC-06). **No manifest is bundled**
(D13): without image bytes it would change nothing, since a never-connected device cannot
have art either way.

> **Rev 4 closed a hole here.** Rev 2 promised "placeholder **+ name**" with no manifest,
> while requiring all overlay geometry to come from the manifest — a contradiction. Resolved
> by D22: geometry travels with the artwork, so bundled art carries bundled geometry and
> needs no network. D13 is unaffected. See §4.7.4.

### Q4 — Download once

Guaranteed by content-hashed filenames, `immutable` cache headers, and an app-owned cache in
`documentDirectory` that the OS does not purge (D14, BC-18, BC-19). Active objects are not
LRU-evicted. They are downloaded once and replaced only when the active manifest publishes a
new content hash for that semantic key, or when integrity/decode validation proves the local
copy corrupt. The manifest alone revalidates, usually as a cheap `304`.

### Q5 — Label name and local storage

Geometry and text fitting are specified in full in §4.6. Summary:

- The renderer emits a **blank** label plus normalised geometry; the app draws the name as a
  native `<Text>` positioned from the **rendered image rect**, not the container (BC-32).
- Fitting uses a bundled-font glyph table, deterministic wrapping, `safeWidth`, ellipsis, a
  legibility floor, and hard clipping (D25). It does not rely on iOS-only
  `adjustsFontSizeToFit`.
- The composite is **never** written to disk (D15). The cached file is the bare image, shared
  by every label with the same `imageKey|labelSku|quantity` (BC-39). Recomposing each render
  costs nothing and keeps text crisp at every preset.
- The name drawn is the **printed** one, not the user's editable name (D16, §4.6.5). A
  rename therefore cannot invalidate a cached image, and "re-render on rename" is not a case
  that exists (BC-36).

**Selected face:** `CormorantGaramond_600SemiBold`, already bundled and loaded before the app
renders. Phase 1 generates and versions its glyph table; export and app builds fail if the
face or metrics artifact is missing.

### Q6 — User photo add / remove

The label carries `photoUri` (nullable) and `imageKey` (immutable identity). Stock art is
derived, never persisted onto the label (D7).

- **Add:** set `photoUri` → precedence selects level 1.
- **Remove:** `photoUri = null` → precedence falls to stock art, which returns automatically.

**No revert logic is needed, because nothing was ever overwritten.** The one rule to enforce:
`imageKey` is set at creation and never cleared by a photo edit. Combined with BC-31, removal
is instant and flicker-free.

### Q7 — Consistency across surfaces

Art renders in seven places: `HomeScreen`, `LabelCard`, `RoomSection`, `LabelDetailScreen`,
`LabelRecallScreen`, `LabelFormScreen`, and the photo viewer. Consistency is structural: one
resolver (§4.5), one component, one cache key (BC-16). The bundled baseline is a 240 pt
contain-fit square (D26); each surface selects only the documented scale, never a separate
asset or geometry path.

| Surface | Measured container | Required fallback size |
|---|---:|---:|
| Home carousel | ≈267 × 360 pt | `full` — 240 pt |
| Label Recall hero | 258 × 348 pt | `full` — 240 pt |
| Label Detail | 258 × 348 pt | `full` — 240 pt |
| Label Setup photo step | wizard viewport | `wizard` — 240 pt |
| RoomSection tile | square two-column tile | `tile` — 120 pt |
| LabelCard thumbnail | 52 × 52 pt | `mini` — 52 pt *(currently 67.2 and clipped)* |

This table is the acceptance target. No surface-specific aspect-ratio tweak is permitted;
all use `resizeMode="contain"` through the shared renderer.

> **Rev 4:** this was aspirational, not true. `CategoryPlaceholder` receives
> `{ placeholder, category, labelName, labelSku, size, onPress }` — no `imageKey`,
> `photoUri`, `printedLabelName`, or `quantity` — and the
> `photoUri ? <Image> : <CategoryPlaceholder>` ternary is **duplicated at 5 call sites**, so
> precedence is decided before the shared component is ever reached. D18 fixes this with a
> new `LabelArtwork` component that owns the chain; only then is BC-10 structural rather
> than something asserted five times.

### Q8 — Hosting

| Factor | Firebase Hosting | Linode |
|---|---|---|
| Availability | Replicated CDN with SLA | Single VM; reboots, disk, cert renewal |
| Latency | Edge nodes | One region |
| Free tier (Spark) | 10 GB storage / **10 GB egress per month** | n/a (already paid) |
| Payload | estimated **≈14 MB** for the complete q95 catalog; final deterministic export is authoritative | Same |
| Free-tier capacity | approximately **700 full-catalog downloads/month** at 14 MB | Unmetered |
| Behaviour at quota | Spark **disables Hosting** — it does not auto-bill | Degrades under load |
| Cost beyond free | $0.15/GB, requires **Blaze** | Zero marginal |

**Decision: paired Firebase Hosting + Linode publication (D5).** Firebase is the mobile
delivery CDN; Linode is the shared local source for UI/QR consumers. They are not competing
manifests: one deterministic package is verified on both targets before Linode `current`
changes.

> **Corrected in rev 4 and re-estimated in rev 5.** Revision 2 claimed the payload was
> "0.16% of quota" and cost "≈ $11 at 10k users/mo". Both were wrong. Storage is not the
> binding constraint; **egress is**. Rev 5's q95/cropped measurement reduces the provisional
> complete catalog from 16.5 MB to approximately 14 MB, but Phase 1 must publish the exact
> deterministic total before any capacity claim is treated as final.
> Real usage is far below a full catalog per user — most users own a handful of spices — but
> the figure has never been modelled, and the $11 number had no usage model behind it.
>
> Two consequences, both required before production:
> 1. **Move to Blaze before launch.** On Spark, crossing the quota *takes the art offline*
>    rather than billing a few dollars. The fallback would hold (BC-08), but silently.
> 2. **Add an egress alert** and a modelled art-per-user estimate. Until then, treat the
>    prefetch aggressiveness in §5.5 as provisional — warming art the user may never view is
>    exactly what inflates this number.

### Q9 — Publishing new art for an existing entry

1. Re-render. 2. New bytes → new hash → **new URL**. 3. Regenerate manifest, bump
`manifestRevision`. 4. Deploy the paired release, retaining all prior immutable Linode
releases and Firebase objects. This initial implementation performs no automatic pruning.

Devices on a cached manifest show old art until revalidation — correct, not broken. **No
stale-image bug class is possible**, because a URL's bytes never change. Changed geometry
ships with the new entry, so image and overlay stay in sync.

### Q10 — Key verification

Answered in §1, fixed by D1/D2, and permanently enforced by the CI guard in §9 item 8.

---

## 7. Naming migration (`spice_key` → `image_key`)

Phase 0 initially used the field name `spice_key`. D8 renames it. Critically:

- **Zero occurrences in `PlaceWellApp`** — the app never consumed it.
- There are no customer labels requiring migration.

Therefore the rename is a pure code/doc change with **no data migration and no impact on
printed labels. New allocations persist `image_key`; lookup/order return it. Existing
development documents with the field absent remain valid and resolve the bundled fallback.

Test renamed: `test_spice_catalog_keys.py` → `test_image_catalog_keys.py`.
Functions renamed: `build_spice_key_index()` → `build_image_key_index()`,
`resolve_spice_key()` → `resolve_image_key()`.

---

## 8. Asset masters repository

Implemented as private repository
`https://github.com/whosaner/PlaceWell-StockImageMasters`, initial commit `5ffef7a`:

- 78 transparent 1254² PNG masters tracked through Git LFS.
- 78 renderer JSON sidecars plus the three original batch manifests.
- Existing `<labelSku>/<imageKey>/<quantity>/` layout retained.
- Generated WebP files excluded; they are release outputs, not canonical inputs.
- `release-inputs.json` pins byte size and SHA-256 for every PNG/sidecar.
- `scripts/verify_release_inputs.py` rejects a missing, changed, or incomplete 78 × 2 set.

This repo is the **input** to the Phase 1 export. It is never deployed.

---

## 9. Phase 0 — key reconciliation (server-side; largely complete)

| # | Change | File | Status |
|---|---|---|---|
| 1 | Catalog to 26 rows + key column | `PlaceWellUI\data\spice.csv` | done (rename pending) |
| 2 | Read the key from CSV | `PlaceWellUI\app\order_builder.py` | done (rename pending) |
| 3 | Forward the key in the allocate payload | `PlaceWellUI\app\qr_client.py` | done (rename pending) |
| 4 | ~~Add the key to the operator grid~~ | `form.html` | **rejected** — see note |
| 5 | Key on `AllocationItem` + Firestore write | `PlaceWellQRService\app\allocate.py` | done (rename pending) |
| 6 | Return the key top-level on lookup + order | `lookup.py`, `order.py` | done (rename pending) |
| 7 | Missing-field backward compatibility | lookup/order + app resolver | approved: null/absent → bundled fallback |
| 8 | CI guard: CSV keys ≡ art config IDs | QR service tests | done (rename pending) |
| 9 | Docs update | `System_Overview.md`, `ROADMAP.md` | in progress |

> **Item 4 was deliberately rejected.** `form.html` rebuilds table rows as JSON on submit, so
> a hand-typed key would be lost, and an editable field invites typos. The key is resolved
> server-side from the display name (casefold + strip) in `build_spice_key_index()` /
> `resolve_spice_key()` instead.

The key is returned as a **top-level** lookup field, not inside `label_metadata`, so
non-spice categories can reuse it. No backfill is required: there are no customer documents,
and null/missing `image_key` is a normal backward-compatible fallback branch.

### 9.1 Why capture-at-creation is not enough *(new in rev 4)*

Two creation paths can leave a label permanently without `imageKey` / `printedLabelName`, and
they share one root cause: **metadata is captured once, opportunistically, and never
repaired.**

| # | Path | What happens |
|---|---|---|
| 1 | **Deep link** `placewell://scan/ID` | `parseQRCode` returns `signature: null`; `lookupLabel` returns `null` *without fetching*. The label is created with `category`, `labelSku`, and name **all null**. This affects **new** labels today, not just legacy ones. |
| 2 | **Transient failure at first scan** | `lookupLabel` returns `null`, the label is created anyway, and `getLabelById` succeeds forever after — so the server is never asked again. Permanent. |

Two facts make the repair far cheaper than a new endpoint:

- **The app can synthesise the signature itself.** `src/utils/hmac.js` already embeds
  `HMAC_SECRET` and computes `SHA256("SECRET:LABELID")[0:4]` locally for offline
  verification. Exposing `computeSignature(labelId)` lets enrichment call the **existing**
  `/api/qr/lookup/{id}-{sig}` endpoint. No new endpoint, no new secret exposure (BC-45).
- **The QR already carries the printed name offline.** `https://placewell.app/s/ID-SIG?n=Flour`
  — `parseQRCode` extracts it. `printedLabelName` needs no network on the standard path
  (BC-46).

**Trigger (D19):** demand-driven — when a label with a null `imageKey` is about to be
displayed, plus opportunistically during the existing BulkImport / Label Setup prefetch. **No
startup sweep**, consistent with BC-02.

**Immutability is enforced in `saveLabel`,** not in each caller (BC-44) — a list of callers
can never be proven complete.

### Capture points for `printedLabelName`


The server's `label_name` is visible to the app exactly **once**. `ScannerScreen` resolves a
known label locally via `getLabelById(labelId)` and never calls the server again:

```
scan → validateQRCode (local HMAC, works offline) → getLabelById(labelId)
   ├── FOUND     → navigate. NO server call, ever again.
   └── NOT FOUND → lookupLabel()  ← the only moment label_name is available
```

So both creation paths must capture it:

| Path | Entry point |
|---|---|
| Single label | `lookupLabel()` → label creation |
| Bulk / order | `lookupOrder()` → `orderLabels` → `bulkCreateLabels()` |

Missing it at creation requires a later demand-driven lookup. Existing development labels
may instead remain on the bundled fallback or be recreated; there is no production migration.

---

## 10. Phase 1 — export and hosting

1. Create a pinned release-input bundle: 78 masters + sidecars, 5 fallback authoring PNGs,
   jar configs, checksums, Python version, Pillow version, and NumPy version. The build must
   not depend on mutable absolute paths outside that bundle.
2. Read the 78 sidecars from the pinned masters input (§8).
3. Crop each master to its alpha content box; transform label/mask geometry from the 1254²
   authoring canvas onto that crop (BC-50).
4. Contain-fit the crop into 800 × 1080 without upscaling and encode **WebP q95,
   alpha-quality 100** (D12/D24).
5. Content-hash each file; name it `{imageKey}__{labelSku}__{quantity}.{hash}.webp`.
6. Generate `manifest.v1.json` (§4.2) with delivered dimensions, transformed geometry,
   `safeWidth`, byte size, SHA-256, and the versioned typography record. Drop `label.text`.
7. Generate the uppercase glyph advance-width table from the exact bundled `fontId`. Fail
   export if the font or metrics artifact is absent.
8. Preserve the implemented category `qrBounds` and prove non-intersection with their text
   boxes (BC-59).
9. Validate catalog keys, all geometry bounds, the ellipse chord calculation, dimensions,
   hashes, byte sizes, content types, and deterministic output.
10. The five bundled PNGs and `geometry.json` are already implemented by
   `PlaceWellApp\scripts\build-fallback-artwork.py` (§4.7.5); verify the app's generated
   artifacts match the release input.
11. Deploy through `Docs\scripts\deploy_stock_images.ps1`: stage and verify the immutable
    Linode release, deploy and verify a Firebase preview channel from the masters
    package, atomically switch Linode `current` with rollback armed, then promote the
    verified preview to Firebase live. Restore Linode if promotion definitively fails;
    preserve recovery state if the live outcome cannot be determined or the new live
    release does not pass complete object and header verification.
12. Preserve the Firebase-oriented manifest bytes exactly on Linode; local consumers ignore
    `baseUrl` and resolve `file` under `current/img/`.
13. Publish the exact complete-catalog byte total for the egress model. Retain prior Linode
    releases and Firebase immutable objects; do not prune automatically in the initial
    implementation.

The export must be **deterministic and repeatable** — same masters in, same hashes out.

---

## 11. Phase 2 — app integration and test plan

### 11.1 Implementation

- `stockImageService` (§4.5) — manifest cache + ETag, image cache in `documentDirectory`,
  in-memory descriptor/object index, atomic verified writes, separate remote/storage failure
  state machines, global in-flight dedupe, four-transfer priority semaphore, retained-object
  pruning, and prefetch API (incl. bitmap warm, BC-43).
- Add native iOS/Android configuration that excludes only the stock-art directory from
  backup (D35/BC-69); release validation uses generated native projects, not Expo Go.
- Warm the cache index in `App.js` `prepare()` before `setAppReady(true)` (BC-41).
- Persist `imageKey` **and `printedLabelName`** through `storage.js`, `qrService.js`, and
  `bulkCreateLabels`, with write-once immutability enforced **inside `saveLabel`** (BC-44).
- Export `computeSignature(labelId)` from `hmac.js`; build the demand-driven enrichment pass
  (§9.1, D19, BC-45/46).
- **`LabelArtwork`** (D18) owning photo → stock → fallback; migrate all 5 call sites off
  their local ternary. `CategoryPlaceholder` stays as the fallback leaf.
- Reuse the implemented `LabelTextOverlay` from `78f5150`; make `LabeledStockImage` use the
  same component. It owns glyph-table fitting, safe width, hard clipping, sanitization,
  whole-word ellipsis, and legibility suppression (BC-50…BC-55).
- `LabeledStockImage` implements image placement and reserved empty space during decode
  (BC-42), delegating all overlay rendering to `LabelTextOverlay`.
- Reuse the implemented five-asset fallback registry and generated geometry from
  `PlaceWellApp` commits `745581d` and `78f5150` (D22, D23, D26, §4.7).
- Fix `photoUri` persistence and build the synchronous availability/error fallback path
  (D32, BC-65/66).
- Persist `artworkMode` with default `auto`; expose the explicit `fallback` opt-out without
  mutating issued identity fields (D33, BC-67).

### 11.2 Test suites

Each maps to behaviour contracts in §5.

| Suite | Covers | Key assertions |
|---|---|---|
| `stockImageService.manifest.test.js` | BC-03…BC-07 | full validation and digest; monotonic revision; last-known-good atomic pointer; valid `304`; corrupt/missing `304` body forces one unconditional GET; stale served offline |
| `stockImageService.manifestFailure.test.js` | BC-08, BC-09 | failure → fallback, no throw; persisted 15-minute suppression applies across cold starts; stale remains usable |
| `stockImageService.resolve.test.js` | BC-10…BC-16, BC-67 | usable-photo precedence; `artworkMode`; `default` resolution; null key normal; semantic descriptor stable across presets; changed hash selects new `assetId` |
| `stockImageService.imageFetch.test.js` | BC-17…BC-19 | URL exact; temp download; MIME/bytes/SHA verified before rename/index; retained hit issues zero requests |
| `stockImageService.imageFailure.test.js` | BC-20…BC-22, BC-64 | exact HTTP/integrity/local classes; `Retry-After` clock handling; local storage never poisons URL ledger |
| `stockImageService.imageRetry.test.js` | BC-21…BC-24 | session/1 h/6 h/24 h state machine; terminal URL classes; new hash eligible; no startup sweep |
| `stockImageService.concurrency.test.js` | BC-60, BC-61 | simultaneous callers share one promise/write; exactly four transfers; visible work overtakes queued bulk; unmount does not cancel shared work |
| `stockImageService.retention.test.js` | BC-62, BC-63 | active/previous-manifest objects retained; stale/orphan/partial cleanup; 64 MiB skips warming rather than evicting active art; decode corruption removes one object |
| `stockImageService.coldStart.test.js` | BC-01, BC-02 | `initializeStorage()` resolves with no art request; no timers or `AppState` listeners registered |
| `BulkImportScreen.artPrefetch.test.js` | BC-27…BC-30 | 30 labels → M unique `assetId` requests; shared four-transfer priority cap; partial failure renders no error UI |
| `LabelFormScreen.artPrefetch.test.js` | BC-25, BC-26, BC-31 | manifest prefetch on mount, unawaited; image prefetch on Next; art warmed even when a user photo is set |
| `LabeledStockImage.noFlicker.test.js` | BC-11, BC-12, BC-42 | final source URI chosen synchronously on the first render; `source` never changes within a boundary; reserved empty space (not the fallback) during decode |
| `LabelArtwork.precedence.test.js` | BC-10, BC-42, BC-65…BC-68 | one component owns usable photo → stock → fallback; missing/native-error photo paths; explicit stock opt-out; synchronous preset dimensions; no call site retains a local ternary |
| `stockImageService.startup.test.js` | BC-01, BC-41, BC-43 | index warmed in `prepare()` before `setAppReady(true)`; disk-only, zero network; prefetch warms the decoded bitmap |
| `enrichment.writeOnce.test.js` | BC-44, BC-45, BC-46 | `null → value` only, never overwrite, enforced in `saveLabel`; deep-link label with no signature is still enriched via `computeSignature`; `?n=` captured with zero network calls |
| `fallback.bundled.test.js` | BC-47, BC-48, BC-56, BC-58 | exactly 5 keys; SKU/category resolution; PNG dimensions; 240/120/52 pt contain-fit; wide fits by width/tall by height |
| Release-pipeline fallback integration | BC-57, BC-59 | pinned inputs reproduce byte-identical PNG/geometry artifacts; explicit `qrBounds`; category text and QR rectangles do not intersect |
| `LabeledStockImage.geometry.test.js` | BC-32…BC-35, BC-40, BC-49…BC-51 | exact golden pixel boxes for all three delivered crops at several container sizes; non-square letterboxing; proportional-resolution invariance; independent crop-transform golden values; round ellipse containment |
| `LabelTextOverlay.textFit.test.js` | BC-52…BC-55 | run the same cases against manifest and bundled geometry: Android/iOS share glyph metrics and line breaks; no `adjustsFontSizeToFit`; longest catalog name, two words, one long token, empty, emoji and RTL; legibility suppression; ellipsis; hard clip |
| `LabeledStockImage.overlayName.test.js` | BC-36…BC-39 | precedence `printedLabelName`→`displayName`→`name`; rename scope for blank vs printed labels; immutable printed name; two names share one `assetId` object |
| Native backup configuration check | BC-69 | generated iOS resource values exclude stock art from iCloud; Android backup/data-extraction rules exclude the same directory from cloud and device transfer |
| Platform artwork screenshot smoke | BC-40, BC-68 | iOS/Android release builds render two-line and rotated fixtures within 0.5% artwork-region pixel tolerance; portrait/landscape boundaries remain aligned |

### 11.3 Note on asserting "latency"

Wall-clock timing assertions in Jest would measure the mock and be flaky. The intent —
*the user never waits* — is asserted more rigorously as:

- **Synchronicity** — resolution returns the final source URI with no `await`, and `source`
  does not change within a boundary (BC-11, BC-12).
- **Non-blocking** — splash/`initializeStorage` resolve with no art request outstanding
  (BC-01).
- **Call counts** — cache hit = 0 requests; dedupe = M requests for N labels; throttle = 1
  request across 5 simulated launches.
- **Fake timers** — backoff intervals via `jest.advanceTimersByTime`, never real clocks.

---

## 12. Phase 3 — quantity levels

Enable the remaining renderer quantity presets, render `26 × 3 × 4 = 312` images, and start
passing the real fill level instead of `default`. **No schema, resolver, or URL change is
required** — that is the point of D10 and D11. Partial rollout is safe: unrendered levels
fall back to `defaultQuantity` (BC-14).

---

## 13. Risks

1. **`photoUri` is not yet persisted safely.** It stores the raw `expo-image-picker` URI, which
   points into the OS cache directory. iOS and Android may purge it under storage pressure,
   so a **user photo can silently vanish** and fall back to stock art — which will look like
   a bug in *this* feature. Copy user photos into `documentDirectory` on save. **Fix in
   Phase 2.**
2. **No production backfill is required.** There are no customer labels. Missing/null
   `image_key` remains a supported fallback branch; development labels may be recreated.
3. **Future customer labels depend on allocation persisting `image_key`.** Keep allocation,
   lookup, order response, and app storage contract tests together.
4. **The rename must land before new labels are allocated** (§7).
5. **Bundled font required** for deterministic overlay metrics.
6. **Analytics needed:** fallback rate, missing-key events, manifest fetch failures —
   otherwise a key mismatch is invisible in production.
7. **Resolved by design in rev 6:** active/previous-manifest objects are retained, stale
   objects are pruned, and a 64 MiB ceiling skips speculative warming rather than evicting
   active art. Native backup exclusion remains an implementation/release gate (D31/D35).
8. **WebP decode support must be verified on iOS** for React Native's `<Image>` at
   SDK 54 / RN 0.81. Native `UIImage` WebP support exists from iOS 14; Expo SDK 54 targets
   iOS 15.1+, so this is expected to work, but it is **unverified** and blocks Phase 2.
9. **Resolved in `PlaceWellApp` `745581d`:** the bundled registry consumes `labelSku` and
   selects all three jar shapes; category fallbacks are also first-class.
10. **Resolved in `PlaceWellApp` `78f5150`:** Label Recall uses `full`, mini is exactly
    52 pt, and placeholder padding no longer clips the 240 pt fallback on narrow devices.

---

## 14. Findings from the rev-4 design review

The GPT-5.6 Sol review raised 12 further **MAJOR** findings. The table retains resolved rows
for traceability; unresolved rows need a decision before the phase named in the last column.

| # | Area | Finding | Decide before |
|---|---|---|---|
| M1 | D10–D11, BC-16/39 | **Resolved in rev 6 (D27, BC-16).** Semantic inputs select an active descriptor; full SHA-256 `assetId` names the cached object and geometry has a separate revision. | done |
| M2 | §4.6.4, BC-33 | **Resolved.** Typography fields are fixed and the selected bundled face is `CormorantGaramond_600SemiBold`. Phase 1 generates its versioned glyph table and makes that artifact a build requirement. | done |
| M3 | §4.6, size presets | **Resolved in rev 5 (D25, BC-54).** A legibility floor reduces line count, then ellipsizes, then suppresses the overlay if one readable glyph cannot fit. | done |
| M4 | BC-04–BC-08, BC-17–BC-23 | **Resolved in rev 6 (D28, BC-04/05/18).** Manifest and object replacements are fully validated last-known-good temp → rename commits; corrupt `304` state forces one unconditional fetch. | done |
| M5 | BC-20–BC-24 | **Resolved in rev 6 (D29, BC-20…BC-24/64).** Remote classes, timeouts, `Retry-After`, clock source, and local-storage cooldowns are explicit and separate. | done |
| M6 | BC-19, BC-28, BC-39 | **Resolved in rev 6 (D30, BC-60/61).** One global promise map keyed by `assetId` and an exact four-transfer priority semaphore own downloads. | done |
| M7 | §13 risk 7 | **Resolved in rev 6 (D31/D35, BC-62/63/69).** Active objects are never evicted, stale/orphan objects are pruned, the safety ceiling skips warming, and native configuration excludes the directory from backups. | done |
| M8 | BC-10, Q6, §13 risk 1 | **Resolved in rev 6 (D32, BC-65/66).** Only indexed usable photos enter precedence; both pre-load and post-load native failures have deterministic boundaries. | done |
| M9 | §12 | **Phase 3 has no quantity data model**: no label field, source of truth, editing flow, or update contract. A server-controlled global `defaultQuantity` could silently change every legacy label. | Phase 3 |
| M10 | D16, BC-36 | **Resolved in rev 6 (D33, BC-36/67).** `artworkMode = "fallback"` explicitly opts out of contents-specific remote art while retaining immutable physical-label identity; blank-label name fallback is correctly scoped. | done |
| M11 | §9 item 8 | The "permanent CI guard" is ineffective: `tests\test_spice_catalog_keys.py` **skips** when sibling repos are absent, which is the normal CI condition. Needs a release workflow checking out catalog + masters + renderer at pinned revisions, validating against the deployed manifest. | Phase 1 |
| M12 | §11 test plan | **Resolved in rev 6.** BC-09/21 define persistent state machines, BC-29 is exactly four, BC-35 uses literal independently calculated goldens, and BC-40 adds platform release-smoke screenshots. | done |

The two MINOR items are resolved by D34/BC-68: dimensions come synchronously from the
documented preset, and orientation begins a new tested layout boundary.

---

## 15. Related documents

- Prior research (superseded where it conflicts): `Docs\roadmap\Jar_Image_Strategy_Research.md`
- Roadmap entry #42: `Docs\roadmap\ROADMAP.md`
- Renderer + approved art: `C:\PlaceWell\spice-jar-renderer-code-assets\README.md`,
  `RELEASE_INVENTORY.md`
- Architecture: `Docs\architecture\System_Overview.md`
- Deployment: `Docs\deployment\Server_Reference.md`
