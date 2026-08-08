# Customer Orders Implementation Audit

Classification: `COMPLETE — SUPPORTED FUNCTIONAL SCOPE`

## Contract

- `GET /customer/orders` lists only purchases where `customer_id` equals the
  authenticated customer principal.
- `GET /customer/orders/:id` applies both order ID and customer ID in the
  backend query; another customer's order returns not found.
- The projection deliberately exposes only a safe reference, current status,
  payment status when stored, totals, date, provider label, and item snapshots.

## Customer UI

`CustomerOrdersRepository` owns the API binding. The existing My Orders screen
has loading, populated, empty, retryable error, pull-to-refresh, and safe
detail-sheet states. It does not show cancellation, refund, reorder, delivery,
or a fabricated lifecycle timeline.

## Verification

Focused controller/service tests cover session-derived ownership, denied access
without a customer session, cross-customer not-found behaviour, and projection
exclusion. Flutter analysis and order model/screen tests pass, including
populated cards with long provider and invoice values at 350, 375, 390, 412,
448, 480, 768, and 1200 logical px.
