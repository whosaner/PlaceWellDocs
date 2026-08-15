# Jar Image Strategy Research

> **⚠️ Partially superseded.** This document was written before the art existed and before
> the key contract was verified. The authoritative implementation spec is
> **`Docs/roadmap/Stock_Image_Implementation_Plan.md`**; where the two disagree, that
> document wins. Specifically outdated here: the 28-spice scale math (the catalog is now
> **26 spices / 78 images, already rendered**), the Firebase Storage hosting recommendation
> (now **Linode**), and the assumption that spice keys would match (**only 21 of 28 did**).
> The fallback chain, `expo-image` caching, resolver seam, and don't-bundle-the-matrix
> conclusions all still hold.

*Research + design for roadmap #10 / #11 / #12. Created 2026-08-11. App baseline: Expo SDK 54, React Native 0.81; latest placeholder implementation reviewed read-only from `PlaceWellApp` branch `feature/real-jar-photos`.*

---

## Executive summary — direct answers

**(a) What changes are needed in the app?**

Add a small stock-image resolution layer: `category + labelSku + spiceKey + optional qtyLevel -> image source`. Today, the app already routes no-photo labels through `CategoryPlaceholder` and per-SKU spice placeholder components; that should become a remote-aware resolver rather than a hardcoded `require()` table. The app also needs to persist a stable `spiceKey` / `imageKey` on each label, adopt `expo-image`, and later add a `quantityLevel` field plus UI for `1/4`, `1/2`, `3/4`, `Full`.

**(b) Performance / storage / bulk risk?**

Yes, the full matrix is large enough that it should **not** be bundled into the app. With the current 28-spice CSV, near-term is `3 SKUs × 28 spices = 84` images; future quantity support is `3 × 28 × 4 = 336` images. Bundled transparent PNGs could easily add tens to hundreds of MB to every install and every relevant OTA update. Remote, pre-resized WebP images with `expo-image` disk/memory caching keep the binary small and download only what each user actually sees.

**(c) Can new spice labels be added without an app-store release?**

Yes, if the stock art is hosted remotely and keyed by data returned from the QR service. Generate art upfront, upload it to storage/CDN, update a small manifest, and have the QR service return the new label's `spice_key` / `image_key`. EAS Update can help ship code or manifest defaults over-the-air, but the large growing image set should be remote-fetched, not bundled into OTA payloads.

**Recommendation:** host stock jar images remotely, fetch by deterministic key, cache with `expo-image`, and keep only the three small generic per-SKU fallbacks bundled for offline / first load.

---

## Current architecture findings

### App placeholder path

The `feature/real-jar-photos` branch replaces SVG-style placeholders with real transparent PNG product photos:

- `src/components/CategoryPlaceholder.js` chooses a placeholder component from `placeholder || getCategoryConfig(category).placeholder`.
- `src/components/placeholders/index.js` maps `spiceJar`, `storageBox`, `genericContainer` to components.
- `SpiceJarPlaceholder` calls `spiceProfileForSku(labelSku)`.
- `jarPhotoProfiles.js` maps the three spice SKUs to local `require()` assets:
  - `round-1.5 -> spiceRound -> assets/spice-jar-round.png`
  - `rect-portrait -> spiceRect -> assets/spice-jar-rect.png`
  - `square-1.75 -> spiceSquare -> assets/spice-jar-square.png`
- `LabeledJarPhoto` renders React Native `<Image resizeMode="contain">` and overlays the label name inside calibrated profile coordinates.

That is a good seam: the visible app does not need every screen to know about stock image logic. The resolver can sit underneath `CategoryPlaceholder` / `SpiceJarPlaceholder`.

### Label metadata flow

- `ScannerScreen` validates the QR, calls `lookupLabel(labelId, signature)`, then navigates to `LabelSetup` with `labelName`, `category`, `labelSku`, and `labelMetadata`.
- `qrService.lookupLabel` currently returns `labelName`, `category`, `labelSku`, defaults, and `labelMetadata` containing spice `freshnessCategory`.
- `LabelFormScreen` stores new labels with `id`, `name`, `photoUri`, `category`, `labelSku`, `freshnessCategory`, freshness fields, location, items, and notes.
- `bulkCreateLabels` stores `category`, `labelSku`, `placeholder`, and `freshnessCategory` from order lookup metadata.
- User photos always take precedence: Home, Detail, Recall, cards, and form render `photoUri` first and only call `CategoryPlaceholder` when no user photo exists.

