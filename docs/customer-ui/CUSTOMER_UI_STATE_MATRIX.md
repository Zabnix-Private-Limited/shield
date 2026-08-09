# Customer UI state matrix

Final integration note (2026-08-09): full browser observation is deferred rather than represented as an empty/zero state. Deterministic error and retry semantics remain the source of truth for release evidence.

| Feature | Loading | Empty | Failure | Safety rule |
|---|---|---|---|---|
| Dashboard | Dashboard shimmer | Backend-provided no-data state | Retryable error card | Never show cached/shared customer values as current data |
| Membership | Membership skeleton | Membership unavailable | Retryable error card | No invented entitlement values |
| Privilege Card | Membership/profile/card-status progress | No issued digital card | Retryable card-status panel | QR only from server payload |
| Wallet/Rewards | Wallet shimmer | No visible transactions | Retryable wallet error | Failed API is not zero balance; benefit stays hidden |
| Services/providers | Access skeleton and provider progress | No active backend provider | Provider retry panel | Do not substitute a provider or service locally |
| Customer provider discovery | Loading indicator | No active provider / no query results | Retryable provider load failure | Route retains query, type, loaded page, and detail selection; unsupported provider metadata is absent rather than fabricated |
| Booking | Provider progress / submission progress | No provider search results | Preselection/submission retry state | No booking submits offline or twice; quote/slot/coverage absent until backend-owned contract exists |
| Visits | Access/load states | Backend-status-filtered empty state | Retryable list/mutation error | Mutations remain self-scoped; prior list is retained on action failure |
| Documents/prescriptions | List/category/search/upload and Pharmacy review | Customer archive/filtered empty state | Generic retryable error, upload retry, duplicate-submit guard | Query-backed Pharmacy context, no storage URL exposure, and explicit consent before pharmacy request |
| Wellness catalogue | Progress indicator | Catalogue empty state | Retry action | Product data remains API/database-derived |
| Orders | Screen loading | No recorded orders | Retryable error and detail-load SnackBar | Principal-scoped history; current status only, no fabricated timeline/cancel/refund/reorder |
| Notifications | Inbox loading | No notifications | Retryable mutation/error message | Do not mark read locally on failed API |
| Settings/support | N/A for unsupported preferences | Explicit unavailable labels | Generic submit failure | Do not present local-only settings as persisted |
# Account/Profile state completion — 2026-08-08

Profile: initial skeleton, retryable load failure, client validation, save in progress, save failure, acknowledgement and discard confirmation are supported. Account workspace: loading, retryable failure, empty and mutation states apply to addresses, dependents, contacts and pharmacy selection. Security: loading, empty, revoke confirmation, mutation-disabled and retryable failure states are supported. Unsupported account/privacy actions are hidden rather than rendered as locally persisted controls.
