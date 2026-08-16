# Customer Portal UAT Remediation — 2026-08-16

## Implemented source corrections

- Session restoration keeps durable credentials through transient network and server failures, restores from a refresh credential alone, and gates cold-start customer deep links behind splash.
- Wallet messaging now distinguishes an active membership awaiting card issuance from a pending membership; it no longer labels an active member as pending.
- Membership cached data is silently revalidated. The saved-data message appears only after a refresh failure.
- Customer activity uses the shared section skeleton rather than a full-page spinner. Customer error copy for activity, prescriptions, and provider detail is plain language.
- The customer drawer no longer exposes Prescriptions as a main navigation destination; the internal route remains available for pharmacy/upload handoffs. Settings has one support entry.
- Legacy demo/staging product rows are excluded from the customer catalogue. Safe public read-only catalogue endpoints are available at `GET /wellness-products` and `GET /wellness-products/:id`.

## Explicit remaining source work

- Public Flutter catalogue route, share UI, guest cart, authenticated checkout/order placement, pharmacy order queue, and order mutation idempotency are not implemented by this remediation.
- `card_requests` remains the existing generic/physical-request persistence model. An Agent-scoped digital card-request review/issue mutation is still required before the requested end-to-end card lifecycle can be called complete.
- Prescription-to-pharmacy request persistence exists, but deployed authenticated UAT is required for upload and pharmacy receipt.
- No deployment, migration application, browser automation, or device UAT was performed.

## Verification

- Focused Flutter membership/wallet/services tests: 11 passed.
- Focused backend pharmacy/customer-membership tests: 16 passed.
- Flutter analysis of touched customer surfaces: passed.
- Backend TypeScript: passed.
