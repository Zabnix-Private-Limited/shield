# Customer Booking and Visits API matrix

Audited: 2026-08-08. `current_schema.md`, `backend/prisma/schema.prisma`, and the existing appointment controller/service are authoritative.

| Capability | Customer route | Endpoint / method | Current contract | Classification |
|---|---|---|---|---|
| Appointment list | `/portal/customer/appointments` | `GET /appointments` | Customer identity derives from authenticated principal; records include customer/provider internally | Supported; customer projection needs review before extracted UI |
| Appointment detail | planned `/portal/customer/visits/:id` | `GET /appointments/:id` | Existing ownership guard checks appointment customer ID | Supported endpoint; customer-safe DTO required |
| Create appointment | `/portal/customer/book-appointment` | `POST /appointments` | `provider_id`, `appointment_type`, `appointment_date`, optional `remarks`; server sets customer ID | Supported request workflow; provider validation/concurrency are incomplete |
| Cancel | Visits action | `POST /appointments/:id/cancel` | Existing ownership guard, status update, notification/event | Supported; no cancellation reason/eligibility contract |
| Reschedule | Visits action | `POST /appointments/:id/reschedule` | New datetime and optional remarks; existing ownership guard, event/notification | Partial; no slot availability contract |
| Provider preselection | Services to booking | Existing route state only | No booking query parsing yet; provider must be loaded authoritatively | Implementation required |
| Service selection | Booking | none | Appointment has `appointment_type`; no provider-service relation/model | NOT SUPPORTED IN CURRENT CONTRACT |
| Patient/dependent selection | Booking | none | `customer_dependents` exists but Appointment has no dependent foreign key | DEFERRED - BACKEND CONTRACT REQUIRED |
| Visit types | Booking | `appointment_type` string | Existing values are request-driven, not a constrained customer-facing catalogue | Partial; use only validated provider type mapping |
| Slots | Booking / reschedule | none | No appointment-slot/provider-schedule model or API | NOT SUPPORTED IN CURRENT CONTRACT |
| Quote/pricing/coverage | Booking | none | No appointment quote endpoint/model; pricing service is staff/workflow oriented | DEFERRED - BACKEND CONTRACT REQUIRED |
| SHIELD Benefit coverage | Booking | none | Benefit rules exist, but no customer appointment quote response | DEFERRED - BACKEND CONTRACT REQUIRED |
| Online link / instructions | Visit details | none | No customer meeting-link or instructions contract | NOT SUPPORTED IN CURRENT CONTRACT |
| Timeline | Visit details | event/notification internals | No customer-safe appointment status-history response | NOT SUPPORTED IN CURRENT CONTRACT |
| Duplicate/idempotency | Create appointment | `POST /appointments` | No idempotency key/slot locking field in current request/model | DEFERRED - BACKEND CONTRACT REQUIRED; Flutter still prevents repeat taps |

## Implemented customer surfaces

- `/portal/customer/book-appointment?provider=&type=` restores a provider only after a customer-safe authoritative provider read; invalid selections are rejected into the picker.
- `/portal/customer/appointments` renders the extracted Visits feature using the existing authenticated list/cancel/reschedule APIs.

## Safety rules

- Customer identity comes from the authenticated principal; client `customer_id` is overwritten by the controller.
- Appointment ownership is verified for detail, cancellation, and reschedule before service access.
- Provider names, service names, prices, benefit coverage, slots, and meeting links must never be inferred from route parameters or fabricated in Flutter.
- Cash Wallet, Reward Points, and SHIELD Benefit remain separate; no appointment quote currently authorizes their display or deduction.
