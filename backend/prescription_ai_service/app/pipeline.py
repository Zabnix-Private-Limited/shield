from __future__ import annotations

import re
from statistics import mean

from fastapi import HTTPException

from .matcher import match_medicines
from .schemas import (
    AnalyzeTextRequest,
    AnalyzeTextResponse,
    ProductMasterItem,
    StructuredMedicine,
    StructuredPrescription,
)

try:  # pragma: no cover - optional runtime dependency
    import fitz  # type: ignore
except Exception:  # pragma: no cover
    fitz = None

try:  # pragma: no cover - optional runtime dependency
    import cv2  # type: ignore
    import numpy as np  # type: ignore
except Exception:  # pragma: no cover
    cv2 = None
    np = None

try:  # pragma: no cover - optional runtime dependency
    from paddleocr import PaddleOCR  # type: ignore
except Exception:  # pragma: no cover
    PaddleOCR = None

_OCR_ENGINE: PaddleOCR | None = None

_MEDICINE_KEYWORDS = (
    "tab",
    "tablet",
    "cap",
    "capsule",
    "syrup",
    "suspension",
    "drops",
    "drop",
    "injection",
    "inj",
    "gel",
    "cream",
    "ointment",
    "softgel",
    "powder",
    "spray",
    "mg",
    "mcg",
    "ml",
)

_FREQUENCY_PATTERN = re.compile(
    r"\b(?:\d-\d-\d(?:-\d)?|od|bd|tds|qid|hs|sos|stat|weekly|daily|once daily|twice daily|thrice daily)\b",
    re.IGNORECASE,
)
_DURATION_PATTERN = re.compile(
    r"\b\d+\s*(?:day|days|week|weeks|month|months)\b",
    re.IGNORECASE,
)
_DOSAGE_PATTERN = re.compile(
    r"\b(?:\d+(?:\.\d+)?)\s*(?:tablet|tab|capsule|cap|softgel|ml|drop|drops|puff|sachet|unit)s?\b",
    re.IGNORECASE,
)
_DATE_PATTERN = re.compile(
    r"\b(?:\d{2}[-/]\d{2}[-/]\d{4}|\d{4}[-/]\d{2}[-/]\d{2})\b"
)


def _get_ocr_engine() -> PaddleOCR:
    global _OCR_ENGINE
    if PaddleOCR is None:
        raise HTTPException(
            status_code=503,
            detail="PaddleOCR is not installed. Run pip install -r requirements.txt.",
        )
    if _OCR_ENGINE is None:
        _OCR_ENGINE = PaddleOCR(use_angle_cls=True, lang="en", show_log=False)
    return _OCR_ENGINE


def _normalize_text(text: str) -> str:
    lines = [re.sub(r"\s+", " ", line).strip() for line in text.splitlines()]
    return "\n".join(line for line in lines if line)


def _read_pdf_text(file_bytes: bytes) -> tuple[str, bool]:
    if fitz is None:
        return "", False

    document = fitz.open(stream=file_bytes, filetype="pdf")
    try:
        lines: list[str] = []
        for page in document:
            page_text = page.get_text("text") or ""
            if page_text.strip():
                lines.append(page_text)
        combined = _normalize_text("\n".join(lines))
        return combined, bool(combined)
    finally:
        document.close()


def _pixmap_to_image_array(pixmap) -> "np.ndarray":
    if np is None:
        raise HTTPException(status_code=503, detail="NumPy is required for OCR image processing.")

    channel_count = 4 if pixmap.alpha else 3
    image = np.frombuffer(pixmap.samples, dtype=np.uint8).reshape(
        pixmap.height,
        pixmap.width,
        channel_count,
    )
    if channel_count == 4 and cv2 is not None:
        return cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
    return image


def _ocr_image_array(image) -> str:
    engine = _get_ocr_engine()
    result = engine.ocr(image, cls=True)
    text_lines: list[str] = []
    for block in result or []:
        for line in block or []:
            candidate = line[1][0] if len(line) > 1 and line[1] else ""
            candidate = re.sub(r"\s+", " ", candidate).strip()
            if candidate:
                text_lines.append(candidate)
    return _normalize_text("\n".join(text_lines))


def _ocr_pdf(file_bytes: bytes) -> str:
    if fitz is None:
        raise HTTPException(
            status_code=503,
            detail="PyMuPDF is required to OCR scanned PDFs. Run pip install -r requirements.txt.",
        )

    document = fitz.open(stream=file_bytes, filetype="pdf")
    try:
        page_texts: list[str] = []
        for page in document:
            pixmap = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
            page_texts.append(_ocr_image_array(_pixmap_to_image_array(pixmap)))
        return _normalize_text("\n".join(page_texts))
    finally:
        document.close()