### QR service fields

`PlaceWellQRService` stores `item_id`, `label_name`, `category`, `label_sku`, `default_placeholder`, and `freshness_category`. Lookup returns `label_name`, `category`, `label_sku`, and a derived `label_metadata = { freshnessCategory }`; it does **not** currently return `item_id` or a dedicated image key. Order lookup already exposes `item_id` to the app response shape, but local bulk storage does not persist it.

`item_id` examples such as `spice_basil_003` are promising, but it is not ideal to make the app parse business meaning from a unique item/order identifier. Add an explicit stable key.

---

## Scale math

The current spice source is `PlaceWellUI/data/spice.csv`: **28 spices**.

| Matrix | Formula | 28-spice count | 50-spice planning count |
|---|---:|---:|---:|
| Current generic per SKU | `3 SKUs` | 3 | 3 |
| Near-term per SKU per spice | `3 × spices` | 84 | 150 |
| Future per SKU per spice per quantity | `3 × spices × 4` | 336 | 600 |

### Storage estimates

Transparent product photos vary heavily by content, but conservative mobile delivery targets should be:

- **Source/master:** keep original transparent PNG/PSD/etc. outside the app for art production.
- **App delivery:** export WebP with alpha, pre-sized to display needs.
- **Recommended variants:** `480px` for tiles/wizard and `720px` for full/hero. A `1254 × 1254` source decodes to about **6.0 MB RAM per image** (`1254 × 1254 × 4 bytes`) before GPU overhead; `720 × 720` is about **2.1 MB**, and `480 × 480` is about **0.9 MB**.

Approximate on-disk payload if bundled:

| Scenario | PNG @ 0.5–2.0 MB each | WebP delivery @ 0.10–0.35 MB each |
|---|---:|---:|
| 84 images | 42–168 MB | 8–30 MB |
| 336 images | 168–672 MB | 34–118 MB |
| 600 planning images | 300 MB–1.2 GB | 60–210 MB |

Even the WebP version is too large and too fast-growing to bundle as a default install payload. It would also make EAS Update payloads large whenever new required assets are statically referenced.

---

## Bundled vs remote recommendation

### Recommendation

Use **remote stock images + local generic fallback**:

1. Bundle only three small fallback images for the three spice SKU shapes: `round-1.5`, `rect-portrait`, `square-1.75`.
2. Host the spice-specific and quantity-specific stock images remotely.
3. Resolve them with deterministic keys and URLs.
4. Cache aggressively with `expo-image` (`cachePolicy="memory-disk"` for visible hero images, `disk` for most thumbnails).
5. Use a small JSON manifest so the app knows which remote art exists and when to fall back.

### Why not fully bundled?

Expo documents local assets as files bundled into the production app binary, while remote assets are not bundled and must provide dimensions explicitly. React Native also requires statically known `require()` paths for static images. A growing spice matrix would therefore increase binary size and cannot be dynamically extended without a new binary or OTA update.

Store limits are not the only concern, but they frame the risk. Apple currently documents a 4 GB maximum uncompressed iOS app size; iOS users also commonly see a cellular-download confirmation setting around the 200 MB threshold. Google Play's current Android App Bundle guidance says device-specific compressed downloads can be much larger than the old 150 MB era, but Play still optimizes by serving only needed code/resources and points large resource sets toward dynamic delivery / asset packs. For PlaceWell, the practical target should be far below hard limits: every extra bundled image is paid by every installer, even users who never scan that spice.

EAS Update can send non-native app pieces like JavaScript, styling, and images, but Expo's asset guidance says new images in updates are downloaded by users and large/multiple assets are better handled by new binaries or kept small. For this feature, using OTA as the primary image delivery channel would simply move the bloat from the app-store binary to OTA payloads. Use OTA for code and possibly a baked-in manifest default; use remote hosting for the image files.

### Remote tradeoffs

