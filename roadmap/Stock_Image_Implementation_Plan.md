# Stock Image — Implementation Plan (Roadmap #42)

*Authoritative implementation spec for per-label stock images.*
*Created 2026-08-14. Revised 2026-08-14 (rev 2) after a full design review.*
*Revised 2026-08-14 (rev 3): category-agnostic naming, label-name overlay geometry.*
*Revised 2026-08-14 (rev 4): resolves 5 blocking flaws from an adversarial design review.*

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
> | 2 | `imageKey`/`printedLabelName` never reach deep-link, transient-failure, or legacy labels; a Firestore backfill cannot touch AsyncStorage | D19 + §9.1 — write-once demand-driven enrichment |
> | 3 | "Correct pixels on the first committed frame" is unachievable (async native decode) and untestable in Jest | D20 + BC-11 restated, BC-41–BC-43 |
> | 4 | BC-12 contradicted itself and raced BC-26; a screen-lifetime latch spans the whole wizard | D21 — explicit re-resolve boundaries |
> | 5 | D13 (no bundled manifest) broke Q3's offline "placeholder + name" promise | D22/D23 + §4.7 — geometry travels with the artwork |
>
> Two factual corrections: the Spark free tier covers only **~620 full-catalog downloads/month**
> and **disables Hosting** rather than billing; and `rect-portrait` is narrower but **not**
> lower than both other SKUs (its `centerY` sits between them).
>
> Twelve further MAJOR findings from the same review are **not yet resolved** — see §14.

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
| D5 | **Host on Firebase Hosting** *(revised — was Linode)*. | A replicated CDN with an SLA and edge latency beats a single Linode VM. Free tier (10 GB storage / 10 GB month) dwarfs a 16.5 MB payload. |
| D6 | **The label name is overlaid at runtime, never baked into the image.** | Users rename labels; baking destroys cache efficiency and correctness. |
| D7 | **Stock art is derived state, never stored on the label.** | Photo add/remove needs no revert logic. |
| D8 | **Field is `image_key` / `imageKey`** *(revised — was `spice_key`)*. | The mechanism was never spice-specific; `load_items_from_csv` is already category-parameterised. |
| D9 | **SKU field is `label_sku` / `labelSku`** *(never `jarSku` or `product_sku`)*. | Already the established name in all three codebases (22 files). |
| D10 | **Lookup key is `imageKey\|labelSku\|quantity`** — 3-part from day one. | Phase 3 fill levels then require no schema or resolver change. |
| D11 | **Manifest declares `defaultQuantity`**; the app substitutes it. | One line, server-controlled; avoids duplicating all 78 entries or per-entry aliases. |
| D12 | **Export lossless WebP at 720×720.** | Measured: 217 KB each, 16.5 MB catalog. Matches the largest real surface (hero card ≈ 774 px at 3×). |
| D13 | **No bundled manifest snapshot** *(revised)*. | A manifest without image bytes solves nothing offline; it only adds a build-sync artifact. |
| D14 | **The app owns its image cache in `documentDirectory`.** | `cacheDirectory` is OS-purgeable; a managed library cache cannot be queried synchronously, which would break the no-flicker contract. |
| D15 | **The cached file is the bare image with a blank label. The composite is never cached.** | One file serves every label using that key/SKU. Baking the name would put it in the cache key, multiply storage by distinct names, force a rewrite on any change, and rasterise text that should stay crisp at every size. |
| D16 | **The overlay shows the name printed on the physical label — not the user's editable name** *(revised — rev 2 said the opposite)*. | The image exists to help the user recognise a physical object. The printed text cannot change, so rendering an edited name would depict a jar that does not exist. |
| D17 | **`printedLabelName` is persisted on the label at creation and never written by an app-side edit.** | The server's `label_name` is visible exactly once — during the first lookup. Every later scan resolves locally by `label_id` and never contacts the server. |
| D18 | **A new `LabelArtwork` component owns the whole precedence chain** (photo → stock → fallback) and takes explicit fields, not a label record. `CategoryPlaceholder` is unchanged and becomes the bottom rung. | The `photoUri ? <Image> : <CategoryPlaceholder>` ternary is currently duplicated at 5 call sites, so precedence is decided *before* `CategoryPlaceholder` is reached and BC-10 is unenforceable. Explicit fields because `LabelFormScreen` has no saved label object — it assembles from route params, `originalLabel`, and live wizard state. |
| D19 | **Metadata enrichment is write-once and demand-driven.** `imageKey`, `printedLabelName`, and `labelSku` are nullable; a repair pass fills `null → value` only and never overwrites. | Capture is currently opportunistic and never repaired. See §9.1 — three separate paths leave labels permanently keyless, one of which affects *new* labels today. |
| D20 | **No visible swap, ever — including the decode window.** Reserved empty space is shown until pixels are ready. | RN `<Image>` decodes even `file://` sources asynchronously, so "correct pixels on the first committed frame" is unachievable by any implementation. Blank → art is not a swap; placeholder → art is. |
| D21 | **Resolution is latched *within* a re-resolve boundary and re-resolved *at* one.** Boundaries are screen focus and wizard step change. | A screen-lifetime latch is wrong on two counts: React Navigation keeps screens mounted for a whole session, and the wizard's steps are slides inside one screen. |
| D22 | **Geometry travels with the artwork it describes.** Downloaded art uses manifest geometry; bundled art uses a bundled constant. | Removes the last dependency between the offline fallback and the network. Preserves D13 exactly, because geometry for *stock* art is never needed without stock art. |
| D23 | **The bundled fallback is 3 SKU-accurate empty jars, each with a blank white label patch**, replacing the single generic silhouette. | Blank labels, the 4 discontinued spices, and anything outside the catalog have no `imageKey` and will **never** receive stock art — the fallback is their *permanent* artwork, not an edge case. See §4.7. |

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

