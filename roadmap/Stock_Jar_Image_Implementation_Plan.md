# Stock Jar Image — Implementation Plan (Roadmap #42)

*Authoritative implementation spec for per-spice stock jar images. Created 2026-08-14.*
*Supersedes the assumptions in `Jar_Image_Strategy_Research.md`, which was written before
the art was produced and before the key contract was verified. Where the two documents
disagree, **this document wins**.*

---

## 0. What changed since the research document

The research doc planned for art that did not yet exist. The art now exists, and
verification against the real catalog produced three corrections:

| Research doc assumed | Actual verified state |
|---|---|
| 28 spices, `3 × 28 = 84` images to produce | **26 spices, 78 images already rendered** and approved |
| Keys would "just match" | **Only 21 of 28 matched.** 7 CSV rows had no art; 5 art files had no CSV row |
| Firebase Storage hosting | **Linode** — the infra already exists and the payload is trivial |
| Per-spice art generation is the main work | Art is **done**. The work is the **key contract**, hosting, and app resolution |

The renderer that produced the art is `C:\PlaceWell\spice-jar-renderer-code-assets`
(deterministic, offline, config-driven; `RELEASE_INVENTORY.md` records the approved set).

---

## 1. Verified key mismatch (the blocking finding)

Comparing the 26 renderer spice IDs (`config/spices/*.json`) against the 28 rows in
`PlaceWellUI\data\spice.csv`:

| Result | Count | Items |
|---|---:|---|
| Exact match | 21 | basil, bay-leaves, black-pepper, chili-flakes, chili-powder, cinnamon, cloves, coriander, cumin, curry-powder, dill, garlic-powder, ginger, nutmeg, onion-powder, oregano, paprika, rosemary, sage, thyme, turmeric |
| CSV row with **no art** | 7 | allspice, cardamom, cayenne, fennel-seeds, mustard-seeds, star-anise, white-pepper |
| Art with **no CSV row** | 5 | cayenne-pepper, fennel, mustard-seed, italian-seasoning, salt |

Additional findings:

- **The app stores no spice key at all.** `storage.js` persists `name`, `category`,
  `labelSku`, `placeholder`, `freshnessCategory` — nothing that identifies the spice.
- **The QR service has no `spice_key`.** `lookup.py` returns `label_sku` and
  `label_metadata: { freshnessCategory }` only.
- **`SpiceJarPlaceholder.js` on `main` ignores `labelSku`** and renders a single bundled
  PNG. The per-SKU seam (`jarPhotoProfiles.js`, `LabeledJarPhoto.js`) exists only on
  `feature/real-jar-photos`.

Had the resolver shipped against a derived slug, **25% of spices would have 404'd.**

---

## 2. Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **Renderer art IDs are the canonical `spice_key`.** The CSV is rewritten to match. | The art names are the product names published on the Etsy store. |
| D2 | **The catalog is exactly the 26 spices that have art.** Allspice, Cardamom, Star Anise, White Pepper are removed. | Guarantees 1:1 coverage; no orphans on either side. |
| D3 | **The server owns the key. The app never derives it.** | Renames, translations, and re-branding stay safe. |
| D4 | **Static manifest + immutable content-hashed URLs.** No per-image lookup API. | Cacheable, offline-tolerant, zero server load. |
| D5 | **Host on Linode** at `placewell.app/jar-stock/`. | Infra, TLS, DNS and deploy tooling already exist; 78 WebP ≈ 15–25 MB. |
| D6 | **The label name is overlaid at runtime, never baked into the image.** | Users rename labels; baking destroys cache efficiency and correctness. |
| D7 | **Stock art is derived state, never stored on the label.** | Photo add/remove needs no revert logic. |

> **Firestore is not a hosting option.** It is a document database; binaries do not belong
> in documents. The real comparison was Firebase Storage (GCS) vs Linode — see D5.

---

## 3. Reconciled catalog (26 spices)

`spice.csv` goes from 28 rows to 26 and gains an explicit `spice_key` column.

**Renames (3)** — these also change the printed label text, since the CSV drives the PDF:

| Old `label_name` | New `label_name` | `spice_key` | `freshness_category` |
|---|---|---|---|
| Cayenne | Cayenne Pepper | `cayenne-pepper` | `ground_chili` (unchanged) |
| Fennel Seeds | Fennel | `fennel` | `seeds` (unchanged) |
| Mustard Seeds | Mustard Seed | `mustard-seed` | `seeds` (unchanged) |

