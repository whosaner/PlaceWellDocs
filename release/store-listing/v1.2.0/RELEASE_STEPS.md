# PlaceWell 1.2.0 — Release Runbook (step by step)

App: PlaceWell   |   Apple App ID: 6788545365   |   Bundle/Package: com.placewell.app
Marketing version: 1.2.0   |   Apple Team: CM5N45M892

Build/version numbers auto-increment on EAS (eas.json: `appVersionSource: remote`,
`production.autoIncrement: true`). The marketing version comes from `app.json`
(1.2.0) and is shared across iOS + Android.

--------------------------------------------------------------------
## STEP 1 — REPOSITORY  (DONE)
--------------------------------------------------------------------
- [x] Guided-tour work committed and merged to `main` (fast-forward): `a265082`
- [x] Tagged `v1.2.0`
- [x] Push to origin:

    cd C:\PlaceWell\PlaceWellApp
    git push origin main --tags

--------------------------------------------------------------------
## STEP 2 — iOS  (App Store — released)
--------------------------------------------------------------------
Version 1.2.0 was publicly released on the App Store on 2026-09-18.

The commands below are retained as the operational process used for future
rebuilds/submissions:

If you do need to (re)build/submit:

    eas build  --platform ios --profile production
    eas submit --platform ios --profile production      # -> TestFlight

In App Store Connect (appstoreconnect.apple.com → PlaceWell):
1. Create the **1.2.0** version (+ Version or Platform).
2. Paste "What's New in This Version" from `WhatsNew_1.2.0.txt`.
3. Screenshots: reuse existing (`../screenshots/ios`). Only re-upload if UI changed.
4. Build: select the 1.2.0 TestFlight build.
5. App Review Information: paste `AppReview_Notes_1.2.0.txt`; attach the demo QR
   sheet (`../qr/REVIEW-SHEET-v1.1.0.png`) and a fresh screen recording if requested.
6. Export compliance: already exempt (`ITSAppUsesNonExemptEncryption: false`).
7. Submit for Review.

--------------------------------------------------------------------
## STEP 3 — Android  (Google Play)
--------------------------------------------------------------------
1. Build + submit (submit auto-targets the `internal` track per eas.json):

    eas build  --platform android --profile production
    eas submit --platform android --profile production

   - Automated submit needs the Play service account — see
     `../Play_Service_Account_Setup.md`. If it errors, download the `.aab` from the
     EAS build page and upload it manually in Play Console.
2. Play Console → Testing → Internal testing: verify the build installs/runs.
3. Add release notes from `WhatsNew_1.2.0.txt`.
4. Promote Internal → Production (Release → Production → Create release →
   add from the internal build).
5. Confirm one-time forms are complete (carried over from 1.1.0 — verify):
   - Data safety (`../Play_Data_Safety_AnswerSheet.txt`)
   - Content rating, Target audience, Ads = No
   - Privacy policy: https://placewell.app/privacy

--------------------------------------------------------------------
## STEP 4 — STORE LISTING  (reuse from 1.1.0 unless changed)
--------------------------------------------------------------------
- App Store fields: `../App_Store_Listing.md` / `../AppStore_PasteReady.txt`
- Play fields: `../Play_Store_Listing.md` / `../Play_Store_PasteReady.txt`
- Play feature graphic: `../play-feature-graphic.png`

--------------------------------------------------------------------
## STEP 5 — POST-RELEASE VERIFICATION  (on the store / TestFlight build)
--------------------------------------------------------------------
- Guided tour: Home hint when empty (returns after deleting all labels);
  import tour on every order import.
- Universal links: `https://placewell.app/s/<id>` opens the app (not the website).
- Custom scheme: `placewell://scan`.
- Camera QR scan (order + label), photo capture/library, permission prompts.
- Fresh install → empty Home → scan → bulk import → create → labels on Home.
- Watch review status in both consoles.

--------------------------------------------------------------------
## PRE-BUILD SAFETY CHECK
--------------------------------------------------------------------
A production EAS build fails fast if the EAS secrets are missing (enforced by
`app.config.js`). Confirm before building:

    eas env:list --environment production     # expect HMAC_SECRET, LOOKUP_SECRET
    # (older CLI: eas secret:list)
