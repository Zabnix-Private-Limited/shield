from __future__ import annotations

import json

from fastapi import FastAPI, File, Form, UploadFile
from pydantic import TypeAdapter

from .pipeline import analyze_file, analyze_text
from .schemas import AnalyzeTextRequest, AnalyzeTextResponse, ProductMasterItem

app = FastAPI(
    title="SHIELD Prescription Intelligence Service",
    version="0.1.0",
    description=(
        "Backend OCR and medicine-recognition companion service for SHIELD. "
        "Designed for PaddleOCR + MedCAT + RapidFuzz based prescription analysis."
    ),
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/analyze-text", response_model=AnalyzeTextResponse)
def analyze_prescription_text(payload: AnalyzeTextRequest) -> AnalyzeTextResponse:
    return analyze_text(payload)


@app.post("/analyze-file", response_model=AnalyzeTextResponse)
async def analyze_prescription_file(
    file: UploadFile = File(...),
    products: str = Form("[]"),
) -> AnalyzeTextResponse:
    product_items = TypeAdapter(list[ProductMasterItem]).validate_python(
        json.loads(products or "[]")
    )
    file_bytes = await file.read()
    return analyze_file(
        file_bytes=file_bytes,
        file_name=file.filename or "prescription.pdf",
        mime_type=file.content_type or "application/octet-stream",
        products=product_items,
    )
