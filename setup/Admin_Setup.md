# PlaceWell Admin Setup

This quickstart covers local setup for the FastAPI-based admin tool that edits shared configuration across the PlaceWell ecosystem.

## Prerequisites
- Python 3.10+
- All PlaceWell projects available as sibling folders under `C:\PlaceWell`

## Install and run
```bash
cd C:\PlaceWell\PlaceWellAdmin
pip install -r requirements.txt
run.bat
```

The tool opens at `http://127.0.0.1:8500`.

## Folder assumption
The admin tool expects this sibling layout:

```text
C:\PlaceWell\
├── PlaceWellAdmin
├── PlaceWellPdfGenerator
├── PlaceWellUI
├── PlaceWellApp
└── PlaceWellQRService
```

## What it manages
- Templates across PlaceWellPdfGenerator and PlaceWellUI
- Styles across PlaceWellPdfGenerator and PlaceWellUI
- Categories across PlaceWellUI and PlaceWellApp

## Related central docs
- Architecture: `C:\PlaceWell\Docs\architecture\System_Overview.md`
- Category guide: `C:\PlaceWell\Docs\setup\Adding_A_Category.md`
- Roadmap: `C:\PlaceWell\Docs\roadmap\ROADMAP.md`
