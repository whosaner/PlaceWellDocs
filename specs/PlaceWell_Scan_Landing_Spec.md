# PlaceWell · Scan Landing Page — Requirements Document

**Version:** 1.0
**Date:** July 2026
**Status:** Approved for implementation
**Owner:** Hussain
**Scope:** The web page served at `https://placewell.app/s/{LABELID}-{SIG}` when the PlaceWell app is **not** installed.
**Reference mockup:** `placewell_scan_landing_v2.html`

---

## 1. Purpose

When a customer scans a PlaceWell QR code and does not have the app installed, the operating system falls back to opening the URL in a browser. This page is what they see.

It has exactly one job: **get the app installed, and get the customer back to the code they just scanned.**

It is not a marketing page. It is not a product page. It does not display any label content.

### 1.1 Non-goals

| Excluded | Reason |
|---|---|
| Deferred deep linking (Branch.io, Smler.io, Firebase Dynamic Links) | Dropped for v1. The physical artifact is in the customer's hand. Re-scanning is one tap. Supersedes `PlaceWell_App_QR_Strategy.md` §5 and the Launch Tracker line item. |
| Label name, contents, photo, or room | Privacy. Anyone can scan a bin in a garage. The server knows this data; the page never renders it. |
| Tablet-optimised layout | PlaceWell is phone-only. Tablets fall into the `other` state (§5). |
| Account creation / login | The app is local-first. No account exists at this point. |
| Product marketing, testimonials, feature tours | Not the job of this page. |

---

## 2. Route

| Property | Value |
|---|---|
| Method | `GET` |
| Path | `/s/{LABELID}-{SIGNATURE}` |
| Renders | Server-side HTML. No client-side JavaScript required for any state. |
| Cache | `Cache-Control: no-store` — revocation must take effect immediately. |
| Signature | Ignored by the server (app-only namespace guard, per QR Service Requirements §2.3). |

### 2.1 Deep-link mechanism — LOCKED

**Universal Links (iOS) + App Links (Android) only.**

The OS intercepts `placewell.app/s/*` *before* the browser opens. If the app is installed, the app opens and **the server is never hit**. This page renders only when the app is absent.

The `302 → placewell://scan/{LABELID}` redirect described in `PlaceWell_QR_Service_Requirements.md` §6.3 is **superseded**. Custom-scheme redirects produce an "address is invalid" error dialog when the app is absent — unacceptable as a first customer touchpoint.

**Consequence for telemetry:** `qr_codes.scan_count`, incremented in this handler, counts *scans where the app was not installed*. It is not a total-scan metric. Real scan telemetry must come from the app.

### 2.2 Required hosting files

| File | Path | Purpose |
|---|---|---|
| Apple App Site Association | `/.well-known/apple-app-site-association` | Served as `application/json`, no file extension, no redirect. |
| Digital Asset Links | `/.well-known/assetlinks.json` | Android App Links verification. |

Both must be reachable over HTTPS with a valid certificate and must not be behind the Apache reverse-proxy rewrite that routes `/s/*` to Uvicorn.

---

## 3. Server-side resolution

The handler resolves **three independent inputs**. There is no client-side detection.

```
GET /s/{LABELID}-{SIG}
    │
    ├─ 1. platform  ← User-Agent header          → ios | android | other
    ├─ 2. state     ← Firestore status on LABELID → active | revoked | not_found
    └─ 3. code_type ← Firestore code_type field   → label | order
    └─ 4. category  ← Firestore category field    → pantry | (future)
             │
             ▼
      Render one page from the state matrix (§4)
```

If `state != active`, `code_type` and `category` are not read and not rendered.

If `state == active`, increment `scan_count` (atomic `FieldValue.increment(1)`) and set `last_scanned_at`. Best-effort async — must not block the render.

---

## 4. State matrix

Six renderable states. All share one shell.

