# Customer UI Visual QA

Reference images were inspected from `Design reference/`; they are visual references only and are not application assets.

## Current evidence

- Shared customer header: targeted static analysis passed.
- Dashboard membership-first hierarchy: targeted static analysis passed.

## Remaining visual evidence

- Mobile (360/390/430/480), tablet, and desktop screenshots.
- Wallet, reward points, services, booking, documents, membership/card, shop/cart, and profile comparison captures.
- Overflow and text-scale checks.

## Header overflow correction — 2026-08-04

| Reference | Route | Screenshot | Difference found | Correction | Remaining difference |
|---|---|---|---|---|---|
| Shared mobile header | All main customer routes | Not captured in this environment | Runtime log reported right overflow at 448px and vertical overflow after hot restarts | Header switches to a mark-only brand below 560px while retaining wallet, rewards, and notification actions | Device capture at 360/390/448px remains required |
# Membership batch visual QA

| Reference | Route | Screenshot | Result |
|---|---|---|---|
| Privilege Card reference | `/portal/customer/privilege-card` | Not captured in this environment | Implemented navy card, white QR surface, rounded 24px card and shared shell; device/browser capture remains required |

Known difference: the current backend does not expose subscription entitlement or physical-card-history data to a customer-safe contract, so those panels are intentionally absent rather than represented with reference-only values.
