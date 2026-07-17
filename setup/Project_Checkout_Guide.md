# PlaceWell Project Checkout Guide

This guide starts from an empty Windows machine and checks out every PlaceWell repository under `C:\PlaceWell`. Verified on 2026-07-17 against the local repos and their Git remotes/branches.

## 1. Prerequisites

Install and verify these tools before cloning:

| Tool | Version / notes | Verify |
|---|---|---|
| Git | Required for all repos. | `git --version` |
| Node.js | Use a current LTS that supports Expo SDK 54 / React 19. PlaceWellApp does not declare `package.json` `engines`; Node 20 LTS or newer is recommended. | `node --version` and `npm --version` |
| Python | QR service runs on Python 3.9+ in Linode. Local `PlaceWellPdfGenerator\.venv\pyvenv.cfg` uses Python 3.13.1. Python 3.9+ is acceptable; Python 3.13 matches the local PDF generator venv. | `python --version` |
| EAS CLI | Required for production app builds and submissions. | `npm install -g eas-cli` then `eas --version` |
| Java 17+ | Optional; required for Maestro E2E testing. | `java -version` |

Optional but useful: Android Studio/emulator for local app and Maestro testing, Xcode on macOS for iOS work, and `curl` for server smoke tests.

## 2. Clone all repos

Create the workspace and clone each repository into `C:\PlaceWell`.

```powershell
New-Item -ItemType Directory -Path C:\PlaceWell -Force
Set-Location C:\PlaceWell

git clone https://github.com/whosaner/PlaceWellApp.git PlaceWellApp
git clone https://github.com/whosaner/PlaceWellQRService.git PlaceWellQRService
git clone https://github.com/whosaner/PlaceWellPdfGenerator.git PlaceWellPdfGenerator
git clone https://github.com/whosaner/PlaceWellDocs.git Docs
git clone https://github.com/whosaner/PlaceWellUI.git PlaceWellUI
```

Verified repo state:

| Local path | Remote | Branch |
|---|---|---|
| `C:\PlaceWell\PlaceWellApp` | `https://github.com/whosaner/PlaceWellApp.git` | `main` |
| `C:\PlaceWell\PlaceWellQRService` | `https://github.com/whosaner/PlaceWellQRService.git` | `main` |
| `C:\PlaceWell\PlaceWellPdfGenerator` | `https://github.com/whosaner/PlaceWellPdfGenerator.git` | `master` |
| `C:\PlaceWell\Docs` | `https://github.com/whosaner/PlaceWellDocs.git` | `master` |
| `C:\PlaceWell\PlaceWellUI` | `https://github.com/whosaner/PlaceWellUI.git` | `master` |

## 3. Per-project setup

### PlaceWellApp — React Native / Expo SDK 54

The app uses Expo `~54.0.35`, React `19.1.0`, and React Native `0.81.5`. `npm install --legacy-peer-deps` is required because React 19 and `jest-expo` peers conflict; `.npmrc` already contains `legacy-peer-deps=true`.

```powershell
Set-Location C:\PlaceWell\PlaceWellApp
npm install --legacy-peer-deps
npx expo start
```

Run unit tests:

```powershell
Set-Location C:\PlaceWell\PlaceWellApp
npx jest --no-coverage
```

Production builds require EAS secrets described below and are run from `C:\PlaceWell\PlaceWellApp`.

### PlaceWellQRService — FastAPI QR allocation and scan landing service

```powershell
Set-Location C:\PlaceWell\PlaceWellQRService
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
# Edit .env before starting.
uvicorn app.main:app --reload
```

Run tests:

```powershell
Set-Location C:\PlaceWell\PlaceWellQRService
.\.venv\Scripts\Activate.ps1
python -m pytest tests/
```

### PlaceWellPdfGenerator — label PDF/PNG generator

The local `.venv` was created with Python 3.13.1. Recreate it on a fresh machine:

```powershell
Set-Location C:\PlaceWell\PlaceWellPdfGenerator
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m placewell_generator.generator
```

For individual PNG export from PDFs, see `PlaceWellPdfGenerator\LABEL_EXPORT_WIKI.md`; it may require installing `pymupdf` in the venv for `extract_labels_from_pdf.py` workflows.

### PlaceWellUI — FastAPI operator UI

`PlaceWellUI` is a separate git repo at `https://github.com/whosaner/PlaceWellUI.git` on branch `master`.

```powershell
Set-Location C:\PlaceWell\PlaceWellUI
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
# Edit .env before starting.
uvicorn app.main:app --host 127.0.0.1 --port 8080 --reload
```