Remote images need a first network fetch and can be unavailable if offline. The bundled fallback covers that. Once viewed, `expo-image` disk caching makes repeat views local.

---

## Proposed image contract

### Stable keys

Add explicit fields rather than parsing display names:

- `spice_key`: normalized, stable key such as `cinnamon`, `turmeric`, `cumin`, `fennel_seeds`.
- `image_key`: optional more general key if future categories need stock art not tied to spice taxonomy.
- `quantity_level`: app-local/user-selected enum for the future phase: `quarter`, `half`, `three_quarter`, `full`.

`item_id` can remain a unique order-line identifier (`spice_cinnamon_002`), but it should not be the only image key. If product tooling already guarantees `item_id = spice_{slug}_{sequence}`, the app can use it as a temporary fallback by stripping prefix/suffix, but the QR service should serve an explicit key.

### Deterministic URL shape

Example versioned paths:

```text
https://cdn.placewell.app/jar-stock/v1/spice/{spiceKey}/{labelSku}/default.webp
https://cdn.placewell.app/jar-stock/v1/spice/{spiceKey}/{labelSku}/{quantityLevel}.webp
```

Concrete examples:

```text
/jar-stock/v1/spice/cinnamon/round-1.5/default.webp
/jar-stock/v1/spice/turmeric/rect-portrait/half.webp
/jar-stock/v1/spice/cumin/square-1.75/full.webp
```

Keep filenames immutable by version or content hash. If art changes, either bump `v2` or publish `...?rev=<hash>` from the manifest so device caches do not show stale images forever.

### Manifest

Host a compact JSON manifest, for example:

```json
{
  "version": 1,
  "baseUrl": "https://cdn.placewell.app/jar-stock/v1",
  "updatedAt": "2026-08-11T00:00:00Z",
  "skus": ["round-1.5", "rect-portrait", "square-1.75"],
  "quantityLevels": ["quarter", "half", "three_quarter", "full"],
  "spices": {
    "cinnamon": {
      "displayName": "Cinnamon",
      "default": ["round-1.5", "rect-portrait", "square-1.75"],
      "levels": ["quarter", "half", "three_quarter", "full"],
      "blurhash": "...optional..."
    }
  }
}
```

The app can fetch/cache this manifest in AsyncStorage with a TTL. If the manifest is unavailable, compute the deterministic URL and fall back on image load failure, or only use known cached manifest entries.

---

## Exact app changes needed

### Phase 1 app changes: per-spice remote images

1. **Add `expo-image`.** Replace stock placeholder rendering from React Native `<Image>` to `expo-image` while leaving user-photo migration for a later broader cleanup if desired.
   - Use `contentFit="contain"` for transparent jar stock art.
   - Use `placeholder` / BlurHash from manifest or a neutral bundled fallback.
   - Use `transition` for smoother swaps.
   - Use `cachePolicy="disk"` or `memory-disk` depending on context.
   - Use `recyclingKey` in lists/carousels: `${label.id}:${stockImageKey}`.
2. **Add an image resolver module**, for example `src/services/stockImageResolver.js`:
   - Inputs: `{ category, labelSku, spiceKey, imageKey, quantityLevel }`.
   - Output: `{ source, fallbackSource, cacheKey, blurhash, profileId }`.
   - Logic: user photo remains outside resolver and still wins; for `category !== 'spice'`, use existing storage/generic placeholders; for missing keys or manifest misses, return bundled SKU fallback.
3. **Pass data through `CategoryPlaceholder`.** Extend `CategoryPlaceholder` and `SpiceJarPlaceholder` props to include `spiceKey` / `imageKey` / later `quantityLevel`.
4. **Persist keys on labels.** Add `spiceKey` and optionally `imageKey` to create/edit payloads in `LabelFormScreen`, and to `bulkCreateLabels`.
5. **Update QR client mapping.** `lookupLabel` should map `data.spice_key` / `data.image_key` or `label_metadata.spiceKey` into route params. `lookupOrder` should include the same for bulk import.
6. **Fallback behavior.** If remote image fails, render current per-SKU generic jar. If label name is still overlaid in the app, reuse the existing calibrated overlay profile by SKU; if the generated image already includes the printed label name, skip overlay.
7. **Tests.** Add resolver unit tests for exact key selection, missing manifest fallback, unknown SKU fallback, and quantity omitted.