| # | platform | state | code_type | Page |
|---|---|---|---|---|
| 1 | ios | active | label | Label · App Store primary |
| 2 | android | active | label | Label · Google Play primary |
| 3 | ios | active | order | Order · App Store primary |
| 4 | android | active | order | Order · Google Play primary |
| 5 | other | active | any | **Other** — "PlaceWell lives on your phone" |
| 6 | any | not_found | — | **404** |
| 7 | any | revoked | — | **410** |

State 5 collapses laptop, desktop, tablet, and any unrecognised UA into one page. Its job is to get the code onto a phone, not to sell.

---

## 5. Platform detection

Server-side, from the `User-Agent` request header.

| Rule (case-insensitive, evaluated in order) | Result |
|---|---|
| UA contains `iPhone` or `iPod` | `ios` |
| UA contains `Android` **and** contains `Mobile` | `android` |
| Anything else — including `iPad`, `Macintosh`, `Windows`, Android tablets, empty UA, bots | `other` |

### 5.1 Rules

- **`iPad` resolves to `other`, deliberately.** PlaceWell is phone-only. iPadOS Safari also reports itself as `Macintosh` by default, so a separate iPad branch would be unreliable anyway. One bucket, correct message.
- **Android without `Mobile` is a tablet.** Same reasoning.
- **The secondary store link is ALWAYS rendered on states 1–4.** Never hide the other platform. UA detection fails inside Instagram/Facebook/Pinterest in-app browsers, on spoofed UAs, and when a customer is buying for a household on the other platform. A wrong guess with no escape hatch is a lost install; a small secondary link costs nothing.
- Detection is a **framework rule**, not per-category config. It does not vary by `code_type` or `category`.

### 5.2 App Store configuration (out of scope for this page, noted for consistency)

- App Store Connect: publish as **iPhone only**, not Universal.
- Play Console: restrict to phone form factors in the device catalogue.
- If the iOS app remains installable on iPad in compatibility mode, that is acceptable — but this page will not encourage it.

---

## 6. Configurable surfaces

This is the framework/config separation. Everything below is **config**. Everything not below is **framework** and does not vary.

### 6.1 `STORE` — platform config

Two entries, `ios` and `android`. Each provides: store URL, primary button label, store glyph, secondary-link copy. Adding a platform means adding an entry.

### 6.2 `TYPE` — code-type config

Keyed on `code_type` from Firestore. Provides: chip prefix, headline, lede, and the three-step list.

| | `label` | `order` |
|---|---|---|
| Chip | `Label · {LABELID}` | `Order · {LABELID}` |
| Headline | This label is blank. | Your labels are ready. |
| Step 02 | **Scan this label again.** The app opens straight to it. | **Scan this card again.** Your whole kit loads at once. |

Exact strings in §8.

### 6.3 `HERO` — category config *(the future-proofing surface)*

Keyed on `category` from Firestore. Provides the hero illustration rendered in the stage area.

| `category` | Hero | Status |
|---|---|---|
| `pantry` | Spice jar(s) — glass body, amber lid, dashed blank label slot | **Ships in v1** |
| `garage` | TBD | Future |
| `kids` | TBD | Future |
| *(missing / unrecognised)* | **`default`** — a blank label card with a dashed slot | **Ships in v1** |

**The `default` hero must ship in v1**, even though only `pantry` codes exist. It is the fallback that makes the config surface real rather than aspirational, and it is category-agnostic by construction: it is the label itself. Without it, the first garage SKU forces a code change to this page. With it, the first garage SKU is a Firestore write.

**Jar count is driven by `code_type`, not `category`:** `label` → 1 hero object, `order` → 3 (one large, two small flanking). This is a property of the `TYPE` config, applied to whichever `HERO` is selected.

### 6.4 What is framework — does not vary

- Porcelain Sky gradient background and all design tokens (see `PlaceWell_Design_System.md`)
- Wordmark, tagline, footer
- Card structure, button geometry, step-list structure
- Platform detection rules
- The presence and bolding of step 02
- The rule that the secondary store link is always rendered