## 4. Critical files not in git

These files are gitignored or intentionally not committed. Obtain or recreate them before local production-like runs, app builds, or deployment.

### PlaceWellQRService

| File | Where it goes | What it is / how to recreate |
|---|---|---|
| `.env` | `C:\PlaceWell\PlaceWellQRService\.env` | Copy from `.env.example` and fill secrets/config. `app\config.py` requires `PLACEWELL_ALLOCATE_SECRET`, `PLACEWELL_LOOKUP_SECRET`, `PLACEWELL_HMAC_SECRET`, and `GOOGLE_APPLICATION_CREDENTIALS`. `.env.example` also lists `PLACEWELL_QR_BASE_URL` and `PLACEWELL_DEEP_LINK_SCHEME`; `app\config.py` also supports `PLACEWELL_ORDER_DEEP_LINK_SCHEME` defaulting to `placewell://order`. |
| `serviceAccountKey.json` | `C:\PlaceWell\PlaceWellQRService\serviceAccountKey.json` or another path referenced by `GOOGLE_APPLICATION_CREDENTIALS` | Firebase service account key. Download from Firebase Console: Project Settings -> Service Accounts -> Generate new private key. Never commit it. |

### PlaceWellApp

| File / secret | Where it goes | What it is / how to recreate |
|---|---|---|
| `GoogleService-Info.plist` | `C:\PlaceWell\PlaceWellApp\GoogleService-Info.plist` | Firebase iOS config file; download from Firebase Console. Gitignored. |
| `google-services.json` | `C:\PlaceWell\PlaceWellApp\google-services.json` | Firebase Android config file; download from Firebase Console. Gitignored. |
| `HMAC_SECRET`, `LOOKUP_SECRET` | EAS secrets, not local files | `app.config.js` reads `process.env.HMAC_SECRET` and `process.env.LOOKUP_SECRET` at EAS build time and fails production builds if either is missing. Use `eas secret:list` to inspect and `eas secret:create --name HMAC_SECRET --value "..."` / `eas secret:create --name LOOKUP_SECRET --value "..."` to create. |
| `credentials.json` | `C:\PlaceWell\PlaceWellApp\credentials.json` | EAS credentials/keystore export. Gitignored. |
| `placewell-prod-*.json` | `C:\PlaceWell\PlaceWellApp\placewell-prod-*.json` | Google Play service account JSON for submission. Gitignored. |
| `.env.local` | `C:\PlaceWell\PlaceWellApp\.env.local` | Optional local dev override for app config secrets. Gitignored. |
| `PRE_BUILD_COMMANDS.txt` | In repo | This tracked reference file contains actual secret values and build/deploy reminders. Treat it as sensitive operational reference. |

### PlaceWellUI

| File | Where it goes | What it is / how to recreate |
|---|---|---|
| `.env` | `C:\PlaceWell\PlaceWellUI\.env` | Copy from `.env.example`. Fill `USERNAME_PREFIX`, `QR_SERVICE_URL`, `QR_ALLOCATE_SECRET`, `PDF_GENERATOR_PATH`, and `PDF_OUTPUT_DIR`. UI password is handled by Apache Basic Auth in deployment, not this file. |

### PlaceWellPdfGenerator

No required secret file is listed in the current README. The venv (`.venv`) and generated PDFs/PNGs are gitignored and should be recreated locally.

## 5. Build and deploy quick reference

### App build and submit

Run from `C:\PlaceWell\PlaceWellApp` after installing dependencies and confirming EAS secrets:

```powershell
eas secret:list
eas build --platform all --profile production
eas submit --platform all --profile production
```

Note: Android automated submit currently has a Play Console permission issue; the fallback is manual AAB upload in Google Play Console.

### Server deploy

Run from `C:\PlaceWell`:

```powershell
C:\PlaceWell\deploy.ps1
```

`deploy.ps1` packages `PlaceWellUI`, `PlaceWellPdfGenerator`, and `PlaceWellQRService`, uploads archives to `root@45.56.71.137` with `scp`, extracts under `/opt/placewell-ui` and `/opt/placewell-service`, and restarts `placewell-ui` plus `placewell.service`.

First-time Linode setup still needs Python installs, service account files, `.env` files, systemd services, Apache, SSL, and firewall/DNS configuration. See:

- `Docs\deployment\Linode_Deployment.md`
- `Docs\deployment\UI_Deployment.md`
- `Docs\deployment\Server_Reference.md`
