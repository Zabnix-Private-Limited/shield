# Customer UI Implementation Status

## Phase 0 — Audit and shared shell

Completed:

- Customer route, feature, API, state, and visual audit.
- Reusable customer design tokens.
- Data-backed responsive authenticated header.
- Header widget coverage verifies the dense main-header layout at the reported 480px viewport and its no-summary retry state without a layout overflow.
- Membership-first dashboard hierarchy using existing dashboard data.
- Static Flutter marketing carousel removed from the live dashboard pending an Operations-owned API contract.
- Operations-owned carousel contract added through the existing commercial-settings table; no schema change or seed required.
- Customer reward-points route added using the existing wallet endpoint and `REWARD_POINTS` transaction ledger; no mock points or shared customer data.
- Customer transaction tiles now use the normalized ledger credit direction, so `EARNED` reward-point entries render as credits instead of debits.
- Privilege Card route added from the membership endpoint's actual `shieldCard` payload. It renders only an issued card and its real QR payload; no subscription or physical-card data is fabricated.
- Membership screen now renders a clear entitlement-unavailable state until a customer-safe subscription contract returns contribution, SHIELD Benefit, monthly allocation and carry-forward values.
- Privilege Card supports the verified physical-card request/status contract. Backend and Flutter both reject attempts to target another customer ID.
- Privilege Card widget coverage verifies the actual QR payload is rendered and that physical-card actions follow the backend card-profile action rather than a client-side assumption.
- Membership widget coverage verifies populated identity/entitlement-gap rendering and the membership API-error state.
- Wallet now has a real full-history route backed by the existing customer wallet response. The preview links there only when the customer has more than six visible transactions; unsupported recharge/export actions are not advertised.
- Wallet access now uses the issued membership returned by the wallet bundle. This prevents active members from being shown the pending-wallet screen solely because the profile response does not carry membership data.
- Customer Services now reads the seeded wellness demo catalogue from an authenticated customer endpoint. Unsupported hardcoded pharmacy, laboratory, home-care, and diet-plan content was removed from the visible flow.
- Customer Notifications now uses the authenticated bulk-read endpoint instead of issuing one mutation per unread record.
- My Orders is now a customer-scoped, read-only pharmacy purchase-history route with loading, empty, error/retry, and refresh states. Customer cart, checkout, tracking, returns, and payments remain unavailable because no verified customer contracts exist.
- Referral & Rewards now presents the authenticated customer’s referral code, counts, available points, and backend referral lifecycle history. QR sharing and referral creation remain unavailable because no customer-safe contract exists.
- Customer Settings no longer presents local-only notification, privacy, wallet, or PIN controls as saved preferences. Supported profile, policy, support, feedback, and sign-out actions remain available.
- Profile-gated customer sections now distinguish access-status loading from an API failure and provide a retryable error state instead of a permanent skeleton.
- Customer document and prescription archive failures now use the shared customer error card with a generic retry message; transport and server details are not rendered to the customer.
- Customer document, signed-download, prescription-review, extraction, and processing-log reads now verify the authenticated customer owns the document. Private object-storage paths are stripped from customer document responses.
- Document and prescription detail sheets now expose the existing signed-URL open and download actions. They never construct or display a storage URL in Flutter.
- The document archive now exposes the existing customer-authenticated prescription upload flow and refreshes the archive from the API after a successful upload.
- The Prescription screen links directly to that one persisted upload flow instead of duplicating a second file-picker implementation.
- Customer Visits now has explicit upcoming/history empty states and the shared retryable failure state while retaining the existing customer-scoped appointment and cancellation workflows.
- Activity Timeline is now a customer-self route backed by `GET /timeline/me`; it has loading, empty, retry, refresh, and data-derived category filter states and never accepts an arbitrary customer ID.
- Profile now lists, adds, and confirms removal of database-backed alternative contacts. Reads and mutations are self-scoped, and no contact is retained only in Flutter state.
- Profile and prescription-upload failures now show safe customer messages instead of raw backend or transport exception text.

Not complete:

- Full commerce, rewards, card lifecycle, referral, family, timeline, booking, and responsive visual QA.
- Customer-safe subscription entitlement, physical-card history, replacement, lost and damaged card API contracts.
- Feature extraction for portal-shell-only customer screens.
