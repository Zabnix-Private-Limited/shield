# Customer UI screen manifest

## Membership

- **Route:** `/portal/customer/membership`
- **Purpose:** Show the authenticated customer’s membership identity, status, tier, validity, and cash-ledger summary.
- **Data/API:** `MembershipRepository` → `GET /customer/membership`; `memberships`, `shield_cards`, and wallet ledger totals.
- **Scope:** Customer principal only; backend resolves the customer identity.
- **States:** Loading skeleton, populated, retryable unavailable/error, refresh, pending card issuance.
- **Components:** Shared customer shell, membership hero, summary cards, status cards, shared error card.
- **Responsive:** One/two/three summary columns according to available content width.
- **Tests:** `customer_membership_model_test.dart`, `customer_membership_screen_test.dart`.

## Privilege Card

- **Route:** `/portal/customer/privilege-card`
- **Purpose:** Render the server-issued digital card/QR payload and supported physical-card status/request action.
- **Data/API:** `GET /customer/membership`, authenticated profile, `GET /customers/:id/card-profile`, `POST /customers/:id/card-requests`.
- **Scope:** Customer-self guard in Flutter and backend; card profile/request cannot target another customer.
- **States:** Membership loading/error, profile loading/error, issued QR card, no digital-card state, physical-card loading/request/status/unavailable-with-retry.
- **Components:** Shared subpage header/shell, digital card, QR renderer, detail rows, physical-card panel.
- **Responsive:** Full-width card surface with intrinsic QR and ellipsized membership identity.
- **Tests:** `customer_privilege_card_screen_test.dart`.

## Unavailable membership lifecycle screens

Subscription details, renewal, card history, lost/damaged/replacement card, and entitlement allocation screens are not rendered as completed routes. Their customer-safe contracts do not exist; `CUSTOMER_MEMBERSHIP_API_MATRIX.md` records the exact gaps.
