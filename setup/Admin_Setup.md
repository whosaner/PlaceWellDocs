# PlaceWell Admin Setup

This quickstart covers the local FastAPI guidance tool used to map shared
configuration changes across the PlaceWell ecosystem.

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
├── PlaceWellUI
├── PlaceWellApp
├── PlaceWellQRService
├── PlaceWell-SpiceJarRenderer
├── PlaceWell-StockImageMasters
└── Docs
```

## Current Phase 1 prototype

The first implemented action is **Add Spice**. Its three-column screen:

1. Collects catalog, texture, and renderer inputs.
2. Generates the exact ordered file-change map.
3. Reports readiness, expected outputs, unchanged systems, and validation
   commands.

Phase 1 is read-only. It does not edit repositories, accept texture bytes, run
Git commands, or deploy services. The screen exists so the workflow can be
reviewed before deciding which steps are safe to automate in Phase 2.

## Related central docs
- Architecture: `C:\PlaceWell\Docs\architecture\System_Overview.md`
- Category guide: `C:\PlaceWell\Docs\setup\Adding_A_Category.md`
- Roadmap: `C:\PlaceWell\Docs\roadmap\ROADMAP.md`
