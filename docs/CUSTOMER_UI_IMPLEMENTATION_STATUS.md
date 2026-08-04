# Customer UI Implementation Status

## Phase 0 — Audit and shared shell

Completed:

- Customer route, feature, API, state, and visual audit.
- Reusable customer design tokens.
- Data-backed responsive authenticated header.
- Header widget coverage verifies the dense main-header layout at the reported 480px viewport and its no-summary retry state without a layout overflow.
- Membership-first dashboard hierarchy using existing dashboard data.
- Dashboard visit and activity sections now distinguish an empty authenticated response from a blank screen, with a services entry point when no visit is scheduled.
- Static Flutter marketing carousel removed from the live dashboard pending an Operations-owned API contract.
- Operations-owned carousel contract added through the existing commercial-settings table. An explicit idempotent non-production seed now publishes three local-image demo banners only when Operations has not configured the setting.
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
- Consultation booking now requires the customer to explicitly select an active backend provider. The selected provider ID is submitted to the existing appointment API; a stale provider selection gets a safe retry message.
- The legacy Book Appointment route now renders the real customer consultation flow. Unsupported customer recharge is no longer registered as a customer portal section because no persisted top-up request contract exists.
- Customer navigation and Services now share the authenticated profile-plus-membership access context. Active issued members see their actual access state, while a failed membership read is a retryable unavailable state instead of an indefinite loading or false pending state.
- Customer Notifications now uses the authenticated bulk-read endpoint instead of issuing one mutation per unread record.
- Customer notification read and bulk-read failures now remain inside the inbox as safe retry messages; no API exception is allowed to escape a customer tap.
- My Orders is now a customer-scoped, read-only pharmacy purchase-history route with loading, empty, error/retry, and refresh states. Customer cart, checkout, tracking, returns, and payments remain unavailable because no verified customer contracts exist.
- Referral & Rewards now presents the authenticated customer’s referral code, counts, available points, and backend referral lifecycle history. QR sharing and referral creation remain unavailable because no customer-safe contract exists.
- Customer Settings no longer presents local-only notification, privacy, wallet, or PIN controls as saved preferences. Supported profile, policy, support, feedback, and sign-out actions remain available.
- Profile-gated customer sections now distinguish access-status loading from an API failure and provide a retryable error state instead of a permanent skeleton.
- Customer document and prescription archive failures now use the shared customer error card with a generic retry message; transport and server details are not rendered to the customer.
- Customer document, signed-download, prescription-review, extraction, and processing-log reads now verify the authenticated customer owns the document. Private object-storage paths are stripped from customer document responses.
- Document and prescription detail sheets now expose the existing signed-URL open and download actions. They never construct or display a storage URL in Flutter.
- The document archive now exposes the existing customer-authenticated prescription upload flow and refreshes the archive from the API after a successful upload.
- The Prescription screen links directly to that one persisted upload flow instead of duplicating a second file-picker implementation.
- The prescription archive now verifies that a failed authenticated read stays retryable and is never presented as an empty prescription history.
- Customer Visits now has explicit upcoming/history empty states and the shared retryable failure state while retaining the existing customer-scoped appointment and cancellation workflows.
- Customer Visits now exposes the existing customer-scoped reschedule endpoint through a date picker. The backend remains authoritative for appointment ownership, the actual appointment time, status, notifications, and timeline event.
- Appointment, document, and prescription access checks now load the authenticated membership bundle alongside the profile. This preserves the issued-card requirement without wrongly blocking active members whose profile payload has no membership field.
- The main customer header now collapses balance controls to icons below 480 logical pixels, preventing the reported narrow-window horizontal overflow while retaining each route action.
- Activity Timeline is now a customer-self route backed by `GET /timeline/me`; it has loading, empty, retry, refresh, and data-derived category filter states and never accepts an arbitrary customer ID.
- Profile now lists, adds, and confirms removal of database-backed alternative contacts. Reads and mutations are self-scoped, and no contact is retained only in Flutter state.
- Profile and prescription-upload failures now show safe customer messages instead of raw backend or transport exception text.
- Customer Settings now routes its Get support action to the existing persisted support-contact request instead of displaying a frontend-only Help Center message.
- Privilege Card now exposes a retryable physical-card-status failure state instead of silently hiding the supported request/status panel when its API is unavailable.
- Membership widget coverage now verifies that the persisted screen displays its loading skeleton until the API resolves, distinct from populated and unavailable states.
- Customer header coverage now verifies the reported 448px width inside the real customer-scaffold SafeArea constraint, not only as a standalone app bar.
- Added the customer route inventory and membership/card screen manifest so supported routes and deliberately unavailable customer workflows are explicit.
- Wallet API failures now show a retryable unavailable state with no fabricated zero balance; ledger and `SHIELD_BENEFIT` filtering remain unchanged.
- Consultation provider loading now distinguishes a retryable provider API failure from a genuine empty provider list.
- Added the customer API-binding and state-matrix references to make scope, empty, and error semantics explicit across the redesign.
- Added the shared customer design-token, component, and accessibility references for consistent follow-on feature work.
- Removed unreachable local lab/home-care request snippets; unavailable catalogue states remain explicit until the backend provides customer-safe contracts.
- Customer document archive coverage now verifies a backend failure is retryable and never presented as an empty customer archive.

Not complete:

- Full commerce, rewards, card lifecycle, referral, family, timeline, booking, and responsive visual QA.
- Customer-safe subscription entitlement, physical-card history, replacement, lost and damaged card API contracts.
- Feature extraction for portal-shell-only customer screens.