Firebase Hosting, static files only. **No Firebase SDK is used to fetch them** — they are
public CDN assets retrieved with an ordinary HTTPS GET. No auth, no tokens, no rules.

```
https://<project-id>.web.app/stock-images/manifest.v1.json
https://<project-id>.web.app/stock-images/img/<file>.webp
```

The plain `web.app` URL is used for now; a custom domain (`img.placewell.app`) can be added
later by changing only `baseUrl` in the manifest — no app change.

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

  // Canvas + label geometry are per SKU, not per image — the renderer copies the
  // same block into all 26 sidecars for a SKU. Hoisted here to avoid 78x repetition.
  "skus": {
    "round-1.5": {
      "canvas": { "width": 1254, "height": 1254 },
      "label": {
        "shape": "rectangle",
        "centerX": 0.500, "centerY": 0.511,
        "width": 0.235, "height": 0.080,
        "rotationDegrees": 0, "maximumLines": 2,
        "textAlign": "center", "textTransform": "uppercase"
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
      "w": 720, "h": 720
    }
  }
}
```

Notes:

- **`label.text` from the sidecar is deliberately dropped.** The user's own label name is
  drawn at runtime; ours would be wrong after any rename.
- Geometry travels with the manifest entry, so art and overlay can never desynchronise.
- Approx. 12–15 KB for 78 entries; one request.

### 4.3 Image URLs

```text
{baseUrl}{imageKey}__{labelSku}__{quantity}.{contentHash}.webp
```

Immutable by construction: different bytes produce a different hash, therefore a different
URL. There is no cache-busting step and no purge step.

One size variant, **720×720 lossless WebP** (D12). The 1254² masters are never shipped —
they are 2054 KB each and decode to ~6 MB RAM.

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
| `LabeledStockImage` | Renders image + label-name overlay using manifest geometry. |
| `CategoryPlaceholder` | Existing seam; unchanged public API. Screens keep calling it. |

**No screen ever builds a URL or calls `fetch` for art.**

---

### 4.6 Label name overlay

The renderer emits a **blank** label (`"mode": "dynamic"`) plus normalised geometry. The app
draws the name at render time as a native `<Text>` node. Nothing is baked (D15).

#### 4.6.1 The three SKUs differ materially

| SKU | centerX | centerY | width | height |
|---|---:|---:|---:|---:|
| `round-1.5` | 0.500 | 0.511 | 0.235 | 0.080 |
| `square-1.75` | 0.504 | 0.538 | 0.235 | 0.105 |
| `rect-portrait` | 0.502 | 0.523 | **0.160** | 0.100 |

All three share `canvas: 1254 × 1254`, `rotationDegrees: 0`, `maximumLines: 2`,
`textAlign: center`, `textTransform: uppercase`.

`rect-portrait`'s box is **47% narrower** than the other two and sits lower. `SpiceJarPlaceholder`
currently hardcodes `top: '40%'` and `width: '68%'` for every SKU, which is wrong for all
three — this is why geometry must come from the manifest (BC-33).

#### 4.6.2 Step 1 — contain-fit

Masters are square; containers are not. Letterboxing is always in play, so the label box must
be derived from the **rendered image rectangle**, never the container (BC-32).

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

**Worked example** — `round-1.5` in the recall hero card (258 × 348 pt):

```
scale     = min(258/1254, 348/1254) = 0.2057
rendered  = 258 × 258      originX = 0      originY = (348 − 258)/2 = 45
boxX = 0  + (0.500 − 0.1175) × 258 =  98.7
boxY = 45 + (0.511 − 0.040)  × 258 = 166.5
boxW = 0.235 × 258 =  60.6
boxH = 0.080 × 258 =  20.6
```

#### 4.6.4 Step 3 — text fitting

1. Apply `textTransform` (`uppercase`).
2. Set `numberOfLines = maximumLines` and `textAlign` from the manifest.
3. Seed `fontSize` from `boxH / maximumLines × capHeightFactor`, then allow
   `adjustsFontSizeToFit` with `minimumFontScale` to shrink long names.
4. Apply `rotationDegrees` as a transform. It is `0` for all current SKUs, but it is in the
   schema and must be honoured.

Because every value derives from normalised geometry, the overlay lands in the same place
relative to the jar at **every** size preset (BC-34).

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

#### 4.7.2 Three SKU-accurate jars, not one generic one (D23)

Today a single generic round silhouette (`spice-jar-large-transparent.png`, 1200 × 1920)
serves all three SKUs, so a `rect-portrait` customer sees a jar that is not the one in their
hand — directly contrary to the purpose of #42. Replace it with three empty transparent jars
matching the real SKU shapes. The renderer already produces all three, so the marginal cost
is low.

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
| Bundled fallback jar | Bundled constant, shipped in the same binary |

There is no reachable state with art but no geometry: stock art can only exist if the
manifest that named its URL was fetched, and BC-47 forbids evicting that manifest while the
art survives. Bundled art and bundled geometry version together with the binary, so they
cannot skew. **D13 therefore stands unchanged** — rev 2's rejection of a bundled manifest was
about image bytes, and geometry for stock art is never needed without stock art.

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
| **BC-04** | A successful fetch is written to `documentDirectory` together with its `ETag`. |
| **BC-05** | Subsequent fetches send `If-None-Match`. A `304` reuses the cached copy and writes nothing. |
| **BC-06** | A cached manifest is used indefinitely while offline. Stale always beats absent. |
| **BC-07** | An unrecognised `schemaVersion` causes the manifest to be ignored — treated as absent, never a crash. |
| **BC-08** | Manifest fetch failure resolves to the built-in placeholder. No crash, no error dialog, no blocked UI. |
| **BC-09** | Manifest retry is throttled to at most once per 15 minutes per session, and retried on cold start. |

### 5.3 Resolution

| ID | Contract |
|---|---|
| **BC-10** | Precedence is exactly: `photoUri` → cached stock art → built-in placeholder. |
| **BC-11** | When art is cached, `LabelArtwork` selects its **final source URI synchronously during the first render** — no `await`, no loading state — and never changes `source` for that label thereafter. *(Restated in rev 4: the rev-2 wording, "correct image on the first frame", is unachievable — see D20.)* |
| **BC-12** | Resolution is latched **within a re-resolve boundary** and re-resolved **at** one. Boundaries are screen focus and wizard step change. A visible image is never swapped in place inside a boundary. |
| **BC-13** | `quantity: "default"` resolves via `manifest.defaultQuantity`. |
| **BC-14** | A miss on the exact quantity falls back to `defaultQuantity`, then to the placeholder. |
| **BC-15** | A null or unknown `imageKey` (blanks, order QRs, non-spice categories) resolves to the placeholder as a **normal branch**, not an error. |
| **BC-16** | Identical inputs produce an identical cache key across every size preset (`full`/`wizard`/`tile`/`mini`). |

### 5.4 Image download and cache

| ID | Contract |
|---|---|
| **BC-17** | The download URL is exactly `baseUrl + file` from the manifest entry. |
| **BC-18** | Images are written to `documentDirectory`, never `cacheDirectory`. |
| **BC-19** | A cached image triggers **zero** network calls on re-render. |
| **BC-20** | Download failure renders the placeholder and records an entry in the failure ledger keyed by URL. |
| **BC-21** | Transient failures (timeout, offline, 5xx) retry on the next natural render of that image, with backoff: next session → 1 h → 6 h → 24 h cap. |
| **BC-22** | A `404` is recorded as permanent and is **not** retried on that URL. |
| **BC-23** | A changed content hash produces a new URL, which is absent from the ledger and therefore fetched normally — self-healing after a corrected deploy. |
| **BC-24** | There is **no startup sweep** that retries all previously failed images. |

### 5.5 Prefetch

| ID | Contract |
|---|---|
| **BC-25** | `LabelFormScreen` mount triggers a manifest prefetch; it is not awaited and does not block render. |
| **BC-26** | Advancing from the Name step resolves the key and starts the image prefetch. While that prefetch is in flight the Photo step renders **reserved empty space**, not the fallback. The fallback appears only on prefetch failure or after a **2 s** timeout, and then latches until the next boundary. |
| **BC-27** | `BulkImportScreen` mount warms the whole `orderLabels` set. |
| **BC-28** | The batch dedupes by cache key (N labels → M unique files) and skips entries already on disk or with a null key. |
| **BC-29** | Batch downloads are capped at 4–6 concurrent. |
| **BC-30** | Batch partial failure is tolerated: successes are cached, failures are ledgered, no error UI, no retry storm. |
| **BC-31** | Stock art is warmed **even when the user sets their own photo**, so a later removal reveals it instantly with no fetch. |

### 5.6 Label name overlay

| ID | Contract |
|---|---|
| **BC-32** | The label box is computed from the **rendered image rectangle** (after contain-fit letterboxing), never from the raw container. Asserted with a deliberately non-square container. |
| **BC-33** | Geometry comes from the manifest. No position, size, or font value for the overlay is hardcoded in a component. |
| **BC-34** | For a given SKU, the overlay's position relative to the image is identical across all size presets (`full`/`wizard`/`tile`/`mini`) when normalised. |
| **BC-35** | All three SKUs produce distinct, correct boxes from the same code path. Assert exact coordinates — `rect-portrait` is **narrower** than both others, but its `centerY` (0.523) sits *between* `round-1.5` (0.511) and `square-1.75` (0.538), so no qualitative ordering claim is valid. |
| **BC-36** | Editing a label's `name` does **not** change the rendered overlay. |
| **BC-37** | Overlay name precedence is exactly `printedLabelName` → manifest `displayName` → `name`. |
| **BC-38** | `printedLabelName` is written once at creation (from `lookupLabel` or `lookupOrder`) and is never mutated by any app-side edit path. |
| **BC-39** | The cache key excludes the name. Two labels with different names but the same `imageKey\|labelSku\|quantity` share **one** cached file and issue **one** download. |
| **BC-40** | `textTransform`, `textAlign`, `maximumLines` and `rotationDegrees` from the manifest are all applied. |

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
| **BC-48** | With no manifest and no network, a label still renders its SKU-accurate bundled jar **with its name**, using bundled geometry (D22, D23). |

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
| Offline, never seen, manifest cached | SKU-accurate bundled jar + name |
| Offline, never seen, no manifest | SKU-accurate bundled jar + name (BC-48) |
| Offline, blank/unknown label | SKU-accurate bundled jar + name — **permanently**, §4.7.1 |

The manifest is served stale indefinitely while offline (BC-06). **No manifest is bundled**
(D13): without image bytes it would change nothing, since a never-connected device cannot
have art either way.

> **Rev 4 closed a hole here.** Rev 2 promised "placeholder **+ name**" with no manifest,
> while requiring all overlay geometry to come from the manifest — a contradiction. Resolved
> by D22: geometry travels with the artwork, so the bundled jar carries bundled geometry and
> needs no network. D13 is unaffected. See §4.7.4.

### Q4 — Download once

Guaranteed by content-hashed filenames, `immutable` cache headers, and an app-owned cache in
`documentDirectory` that the OS cannot purge (D14, BC-18, BC-19). One download per URL per
device, ever. Only the manifest revalidates, usually as a cheap `304`.

### Q5 — Label name and local storage

Geometry and text fitting are specified in full in §4.6. Summary:

- The renderer emits a **blank** label plus normalised geometry; the app draws the name as a
  native `<Text>` positioned from the **rendered image rect**, not the container (BC-32).
- The composite is **never** written to disk (D15). The cached file is the bare image, shared
  by every label with the same `imageKey|labelSku|quantity` (BC-39). Recomposing each render
  costs nothing and keeps text crisp at every preset.
- The name drawn is the **printed** one, not the user's editable name (D16, §4.6.5). A
  rename therefore cannot invalidate a cached image, and "re-render on rename" is not a case
  that exists (BC-36).

**Prerequisite:** bundle the overlay font so text metrics are identical across devices.

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
resolver (§4.5), one component, one cache key (BC-16). Surfaces differ only in size preset —
never in *which* image appears.

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
| Payload | 16.5 MB for the *complete* catalog | Same |
| Free-tier capacity | **~620 full-catalog downloads/month** | Unmetered |
| Behaviour at quota | Spark **disables Hosting** — it does not auto-bill | Degrades under load |
| Cost beyond free | $0.15/GB, requires **Blaze** | Zero marginal |

**Decision: Firebase Hosting (D5).** Revision 1 chose Linode to avoid new infrastructure;
availability is the better objective.

> **Corrected in rev 4.** Revision 2 claimed the payload was "0.16% of quota" and cost
> "≈ $11 at 10k users/mo". Both were wrong. Storage is 0.16% of quota; **egress is the
> binding constraint**, and 10 GB/month divided by 16.5 MB is only ~620 complete catalogs.
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
`manifestRevision`. 4. Deploy, **keeping old files for at least one release cycle**.

Devices on a cached manifest show old art until revalidation — correct, not broken. **No
stale-image bug class is possible**, because a URL's bytes never change. Changed geometry
ships with the new entry, so image and overlay stay in sync.

### Q10 — Key verification

Answered in §1, fixed by D1/D2, and permanently enforced by the CI guard in §9 item 8.

---

## 7. Naming migration (`spice_key` → `image_key`)

Phase 0 shipped the field as `spice_key`. D8 renames it. Scope at time of writing:
**~101 occurrences across 14 files in 4 repos**, and critically:

- **Zero occurrences in `PlaceWellApp`** — the app never consumed it.
- **The Firestore backfill has never been run**, so no documents carry the field.

Therefore the rename is a pure code/doc change with **no data migration and no impact on
printed labels**. It must happen before the backfill runs; afterwards it becomes expensive.

Files renamed: `backfill_spice_keys.py` → `backfill_image_keys.py`,
`test_spice_catalog_keys.py` → `test_image_catalog_keys.py`.
Functions renamed: `build_spice_key_index()` → `build_image_key_index()`,
`resolve_spice_key()` → `resolve_image_key()`.

---

## 8. Asset masters repository

The rendered output (78 × {PNG, lossless WebP, JSON sidecar} ≈ 300–400 MB) currently sits in
`C:\PlaceWell\Images`, untracked. Proposed:

- A dedicated repo (e.g. `PlaceWell-StockImageMasters`), **not** inside the renderer repo.
- **Git LFS** for `*.png` and `*.webp`, so re-renders do not bloat every clone forever.
- Keep the existing `<labelSku>/<imageKey>/<quantity>/` layout — it matches the renderer's
  own output and the per-SKU `batch-manifest.json` paths remain valid.
- `PROVENANCE.md` recording renderer version, generation date, and source commit.

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
| 7 | One-time Firestore backfill by `label_name` | `scripts\backfill_image_keys.py` | written, **never run** |
| 8 | CI guard: CSV keys ≡ art config IDs | QR service tests | done (rename pending) |
| 9 | Docs update | `System_Overview.md`, `ROADMAP.md` | done (rename pending) |

> **Item 4 was deliberately rejected.** `form.html` rebuilds table rows as JSON on submit, so
> a hand-typed key would be lost, and an editable field invites typos. The key is resolved
> server-side from the display name (casefold + strip) in `build_spice_key_index()` /
> `resolve_spice_key()` instead.

The key is returned as a **top-level** lookup field, not inside `label_metadata`, so
non-spice categories can reuse it.

### Backfill notes

Labels already allocated carry neither field. The migration maps `label_name → image_key` and
also persists `printedLabelName`, including the three superseded names (`Cayenne`,
`Fennel Seeds`, `Mustard Seeds`) — for those, `printedLabelName` must be the **old** printed
text, not the new catalog name, since that is what is physically on the jar. Labels for the 4
removed spices resolve to the built-in placeholder, which is working as designed.

### 9.1 Why capture-at-creation is not enough *(new in rev 4)*

Three separate paths leave a label permanently without `imageKey` / `printedLabelName`, and
they share one root cause: **metadata is captured once, opportunistically, and never
repaired.**

| # | Path | What happens |
|---|---|---|
| 1 | **Deep link** `placewell://scan/ID` | `parseQRCode` returns `signature: null`; `lookupLabel` returns `null` *without fetching*. The label is created with `category`, `labelSku`, and name **all null**. This affects **new** labels today, not just legacy ones. |
| 2 | **Transient failure at first scan** | `lookupLabel` returns `null`, the label is created anyway, and `getLabelById` succeeds forever after — so the server is never asked again. Permanent. |
| 3 | **Legacy labels** | Created before this ships. A Firestore backfill **cannot reach AsyncStorage**. |

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

