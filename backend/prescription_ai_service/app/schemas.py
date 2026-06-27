from __future__ import annotations

from pydantic import BaseModel, Field


class ProductMasterItem(BaseModel):
    product_id: str = Field(..., description="SHIELD product identifier")
    product_name: str = Field(..., description="Canonical medicine or product name")
    brand: str | None = Field(default=None, description="Brand name if available")
    product_code: str | None = Field(default=None, description="Internal product code")


class AnalyzeTextRequest(BaseModel):
    extracted_text: str = Field(..., description="OCR text or manually supplied prescription text")
    products: list[ProductMasterItem] = Field(
        default_factory=list,
        description="Candidate medicine master used for fuzzy matching",
    )


class StructuredMedicine(BaseModel):
    name: str
    confidence: float
    dosage: str
    duration: str
    frequency: str


class MatchCandidate(BaseModel):
    product_id: str
    product_name: str
    brand: str | None = None
    confidence: float


class MedicineMatch(BaseModel):
    raw_name: str
    matched_name: str | None = None
    confidence: float
    status: str
    dosage: str
    duration: str
    frequency: str
    candidates: list[MatchCandidate] = Field(default_factory=list)


class StructuredPrescription(BaseModel):
    patient: str
    doctor: str
    date: str
    medicines: list[StructuredMedicine] = Field(default_factory=list)


class AnalyzeTextResponse(BaseModel):
    patient: str
    doctor: str
    date: str
    raw_text: str = ""
    medicines: list[StructuredMedicine] = Field(default_factory=list)
    medicine_matches: list[MedicineMatch] = Field(default_factory=list)
    overall_confidence: float
    engine: str