---

## 7. Firestore — required schema additions

The `qr_codes` collection currently carries `label_name`, `status`, `scan_count`, `last_scanned_at`. This page requires two additions.

| Field | Type | Values | Default | Written by |
|---|---|---|---|---|
| `code_type` | string | `label` \| `order` | `label` | Allocation service (`POST /api/qr/allocate`) |
| `category` | string | `pantry` (v1) | `pantry` | Allocation service |

**Backfill required** for any IDs already allocated. Both fields must be non-null before this page ships, or the handler must treat a missing value as its default rather than erroring.

**Open question — see §11:** whether `order` codes live in `qr_codes` alongside labels with `code_type: "order"`, or in a separate `orders` collection with its own lookup. The spec assumes a single collection with a discriminator field. If they are separate collections, §3 needs a two-step lookup.

---

## 8. Content

Exact strings. Sentence case. No exclamation marks. Active voice.

### 8.1 Shell (all states)

| Element | Content |
|---|---|
| Wordmark | `Place` + italic amber `W` + `ell` |
| Tagline | *Everything in its place, done well.* |
| Footer | `placewell.app · BeNiralu LLC` |

### 8.2 State: `label` (active)

- **Chip:** `LABEL  {LABELID}`
- **Headline:** This label is blank.
- **Lede:** Get the free PlaceWell app to name it, photograph what's inside, and find it again with a single scan.
- **Primary CTA:** `Download on the App Store` / `Get it on Google Play`
- **Secondary link:** `Using Android? Get it on Google Play` / `On an iPhone? Download on the App Store`
- **Steps:**
  - `01` Install the free app.
  - `02` **Scan this label again.** The app opens straight to it.
  - `03` Name it, snap what's inside, set its room.

### 8.3 State: `order` (active)

- **Chip:** `ORDER  {LABELID}`
- **Headline:** Your labels are ready.
- **Lede:** Get the free PlaceWell app. Scanning this card once loads every label in your kit — so you can set them up as you stick them on.
- **Primary CTA / Secondary link:** as above
- **Steps:**
  - `01` Install the free app.
  - `02` **Scan this card again.** Your whole kit loads at once.
  - `03` Stick a label on, scan it, tell it what it holds.

### 8.4 State: `other`

- **Chip:** `{LABELID}`
- **Headline:** PlaceWell lives on your phone.
- **Lede:** That's where the camera is. Install the app, then scan this code again with your phone to set it up.
- **Primary element:** a QR code encoding this exact URL, with the caption "Point your phone camera here."
- **Secondary:** App Store and Google Play badges, both, equal weight, below the QR.

**Ordering rule:** on this state the QR is the primary action and the store badges are secondary. This inverts states 1–4. Reason: a person on a laptop cannot usefully install a phone app from that device; the shortest path to value is getting the code onto their phone.

### 8.5 State: `404` — not found

- HTTP status: `404`
- **Chip:** `UNRECOGNISED CODE`
- **Headline:** That's not a PlaceWell code.
- **Lede:** It didn't match anything in our system. Check you're scanning the QR on a PlaceWell label or kit card — not a shipping barcode or another sticker.
- **CTA:** ghost button — see §11, open item 3
- **Secondary link:** `Bought a kit and still stuck? Email support`
- No steps list. Terracotta accent on the hero.

### 8.6 State: `410` — revoked

- HTTP status: `410`
- **Chip:** `{LABELID}  ·  RETIRED`
- **Headline:** This code is retired.
- **Lede:** It was deactivated and no longer links to anything. If you didn't retire it yourself, we can look into it.
- **CTA:** `Email PlaceWell support`
- **Secondary link:** `Or order a replacement label`
- No steps list. Terracotta accent on the hero.

---

## 9. Design

All tokens from `PlaceWell_Design_System.md` — Porcelain Sky. Not restated here. The mockup is the reference implementation.

