from __future__ import annotations

import os
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
    "g",
    "ml",
)

_NON_MEDICINE_PREFIXES = (
    "patient",
    "doctor",
    "date",
    "age",
    "gender",
    "address",
    "diagnosis",
    "rx",
    "advice",
    "name",
    "phone",
    "mobile",
    "contact",
    "sig",
    "refill",
    "label",
    "generic if available",
    "dea",
    "state license",
    "licence",
    "license",
    "figure",
    "m. ft.",
)

_NON_MEDICINE_KEYWORDS = (
    " street",
    " road",
    " avenue",
    " lane",
    " phone",
    " mobile",
    " contact",
    "hospital",
    "clinic",
    "yesno",
    "compounding",
    "example of a prescription",
    "use as directed",
    "discard after",
    "state license",
    "dea no",
)

_FREQUENCY_PATTERN = re.compile(
    r"\b(?:\d-\d-\d(?:-\d)?|od|bd|tds|qid|hs|sos|stat|weekly|daily|once daily|twice daily|thrice daily|q\d{1,2}h)\b",
    re.IGNORECASE,
)
_DURATION_PATTERN = re.compile(
    r"\b(?:x\s*)?\d+\s*(?:d|day|days|wk|wks|week|weeks|month|months)\b",
    re.IGNORECASE,
)
_TABLE_FREQUENCY_PATTERN = re.compile(
    r"\b\d+\s*(?:morning|night|afternoon|evening)\b",
    re.IGNORECASE,
)
_DOSAGE_PATTERN = re.compile(
    r"\b(?:\d+(?:\.\d+)?)\s*(?:mg|mcg|g|kg|tablet|tab|capsule|cap|softgel|ml|drop|drops|puff|sachet|unit)s?\b",
    re.IGNORECASE,
)
_DATE_PATTERN = re.compile(
    r"\b(?:\d{2}[-/]\d{2}[-/]\d{4}|\d{4}[-/]\d{2}[-/]\d{2})\b"
)
_PURE_MEASUREMENT_PATTERN = re.compile(
    r"^\d+(?:\.\d+)?\s*(?:mg|mcg|g|kg|ml|l|tablet|tab|capsule|cap|softgel|drop|drops|puff|sachet|unit)s?$",
    re.IGNORECASE,
)
_DOCTOR_CREDENTIAL_PATTERN = re.compile(
    r",?\s*(?:m\.?\s*d\.?|d\.?\s*o\.?|mbbs|bds|mld)\.?$",
    re.IGNORECASE,
)
_NUMBERED_MEDICINE_ROW_PATTERN = re.compile(r"^\s*\d+[\)\.\-]\s*")
_TABLE_DURATION_AT_END_PATTERN = re.compile(
    r"(?P<duration>\d+\s*(?:day|days|week|weeks|month|months)\b.*)$",
    re.IGNORECASE,
)
_MEDICINE_SECTION_END_PREFIXES = (
    "advice",
    "follow up",
    "follow-up",
    "investigation",
    "test",
    "instructions",
)
_FREEFORM_MEDICINE_FORMS = (
    "tab",
    "tablet",
    "cap",
    "capsule",
    "syp",
    "syr",
    "syrup",
    "inj",
    "injection",
    "drops",
    "drop",
    "ointment",
    "cream",
    "gel",
    "respule",
)
_FREEFORM_MEDICINE_NAME_PATTERN = re.compile(
    r"\b(?:tab(?:let)?|cap(?:sule)?|syp|syr(?:up)?|inj(?:ection)?|drop(?:s)?)\b",
    re.IGNORECASE,
)
_FREEFORM_SECTION_START_PREFIXES = (
    "rx",
    "advice",
    "medicines",
    "medicine",
)
_FREEFORM_SECTION_END_PREFIXES = (
    "review",
    "follow up",
    "follow-up",
    "signature",
)


