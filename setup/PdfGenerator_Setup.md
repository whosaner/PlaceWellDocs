# PlaceWell PDF Generator Setup

This quickstart covers local setup for the Python library that renders PlaceWell label sheets and manifest PDFs.

## Prerequisites
- Python 3.10+

## Install
```bash
cd C:\PlaceWell\PlaceWellPdfGenerator
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Run the standalone generator test
```bash
python -m placewell_generator.generator
```

This reads `test_order_v2.json` and writes output PDFs to `C:\PlaceWell\PlaceWellPdfGenerator\output`.

## Integration note
PlaceWellUI imports the generator directly:

```python
from placewell_generator.generator import generate_pdfs
```

Make sure the `C:\PlaceWell\PlaceWellPdfGenerator` path is available to the UI runtime.

## Related central docs
- Architecture: `C:\PlaceWell\Docs\architecture\System_Overview.md`
- Design system: `C:\PlaceWell\Docs\design\Design_System.md`
