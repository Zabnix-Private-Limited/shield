# Customer Documents API Matrix

Status: in progress — supported security foundation implemented.

| Capability | Current contract | Customer rule | Status |
| --- | --- | --- | --- |
| List | `GET /documents` | JWT customer identity overrides `customer_id` query input | Supported |
| Details | `GET /documents/:id` | Ownership is checked before lookup | Supported |
| Upload | `POST /documents/upload` multipart | Customer identity is resolved from the session; PDF/JPEG/PNG/WebP only; 15 MB multer limit | Supported |
| Viewer/download URL | `GET /documents/:id/download` | Ownership is checked before URL generation; R2 uses a server-issued five-minute signed URL | Supported for R2 |
| Local development download | No authenticated streaming endpoint | Raw local paths are never returned | Deferred — secure streaming contract required |
| Archive/delete | `DELETE /documents/:id` | Controller ownership check prevents cross-customer access; customer RBAC does not grant delete | Deferred — retention policy required |
| Search/filter | Client-side over customer-safe list metadata | No storage path, customer ID, staff notes, extraction, or audit data exposed | Supported |
| OCR/extraction/review/logs | Internal document-intelligence endpoints | Customers are explicitly denied access | Not supported in current customer contract |

Storage: `StorageService.persistPrivateObject` writes to R2 when configured, otherwise private local development storage. `storage_path`, raw object keys, extraction data, processing logs, customer relations, and uploader relations are excluded from customer projections.

Schema: authoritative `current_schema.md` `documents` table; Prisma `Document`. No schema change is required for this slice.
