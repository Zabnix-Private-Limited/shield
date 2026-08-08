# Customer Visits implementation audit

Audited: 2026-08-08.

The customer Visits route now uses the extracted `features/customer/visits/` repository/controller/screen rather than the legacy inline portal view.

Supported: customer-owned appointment list, Upcoming/Completed/Cancelled/All filters based on backend status, loading, empty, error/retry, refresh, customer-safe visit summary/details, cancellation confirmation, cancellation, reschedule date request, and update refresh. The customer controller never accepts a customer ID; the backend principal owns the scope.

Not supported in the current customer appointment contract: service catalogue, dependent patient linkage, fixed slots, pricing, SHIELD Benefit coverage, meeting links, appointment instructions, customer-safe status-history timeline, offline cache, and pagination. These are omitted rather than represented by placeholder values.
