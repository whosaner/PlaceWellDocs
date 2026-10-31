# PlaceWell 1.2.0 — Release Collateral (App Store + Google Play)

Marketing version **1.2.0** (`PlaceWellApp/app.json`). Bumped from 1.1.0 because
App Store Connect had already approved/closed the 1.1.0 version train
(ITMS-90062 / ITMS-90186 on the 1.1.0 resubmission).

## What's new in 1.2.0
First-run guided onboarding:
- The **Home** screen spotlights the round **Scan** button — "Scan your PlaceWell
  Order Label" — whenever there are no labels yet.
- A short **3-step walkthrough** guides setup right after an Order QR import
  (apply room/zone to the whole kit, customize a label, create the labels).
- Both hints **recur**: the Home hint shows whenever the home is empty; the import
  tour shows on every order import. Dismissal ("Got it" / "Skip") is session-scoped
  and not persisted.

## Release status
- [x] Code merged to `main` (`a265082`) and tagged **`v1.2.0`**
- [x] Verified on iOS (TestFlight) and Android
- [x] Pushed `main` and tag `v1.2.0` to GitHub
- [x] iOS 1.2.0 publicly released on the App Store on 2026-09-18
- [ ] Verify the exact Android production version in Play Console (the public
  Play listing does not expose it reliably)
- [x] App Store What's New text and reviewer collateral prepared

## Files in this folder (1.2.0-specific)
| File | Purpose |
|---|---|
| `RELEASE_STEPS.md` | Step-by-step release runbook — **start here** |
| `WhatsNew_1.2.0.txt` | Release notes for App Store ("What's New") + Google Play |
| `AppReview_Notes_1.2.0.txt` | Reviewer notes to paste into App Store Connect → App Review Information |

## Reusable from the parent `store-listing/` folder (unchanged for 1.2.0)
- `App_Store_Listing.md`, `Play_Store_Listing.md` — listing metadata (name, subtitle, description, keywords, category)
- `AppStore_PasteReady.txt`, `Play_Store_PasteReady.txt` — paste-ready listing text
- `play-feature-graphic.png` — Play feature graphic (1024×500)
- `screenshots/ios`, `screenshots/android` — screenshots (reuse; the guided tour overlays existing screens, so no new base screens are required)
- `Play_Data_Safety_AnswerSheet.txt` — Play Data safety answers
- `Play_Service_Account_Setup.md` — Android automated-submit service account (or manual `.aab` fallback)
- `qr/REVIEW-SHEET-v1.1.0.png` — demo QR sheet for reviewers