Missing it at creation means the value is unrecoverable without a network round-trip per
label — exactly what this flow is designed to avoid. Labels created before this ships are
reachable only via the backfill above.

---

## 10. Phase 1 — export and hosting

1. Read the 78 sidecars from the masters repo (§8).
2. Downscale masters 1254² → 720², encode **lossless WebP** (D12).
3. Content-hash each file; name it `{imageKey}__{labelSku}__{quantity}.{hash}.webp`.
4. Generate `manifest.v1.json` (§4.2) — geometry from the sidecars, `label.text` dropped.
5. Deploy to Firebase Hosting with the headers in §4.4.
6. Verify: `Content-Type: image/webp`, `immutable` on images, `must-revalidate` on manifest.

The export must be **deterministic and repeatable** — same masters in, same hashes out.

---

## 11. Phase 2 — app integration and test plan

### 11.1 Implementation

- `stockImageService` (§4.5) — manifest cache + ETag, image cache in `documentDirectory`,
  in-memory index, failure ledger with backoff, prefetch API (incl. bitmap warm, BC-43).
- Warm the cache index in `App.js` `prepare()` before `setAppReady(true)` (BC-41).
- Persist `imageKey` **and `printedLabelName`** through `storage.js`, `qrService.js`, and
  `bulkCreateLabels`, with write-once immutability enforced **inside `saveLabel`** (BC-44).