**Additions (2)** — art exists, no CSV row:

| `label_name` | `spice_key` | `freshness_category` |
|---|---|---|
| Italian Seasoning | `italian-seasoning` | `dried_herb` |
| Salt | `salt` | `salt` (valid; `null` shelf life in `freshness.js`) |

**Removals (4):** Allspice, Cardamom, Star Anise, White Pepper.

> The art config's `category` field (`powder`, `whole`, `blend`, `flakes`, `dried-herb`)
> is a **rendering hint for the renderer** and is *not* the freshness category. The two are
> independent; `freshness_category` values are unchanged by this work.

---

## 4. Architecture

### 4.1 Manifest

`GET https://placewell.app/jar-stock/v1/manifest.json`

```json
{
  "schemaVersion": 1,
  "manifestRevision": 7,
  "baseUrl": "https://placewell.app/jar-stock",
  "generatedAt": "2026-08-14T00:00:00Z",
  "skus": ["round-1.5", "rect-portrait", "square-1.75"],
  "defaultQuantity": "almost-full",
  "spices": {
    "cinnamon": {
      "displayName": "Cinnamon",
      "assetVersion": "1.0.0",
      "skus": {
        "round-1.5": {
          "path": "v1/spice/cinnamon/round-1.5/almost-full.a1b2c3d4.webp",
          "width": 720,
          "height": 720,
          "label": {
            "centerX": 0.500, "centerY": 0.511,
            "width": 0.235, "height": 0.080,
            "rotationDegrees": 0, "maximumLines": 2,
            "textAlign": "center", "textTransform": "uppercase"
          }
        }
      }
    }
  }
}
```

The `label` block is copied verbatim from the renderer's JSON sidecar. This is essential:
the app never guesses geometry, and **geometry travels with the image version**, so art and
overlay can never desynchronize.

### 4.2 Image URLs

```text
/jar-stock/v1/spice/{spiceKey}/{labelSku}/{quantity}.{contentHash}.webp
```

Immutable by construction. Two size variants: `480` (tiles/cards) and `720` (hero/detail).
The 1254² masters stay in the renderer repo as source — never shipped to devices
(a 1254² image decodes to ~6 MB RAM; 720² is ~2.1 MB, 480² is ~0.9 MB).

### 4.3 Apache headers

```apache
# Images — immutable, cached forever
<LocationMatch "^/jar-stock/v1/spice/">
  Header set Cache-Control "public, max-age=31536000, immutable"
</LocationMatch>

# Manifest — short TTL, revalidated via ETag
<Location "/jar-stock/v1/manifest.json">
  Header set Cache-Control "public, max-age=300, must-revalidate"
</Location>
```

Apache must return a genuine `404` for missing art — not an HTML error page — so the app's
`onError` fires cleanly instead of trying to decode HTML as an image.

Images are **public and unauthenticated**. They are generic product art containing no user
data; adding auth would break caching for no security benefit.

---

## 5. Answers to the design questions

### Q1 — The lookup service

A static manifest plus deterministic URLs, not an API. A per-request endpoint would add
latency, a new failure mode, and server load for content that changes a few times a year.
The QR service's only new responsibility is **returning `spice_key`** on lookup and order
responses.

### Q2 — Service unavailable / image not found

Failure is structural, not exceptional. Five-level precedence, evaluated top-down, where
every level is guaranteed to render:

1. User photo (`photoUri`)
2. Cached remote stock image (disk)
3. Remote stock image (network)
4. Bundled generic per-SKU jar + text overlay
5. Bundled generic container (unknown category/SKU)

Rules that make this safe:

- The manifest fetch has a short timeout and **never blocks first paint** — level 4 renders
  immediately, the remote image swaps in when it arrives.
- A missing/unknown `spice_key`, or a key absent from the manifest, is a **normal branch**,
  not an error.
- An unrecognised `schemaVersion` causes the manifest to be ignored, not a crash.
- No image path may throw; `onError` falls back and emits a counted analytics event.

Because levels 4 and 5 are compiled into the binary, **no reachable state leaves the app
with nothing to draw.**

### Q3 — Offline

