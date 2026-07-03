# PlaceWell UI Setup

This quickstart covers local setup for the operator-facing FastAPI order form.

## Prerequisites
- Python 3.10+
- Local access to PlaceWellQRService
- Local access to the PlaceWellPdfGenerator folder

## Install
```bash
cd C:\PlaceWell\PlaceWellUI
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

## Configure `.env`
Set the QR service URL, allocation bearer token, PDF generator path, and output folder.

Typical values:
```text
QR_SERVICE_URL=http://127.0.0.1:8000
QR_ALLOCATE_SECRET=<same value used by PlaceWellQRService>
PDF_GENERATOR_PATH=C:\PlaceWell\PlaceWellPdfGenerator
PDF_OUTPUT_DIR=C:\PlaceWell\PlaceWellUI\output
```

## Run locally
```bash
uvicorn app.main:app --host 127.0.0.1 --port 8080 --reload
```

Open `http://localhost:8080` in your browser.

## Related central docs
- Architecture: `C:\PlaceWell\Docs\architecture\System_Overview.md`
- Deployment: `C:\PlaceWell\Docs\deployment\UI_Deployment.md`
- Category guide: `C:\PlaceWell\Docs\setup\Adding_A_Category.md`