- Export `computeSignature(labelId)` from `hmac.js`; build the demand-driven enrichment pass
  (§9.1, D19, BC-45/46).
- **`LabelArtwork`** (D18) owning photo → stock → fallback; migrate all 5 call sites off
  their local ternary. `CategoryPlaceholder` stays as the fallback leaf.
- `LabeledStockImage` implementing §4.6, with reserved empty space during decode (BC-42).
- Produce and bundle the 3 SKU-accurate fallback jars with white label patches, plus their
  bundled geometry constant (D22, D23, §4.7).
- Fix `photoUri` persistence (§13 risk 1).

### 11.2 Test suites

Each maps to behaviour contracts in §5.

| Suite | Covers | Key assertions |
|---|---|---|
| `stockImageService.manifest.test.js` | BC-03…BC-07 | cold fetch writes cache + ETag; `If-None-Match` sent; `304` writes nothing; unknown `schemaVersion` ignored; stale served offline |
| `stockImageService.manifestFailure.test.js` | BC-08, BC-09 | failure → placeholder, no throw; retry throttled to 1 per 15 min; retried on cold start |
| `stockImageService.resolve.test.js` | BC-10…BC-16 | precedence order; `default` → `defaultQuantity`; quantity miss falls back; null key is a normal branch; identical cache key across presets |
| `stockImageService.imageFetch.test.js` | BC-17…BC-19 | URL = `baseUrl + file`; written to `documentDirectory` **not** `cacheDirectory`; second render issues **0** requests |
| `stockImageService.imageFailure.test.js` | BC-20, BC-22 | failure → placeholder + ledger entry; `404` marked permanent |
| `stockImageService.imageRetry.test.js` | BC-21, BC-23, BC-24 | backoff 1 h/6 h/24 h via fake timers; `404` never retried; new hash fetched normally; no startup sweep |
| `stockImageService.coldStart.test.js` | BC-01, BC-02 | `initializeStorage()` resolves with no art request; no timers or `AppState` listeners registered |
| `BulkImportScreen.artPrefetch.test.js` | BC-27…BC-30 | 30 labels → M unique requests (dedupe); concurrency cap never exceeded; partial failure renders no error UI |
| `LabelFormScreen.artPrefetch.test.js` | BC-25, BC-26, BC-31 | manifest prefetch on mount, unawaited; image prefetch on Next; art warmed even when a user photo is set |
| `LabeledStockImage.noFlicker.test.js` | BC-11, BC-12, BC-42 | final source URI chosen synchronously on the first render; `source` never changes within a boundary; reserved empty space (not the fallback) during decode |
| `LabelArtwork.precedence.test.js` | BC-10, BC-42 | one component owns photo → stock → fallback; all 5 migrated call sites resolve identically from the same inputs; no call site retains a local ternary |
| `stockImageService.startup.test.js` | BC-01, BC-41, BC-43 | index warmed in `prepare()` before `setAppReady(true)`; disk-only, zero network; prefetch warms the decoded bitmap |
| `enrichment.writeOnce.test.js` | BC-44, BC-45, BC-46 | `null → value` only, never overwrite, enforced in `saveLabel`; deep-link label with no signature is still enriched via `computeSignature`; `?n=` captured with zero network calls |
| `fallback.bundled.test.js` | BC-47, BC-48 | manifest never evicted while referenced art is cached; with no manifest and no network, the correct SKU jar renders **with** its name from bundled geometry |
| `LabeledStockImage.geometry.test.js` | BC-32…BC-35, BC-40 | exact pixel boxes for all three SKUs at several container sizes, incl. a **non-square** container to catch letterboxing regressions; no hardcoded geometry; `rect-portrait` distinct from the other two; transform/align/lines applied |
| `LabeledStockImage.overlayName.test.js` | BC-36…BC-39 | precedence `printedLabelName`→`displayName`→`name`; renaming leaves the overlay unchanged; `printedLabelName` never mutated by edit paths; two differently-named labels share one cached file and one download |

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

