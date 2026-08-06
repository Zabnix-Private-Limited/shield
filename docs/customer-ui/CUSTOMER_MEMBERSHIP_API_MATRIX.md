# Customer membership and card API matrix

Audited: 2026-08-06. `current_schema.md` is authoritative for persisted models; an API is treated as supported only when a customer-reachable contract was verified.

| Operation | Endpoint and method | Customer scope | Returned/supported values | UI decision |
|---|---|---|---|---|
| Current membership | `GET /customer/membership` | Customer principal resolves to its own `customerId`; agent access is additionally scope-checked | Membership number, status, dates, membership type/plan, cash-ledger totals, digital card | Supported |
| Subscription entitlement | `GET /customer/membership` | Same customer-self resolver; no customer ID is accepted for a customer principal | Stored plan/status, customer contribution, SHIELD Benefit, total entitlement and the latest allocation on or before the current month | Supported, read-only |
| Digital privilege card | Included as `shieldCard` in `GET /customer/membership` | Same as above | Card number, actual QR payload, status, issued date/business | Supported when a card exists |
| Cash membership usage | Included as `membershipStats` in `GET /customer/membership` | Same as above | Cash wallet credited/debited/available; this is not SHIELD Benefit | Supported as wallet-derived summary only |
| Physical-card request | `POST /customers/:id/card-requests` | Customer-self guard, provider/agent scope checks, Flutter authenticated-id guard | Creates/reuses a request; customer UI confirms returned status | Supported |
| Physical-card status | `GET /customers/:id/card-profile` | Customer-self guard, provider/agent scope checks, Flutter authenticated-id guard | Latest request and card, action state | Supported |
| Subscription read (staff/demo) | `GET /management-demo/subscriptions/:customerId` | `customers.view`, no customer-self resolver in this controller | Subscription and full allocation history | Not customer-safe; do not use in customer app |
| Subscription activation/preview | `POST /management-demo/subscriptions/:customerId/activate`, `POST /management-demo/subscriptions/preview` | Staff permission | Management-demo workflow | Not customer operation |
| Card history/replacement/lost/damaged | No verified customer API | N/A | Schema has `card_requests`, no customer history/replacement contract located | Unsupported |

## Data models

- `memberships`: membership number, status, activation/expiry and type.
- `shield_cards`: one card per customer, card number, QR payload, status, issuing business/date.
- `membership_subscriptions` and `subscription_monthly_allocations`: configured contribution, SHIELD Benefit, entitlement and monthly allocation data. The customer membership bundle now returns a minimal self-scoped projection, not the staff/demo history contract.
- `card_requests`: physical-card request state; no customer-safe history contract verified.

## Explicit gaps

- No verified customer-safe physical-card history/replacement/lost/damaged endpoints.
- The present membership DTO omits customer display name; the privilege card screen obtains it through the existing authenticated customer profile API.

## Current customer presentation

The membership screen presents identity, validity, plan and actual CASH-ledger summary. If the backend returns a subscription projection, it renders server-issued contribution, SHIELD Benefit, total entitlement and allocation values. SHIELD Benefit is explicitly labelled as an entitlement, never as CASH or reward points. If no subscription exists, the screen truthfully says so. The privilege-card route shows an issued digital card or the real physical-card request/status state. If the card-profile request fails, it keeps the card screen usable and shows a retryable physical-card-status state instead of silently removing the section.

## Verification coverage

- `frontend/test/customer_membership_model_test.dart` verifies that the membership bundle retains the server-issued card number, QR payload, and status.
- `frontend/test/customer_membership_screen_test.dart` verifies loading, populated identity/entitlement-gap, and API-error states without inventing a contribution or SHIELD Benefit.
- `frontend/test/customer_privilege_card_screen_test.dart` verifies QR rendering from the supported payload, hides the request action when the card-profile contract says `VIEW_CARD`, and submits the request only when it says `REQUEST_PHYSICAL_CARD`.
