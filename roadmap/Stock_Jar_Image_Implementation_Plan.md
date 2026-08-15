# Stock Jar Image — Implementation Plan (Roadmap #42)

*Authoritative implementation spec for per-label stock jar images.*
*Created 2026-08-14. Revised 2026-08-14 (rev 2) after a full design review.*

*Supersedes `Jar_Image_Strategy_Research.md`, which was written before the art was produced
and before the key contract was verified. Where the two disagree, **this document wins**.*

> **Revision 2 changed several decisions from revision 1.** Hosting moved from Linode to
> Firebase Hosting; `spice_key` was renamed `image_key`; `jarSku` was corrected to
> `labelSku`; the manifest gained `defaultQuantity` and a 3-part lookup key; the bundled
> manifest snapshot was dropped; `expo-image`'s managed cache was replaced with an
> app-owned cache in `documentDirectory`. Sections 4, 5, 10 and 11 are new or rewritten.

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
https://<project-id>.web.app/jar-stock/manifest.v1.json
https://<project-id>.web.app/jar-stock/img/<file>.webp
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
  "baseUrl": "https://<project-id>.web.app/jar-stock/img/",

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
        "source": "/jar-stock/img/**",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      },
      {
        "source": "/jar-stock/manifest.v1.json",
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
| `jarArtService` | The **only** code that fetches, caches, and resolves. Owns the manifest cache, the image cache, the in-memory index, and the failure ledger. |
| `LabeledJarPhoto` | Renders image + label-name overlay using manifest geometry. |
| `CategoryPlaceholder` | Existing seam; unchanged public API. Screens keep calling it. |

**No screen ever builds a URL or calls `fetch` for art.**

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
| **BC-11** | When art is already cached, resolution is **synchronous** — no `await`, no loading state, correct image on the first frame. |
| **BC-12** | A visible image is **never swapped in place**. If art is uncached at mount, the placeholder is kept for that screen's lifetime; new art applies on the next natural render. |
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
| **BC-21** | Transient failures (timeout, offline, 5xx) retry on the next natural render of that jar, with backoff: next session → 1 h → 6 h → 24 h cap. |
| **BC-22** | A `404` is recorded as permanent and is **not** retried on that URL. |
| **BC-23** | A changed content hash produces a new URL, which is absent from the ledger and therefore fetched normally — self-healing after a corrected deploy. |
| **BC-24** | There is **no startup sweep** that retries all previously failed images. |

### 5.5 Prefetch

| ID | Contract |
|---|---|
| **BC-25** | `LabelFormScreen` mount triggers a manifest prefetch; it is not awaited and does not block render. |
| **BC-26** | Advancing from the Name step resolves the key and starts the image prefetch, so the Photo step (step 1) can render final art. |
| **BC-27** | `BulkImportScreen` mount warms the whole `orderLabels` set. |
| **BC-28** | The batch dedupes by cache key (N labels → M unique files) and skips entries already on disk or with a null key. |
| **BC-29** | Batch downloads are capped at 4–6 concurrent. |
| **BC-30** | Batch partial failure is tolerated: successes are cached, failures are ledgered, no error UI, no retry storm. |
| **BC-31** | Stock art is warmed **even when the user sets their own photo**, so a later removal reveals it instantly with no fetch. |

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
| Offline, never seen, manifest cached | Built-in placeholder + name |
| Offline, never seen, no manifest | Built-in placeholder + name |
| Offline, blank/unknown label | Built-in placeholder |

The manifest is served stale indefinitely while offline (BC-06). **No manifest is bundled**
(D13): without image bytes it would change nothing, since a never-connected device cannot
have art either way.

### Q4 — Download once

Guaranteed by content-hashed filenames, `immutable` cache headers, and an app-owned cache in
`documentDirectory` that the OS cannot purge (D14, BC-18, BC-19). One download per URL per
device, ever. Only the manifest revalidates, usually as a cheap `304`.

### Q5 — Label name and local storage

The renderer emits a **blank** label with `"mode": "dynamic"` plus normalised geometry. The
app renders the transparent WebP, then absolutely positions a `<Text>` using the manifest's
`label` block, scaled to the **rendered image rectangle** (accounting for `contain`
letterboxing) — not the container.

The composite "image + name" is never written to disk; it is recomposed each render, which
costs nothing and stays correct after a rename.

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

### Q8 — Hosting

| Factor | Firebase Hosting | Linode |
|---|---|---|
| Availability | Replicated CDN with SLA | Single VM; reboots, disk, cert renewal |
| Latency | Edge nodes | One region |
| Free tier | 10 GB storage / 10 GB month | n/a (already paid) |
| Payload | 16.5 MB — 0.16% of quota | Same |
| Cost beyond free | $0.15/GB (≈ $11 at 10k users/mo) | Zero marginal |

**Decision: Firebase Hosting (D5).** Revision 1 chose Linode to avoid new infrastructure;
availability is the better objective. Cost is negligible at any realistic scale.

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

---

## 8. Asset masters repository

The rendered output (78 × {PNG, lossless WebP, JSON sidecar} ≈ 300–400 MB) currently sits in
`C:\PlaceWell\Images`, untracked. Proposed:

- A dedicated repo (e.g. `PlaceWell-JarStockMasters`), **not** inside the renderer repo.
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

Labels already allocated carry no key. The migration maps `label_name → image_key`, including
the three superseded names (`Cayenne`, `Fennel Seeds`, `Mustard Seeds`). Physical labels in
customers' hands keep their printed text — harmless, provided the key is correct. Labels for
the 4 removed spices resolve to the built-in placeholder, which is working as designed.

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

- `jarArtService` (§4.5) — manifest cache + ETag, image cache in `documentDirectory`,
  in-memory index, failure ledger with backoff, prefetch API.
- Persist `imageKey` through `storage.js`, `qrService.js`, and `bulkCreateLabels`.
- `LabeledJarPhoto` + wiring through `CategoryPlaceholder`.
- Fix `photoUri` persistence (§12 risk 1).

### 11.2 Test suites

Each maps to behaviour contracts in §5.

| Suite | Covers | Key assertions |
|---|---|---|
| `jarArtService.manifest.test.js` | BC-03…BC-07 | cold fetch writes cache + ETag; `If-None-Match` sent; `304` writes nothing; unknown `schemaVersion` ignored; stale served offline |
| `jarArtService.manifestFailure.test.js` | BC-08, BC-09 | failure → placeholder, no throw; retry throttled to 1 per 15 min; retried on cold start |
| `jarArtService.resolve.test.js` | BC-10…BC-16 | precedence order; `default` → `defaultQuantity`; quantity miss falls back; null key is a normal branch; identical cache key across presets |
| `jarArtService.imageFetch.test.js` | BC-17…BC-19 | URL = `baseUrl + file`; written to `documentDirectory` **not** `cacheDirectory`; second render issues **0** requests |
| `jarArtService.imageFailure.test.js` | BC-20, BC-22 | failure → placeholder + ledger entry; `404` marked permanent |
| `jarArtService.imageRetry.test.js` | BC-21, BC-23, BC-24 | backoff 1 h/6 h/24 h via fake timers; `404` never retried; new hash fetched normally; no startup sweep |
| `jarArtService.coldStart.test.js` | BC-01, BC-02 | `initializeStorage()` resolves with no art request; no timers or `AppState` listeners registered |
| `BulkImportScreen.artPrefetch.test.js` | BC-27…BC-30 | 30 labels → M unique requests (dedupe); concurrency cap never exceeded; partial failure renders no error UI |
| `LabelFormScreen.artPrefetch.test.js` | BC-25, BC-26, BC-31 | manifest prefetch on mount, unawaited; image prefetch on Next; art warmed even when a user photo is set |
| `LabeledJarPhoto.noFlicker.test.js` | BC-11, BC-12 | cached art present on the **first** committed frame; uncached never swaps mid-view |

### 11.3 Note on asserting "latency"

Wall-clock timing assertions in Jest would measure the mock and be flaky. The intent —
*the user never waits* — is asserted more rigorously as:

- **Synchronicity** — resolution returns a value with no `await`; the first committed frame
  already has the final image (BC-11).
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

## 14. Related documents

- Prior research (superseded where it conflicts): `Docs\roadmap\Jar_Image_Strategy_Research.md`
- Roadmap entry #42: `Docs\roadmap\ROADMAP.md`
- Renderer + approved art: `C:\PlaceWell\spice-jar-renderer-code-assets\README.md`,
  `RELEASE_INVENTORY.md`
- Architecture: `Docs\architecture\System_Overview.md`
- Deployment: `Docs\deployment\Server_Reference.md`
