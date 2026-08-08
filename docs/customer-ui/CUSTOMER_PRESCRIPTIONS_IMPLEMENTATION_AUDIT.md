# Customer Prescriptions Implementation Audit

Classification: `COMPLETE — SUPPORTED FUNCTIONAL SCOPE`.

- Prescription list is the customer-owned `PRESCRIPTION` document subset with truthful returned status, upload, and R2 signed viewer/download support.
- Services Pharmacy context is route-preserved. A preferred Pharmacy is used only as a server-validated active Pharmacy fallback.
- Customer must explicitly review and confirm before `POST /pharmacy/prescriptions`; duplicate active requests are rejected and the response is customer-safe.
- The committed additive migration is not applied automatically. OCR/medicine extraction, pharmacist clinical approval, fulfilment, payment, and delivery are not represented in the customer UI.