def _ocr_image(file_bytes: bytes) -> str:
    if cv2 is None or np is None:
        raise HTTPException(
            status_code=503,
            detail="OpenCV and NumPy are required for image OCR. Run pip install -r requirements.txt.",
        )

    image = cv2.imdecode(np.frombuffer(file_bytes, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise HTTPException(status_code=400, detail="Unable to decode the uploaded image.")
    return _ocr_image_array(image)


def extract_text_from_file(file_bytes: bytes, file_name: str, mime_type: str) -> tuple[str, str]:
    lower_name = file_name.lower()
    lower_type = (mime_type or "").lower()

    if lower_name.endswith(".pdf") or "pdf" in lower_type:
        direct_text, has_text = _read_pdf_text(file_bytes)
        if has_text and len(direct_text.replace("\n", " ").strip()) >= 24:
            return direct_text, "pymupdf-text"
        return _ocr_pdf(file_bytes), "pymupdf+paddleocr"

    if any(lower_name.endswith(ext) for ext in (".png", ".jpg", ".jpeg")) or lower_type.startswith("image/"):
        return _ocr_image(file_bytes), "paddleocr-image"

    try:
        return _normalize_text(file_bytes.decode("utf-8")), "plain-text"
    except UnicodeDecodeError as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type for prescription analysis: {file_name}",
        ) from exc


def _read_field(lines: list[str], prefixes: tuple[str, ...], fallback: str) -> str:
    for line in lines:
        lower = line.lower()
        for prefix in prefixes:
            if lower.startswith(prefix.lower()):
                return line.split(":", 1)[1].strip() if ":" in line else fallback
    return fallback


def _looks_like_medicine_line(line: str) -> bool:
    lower = line.lower()
    if len(line.strip()) < 3:
        return False
    if any(lower.startswith(prefix) for prefix in ("patient", "doctor", "date", "age", "gender", "address", "diagnosis", "rx", "advice")):
        return False
    if "|" in line:
        return True
    if _FREQUENCY_PATTERN.search(line) or _DURATION_PATTERN.search(line):
        return True
    if any(keyword in lower for keyword in _MEDICINE_KEYWORDS):
        return True
    return bool(re.search(r"\b\d{2,4}\b", line))


def _clean_name(name: str) -> str:
    cleaned = re.sub(r"^[\-\.\)\(]+", "", name).strip(" -:,.")
    cleaned = re.sub(r"\s{2,}", " ", cleaned)
    return cleaned


def _parse_compact_medicine_line(line: str) -> StructuredMedicine:
    if "|" in line:
        parts = [part.strip(" -") for part in line.split("|")]
        name = parts[0] if parts else "Medicine"
        dosage = parts[1] if len(parts) > 1 else "As directed"
        frequency = parts[2] if len(parts) > 2 else "As directed"
        duration = parts[3] if len(parts) > 3 else "Not specified"
        return StructuredMedicine(
            name=_clean_name(name) or "Medicine",
            confidence=94.0,
            dosage=dosage or "As directed",
            duration=duration or "Not specified",
            frequency=frequency or "As directed",
        )

    dosage_match = _DOSAGE_PATTERN.search(line)
    frequency_match = _FREQUENCY_PATTERN.search(line)
    duration_match = _DURATION_PATTERN.search(line)

    dosage = dosage_match.group(0) if dosage_match else "As directed"
    frequency = frequency_match.group(0).upper() if frequency_match else "As directed"
    duration = duration_match.group(0) if duration_match else "Not specified"

    name = line
    for token in (
        dosage_match.group(0) if dosage_match else "",
        frequency_match.group(0) if frequency_match else "",
        duration_match.group(0) if duration_match else "",
    ):
        if token:
            name = re.sub(re.escape(token), " ", name, flags=re.IGNORECASE)

    name = _clean_name(name)
    if not name:
        name = _clean_name(line.split("  ")[0]) or "Medicine"

    return StructuredMedicine(
        name=name,
        confidence=88.0,
        dosage=dosage,
        duration=duration,
        frequency=frequency,
    )


def parse_prescription_text(text: str) -> StructuredPrescription:
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    patient = _read_field(lines, ("Patient", "Pt", "Name"), "Customer")
    doctor = _read_field(lines, ("Doctor", "Dr"), "Doctor unavailable")
    date = _read_field(lines, ("Date",), "")
    if not date:
        for line in lines:
            date_match = _DATE_PATTERN.search(line)
            if date_match:
                date = date_match.group(0).replace("/", "-")
                break

    medicines: list[StructuredMedicine] = []
    seen_names: set[str] = set()

    for line in lines:
        if not _looks_like_medicine_line(line):
            continue

        medicine = _parse_compact_medicine_line(line)
        normalized_name = medicine.name.lower()
        if normalized_name in seen_names:
            continue
        seen_names.add(normalized_name)
        medicines.append(medicine)

    return StructuredPrescription(
        patient=patient,
        doctor=doctor,
        date=date,
        medicines=medicines[:12],
    )


def _build_response(
    structured: StructuredPrescription,
    matches,
    overall_confidence: float,
    raw_text: str,
    engine: str,
) -> AnalyzeTextResponse:
    return AnalyzeTextResponse(
        patient=structured.patient,
        doctor=structured.doctor,
        date=structured.date,
        raw_text=raw_text,
        medicines=structured.medicines,
        medicine_matches=matches,
        overall_confidence=overall_confidence,
        engine=engine,
    )


def analyze_text(request: AnalyzeTextRequest) -> AnalyzeTextResponse:
    raw_text = _normalize_text(request.extracted_text)
    structured = parse_prescription_text(raw_text)
    matches = match_medicines(structured.medicines, request.products)

    extracted_scores = [medicine.confidence for medicine in structured.medicines]
    match_scores = [match.confidence for match in matches]
    combined_scores = extracted_scores + match_scores
    overall_confidence = round(mean(combined_scores), 1) if combined_scores else 0.0

    return _build_response(
        structured=structured,
        matches=matches,
        overall_confidence=overall_confidence,
        raw_text=raw_text,
        engine="text+rapidfuzz",
    )


def analyze_file(
    *,
    file_bytes: bytes,
    file_name: str,
    mime_type: str,
    products: list[ProductMasterItem],
) -> AnalyzeTextResponse:
    raw_text, engine = extract_text_from_file(file_bytes, file_name, mime_type)
    request = AnalyzeTextRequest(extracted_text=raw_text, products=products)
    analyzed = analyze_text(request)
    return analyzed.model_copy(update={"engine": f"{engine}+rapidfuzz", "raw_text": raw_text})