| Scenario | Result |
|---|---|
| Offline, image seen before | Cached image, full fidelity |
| Offline, never seen, manifest cached | Bundled SKU jar + name overlay |
| Offline, never seen, no manifest | Bundled SKU jar + name overlay |
| Offline, blank/unknown label | Generic container |

The manifest is cached in AsyncStorage with a 24 h TTL and is **served stale indefinitely
while offline** — an old manifest always beats none. The three bundled per-SKU jars
(≈2.2 MB) are the offline floor.

### Q4 — Download once

Guaranteed by the server:

- **Content-hashed filenames** — a URL's bytes never change.
- **`Cache-Control: immutable, max-age=31536000`.**
- `expo-image` with `cachePolicy="memory-disk"` persists across restarts, keyed by URL.

One download per URL per device, ever. Only the manifest revalidates, usually as a cheap
`304`.

### Q5 — Label name and local storage

The renderer deliberately emits a **blank** label with `"mode": "dynamic"` plus normalized
geometry. Keep that:

- Users rename labels; a baked image would be permanently wrong.
- Baking multiplies the matrix by every distinct name and destroys CDN cache efficiency.
- Blank art is reusable across quantity levels and future locales.

The app renders the transparent WebP, then absolutely positions a `<Text>` using the
manifest's `label` geometry, scaled to the **rendered image rectangle** (accounting for
`contentFit="contain"` letterboxing) — not the container.

Local storage is `expo-image`'s disk cache; no hand-managed files. The composited
"image + name" is never written to disk — it is recomposed at render time, which costs
nothing and stays correct after a rename.

**Prerequisite:** bundle the overlay font so text metrics are identical across devices.

### Q6 — User photo add / remove

The label carries `photoUri` (nullable) and `spiceKey` (immutable identity). Stock art is
derived, never persisted onto the label.

- **Add:** capture/pick → set `photoUri` → save. Precedence selects level 1.
- **Remove:** confirm → `photoUri = null` → save. Precedence falls to level 2/3 and the
  stock jar returns automatically.

**No revert logic is needed, because nothing was ever overwritten.** The single rule to
enforce: `spiceKey` is set at creation and never cleared by a photo edit — in
`LabelFormScreen`, `LabelDetailScreen`, `LabelRecallScreen`, and `bulkCreateLabels`.

### Q7 — Consistency across surfaces

Photos render in seven places: `HomeScreen`, `LabelCard`, `RoomSection`,
`LabelDetailScreen`, `LabelRecallScreen`, `LabelFormScreen`, and the photo viewer.
Consistency is enforced structurally:

- **One resolver** (`stockImageResolver.js`) is the only code that maps
  `{category, labelSku, spiceKey, quantityLevel}` to a source. No screen builds a URL.
- **One component** (`LabeledJarPhoto`) owns image + overlay + fallback; screens choose only
  a `size` preset.
- Every surface keeps calling `CategoryPlaceholder`, preserving the existing seam.
- Manifest revision lives in a single cached module, so all surfaces agree within a session.
- Tests assert identical inputs produce an identical `cacheKey` across all size presets.

Surfaces then differ only in resolution and crop — never in *which* image appears.

### Q8 — Hosting

| Factor | Linode | Firebase Storage |
|---|---|---|
| Infra already exists | Apache, TLS, DNS, `deploy.ps1` | New bucket, rules, SDK |
| Domain | Same-origin `placewell.app` | Separate host |
| Cache-header control | Full | Less direct |
| Payload | 78 WebP ≈ 15–25 MB | Same |
| Cost | Zero marginal | Egress billing |

**Decision: Linode.** 78 files of a few hundred KB is a rounding error for a box already
serving FastAPI, the operator UI, and the scan landing page. A second storage vendor and
credential buys nothing today. If traffic grows, put a CDN in front of the *same* immutable
URLs — no app change, because the paths do not move.

### Q9 — Publishing new art for an existing spice/SKU

1. Re-render the art.
2. New content → new hash → **new URL**.
3. Regenerate the manifest; bump `manifestRevision`.
4. Deploy. **Keep old files for at least one release cycle.**

Consequences:

- Devices on a cached manifest show old art until TTL expiry (≤24 h) — correct, not broken.
- **No stale-image bug class is possible**, because a URL's bytes never change.
- Offline devices on an old manifest still resolve successfully (old files retained).
- Changed label geometry ships *with* the new manifest entry, so image and overlay stay in
  sync.

