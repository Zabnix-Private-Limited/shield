# ROUTE, DATA, API AND SECURITY GUIDE

## Route strategy

The customer interface currently uses `/portal/customer/:section`. Preserve existing route names and guards wherever possible.

Before adding any route:

1. Search all GoRouter declarations and portal metadata.
2. Check whether an inline view, nested route or route alias already exists.
3. Preserve inbound/deep links.
4. Preserve auth redirects and session restoration.
5. Add a route only when it creates a clear, testable customer task.
6. Document redirects from obsolete paths.

Suggested route patterns in the screen matrix are targets, not permission to duplicate existing routes.

## Data-binding worksheet required for every screen

Record:

- Screen
- Route
- User action
- Controller endpoint
- HTTP method
- Request DTO
- Response DTO
- Frontend model
- Repository method
- Riverpod provider/notifier
- Persisted models/tables
- Authorization rule
- Audit requirement
- Cache behavior
- Error/status mapping
- Empty-state meaning

## API use

- Reuse existing API clients.
- Use typed response models.
- Do not parse loosely typed maps throughout widgets.
- Preserve cancellation, timeout, retry and token-refresh behavior.
- Do not retry non-idempotent mutations automatically without an idempotency key or safe server handling.
- Map backend lifecycle enums to centralized UI labels.
- Do not create client-only authoritative financial calculations.

## Authentication and scope

Every customer endpoint and query must derive the current customer from the verified principal/session or validate requested IDs against that principal.

Reject cross-customer access even when a user guesses a UUID or route parameter.

Required negative tests include, where applicable:

- Customer A cannot fetch Customer B wallet
- Customer A cannot fetch Customer B membership/card
- Customer A cannot fetch Customer B documents/prescriptions
- Customer A cannot fetch Customer B appointments
- Customer A cannot fetch Customer B orders/addresses
- Customer A cannot fetch Customer B referral tree
- Customer A cannot mutate Customer B profile/family data

## Financial safety

- Use integer minor units for money where the backend does so.
- Use ledger-derived balances.
- Keep `CASH`, `REWARD_POINTS` and `SHIELD_BENEFIT` separate.
- Never allow negative balance through client calculation.
- Every financial mutation must be transactional, idempotent and audited.
- UI must display backend status for pending, succeeded, failed, reversed and refunded events.
- No bank withdrawal or wallet transfer unless explicitly approved and implemented.

## Membership/card safety

- Membership state must be backend-derived.
- UI does not activate customers by changing local state.
- Digital/physical card lifecycle maps to verified backend enums.
- QR payloads must be signed/opaque where supported; never encode sensitive customer details directly.
- Card request, block and replacement actions require audit events.

## Documents

- Use authorized/signed access.
- Do not expose R2/object-storage origin URLs.
- Validate MIME type, size and ownership.
- Show upload progress and recoverable failure.
- Preserve original file and metadata.
- Access and sharing events should be auditable where required.

## Commerce

- Product catalogue remains database/API-driven.
- Price, availability, inventory, discount, tax and totals come from backend-authoritative data.
- Cart/order mutations must be idempotent.
- Do not trust client totals.
- Preserve demo/live product classification.

## Cache behavior

Where caching already exists:

- Distinguish fresh, stale and unavailable data.
- Never show another customer’s cached data after account switch.
- Clear customer-scoped caches on logout/session change.
- Preserve a visible stale-data indicator when appropriate.
