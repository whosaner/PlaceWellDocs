# PlaceWell QR Service Setup

This quickstart covers local development for the FastAPI service that allocates PlaceWell QR codes, resolves scan redirects, and looks up label metadata.

## Prerequisites
- Python 3.9+
- Firestore enabled in Firebase project `placewell-prod`
- A local `serviceAccountKey.json` for Firebase Admin SDK access

## Install
```bash
cd C:\PlaceWell\PlaceWellQRService
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

## Configure `.env`
Fill in these values:
- `PLACEWELL_ALLOCATE_SECRET`
- `PLACEWELL_HMAC_SECRET`
- `GOOGLE_APPLICATION_CREDENTIALS=C:\PlaceWell\PlaceWellQRService\serviceAccountKey.json`
- `PLACEWELL_QR_BASE_URL=https://placewell.app/s`
- `PLACEWELL_DEEP_LINK_SCHEME=placewell://scan`

`PLACEWELL_HMAC_SECRET` must match the mobile app setting exactly.

## Run locally
```bash
.venv\Scripts\uvicorn app.main:app --reload
```

The service runs at `http://localhost:8000` and FastAPI docs are available at `http://localhost:8000/docs`.

## Related central docs
- Architecture: `C:\PlaceWell\Docs\architecture\System_Overview.md`
- Deployment: `C:\PlaceWell\Docs\deployment\Linode_Deployment.md`
- Server ops: `C:\PlaceWell\Docs\deployment\Server_Reference.md`
