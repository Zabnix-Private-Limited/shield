# Customer Final Release Audit

Audited: 2026-08-09. Database authority: `current_schema.md` (read; not modified). No database-changing command or SQL was executed.

| Module | Route / surface | Entry point | Backend/API | Auth / ownership | State & retry | Responsive / a11y | Tests | Browser QA | Status |
|---|---|---|---|---|---|---|---|---|---|
| Home | `/portal/customer/dashboard` | bottom nav, root | customer dashboard | customer JWT | loading/error/retry | shared shell coverage | existing customer tests | deferred | PASS |
| Membership | `membership`, `membership/subscription`, `membership/benefits` | nav/profile | customer membership | customer JWT | loading/error/retry | membership responsive tests | existing tests | deferred | PASS |
| Card | `privilege-card` | membership | self card/history/request APIs | customer JWT | unavailable/retry | card coverage | existing tests | deferred | PASS |
| Wallet / rewards | `wallet`, `wallet-history`, `rewards` | bottom nav/header | wallet self API | customer JWT; CASH and REWARD_POINTS separated | loading/error/retry | wallet/header coverage | existing tests | deferred | PASS |
| Services | `services` | bottom nav, dashboard | customer provider APIs | customer JWT/safe provider DTO | loading/empty/error/pagination retry | services coverage | existing tests | deferred | PASS |
| Booking / visits | `book-appointment`, `appointments` | services, dashboard, nav | customer provider/appointment APIs | customer JWT | submit/loading/error/retry | booking/visits responsive coverage | existing tests | deferred | PASS |
| Documents / prescriptions | `documents`, `prescriptions` | dashboard, services | safe document and pharmacy APIs | customer ownership | loading/empty/error/upload retry | document responsive coverage | existing tests | deferred | PASS |
| Wellness | Services catalogue surface | services | safe paginated catalogue APIs | customer JWT | search/empty/error/pagination | services coverage | existing tests | deferred | PASS — catalogue only |
| Orders | `orders` | menu/profile | self order APIs | customer ownership | loading/empty/error/retry | order coverage | existing tests | deferred | PASS |
| Referrals / activity | `referrals`, `activity` | menu/profile | `/referrals/me`, `/timeline/me` | session-owned projection | loading/empty/error/retry | existing UI patterns | existing tests | deferred | PASS |
| Notifications | `notifications` | header, dashboard | self inbox/read APIs | customer ownership | unread/error/retry | app-bar coverage | existing tests | deferred | PASS |
| Profile / account | `profile`, `account`, `settings` | bottom nav/profile | `GET/PATCH /customer/profile`, account APIs | JWT-owned safe profile and resource ownership | loading/error/save/retry | 350–1200 account coverage | account tests | deferred | PASS |
| Sessions | Settings sheet | Settings | `/auth/sessions` revoke APIs | owner-scoped safe projection | loading/empty/error/retry | sheet uses safe scrolling | auth service tests | deferred | PASS |

## Defects fixed in this pass

P0/P1: none remaining. A customer could still invoke generic self profile reads through `/customers/:id`, which returns internal relationships intended for operational users. Customer `me` and self-ID controller reads now return the narrow `getCustomerSelfProfile` projection, and Wallet/Privilege Card use `/customer/profile` directly. Regression tests prove the safe routing.

## Security checklist

| Boundary | Result | Evidence |
|---|---|---|
| Authentication / route guards | PASS | GoRouter customer/internal separation; auth tests |
| Customer isolation | PASS | customer-account, controller and session ownership tests |
| Session safety | PASS | owner-scoped list/revoke tests; no tokens/hashes in projection |
| Customer-safe profile DTO | PASS | dedicated projection and regression tests |
| Documents/prescriptions/provider privacy | PASS — supported contracts | existing customer-safe projections and focused suites |
| Financial separation | PASS | `wallet_transactions.sub_ledger_type` is present in current schema; customer wallet/reward bindings use separate CASH and REWARD_POINTS paths; SHIELD_BENEFIT remains hidden entitlement |
| Sensitive logs | PASS — static audit | no production customer-flow OTP/token debug logging found |
| Storage URL safety | PASS — supported contract | signed-view/download design documented and retained |

## Verification evidence

- Focused backend Jest: 24 passed (`customer.controller`, `customer-account.controller`, `customer.service`, `auth.session`).
- Earlier account responsive widget suite: 2 passed at 350, 375, 390, 412, 448, 480, 768 and 1200px.
- Earlier targeted Flutter analyze passed after account changes.
- Full `flutter test`, full `flutter analyze`, and combined build/analyze attempts were stopped after no runner progress in this Windows environment; they are **DEFERRED — TOOLING FAILURE**, not passes.
- Authenticated browser QA and screenshots are **DEFERRED — TOOLING FAILURE** until a stable local server/browser session is available.

## Release blockers and recommendation

- P0: none.
- P1: none found in supported scope.
- P2: final authenticated browser smoke, full Flutter analyzer/test and isolated backend build must be completed in a stable CI/local runner.
- Deferred contracts: primary phone Firebase migration, account deletion/export, wallet top-up/export, cart/checkout/payment, provider ratings/distance/favourites, real slots/pricing/coverage, dependent booking, prescription fulfilment, secure sharing/OCR, order refunds/tracking, referral share, and notification deep-link pagination.

**Final recommendation: READY FOR INTERNAL QA.**