1. **`photoUri` is not persisted safely.** It stores the raw `expo-image-picker` URI, which
   points into the OS cache directory. iOS and Android may purge it under storage pressure,
   so a **user photo can silently vanish** and fall back to stock art — which will look like
   a bug in *this* feature. Copy user photos into `documentDirectory` on save. **Fix in
   Phase 2.**
2. **Backfill is mandatory before launch**, or previously allocated labels never get art.
3. **Physical labels already shipped are immutable** — backfill is the only way to reach them.
4. **The rename must land before the backfill runs** (§7).
5. **Bundled font required** for deterministic overlay metrics.
6. **Analytics needed:** fallback rate, missing-key events, manifest fetch failures —
   otherwise a key mismatch is invisible in production.
7. **Cache growth cap** so the image cache cannot grow unbounded.
8. **WebP decode support must be verified on iOS** for React Native's `<Image>` at
   SDK 54 / RN 0.81. Native `UIImage` WebP support exists from iOS 14; Expo SDK 54 targets
   iOS 15.1+, so this is expected to work, but it is **unverified** and blocks Phase 2.
9. **`SpiceJarPlaceholder` currently ignores `labelSku`** and renders one PNG for all SKUs.
   The per-SKU seam must be built for the fallback to be SKU-correct.
10. **`LabelRecallScreen` renders the placeholder at `size="tile"` (75×120) inside a hero
    card of `SCREEN_WIDTH × 0.60` (≈258×348 pt).** The art looks lost because of this scale
    mismatch, not because of resolution. Fixing it is an app-side change independent of
    hosting.