### Phase 2 app changes: quantity-level stock images

1. Add `quantityLevel` to the label object, initially nullable.
2. Add UI to choose `1/4`, `1/2`, `3/4`, `Full` in the photo/freshness step for spice labels. If guided capture #12 remains, reuse its fill-level selector styling; if no user photo is taken, the selected level controls the stock placeholder image.
3. Save/edit `quantityLevel` in `LabelFormScreen`, `LabelRecallScreen`, and any bulk import freshness UI.
4. Add resolver keying: `{spiceKey}/{labelSku}/{quantityLevel}.webp`, with fallback to `{spiceKey}/{labelSku}/default.webp`, then generic SKU fallback.

---

## Data and QR-service changes

### QR allocation / lookup

Add fields to `AllocationItem` and Firestore documents:

- `spice_key: Optional[str] = None`
- `image_key: Optional[str] = None`
- optionally `art_version: Optional[str] = None` if per-label art versioning is needed

Return them from lookup:

- Top-level response fields: `spice_key`, `image_key`, `item_id`.
- Or inside `label_metadata`: `{ freshnessCategory, spiceKey, imageKey }`.

Top-level fields are easier for non-spice future categories; `label_metadata` is acceptable if the app already treats category-specific metadata as the enrichment envelope. Either way, keep naming camelCase in the JS client.

### Manifest generation/upload workflow

When new art is produced:

1. Add/confirm the spice row in the source CSV/catalog with `label_name`, `spice_key`, freshness category, and defaults.
2. Generate source masters for all required SKUs and, later, levels.
3. Export delivery images as WebP with alpha at `480` and `720` variants (or one `720` variant if simplicity wins initially).
4. Upload to Firebase Storage / Google Cloud Storage or a CDN path using the deterministic URL scheme.
5. Generate/update `manifest.json` with available keys, dimensions, hashes, and optional BlurHash.
6. Update QR service data so newly allocated labels include `spice_key` / `image_key`.
7. No app-store release is needed for new stock art or new spice labels as long as the app already has the resolver code and the QR service returns the keys.

### Hosting options

- **Firebase Storage / Google Cloud Storage:** best fit now because the QR service already uses Firebase/Firestore and Firebase Storage is built on Google Cloud infrastructure for scalable file storage. It is simple operationally and can be managed by backend scripts/Admin SDK.
- **Google Cloud CDN / CDN in front of a bucket:** best fit when traffic grows. Cloud CDN serves content from Google's edge and caches cacheable responses close to users. A backend bucket with immutable cache headers is appropriate for stock images.
- **Do not put these images in Firestore documents.** Firestore should store metadata and keys, not binary art.

---

## Performance and rendering considerations

### Image format

Use WebP for delivery. Expo Image supports WebP on Android, iOS, and web. Google's WebP FAQ says lossless WebP images are 26% smaller than PNGs, and Google's lossless/alpha study found WebP lossless compressed 23% better than ZopfliPNG and 42% better than libpng, with lossy+alpha offering much larger savings for suitable images.

Keep transparent PNG/source masters for production workflows, but ship WebP to devices.

### Dimensions and memory

Do not serve the 1254-square source to every card. The image is decoded in memory roughly as width × height × 4 bytes. Recommended:

- mini thumbnails: 112–160 px if separate variant is worth it, otherwise use cached 480.
- card/tile/wizard: 480 px.
- full hero/detail/recall: 720 px.
- original 1254 only for source/archive or future zoom use.

### Lists, Home carousel, and grids

React Native's FlatList performance guide calls out memory consumption, window size, batch rendering, and using light/cached optimized images. For PlaceWell:

- Keep Home carousel/rendered lists lazy and avoid pre-rendering the entire stock matrix.
- Use `recyclingKey` when an image cell may be reused for a different label.
- Memoize image card components where possible.
- Serve exact dimensions and keep layout square/aspect-ratio stable to avoid layout thrash.
- Use CDN cache headers and immutable URLs.
- Prefetch only the next 1–3 likely visible images, not the whole catalog.
- Avoid showing high-res assets in small tiles.

