# Customer Booking implementation audit

Audited: 2026-08-08.

The extracted `features/customer/booking/` feature replaces the legacy mixed booking view at `/portal/customer/book-appointment`.

Supported: Services provider-detail booking entry carries `provider`/`type`; direct URLs reload provider data from the customer-safe endpoint; inactive/invalid providers are rejected server-side; provider search/change; preferred date/time request; optional bounded reason; real appointment creation; loading, recoverable failure, success, and controller-level duplicate-submit prevention.

The backend owns customer identity and rejects inactive providers. Customer response projections omit raw customer/provider records and keep only appointment fields plus public provider identity/type.

Not supported in the current contract: service catalogue, provider-service compatibility, dependent booking, constrained visit-type catalogue, slots, slot conflicts, quote/pricing, SHIELD Benefit booking coverage, review quote, idempotency key, online consultation links, offline queue, and customer meeting/instruction lifecycle. The UI neither renders fake values nor submits unsupported data.