### Q10 — Key verification

Answered in §1 and fixed by D1/D2. Permanently enforced by a CI guard (§6, item 8) that
fails the build if CSV keys and `config/spices/*.json` IDs ever diverge again.

---

## 6. Phase 0 — key reconciliation (blocking; server-side only)

| # | Change | File |
|---|---|---|
| 1 | Rewrite catalog to 26 rows + `spice_key` column | `PlaceWellUI\data\spice.csv` |
| 2 | Read `spice_key` from CSV | `PlaceWellUI\app\order_builder.py` |
| 3 | Forward `spice_key` in the allocate payload | `PlaceWellUI\app\qr_client.py` |
| 4 | Add `spice_key` to the operator grid | `PlaceWellUI\app\templates\form.html` |
| 5 | Add `spice_key` to `AllocationItem` + Firestore write | `PlaceWellQRService\app\allocate.py` |
| 6 | Return `spice_key` top-level on lookup + order | `PlaceWellQRService\app\lookup.py`, `order.py` |
| 7 | One-time backfill of existing Firestore docs by `label_name` (incl. the 3 old names) | `PlaceWellQRService\scripts\backfill_spice_keys.py` |
| 8 | Guard test: CSV keys ≡ art config IDs | QR service / UI tests |
| 9 | Docs update | `Docs\architecture\System_Overview.md`, `ROADMAP.md` |

`spice_key` is returned as a **top-level** lookup field, not inside `label_metadata`, so
non-spice categories can reuse it later.

### Backfill notes

Labels already allocated in Firestore carry no `spice_key`. The migration maps
`label_name → spice_key`, including the three superseded names (`Cayenne`, `Fennel Seeds`,
`Mustard Seeds`). Physical labels already in customers' hands keep their printed text —
harmless, provided the key is correct. Labels for the 4 removed spices resolve to the
generic SKU jar (fallback level 4), which is working as designed.

---

## 7. Later phases

**Phase 1 — asset pipeline & hosting**
Export the 78 masters to WebP at 480/720; content-hash filenames; generate the manifest from
the renderer sidecars; deploy to Linode with immutable headers; extend `deploy.ps1`.

**Phase 2 — app integration**
Persist `spiceKey`; build the resolver + manifest cache; adopt `expo-image`; wire
`LabeledJarPhoto` through `CategoryPlaceholder`; fix `photoUri` persistence (§8); add tests
for fallback, offline, and rename.

**Phase 3 — quantity levels**
Enable the remaining quantity presets in the renderer, render `26 × 3 × 4 = 312` images,
extend the resolver (`{quantity}` → spice default → generic SKU), and add the ¼/½/¾/Full UI.

---

## 8. Additional risks identified

1. **`photoUri` is not persisted safely.** It stores the raw `expo-image-picker` URI, which
   points into the OS cache directory. iOS and Android may purge that directory under
   storage pressure, so a **user photo can silently vanish** and fall back to stock art —
   which will look like a bug in *this* feature. Copy user photos into
   `FileSystem.documentDirectory` on save. **Fix during Phase 2.**
2. **Backfill is mandatory before launch**, or previously allocated labels never get art.
3. **Physical labels already shipped are immutable** — backfill is the only way to reach them.
4. **Blank / write-in labels** have no spice and must resolve deterministically to the
   generic SKU jar.
5. **Bundled font required** for deterministic overlay metrics.
6. **Analytics needed:** fallback rate, missing-key events, manifest fetch failures —
   otherwise a key mismatch is invisible in production.
7. **Cache growth cap** so the disk cache cannot grow unbounded.
8. **Two size variants** — never serve 1254² to a tile.

---

## 9. Related documents

- Prior research (superseded where it conflicts): `Docs\roadmap\Jar_Image_Strategy_Research.md`
- Roadmap entry #42: `Docs\roadmap\ROADMAP.md`
- Renderer + approved art: `C:\PlaceWell\spice-jar-renderer-code-assets\README.md`,
  `RELEASE_INVENTORY.md`
- Architecture: `Docs\architecture\System_Overview.md`
- Deployment: `Docs\deployment\Server_Reference.md`, `Linode_Deployment.md`