### Offline behavior

The user should never see a broken image:

1. user photo if present;
2. cached remote stock image if available;
3. remote stock image when online;
4. bundled per-SKU generic fallback;
5. generic container fallback for unknown category/SKU.

---

## Relationship to roadmap #10 / #11 / #12

- **#10 Real jar photos:** this proposal extends #10 from "one real jar photo per SKU" to a remote, per-spice stock-art catalog. The current branch's component seam is still the right starting point.
- **#11 Multi-photo labels:** no conflict. User-owned photos still win over stock placeholders. If #11 adds `photoUris`, the precedence becomes first/hero user photo, then stock placeholder only when `photoUris` is empty.
- **#12 Guided jar capture:** #12's manual fill marker captures a user photo plus a user-set fill bucket. The proposed quantity-level stock images are for the **placeholder/no-user-photo** case. They can reuse the same fill-level enum and UI, and may supersede the need to draw manual marker overlays on stock placeholders. For user photos, keep #12's captured `fillLevel` as metadata; do not replace the user's photo with stock art.

---

## Phased implementation plan

### Phase 0 — Asset/data foundation

- Choose canonical keys: `spice_key` and `image_key`.
- Add keys to spice CSV/catalog and QR allocation pipeline.
- Pick hosting: Firebase Storage/GCS now; CDN in front when needed.
- Define manifest schema and URL versioning.

### Phase 1 — Per-spice remote placeholders

- Implement app resolver and manifest cache.
- Add QR lookup/order fields and app storage fields.
- Swap stock placeholder rendering to `expo-image`.
- Bundle only generic per-SKU fallback images.
- Upload `3 × 28 = 84` WebP images.
- Validate Home carousel, LabelForm photo step, LabelDetail, LabelRecall, LabelCard, RoomSection.

### Phase 2 — Quantity-level stock placeholders

- Add `quantityLevel` enum and UI for spice labels.
- Save/edit level on label records.
- Upload `3 × spices × 4` level images.
- Resolver uses level image first, then spice default, then generic fallback.

### Phase 3 — Operational polish

- Add manifest hash/version checks and admin upload script.
- Add lightweight prefetch of recently scanned/visible labels.
- Add asset monitoring: missing-key logs, fallback rate, average image download size.
- Consider Cloud CDN if Firebase/GCS direct serving is not sufficient.

---

## Sources

- Expo Assets docs: local assets are bundled into the production binary; remote assets are not bundled and require explicit dimensions. https://docs.expo.dev/develop/user-interface/assets/
- React Native Images docs: static image `require()` paths must be statically known; network images keep binary size down but need dimensions. https://reactnative.dev/docs/images
- Expo Image docs: performant cross-platform image component; disk/memory caching; BlurHash/ThumbHash; transitions; `contentFit`; WebP support; SDWebImage/Glide. https://docs.expo.dev/versions/latest/sdk/image/
- Expo EAS Update docs: OTA updates ship JS/assets, not native changes; large/multiple assets should be kept small and are downloaded when new. https://docs.expo.dev/eas-update/introduction/ and https://docs.expo.dev/eas-update/optimize-assets/
- Apple App Store Connect maximum build sizes: iOS uncompressed app limit is 4 GB, but size still affects install experience; iOS App Store cellular settings commonly prompt around 200 MB. https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes
- Android App Bundle docs: Google Play serves optimized device-specific downloads and points large resources toward dynamic delivery / Play Asset Delivery. https://developer.android.com/guide/app-bundle/ and https://developer.android.com/guide/playcore/asset-delivery
- Firebase Storage docs: scalable object storage built on Google Cloud infrastructure. https://firebase.google.com/docs/storage
- Google Cloud CDN docs: edge caching serves content closer to users and reduces origin requests. https://cloud.google.com/cdn/docs/overview
- WebP FAQ and lossless/alpha study: WebP supports lossy/lossless transparent images and is materially smaller than PNG. https://developers.google.com/speed/webp/faq and https://developers.google.com/speed/webp/docs/webp_lossless_alpha_study
- React Native FlatList optimization docs: tune rendering windows/batches and use light cached optimized images. https://reactnative.dev/docs/optimizing-flatlist-configuration

