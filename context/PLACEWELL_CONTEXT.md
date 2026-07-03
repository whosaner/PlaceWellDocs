# PlaceWell — Complete Project Context

> **Purpose of this file:** This document gives any AI assistant (GitHub Copilot, Claude, Cursor, etc.) full context to pick up PlaceWell work without prior conversation history. Treat every section as authoritative. Do not suggest revisiting closed decisions unless explicitly asked.

---

## 1. What Is PlaceWell?

PlaceWell is a premium home organization label business co-founded by **Hussain** (tech, systems, B2B) and **Khadija** (brand, Etsy, social). It combines:

- **Physical labels** — beautifully designed, printed on waterproof material, shipped to customers
- **QR codes on labels** — each label has a unique QR code that links to a digital inventory entry
- **A companion mobile app** — React Native/Expo app where users manage what's behind/inside each label

The core value proposition: labels that are *designed objects* (not just utilitarian stickers) that also unlock smart home organization through QR-powered digital tracking.

---

## 2. The QR System (Technical Decision — Closed)

- **Format:** `placewell.app/scan/XJ72K` — short alphanumeric unique ID (5 chars), URL-encoded in QR
- **QR standard chosen:** QR Code (not Data Matrix, not NFC, not BLE)
  - Rationale: Universal phone camera compatibility, no app required to scan, works at the sizes labels will be printed, Etsy buyers don't need to install anything to scan
- **Data storage (MVP):** All inventory data lives in the mobile app (local storage). The QR just holds the short ID; the app maps IDs to user data locally.
- **Future:** Cloud sync / account system post-MVP, but no backend at launch

---

## 3. Brand Identity (Do Not Deviate)

### Palette
| Token | Hex | Usage |
|---|---|---|
| Ink | `#2C2C2C` | Primary text, strong UI elements |
| Chalk | `#F5F0EB` | Backgrounds, light surfaces |
| Sage | `#8FAF8F` | Accents, nature/organic feel |
| Terracotta | `#C4714A` | Warm accents, CTA highlights |
| Stone | `#9E9E8F` | Secondary text, dividers |

### Typography
| Role | Font | Notes |
|---|---|---|
| Display / hero | Cormorant Garamond | Elegant serif, used for label product names, headlines |
| Utility / UI | DM Mono | Monospace, used for QR IDs, metadata, app UI labels |
| Body / marketing | Jost | Clean sans-serif for web and marketing copy |
| Secondary display | Libre Baskerville | Alt display serif for variety |

### Aesthetic
- **Warm minimal** — not cold/clinical, not maximalist/busy
- Think: artisan pantry labels, linen texture, natural tones
- Avoid: tech-startup blue/white, busy borders, drop shadows, gradients
- Physical label design should look good *before* someone even scans the QR — the QR is integrated tastefully, not slapped on

---

## 4. Product Line (MVP Focus)

### Entry Product: Spice & Pantry Labels
- First Etsy listing category
- High repurchase potential, gifting appeal, large existing Etsy market
- Size: TBD per label design, but standard pantry jar label proportions
- Material: **Waterproof polyester vinyl** (chosen over BOPP for durability, matte finish quality)
- Print method: Digital print + laminate

### Future Product Categories (Post-MVP)
- Storage bin labels (garage, playroom, office)
- Moving box labels
- Builder/realtor welcome kit labels (B2B)
- Nursery / kids' room labels

---

## 5. Go-to-Market Strategy

### Phase 1: Etsy (Current Focus)
- **Store:** Listed under Khadija's existing **BeNiralu** Etsy store (not a new store)
  - Rationale: BeNiralu has existing reviews and trust equity — starting fresh loses that
  - PlaceWell is a product line within BeNiralu, eventually may spin out as its own store
- **Positioning:** Premium design-forward labels, not cheapest option
- **SEO targets:** "spice jar labels," "pantry organization labels," "custom kitchen labels," "QR home organization"
- **Initial listing strategy:** 3–5 SKUs (e.g., spice label sets in different styles/sizes)
- **Competitor gap:** No major Etsy seller combines premium design + QR digital tracking

