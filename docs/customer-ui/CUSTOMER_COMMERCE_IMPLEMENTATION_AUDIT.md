# Customer Commerce Implementation Audit

Last audited: 2026-08-08

Classification: `COMPLETE — SUPPORTED FUNCTIONAL SCOPE`

## Implemented, verified scope

- Wellness catalogue remains customer-safe, searchable, filtered, paginated,
  and explicitly distinguishes catalogue visibility from purchasability.
- The backend returns `purchasable: false` for all current catalogue records;
  Flutter displays the reason and does not offer a false cart or checkout.
- My Orders now uses customer-owned `GET /customer/orders` and
  `GET /customer/orders/:id` contracts rather than a provider-oriented purchase
  endpoint. The order query is constrained by the principal-derived customer ID.
- Order detail exposes reference, current status, payment status when recorded,
  safe provider label, date, item names, quantity, and stored price snapshots.
  It excludes cost, margin, billing JSON, payment metadata, staff notes, audit
  data, and other customer data.

## Deliberately deferred

There is no valid customer cart, checkout, customer order creation, payment,
delivery snapshot, stock reservation, cancellation, refund, reorder, or order
status-history contract. These are `DEFERRED — BACKEND CONTRACT REQUIRED` and
must not be simulated by Flutter or repurpose the provider purchase mutation.

## Database readiness

Migration `20260808_prescription_pharmacy_requests` was backed up, deployed,
and verified against the approved non-production database. No commerce schema
was added because the required product and fulfilment decisions are absent.