def _get_ocr_engine() -> PaddleOCR:
    global _OCR_ENGINE
    if PaddleOCR is None:
        raise HTTPException(
            status_code=503,
            detail="PaddleOCR is not installed. Run pip install -r requirements.txt.",
        )
    if _OCR_ENGINE is None:
        os.environ.setdefault("FLAGS_enable_pir_api", "0")
        # PaddleOCR 3.x removed some 2.x constructor flags like `show_log`,
        # so keep the bootstrap args minimal and version-tolerant.
        _OCR_ENGINE = PaddleOCR(lang="en", enable_mkldnn=False)
    return _OCR_ENGINE


def _normalize_text(text: str) -> str:
    normalized_lines: list[str] = []
    for raw_line in text.splitlines():
        line = re.sub(r"\s+", " ", raw_line).strip()
        if not line:
            continue
        if normalized_lines and normalized_lines[-1].endswith("-"):
            normalized_lines[-1] = f"{normalized_lines[-1][:-1]}{line}"
            continue
        normalized_lines.append(line)
    return "\n".join(normalized_lines)


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


def _ensure_bgr_image(image):
    if cv2 is None:
        return image
    if len(image.shape) == 2:
        return cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
    if len(image.shape) == 3 and image.shape[2] == 4:
        return cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
    return image


def _build_ocr_variants(image) -> list[tuple[str, "np.ndarray"]]:
    if cv2 is None:
        return [("raw", image)]

    base = _ensure_bgr_image(image)
    gray = cv2.cvtColor(base, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (3, 3), 0)
    threshold = cv2.adaptiveThreshold(
        blurred,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        31,
        11,
    )
    upscaled = cv2.resize(
        threshold,
        None,
        fx=1.5,
        fy=1.5,
        interpolation=cv2.INTER_CUBIC,
    )

    return [
        ("raw", base),
        ("threshold", _ensure_bgr_image(threshold)),
        ("upscaled-threshold", _ensure_bgr_image(upscaled)),
    ]


def _extract_text_lines_from_ocr_result(result) -> str:
    text_lines: list[str] = []
    for block in result or []:
        if isinstance(block, dict):
            rec_texts = block.get("rec_texts") or []
            for candidate in rec_texts:
                normalized = re.sub(r"\s+", " ", str(candidate)).strip()
                if normalized:
                    text_lines.append(normalized)
            continue

        for line in block or []:
            candidate = line[1][0] if len(line) > 1 and line[1] else ""
            candidate = re.sub(r"\s+", " ", candidate).strip()
            if candidate:
                text_lines.append(candidate)
    return _normalize_text("\n".join(text_lines))


def _score_ocr_text(text: str) -> tuple[float, int, int, int]:
    normalized = _normalize_text(text)
    if not normalized:
        return (-1.0, 0, 0, 0)

    parsed = parse_prescription_text(normalized)
    lines = [line.lower() for line in normalized.splitlines() if line.strip()]
    medicine_count = len(parsed.medicines)
    strong_medicine_hits = sum(
        1
        for medicine in parsed.medicines
        if medicine.name and medicine.name != "Medicine"
    )
    penalty_hits = sum(
        1
        for line in lines
        if any(keyword in line for keyword in _NON_MEDICINE_KEYWORDS)
    )
    section_bonus = sum(
        1
        for line in lines
        if "medicine name" in line or line.startswith("rx") or line.startswith("advice")
    )

    score = (
        medicine_count * 10
        + strong_medicine_hits * 4
        + section_bonus * 3
        - penalty_hits * 2
        + min(len(normalized), 400) / 400
    )
    return (score, medicine_count, strong_medicine_hits, -penalty_hits)


