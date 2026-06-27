from __future__ import annotations

from difflib import SequenceMatcher

from .schemas import MatchCandidate, MedicineMatch, ProductMasterItem, StructuredMedicine

try:
    from rapidfuzz import fuzz  # type: ignore
except Exception:  # pragma: no cover - fallback if rapidfuzz not installed
    fuzz = None


def _normalize(value: str | None) -> str:
    return " ".join((value or "").lower().replace("-", " ").split())


def _ratio(left: str, right: str) -> float:
    if not left or not right:
        return 0.0

    if fuzz is not None:
        ratio_score = fuzz.ratio(left, right)
        partial_score = fuzz.partial_ratio(left, right)
        token_score = fuzz.token_sort_ratio(left, right)
        return round((ratio_score * 0.4 + partial_score * 0.25 + token_score * 0.35) / 100, 3)

    return round(SequenceMatcher(None, left, right).ratio(), 3)


def match_medicines(
    medicines: list[StructuredMedicine],
    products: list[ProductMasterItem],
) -> list[MedicineMatch]:
    results: list[MedicineMatch] = []

    for medicine in medicines:
        search_name = _normalize(medicine.name)
        scored: list[MatchCandidate] = []

        for product in products:
            variants = [
                _normalize(product.product_name),
                _normalize(product.brand),
                _normalize(product.product_code),
                _normalize(f"{product.product_name} {product.brand or ''}"),
            ]
            best_score = max((_ratio(search_name, variant) for variant in variants), default=0.0)
            if best_score < 0.25:
                continue
            scored.append(
                MatchCandidate(
                    product_id=product.product_id,
                    product_name=product.product_name,
                    brand=product.brand,
                    confidence=round(best_score * 100, 1),
                )
            )

        scored.sort(key=lambda item: item.confidence, reverse=True)
        top_candidates = scored[:3]
        best = top_candidates[0] if top_candidates else None

        if best is None:
            status = "UNMATCHED"
            confidence = 0.0
            matched_name = None
        elif best.confidence >= 82:
            status = "MATCHED"
            confidence = best.confidence
            matched_name = best.product_name
        elif best.confidence >= 62:
            status = "REVIEW"
            confidence = best.confidence
            matched_name = best.product_name
        else:
            status = "UNMATCHED"
            confidence = best.confidence
            matched_name = best.product_name

        results.append(
            MedicineMatch(
                raw_name=medicine.name,
                matched_name=matched_name,
                confidence=confidence,
                status=status,
                dosage=medicine.dosage,
                duration=medicine.duration,
                frequency=medicine.frequency,
                candidates=top_candidates,
            )
        )

    return results
