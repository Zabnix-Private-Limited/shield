# Customer UI Visual QA

Reference images were inspected from `Design reference/`; they are visual references only and are not application assets.

## Current evidence

- Shared customer header: targeted static analysis passed.
- Dashboard membership-first hierarchy: targeted static analysis passed.
- 2026-08-04 local web capture attempt: `flutter run -d chrome --web-port 5353` remained in startup/build state and did not expose the local port after a short wait. No screenshot was captured or claimed.
- 2026-08-04 responsive browser check: the existing `localhost:53431` Flutter server was reachable and a 480×800 capture was taken in Chrome, but it rendered only the blank Flutter surface (white canvas with the top shell stripe), with no DOM content or console errors. The capture was not saved as a project artifact and cannot verify the authenticated header.

## Remaining visual evidence

- Mobile (360/390/430/480), tablet, and desktop screenshots.
- Wallet, reward points, services, booking, documents, membership/card, shop/cart, and profile comparison captures.
- Overflow and text-scale checks.

## Header overflow correction — 2026-08-04

| Reference | Route | Screenshot | Difference found | Correction | Remaining difference |
|---|---|---|---|---|---|
| Shared mobile header | All main customer routes | Browser capture attempted at 480×800; no project screenshot artifact because the local app rendered only a blank Flutter surface | Runtime log reported right overflow at 448px and vertical overflow after hot restarts | Header switches to a mark-only brand below 560px while retaining wallet, rewards, and notification actions; widget regression test passes at 480px | Authenticated device capture at 360/390/448px remains required |
| My Orders | `/portal/customer/orders` | Not captured in this environment | New customer purchase-history route | Uses the shared customer shell, white bordered order cards, navy amounts, and existing status treatment | Device capture remains required |
| Referral & Rewards | `/portal/customer/referrals` | Not captured in this environment | New customer referral-status route | Uses the shared customer shell, white bordered cards, navy summary values, and lifecycle statuses | Device capture remains required |
| Activity Timeline | `/portal/customer/activity` | Not captured in this environment | New database-backed customer-self timeline route | Uses the shared customer shell, white bordered event cards, and category accents | Device capture remains required |
# Membership batch visual QA

| Reference | Route | Screenshot | Result |
|---|---|---|---|
| Privilege Card reference | `/portal/customer/privilege-card` | Not captured in this environment | Implemented navy card, white QR surface, rounded 24px card and shared shell; device/browser capture remains required |

Known difference: the current backend does not expose subscription entitlement or physical-card-history data to a customer-safe contract, so those panels are intentionally absent rather than represented with reference-only values.
