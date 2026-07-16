# PlaceWell App Setup

This quickstart covers local setup for the React Native + Expo mobile app.

## Prerequisites
- Node.js 18+
- Expo Go on a physical iOS or Android device

## Install
```bash
cd C:\PlaceWell\PlaceWellApp
npm install --legacy-peer-deps
```

## Configure app secrets
Set the Expo `extra` values in `app.json`:

```json
"extra": {
  "hmacSecret": "YOUR_SECRET_KEY_HERE",
  "qrServiceUrl": "https://placewell.app",
  "qrServiceToken": "YOUR_BEARER_TOKEN"
}
```

`hmacSecret` must match the QR Service HMAC secret exactly. Never commit real secrets.

## Run locally
```bash
npx expo start
```

Open Expo Go on your phone and scan the terminal QR code.

## Test
```bash
npx jest --no-coverage --maxWorkers=2
```

## Maestro E2E workspace
- The app now includes a Maestro workspace at `C:\PlaceWell\PlaceWellApp\.maestro\`.
- Use a **standalone/dev-client build** with app ID `com.placewell.app` for Maestro work — not Expo Go.
- Shared flow generation commands live in `PlaceWellApp\package.json`:
  ```bash
  npm run maestro:list
  npm run maestro:add -- --prompt "Add a regression test for bulk import where track freshness is off"
  npm run maestro:test -- --id CORE-01
  ```
- Current smoke flows expect runtime env vars such as `APP_ID`, `PW_SCAN_NEW_SPICE_URL`, `PW_SCAN_NEW_STORAGE_URL`, `PW_SCAN_EXISTING_SPICE_LINK`, `PW_SCAN_EXISTING_STORAGE_LINK`, `PW_ORDER_LINK`, and `PW_SCAN_BAD_SIGNATURE_URL`.
- Maestro launch-argument detection is wired through `src\utils\testMode.js` with `react-native-launch-arguments` so future test-mode hooks can key off `MAESTRO_TEST_MODE=true`.

## Related central docs
- Architecture: `C:\PlaceWell\Docs\architecture\System_Overview.md`
- Design system: `C:\PlaceWell\Docs\design\Design_System.md`
- Feature spec: `C:\PlaceWell\Docs\features\ScanToRecall.md`
- Release checklist: `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md`

## Firebase Analytics — production activation

Analytics events are instrumented in the app but are **silent no-ops in Expo Go**. To activate for a production EAS build:

1. Create a Firebase project (or use `placewell-prod` if already set up)
2. Add `google-services.json` (Android) to `C:\PlaceWell\PlaceWellApp\`
3. Add `GoogleService-Info.plist` (iOS) to `C:\PlaceWell\PlaceWellApp\`
4. Add the Firebase plugin to `app.json`:
   ```json
   "plugins": [
     "@react-native-firebase/app"
   ]
   ```
5. Run `eas build` — all 10 analytics events activate with no code changes

See `C:\PlaceWell\Docs\architecture\System_Overview.md` for the full event list.
