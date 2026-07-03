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

## Related central docs
- Architecture: `C:\PlaceWell\Docs\architecture\System_Overview.md`
- Design system: `C:\PlaceWell\Docs\design\Design_System.md`
- Feature spec: `C:\PlaceWell\Docs\features\ScanToRecall.md`
- Release checklist: `C:\PlaceWell\Docs\release\Release_Validation_Checklist.md`