### Phase 2: B2B / Homebuilder Channel (Scaling Lever)
- **Target:** New construction homebuilders and realtors in Cypress, TX and surrounding Houston metro
- **Offer:** PlaceWell welcome kits — branded label sets as a move-in gift or buyer incentive
- **Why this works:** Hussain lives in a Taylor Morrison new construction community, understands the buyer persona firsthand, and has proximity to the Cypress new construction market
- **Format:** Custom-branded kits (builder's logo + PlaceWell branding), bulk pricing
- **Status:** Identified as primary scaling lever; outreach not yet started

### Known Competitors
| Competitor | Weakness vs PlaceWell |
|---|---|
| SmartLabels | Not on Etsy; no design focus |
| ToteScan | Not on Etsy; utilitarian aesthetic |
| Generic Etsy label sellers | No QR/digital tracking |

---

## 6. Tech Stack

### Mobile App (Primary Product Tech)
- **Framework:** React Native with Expo
- **MVP scope:**
  - QR scan → open label detail view
  - Add/edit item linked to a label ID
  - Label list / home screen
  - Local storage (no backend at MVP)
- **Target platforms:** iOS and Android
- **State management:** TBD (lean toward Zustand or Context API for simplicity)
- **Navigation:** React Navigation (Expo Router also acceptable)

### Label Generation / QR
- QR codes generated programmatically (library TBD: `react-native-qrcode-svg` or server-side generation)
- Short ID format: 5 uppercase alphanumeric chars (e.g., `XJ72K`)
- QR resolves to: `placewell.app/scan/XJ72K`
- Domain `placewell.app` is the intended domain (confirm registration status before build)

### Web Presence
- No web app at MVP
- `placewell.app/scan/:id` may need a minimal redirect or landing page (app deep link)
- Consider Expo's universal links / deep linking setup early

---

## 7. Roles & Responsibilities

| Area | Owner |
|---|---|
| Brand identity, label design | Khadija |
| Etsy listings, product photography, social | Khadija |
| Mobile app development | Hussain |
| B2B outreach, homebuilder channel | Hussain |
| Systems, QR infrastructure, domain | Hussain |
| Business strategy (joint) | Both |

---

## 8. Closed Decisions (Do Not Reopen Unless Asked)

| Decision | Choice Made | Rationale |
|---|---|---|
| QR vs NFC | QR | Universal, no hardware cost, works at label sizes |
| QR vs Data Matrix | QR | Better phone camera support, more consumer-familiar |
| Etsy vs own storefront | Etsy first | Lower friction, existing BeNiralu trust equity |
| New store vs BeNiralu | BeNiralu | Preserve review history |
| Material | Waterproof polyester vinyl | Durability, matte finish, kitchen/pantry appropriate |
| MVP data storage | Local (no backend) | Fastest to ship; cloud sync is post-MVP |
| Entry product | Spice/pantry labels | High demand, gifting, repurchase |
| Primary scaling lever | B2B homebuilder channel | Hussain's market proximity, higher AOV |

---

## 9. Business Context

- **Stage:** Pre-revenue, pre-launch. Still in build/design phase.
- **Structure:** Side business alongside Hussain's role as Software Engineer at Microsoft
- **Location:** Cypress, TX (Houston metro) — relevant for B2B homebuilder targeting
- **Halal compliance:** All business practices and any physical product sourcing should be halal-compliant
- **Etsy account:** Khadija's existing BeNiralu store; she manages the seller relationship
- **Financial model:** Physical product margins (print + material + shipping) + eventual SaaS or premium app features (not yet scoped)

---

## 10. Open Questions / Next Steps (as of last context update)

- [ ] Finalize first label design(s) — Khadija leading
- [ ] Register / confirm `placewell.app` domain
- [ ] Set up Expo project scaffold
- [ ] Define QR ID generation logic and short-ID schema
- [ ] Build MVP app: scan → view → add item → list screen
- [ ] Photograph first product set for Etsy listing
- [ ] Write Etsy listing copy (SEO-optimized)
- [ ] Begin B2B outreach research (homebuilders in Cypress TX area)

---

## 11. How to Work on This Project

When assisting with PlaceWell, default to:
- **Brand-consistent language:** warm, confident, minimal. Avoid corporate jargon.
- **Respecting closed decisions:** Don't re-suggest NFC, a standalone new Etsy store, BOPP, etc.
- **Scope awareness:** MVP = app + Etsy. Don't gold-plate. Ship first, iterate.
- **Hussain's working style:** Bias toward action. Start building and refine. Don't over-plan.
- **Khadija's ownership:** Brand and Etsy are hers. Don't make decisions in those areas without flagging.

---

*Last updated: April 2026. Maintained by Hussain. Source of truth for all AI assistant context on PlaceWell.*
