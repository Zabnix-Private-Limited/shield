# Customer UI API bindings

All entries use the authenticated customer session. Flutter route guards improve UX only; backend ownership and role checks remain authoritative.

| Feature | Flutter binding | API contract | Customer-data rule |
|---|---|---|---|
| Dashboard/header | `DashboardRepository` | `GET /customer/dashboard` | Dashboard bundle belongs to the principal; header derives CASH and reward totals from it |
| Membership/Card | `MembershipRepository`, `ApiService` | `GET /customer/membership`; `GET /customer/membership/card`; `GET /customer/membership/card/requests`; `POST /customer/membership/card/request` | Customer-self membership bundle includes a read-only subscription projection; SHIELD Benefit stays distinct from CASH and reward-point balances; QR is unavailable until the backend provides a signed verification contract |
| Cash Wallet/Rewards | `WalletRepository` | `GET /customer/wallet` | CASH and `REWARD_POINTS` are separate ledgers; `SHIELD_BENEFIT` is not customer-visible balance |
| Providers/booking | `ApiService` in customer services view | `GET /service-providers`; customer appointment create | UI submits only selected active provider; backend binds appointment to customer principal |
| Visits | `ApiService` | Customer appointments list/cancel/reschedule | Backend verifies customer ownership for every mutation |
| Documents/prescriptions | Customer document screens | Customer document read/upload/detail/signed download APIs | Customer-owned document checks; storage paths never render in Flutter |
| Wellness catalogue | `ApiService.getCustomerWellnessProducts`, `getCustomerWellnessProduct` | `GET /customer/wellness-products?query=&categoryId=&page=&pageSize=`; `GET /customer/wellness-products/:id` | Customer-safe paginated records only; imported batch renders as `DEMO` with the required non-live inventory disclosure |
| Orders | `CustomerOrdersScreen` | `GET /pharmacy/purchases?customer_id=` | Read-only customer purchase history; no cart/checkout contract |
| Referrals | `CustomerReferralsScreen` | `GET /referrals/summary/:customerId` | Customer-scoped lifecycle history; no client reward calculation |
| Activity/notifications | Customer timeline/inbox views | `GET /timeline/me`; notification read APIs | Timeline resolves self; notification mutations are ownership-scoped |
| Profile/support | Profile/settings views | Profile/alternative contact/support/feedback APIs | Contacts and mutations are self-scoped; support/feedback persist through their existing APIs |

## Operations banner configuration

`GET /customer/dashboard` returns only eligible `OPERATIONS_CUSTOMER_BANNERS` records from the existing `commercial_settings` table. Each published dashboard record supplies its title, subtitle, image URL or bundled asset path, accessible description, and an internal customer CTA route. For an approved non-production database with no Operations setting, run `backend/prisma/demo-seeds/20260805_operations_customer_banners.sql`; it uses `ON CONFLICT DO NOTHING`, so it never replaces an Operations-managed configuration.

## Explicitly not bound

- Management-demo subscription history/mutation APIs, card history/replacement APIs, customer wallet top-up/statements, reward redemption/expiry, cart/checkout/order tracking, and referral sharing are not customer UI bindings until a customer-safe contract exists.
