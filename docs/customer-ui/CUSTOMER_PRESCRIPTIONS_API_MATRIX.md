# Customer Prescriptions API Matrix

Status: in progress — prescriptions are private `documents` with `document_type=PRESCRIPTION`; `prescriptions` stores issued prescription linkage and date where available.

| Capability | Current contract | Customer rule | Status |
| --- | --- | --- | --- |
| List/details | Customer Documents APIs filtered to `PRESCRIPTION` | Session-derived ownership and customer-safe projection | Supported |
| Upload | Customer document upload with forced `PRESCRIPTION` type | Session-derived customer; file allowlist and size limit apply | Supported |
| Status | `documents.status` | Render the returned status only; upload resolves to `UPLOADED` | Supported |
| Viewer/download | Customer document download endpoint | R2 signed URL only after ownership check | Supported for R2 |
| Preferred pharmacy | `customer_preferences.preferred_provider_id` exists | Must be validated as active `PHARMACY` before display/use | Partial — UI integration pending |
| Pharmacy search | Customer provider discovery endpoint | Reuse provider discovery `PHARMACY` filter | Supported contract |
| Prescription-to-pharmacy request | No model, route, or status found in `current_schema.md`/Prisma | Do not submit or fabricate acknowledgement | Deferred — backend/product contract required |
| OCR/medicine extraction | Document intelligence endpoints exist | Not exposed to customers in this slice | Not supported in current customer contract |
| Fulfilment/payment/delivery | No customer contract | No UI action | Not supported in current contract |
