# Customer UI Implementation Status

## Phase 0 — Audit and shared shell

Completed:

- Customer route, feature, API, state, and visual audit.
- Reusable customer design tokens.
- Data-backed responsive authenticated header.
- Membership-first dashboard hierarchy using existing dashboard data.
- Static Flutter marketing carousel removed from the live dashboard pending an Operations-owned API contract.
- Operations-owned carousel contract added through the existing commercial-settings table; no schema change or seed required.
- Customer reward-points route added using the existing wallet endpoint and `REWARD_POINTS` transaction ledger; no mock points or shared customer data.
- Privilege Card route added from the membership endpoint's actual `shieldCard` payload. It renders only an issued card and its real QR payload; no subscription or physical-card data is fabricated.
- Membership screen now renders a clear entitlement-unavailable state until a customer-safe subscription contract returns contribution, SHIELD Benefit, monthly allocation and carry-forward values.
- Privilege Card supports the verified physical-card request/status contract. Backend and Flutter both reject attempts to target another customer ID.
- Membership widget coverage verifies populated identity/entitlement-gap rendering and the membership API-error state.
- Wallet now has a real full-history route backed by the existing customer wallet response. The preview links there only when the customer has more than six visible transactions; unsupported recharge/export actions are not advertised.
- Customer Services now reads the seeded wellness demo catalogue from an authenticated customer endpoint. Unsupported hardcoded pharmacy, laboratory, home-care, and diet-plan content was removed from the visible flow.
- Customer Notifications now uses the authenticated bulk-read endpoint instead of issuing one mutation per unread record.
- My Orders is now a customer-scoped, read-only pharmacy purchase-history route with loading, empty, error/retry, and refresh states. Customer cart, checkout, tracking, returns, and payments remain unavailable because no verified customer contracts exist.
- Referral & Rewards now presents the authenticated customer’s referral code, counts, available points, and backend referral lifecycle history. QR sharing and referral creation remain unavailable because no customer-safe contract exists.

Not complete:

- Full commerce, rewards, card lifecycle, referral, family, timeline, booking, and responsive visual QA.
- Customer-safe subscription entitlement, physical-card history, replacement, lost and damaged card API contracts.
- Feature extraction for portal-shell-only customer screens.