| Aspect | Spec |
|---|---|
| Background | `LinearGradient` bgTop `#DDE6EC` → bgMid `#B8CFDA` → bgBot `#8AABBD`, vertical |
| Card | Frosted glass — `rgba(255,255,255,0.42)`, border `rgba(255,255,255,0.62)`, radius 20 |
| Primary CTA | Amber `#C9A66B` pill, amber glow shadow — matches the app's scan button |
| Error accent | Terracotta `#C4785A` — lid and slot only, never the type |
| Display | Cormorant Garamond 600 (headline), 400 (wordmark) |
| Body | Jost 400/500 |
| Utility | DM Mono — chip, step numbers, footer |
| Tagline | Libre Baskerville italic |
| Motion | Two staggered entrance transforms, ~800ms. Nothing else. Respects `prefers-reduced-motion`. |

### 9.1 Quality floor

- Fully responsive; no horizontal scroll at 320px
- Visible keyboard focus on every interactive element
- `prefers-reduced-motion: reduce` disables all animation
- Renders correctly with JavaScript disabled — all states are server-rendered
- Fonts self-hosted or preconnected; page must not block on a font CDN

### 9.2 iOS Smart App Banner

Include on states 1–4 once the App Store ID exists:

```html
<meta name="apple-itunes-app" content="app-id={APP_STORE_ID}">
```

Free native install banner in Safari. Costs nothing. Adds a second install path above the fold.

---

## 10. Acceptance criteria

| # | Test | Pass |
|---|---|---|
| 1 | Scan a `label` code on iPhone, app not installed | Page renders, App Store primary, Google Play secondary visible |
| 2 | Scan a `label` code on Android phone, app not installed | Page renders, Google Play primary, App Store secondary visible |
| 3 | Scan an `order` code, either platform | Order copy, three heroes, "scan this card again" in step 02 |
| 4 | Scan any code on iPad | `other` state — QR primary, both badges secondary |
| 5 | Open the URL on a laptop | `other` state |
| 6 | Scan a code with the app installed | **Page never renders.** App opens directly to the code. |
| 7 | Scan an unknown ID | HTTP 404, error state, no store buttons |
| 8 | Scan a revoked ID | HTTP 410, error state |
| 9 | Any active scan | `scan_count` incremented exactly once, `last_scanned_at` updated |
| 10 | Any state, JavaScript disabled | Renders identically |
| 11 | Any state, 320px viewport | No horizontal scroll, all CTAs reachable |
| 12 | Firestore record missing `category` | Falls back to `default` hero. No error. |
| 13 | Firestore record missing `code_type` | Falls back to `label`. No error. |
| 14 | Open inside the Instagram in-app browser | Renders. Secondary store link present and tappable. |

---

## 11. Open items

1. **Do `order` codes live in `qr_codes` with a `code_type` discriminator, or in a separate collection?** Affects §3 lookup logic. Spec currently assumes single collection.
2. **The order card and this page must agree.** The physical insert card in the box says something; step 02 here says "scan this card again." Those two copy decisions should be made together, not separately. Insert card copy is not yet written.
3. **404 CTA destination.** Currently `See PlaceWell labels`. Should the 404 page sell — link to the Etsy shop — or should it apologise and stop? A person hitting 404 scanned something that isn't ours; they may not be a customer at all.
4. **Backfill plan for `code_type` and `category`** on already-allocated IDs.

---

## 12. Superseded decisions

| Document | Section | Superseded by |
|---|---|---|
| `PlaceWell_App_QR_Strategy.md` | §5 — Deferred deep linking via Branch.io / Firebase | §1.1 — dropped for v1 |
| `PlaceWell_QR_Service_Requirements.md` | §6.3 step 7 — `302 → placewell://scan/{LABELID}` | §2.1 — Universal Links / App Links only |
| `PlaceWell_Launch_Tracker.md` | "Test deferred deep linking flow (scan → install → lands on label)" | §1.1 — removed |