def _ocr_image_array(image) -> str:
    engine = _get_ocr_engine()
    best_text = ""
    best_score = (-1.0, 0, 0, 0)

    for variant_name, variant in _build_ocr_variants(image):
        result = engine.predict(variant)
        candidate_text = _extract_text_lines_from_ocr_result(result)
        candidate_score = _score_ocr_text(candidate_text)
        if candidate_score > best_score:
            best_score = candidate_score
            best_text = candidate_text
        # Most real uploads should use the first raw OCR pass; extra variants are
        # only worth the latency when the raw result looks structurally weak.
        if (
            variant_name == "raw"
            and candidate_score[1] >= 3
            and candidate_score[2] >= 3
            and candidate_score[0] >= 40
        ):
            return candidate_text

    return best_text


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
    if any(lower.startswith(prefix) for prefix in _NON_MEDICINE_PREFIXES):
        return False
    if _DOCTOR_CREDENTIAL_PATTERN.search(line.strip()):
        return False
    if any(keyword in lower for keyword in _NON_MEDICINE_KEYWORDS):
        return False
    if _PURE_MEASUREMENT_PATTERN.fullmatch(line):
        return False
    if "|" in line:
        return True
    if _FREQUENCY_PATTERN.search(line) or _DURATION_PATTERN.search(line):
        return True
    if any(keyword in lower for keyword in _MEDICINE_KEYWORDS):
        return True
    return False


def _looks_like_medicine_name(line: str) -> bool:
    lower = line.lower().strip()
    if not lower or _looks_like_medicine_line(line):
        return False
    if any(lower.startswith(prefix) for prefix in _NON_MEDICINE_PREFIXES):
        return False
    if _DOCTOR_CREDENTIAL_PATTERN.search(line.strip()):
        return False
    if any(keyword in lower for keyword in _NON_MEDICINE_KEYWORDS):
        return False
    if re.search(r"\b\d{3,}\b", line):
        return False
    words = re.findall(r"[A-Za-z]+", line)
    if not words or len(words) > 6:
        return False
    return len(" ".join(words)) >= 4


def _clean_name(name: str) -> str:
    cleaned = re.sub(r"^[\-\.\)\(]+", "", name).strip(" -:,.")
    cleaned = re.sub(r"\s{2,}", " ", cleaned)
    return cleaned


def _clean_duration(duration: str) -> str:
    cleaned = duration.strip(" ,.")
    return re.sub(r"^x\s*", "", cleaned, flags=re.IGNORECASE)


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


def _extract_medicine_section_lines(lines: list[str]) -> list[str]:
    start_index = -1
    for index, line in enumerate(lines):
        lower = line.lower()
        if "medicine name" in lower and "dosage" in lower:
            start_index = index + 1
            break

    if start_index == -1:
        return []

    section_lines: list[str] = []
    for line in lines[start_index:]:
        lower = line.lower().strip()
        if any(lower.startswith(prefix) for prefix in _MEDICINE_SECTION_END_PREFIXES):
            break
        if lower in {"r", "rx"}:
            continue
        if line.strip():
            section_lines.append(line.strip())
    return section_lines


def _clean_table_medicine_name(name: str) -> str:
    cleaned = _NUMBERED_MEDICINE_ROW_PATTERN.sub("", name).strip()
    cleaned = re.sub(r"\s{2,}", " ", cleaned)
    return _clean_name(cleaned)


def _parse_table_medicine_rows(lines: list[str]) -> list[StructuredMedicine]:
    medicines: list[StructuredMedicine] = []
    seen_names: set[str] = set()

    for line in lines:
        if not _NUMBERED_MEDICINE_ROW_PATTERN.match(line):
            continue

        duration_match = _TABLE_DURATION_AT_END_PATTERN.search(line)
        duration = (
            duration_match.group("duration").strip()
            if duration_match
            else "Not specified"
        )
        line_without_duration = (
            line[: duration_match.start()].strip() if duration_match else line.strip()
        )

        frequency_matches = list(_TABLE_FREQUENCY_PATTERN.finditer(line_without_duration))
        frequency = "As directed"
        name_part = line_without_duration
        if frequency_matches:
            frequency_start = frequency_matches[0].start()
            frequency = line_without_duration[frequency_start:].strip(" ,")
            name_part = line_without_duration[:frequency_start].strip()

        name = _clean_table_medicine_name(name_part)
        if not name:
            continue

        normalized_name = name.lower()
        if normalized_name in seen_names:
            continue
        seen_names.add(normalized_name)

        medicines.append(
            StructuredMedicine(
                name=name,
                confidence=90.0,
                dosage="As directed",
                duration=duration,
                frequency=frequency or "As directed",
            )
        )

    return medicines


