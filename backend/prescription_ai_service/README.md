# SHIELD Prescription Intelligence Service

This service is the planned Python backend companion for SHIELD prescription OCR and medicine recognition.

## Intended stack

- `PaddleOCR` for primary OCR
- `TrOCR` as a handwriting-oriented fallback
- `RapidFuzz` for fuzzy medicine matching against the SHIELD product master
- `MedCAT` for medical entity recognition and post-processing
- `PyMuPDF` for PDF page extraction
- `OpenCV` for image preprocessing
- `FastAPI` as the backend API surface

## Current scope in this repo

This scaffold establishes the service contract and the medicine-matching workflow without changing the existing NestJS upload API.

Implemented now:

- `POST /analyze-text`
- Structured prescription parsing from OCR-like text
- Fuzzy medicine matching against a supplied product master
- Response payload shaped for SHIELD pharmacist review and cart-prefill flows

Planned next:

- File and PDF ingestion endpoint
- PaddleOCR execution for image/PDF input
- MedCAT enrichment for medicine, dosage, and medical terminology extraction
- Optional TrOCR fallback for difficult handwriting
- NestJS adapter so `backend/src/document/document.service.ts` can call this service instead of the current in-process mock parser

## Local run

```bash
cd backend/prescription_ai_service
python -m venv .venv
.venv\\Scripts\\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8010
```

## Example request

```json
{
  "extracted_text": "Patient: Rahul\nDoctor: Dr. Kumar\nDate: 24-06-2026\n- Paracitamol 650 | 1 Tablet | 1-0-1 | 5 Days\n- Augmentn 625 | 1 Tablet | BD | 5 Days",
  "products": [
    {
      "product_id": "1",
      "product_name": "Paracetamol 650",
      "brand": "Crocin",
      "product_code": "PCM650"
    },
    {
      "product_id": "2",
      "product_name": "Augmentin 625",
      "brand": "GSK",
      "product_code": "AUG625"
    }
  ]
}
```

## Example response shape

```json
{
  "patient": "Rahul",
  "doctor": "Dr. Kumar",
  "date": "24-06-2026",
  "medicines": [
    {
      "name": "Paracitamol 650",
      "confidence": 94,
      "dosage": "1 Tablet",
      "duration": "5 Days",
      "frequency": "1-0-1"
    }
  ],
  "medicine_matches": [
    {
      "raw_name": "Paracitamol 650",
      "matched_name": "Paracetamol 650",
      "confidence": 98,
      "status": "MATCHED",
      "dosage": "1 Tablet",
      "duration": "5 Days",
      "frequency": "1-0-1",
      "candidates": []
    }
  ],
  "overall_confidence": 96,
  "engine": "paddleocr+rapidfuzz+medcat-ready"
}
```
