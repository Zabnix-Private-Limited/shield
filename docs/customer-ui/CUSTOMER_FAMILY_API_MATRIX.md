# Customer Family API Matrix

| Capability | UI route | API | DB / Prisma | Ownership / validation | Classification |
|---|---|---|---|---|---|
| Dependent list/details | `/portal/customer/account` | `GET /customer/dependents`, `GET /customer/dependents/:id` | `customer_dependents` / `CustomerDependent` | Customer ID derives from JWT; every lookup includes `customer_id` and `deleted_at IS NULL` | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Add/edit dependent | same | `POST/PATCH /customer/dependents` | same | First name and relationship required; DOB must parse; customer ID from session | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Remove/archive | same | `DELETE /customer/dependents/:id` | `deleted_at` | Soft archive constrained to owning customer | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Eligibility/membership/booking | none | none | No columns/contracts | No inferred age, coverage, membership, or appointment-patient semantics | DEFERRED — BACKEND CONTRACT REQUIRED |

## Ownership audit

The account controller never accepts a frontend customer ID as the owner. Service queries use both resource ID and authenticated customer ID, so a foreign dependent resolves as not found rather than being read, edited, or archived.