---

## 14. Open findings from the rev-4 design review

The GPT-5.6 Sol review raised 12 further **MAJOR** findings that are acknowledged but **not
yet resolved**. Each needs a decision before the phase named in the last column.

| # | Area | Finding | Decide before |
|---|---|---|---|
| M1 | D10–D11, BC-16/39 | The spec conflates the **semantic lookup key** with **asset identity**. If cache files are keyed by `imageKey\|labelSku\|quantity`, a new content-hash URL still resolves the old file. Needs an explicit index: lookup key → asset identity (URL or SHA-256) + geometry revision. | Phase 2 |
| M2 | §4.6.4, BC-33 | **Typography is under-specified**: no font family, weight, line height, letter spacing, colour, vertical alignment, `includeFontPadding`, `allowFontScaling`, concrete `capHeightFactor`, or minimum scale. The renderer's own docs specify different rules (`box.height × 0.27`, fixed line height/tracking). BC-33 cannot be satisfied while these are absent from the manifest. | Phase 1 |
| M3 | §4.6, size presets | At `mini` (42 pt), `rect-portrait`'s text box is ≈ **6.7 × 4.2 pt** — not legible at any font size. Need a minimum-legible-size threshold below which the overlay is suppressed. | Phase 2 |
| M4 | BC-04–BC-08, BC-17–BC-23 | **No atomicity or integrity design for cache writes.** Expo FileSystem can leave partial files on Android, and a truncated file then counts as cached forever. Need: download to temp → verify SHA-256 + byte size + content type → atomic move. Manifest needs a digest and full validation before replacing last-known-good. `304` with a missing/corrupt body is undefined. | Phase 2 |
| M5 | BC-20–BC-24 | **Failure classification is incomplete.** Disk-full and permission errors must not poison a URL's retry ledger. 408/429/403/410 unspecified; no request timeout, no `Retry-After`, no clock-skew handling. | Phase 2 |
| M6 | BC-19, BC-28, BC-39 | **No in-flight dedupe.** Two simultaneously mounted components can race the same uncached URL and the same destination file. Needs a global in-flight promise map keyed by asset URL. | Phase 2 |
| M7 | §13 risk 7 | **Cache cap contradicts "one download per device, ever"** and no eviction policy exists. Need LRU/retention rules, partial-file cleanup, and an explicit statement that eviction permits redownload. Also exclude the art cache from device backups. | Phase 2 |
| M8 | BC-10, Q6, §13 risk 1 | The claim that a purged `photoUri` falls back to stock is **false** — a non-null URI wins resolution, then native `<Image>` errors and usually draws nothing. Needs synchronous existence verification and an `onError` fallback path. | Phase 2 |
| M9 | §12 | **Phase 3 has no quantity data model**: no label field, source of truth, editing flow, or update contract. A server-controlled global `defaultQuantity` could silently change every legacy label. | Phase 3 |
| M10 | D16, BC-36 | **Repurposed jars are unhandled.** A "Cumin" label later filled with coriander still shows cumin art and `CUMIN`. Also, BC-36 contradicts the precedence rule for blank labels, where `name` *is* rung ③ and editing it *must* change the overlay. Needs an override/opt-out and a scoped BC-36. | Phase 2 |
| M11 | §9 item 8 | The "permanent CI guard" is ineffective: `tests\test_spice_catalog_keys.py` **skips** when sibling repos are absent, which is the normal CI condition. Needs a release workflow checking out catalog + masters + renderer at pinned revisions, validating against the deployed manifest. | Phase 1 |
| M12 | §11 test plan | Several contracts are vague or circular: BC-09 conflicts with "1 request across 5 launches"; BC-21 lacks a state machine; BC-29 gives a range not a limit; BC-35 is circular if expected values come from the same fixture; BC-40 proves props were passed, not native rendering. | Phase 2 |

Two further MINOR items: `containerW/containerH` has no defined source (`onLayout` would
introduce a post-commit overlay shift), and rotation/orientation changes are untested.

---

## 15. Related documents

- Prior research (superseded where it conflicts): `Docs\roadmap\Jar_Image_Strategy_Research.md`
- Roadmap entry #42: `Docs\roadmap\ROADMAP.md`
- Renderer + approved art: `C:\PlaceWell\spice-jar-renderer-code-assets\README.md`,
  `RELEASE_INVENTORY.md`
- Architecture: `Docs\architecture\System_Overview.md`
- Deployment: `Docs\deployment\Server_Reference.md`
