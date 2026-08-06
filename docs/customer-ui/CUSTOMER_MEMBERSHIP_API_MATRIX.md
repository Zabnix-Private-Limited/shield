# Customer membership and card API matrix

Audited: 2026-08-06. `current_schema.md` is authoritative for persisted models; an API is treated as supported only when a customer-reachable contract was verified.

| Operation | Endpoint and method | Customer scope | Returned/supported values | UI decision |
|---|---|---|---|---|
| Current membership | `GET /customer/membership` | Customer principal resolves to its own `customerId`; agent access is additionally scope-checked | Membership number, status, dates, membership type/plan, cash-ledger totals, digital card | Supported |
| Subscription entitlement | `GET /customer/membership` | Same customer-self resolver; no customer ID is accepted for a customer principal | Stored plan/status, customer contribution, SHIELD Benefit, total entitlement and the latest allocation on or before the current month | Supported, read-only |
| Membership benefits | `GET /customer/membership` plan fields only | Same customer-self resolver | Plan name, status and eligibility metadata; no structured coverage, exclusions, annual/monthly limits, or carry-forward policy | Partial: UI must show the contract gap, not tier-based claims |
| Digital privilege card | `GET /customer/membership/card` | Customer principal resolves to its own customer ID | Card number, status, issued date and request status | Supported when a card exists |
| Secure QR verification | No verified customer/provider QR-verification endpoint | N/A | Persisted `shield_cards.qr_code` is a static string; no expiry, signing, verifier, replay protection, or PII review contract | DEFERRED — SECURITY CONTRACT REQUIRED; UI must not render it as a QR code |
| Cash membership usage | Included as `membershipStats` in `GET /customer/membership` | Same as above | Cash wallet credited/debited/available; this is not SHIELD Benefit | Supported as wallet-derived summary only |
| Physical-card request | `POST /customer/membership/card/request` | Customer principal derived by the controller; no client customer ID | Creates/reuses an active request and writes an audit log | Supported |
| Physical-card status | `GET /customer/membership/card` | Customer principal derived by the controller | Latest request and card, action state | Supported |
| Physical-card history | `GET /customer/membership/card/requests` | Customer principal derived by the controller | Customer-owned request status, requested/reviewed dates and staff remarks | Supported |
| Subscription read (staff/demo) | `GET /management-demo/subscriptions/:customerId` | `customers.view`, no customer-self resolver in this controller | Subscription and full allocation history | Not customer-safe; do not use in customer app |
| Subscription activation/preview | `POST /management-demo/subscriptions/:customerId/activate`, `POST /management-demo/subscriptions/preview` | Staff permission | Management-demo workflow | Not customer operation |
| Lost card | No verified customer API | N/A | No lifecycle reason/event or safe deactivation contract | NOT SUPPORTED IN CURRENT CONTRACT |
| Damaged card | No verified customer API | N/A | No lifecycle reason/event, assessment, fee, or delivery contract | NOT SUPPORTED IN CURRENT CONTRACT |
| Replacement card | No verified customer API | N/A | Current single-card schema has no replacement policy, duplicate-card rule, or safe replacement contract | DEFERRED — PRODUCT DECISION AND BACKEND CONTRACT REQUIRED |
| Membership renewal | No verified customer API | N/A | No renewal quote, payment, validity, carry-forward, audit, or notification workflow | DEFERRED — PRODUCT DECISION AND BACKEND CONTRACT REQUIRED |

## Data models

- `memberships`: membership number, status, activation/expiry and type.
- `shield_cards`: one card per customer, card number, stored QR string, status, issuing business/date. The stored QR string is not a customer-safe verification contract.
- `membership_subscriptions` and `subscription_monthly_allocations`: configured contribution, SHIELD Benefit, entitlement and monthly allocation data. The customer membership bundle now returns a minimal self-scoped projection, not the staff/demo history contract.
- `card_requests`: physical-card request state with customer-self status and history routes.

## Explicit gaps

- No verified customer-safe lost, damaged or replacement-card endpoint, nor an event model capable of preserving those lifecycle reasons.
- No structured plan-benefit model or customer benefit endpoint, so coverage claims must remain unavailable.
- The present membership DTO omits customer display name; the privilege card screen obtains it through the existing authenticated customer profile API.

## Current customer presentation

The membership screen presents identity, validity, plan and actual CASH-ledger summary. If the backend returns a subscription projection, it renders server-issued contribution, SHIELD Benefit, total entitlement and allocation values. SHIELD Benefit is explicitly labelled as an entitlement, never as CASH or reward points. If no subscription exists, the screen truthfully says so. The privilege-card route shows an issued digital card, real physical-card request/status and history. It deliberately withholds the persisted QR string until a signed, server-verifiable QR contract exists.

## Verification coverage

- `frontend/test/customer_membership_model_test.dart` verifies that the membership bundle retains the server-issued card number, QR payload, and status.
- `frontend/test/customer_membership_screen_test.dart` verifies loading, populated identity/entitlement-gap, and API-error states without inventing a contribution or SHIELD Benefit.
- `frontend/test/customer_privilege_card_screen_test.dart` verifies QR rendering from the supported payload, hides the request action when the card-profile contract says `VIEW_CARD`, and submits the request only when it says `REQUEST_PHYSICAL_CARD`.