def _looks_like_freeform_medicine_candidate(line: str) -> bool:
    lower = line.lower()
    if any(lower.startswith(prefix) for prefix in _NON_MEDICINE_PREFIXES):
        return False
    if any(keyword in lower for keyword in _NON_MEDICINE_KEYWORDS):
        return False
    if not any(form in lower for form in _FREEFORM_MEDICINE_FORMS):
        return False
    return bool(_DOSAGE_PATTERN.search(line) or _FREQUENCY_PATTERN.search(line))


def _extract_freeform_medicine_lines(lines: list[str]) -> list[str]:
    section_lines: list[str] = []
    in_section = False

    for line in lines:
        lower = line.lower().strip()
        if any(lower.startswith(prefix) for prefix in _FREEFORM_SECTION_START_PREFIXES):
            in_section = True
            if _looks_like_freeform_medicine_candidate(line):
                section_lines.append(line)
            continue
        if in_section and any(lower.startswith(prefix) for prefix in _FREEFORM_SECTION_END_PREFIXES):
            break
        if in_section and _looks_like_freeform_medicine_candidate(line):
            section_lines.append(line)

    if section_lines:
        return section_lines

    return [line for line in lines if _looks_like_freeform_medicine_candidate(line)]


def _parse_freeform_medicine_lines(lines: list[str]) -> list[StructuredMedicine]:
    medicines: list[StructuredMedicine] = []
    seen_names: set[str] = set()

    for line in lines:
        dosage_match = _DOSAGE_PATTERN.search(line)
        frequency_match = _FREQUENCY_PATTERN.search(line)
        duration_match = _DURATION_PATTERN.search(line)

        dosage = dosage_match.group(0) if dosage_match else "As directed"
        frequency = (
            frequency_match.group(0).upper()
            if frequency_match
            else "As directed"
        )
        duration = (
            _clean_duration(duration_match.group(0))
            if duration_match
            else "Not specified"
        )

        name = line
        for token in (
            dosage_match.group(0) if dosage_match else "",
            frequency_match.group(0) if frequency_match else "",
            duration_match.group(0) if duration_match else "",
        ):
            if token:
                name = re.sub(re.escape(token), " ", name, flags=re.IGNORECASE)

        name = re.sub(r"\b(?:after food|before food)\b", " ", name, flags=re.IGNORECASE)
        name = re.sub(r"\s{2,}", " ", name).strip(" ,.-")
        name = _clean_name(name)

        if not _FREEFORM_MEDICINE_NAME_PATTERN.search(name):
            continue

        normalized_name = name.lower()
        if normalized_name in seen_names:
            continue
        seen_names.add(normalized_name)

        medicines.append(
            StructuredMedicine(
                name=name,
                confidence=89.0,
                dosage=dosage,
                duration=duration,
                frequency=frequency,
            )
        )

    return medicines


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

    section_lines = _extract_medicine_section_lines(lines)
    if section_lines:
        medicines = _parse_table_medicine_rows(section_lines)
        return StructuredPrescription(
            patient=patient,
            doctor=doctor,
            date=date,
            medicines=medicines[:12],
        )

    freeform_lines = _extract_freeform_medicine_lines(lines)
    if freeform_lines:
        medicines = _parse_freeform_medicine_lines(freeform_lines)
        if medicines:
            return StructuredPrescription(
                patient=patient,
                doctor=doctor,
                date=date,
                medicines=medicines[:12],
            )

    medicines: list[StructuredMedicine] = []
    seen_names: set[str] = set()

    index = 0
    while index < len(lines):
        line = lines[index]
        if not _looks_like_medicine_line(line):
            if (
                index + 1 < len(lines)
                and _looks_like_medicine_name(line)
                and _PURE_MEASUREMENT_PATTERN.fullmatch(lines[index + 1])
            ):
                line = f"{line} {lines[index + 1]}"
                index += 1
            else:
                index += 1
                continue

        medicine = _parse_compact_medicine_line(line)
        normalized_name = medicine.name.lower()
        if normalized_name in seen_names:
            index += 1
            continue
        seen_names.add(normalized_name)
        medicines.append(medicine)
        index += 1

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
