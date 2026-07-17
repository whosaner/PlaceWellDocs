# PlaceWell Store Listing Launch Collateral

This folder contains launch collateral for App Store Connect and Google Play Console.

## Files

- `App_Store_Listing.md` — App Store Connect metadata: app name, subtitle, promotional text, description, keywords, URLs, What’s New, category, and age-rating guidance.
- `Play_Store_Listing.md` — Google Play main store listing: app name, short description, full description, category/tags, content-rating guidance, and contact fields.
- `Play_Service_Account_Setup.md` — Steps to fix automated `eas submit --platform android` service-account permissions, plus manual AAB upload fallback.
- `make_feature_graphic.py` — Regenerates the Google Play feature graphic using the PlaceWell PDF generator Python environment and brand fonts.
- `play-feature-graphic.png` — 1024×500 Google Play feature graphic.

## Where to paste

- Paste App Store fields into **App Store Connect → Apps → PlaceWell → App Information / Pricing and Availability / Version metadata**.
- Paste Play Store fields into **Google Play Console → PlaceWell → Store presence → Main store listing**.
- Use `play-feature-graphic.png` in the Play Console **Feature graphic** field.

## Still needed from the owner

- App Store screenshots, including 6.7-inch iPhone screenshots.
- Google Play phone screenshots, minimum 2.
- Final product/lifestyle screenshots or mockups that show the real app and labels.
- App icon is already available at `C:\PlaceWell\PlaceWellApp\assets\playstore-icon.png`.
