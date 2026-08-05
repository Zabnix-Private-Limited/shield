# Customer UI Visual QA

Reference images were inspected from `Design reference/`; they are visual references only and are not application assets.

## Current evidence

- Shared customer header: targeted static analysis passed.
- Dashboard membership-first hierarchy: targeted static analysis passed.
- 2026-08-05 local Playwright capture: the current production-style login renders correctly at `http://localhost:5354/`; `9876543210` passes client validation and is normalized to `+919876543210` before the Firebase request. The authenticated flow is blocked only because Firebase web phone auth is not configured for localhost; `ALLOW_LOCAL_WEB_PHONE_AUTH=true` plus Firebase authorized-domain/test-phone configuration are required before entering `123123` can be verified.
- 2026-08-04 local web capture attempt: `flutter run -d chrome --web-port 5353` remained in startup/build state and did not expose the local port after a short wait. No screenshot was captured or claimed.
- 2026-08-04 responsive browser check: the existing `localhost:53431` Flutter server was reachable and a 480×800 capture was taken in Chrome, but it rendered only the blank Flutter surface (white canvas with the top shell stripe), with no DOM content or console errors. The capture was not saved as a project artifact and cannot verify the authenticated header.
- 2026-08-05 authenticated Chrome QA: used the user-provided logged-in customer session at `localhost:53431` without submitting, revoking, or signing out. The live Profile route rendered the member identity and membership data; Edit details opened the supported customer-safe form and cancelled cleanly without a write. Settings rendered the truthful unavailable preference states, support options, and the Active sessions entry. The Active sessions sheet loaded the customer-scoped session list and identified the current device. Services loaded the active wellness catalogue with real product cards and prices, with no demo disclosure or placeholder catalogue.
- The only console error captured during this pass was a Chrome extension asynchronous-listener message, not a SHIELD route/runtime error.

## Remaining visual evidence

- Mobile (360/390/430/480), tablet, and desktop screenshots.
- Wallet, reward points, services, booking, documents, membership/card, shop/cart, and profile comparison captures.
- Overflow and text-scale checks.

## Header overflow correction — 2026-08-04

| Reference | Route | Screenshot | Difference found | Correction | Remaining difference |
|---|---|---|---|---|---|
| Shared mobile header | All main customer routes | Browser capture attempted at 480×800; no project screenshot artifact because the local app rendered only a blank Flutter surface | Runtime log reported right overflow at 448px and vertical overflow after hot restarts | Header removes the brand lockup on dense widths and collapses wallet/reward controls to route-preserving icons below 480px; regression tests pass at 480px/448px and in the actual 448px customer-scaffold SafeArea constraint | Authenticated device capture at 360/390/448px remains required; any remaining vertical overflow needs a rendered route to identify its widget |
| My Orders | `/portal/customer/orders` | Not captured in this environment | New customer purchase-history route | Uses the shared customer shell, white bordered order cards, navy amounts, and existing status treatment | Device capture remains required |
| Referral & Rewards | `/portal/customer/referrals` | Not captured in this environment | New customer referral-status route | Uses the shared customer shell, white bordered cards, navy summary values, and lifecycle statuses | Device capture remains required |
| Activity Timeline | `/portal/customer/activity` | Not captured in this environment | New database-backed customer-self timeline route | Uses the shared customer shell, white bordered event cards, and category accents | Device capture remains required |
| My Visits | `/portal/customer/appointments` | Not captured in this environment | Existing visit card lacked a customer reschedule action despite the supported endpoint | Added a compact date-picker action beside cancellation, retaining the shared cards and status treatment | Authenticated device capture remains required |
# Membership batch visual QA

| Reference | Route | Screenshot | Result |
|---|---|---|---|
| Privilege Card reference | `/portal/customer/privilege-card` | Not captured in this environment | Implemented navy card, white QR surface, rounded 24px card and shared shell; device/browser capture remains required |

Known difference: the current backend does not expose subscription entitlement or physical-card-history data to a customer-safe contract, so those panels are intentionally absent rather than represented with reference-only values.

| Privilege Card reference | `/portal/customer/privilege-card` physical-card panel | Not captured in this environment | Card-profile API failures previously made this panel disappear | Retains a bordered unavailable panel with a Retry action; authenticated device capture remains required |

| Customer Settings | `/portal/customer/settings` | Not captured in this environment | Replaced the frontend-only Help Center action with the existing support-contact sheet; no visual-only shell was added | Authenticated device capture remains required |
| Customer Profile and Settings | `/portal/customer/profile`, `/portal/customer/settings` | Not captured in this environment | Added grouped profile-and-family capability cards, FAQ, About, and destructive sign-out confirmation in the existing customer shell | Uses the shared rounded cards, navy hierarchy, cobalt actions, and truthful unavailable treatment; authenticated capture remains required |
