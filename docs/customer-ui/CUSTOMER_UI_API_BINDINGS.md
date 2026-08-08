# Customer UI API bindings

All entries use the authenticated customer session. Flutter route guards improve UX only; backend ownership and role checks remain authoritative.

| Feature | Flutter binding | API contract | Customer-data rule |
|---|---|---|---|
| Dashboard/header | `DashboardRepository` | `GET /customer/dashboard` | Dashboard bundle belongs to the principal; header derives CASH and reward totals from it |
| Membership/Card | `MembershipRepository`, `ApiService` | `GET /customer/membership`; `GET /customer/membership/card`; `GET /customer/membership/card/requests`; `POST /customer/membership/card/request` | Customer-self membership bundle includes a read-only subscription projection; SHIELD Benefit stays distinct from CASH and reward-point balances; QR is unavailable until the backend provides a signed verification contract |
| Cash Wallet/Rewards | `WalletRepository` | `GET /customer/wallet` | CASH and `REWARD_POINTS` are separate ledgers; `SHIELD_BENEFIT` is not customer-visible balance |
| Provider discovery | `CustomerProviderRepository`, `CustomerServicesController` | `GET /customer/providers/categories`; `GET /customer/providers?query=&type=&page=&pageSize=`; `GET /customer/providers/:id` | Customer-only active provider projection; route stores type/query/page/detail; `Active provider` means directory eligibility only, not appointment availability |
| Providers/booking | Existing booking view | Existing staff/provider list and customer appointment create | UI submits only selected active provider; backend binds appointment to customer principal |
| Booking | `CustomerBookingRepository`, `CustomerBookingController` | `GET /customer/providers/:id`; `GET /customer/providers`; `POST /appointments` | Provider is revalidated from customer-safe API; customer ID is derived server-side; date/time is a request, not a slot; no quote/coverage contract |
| Visits | `CustomerVisitsRepository`, `CustomerVisitsController` | `GET /appointments`; `POST /appointments/:id/cancel`; `POST /appointments/:id/reschedule` | Backend verifies customer ownership for every read/mutation; customer response is a safe appointment/provider projection |
| Documents/prescriptions | Customer document screens | Customer document read/upload/detail/signed download APIs; `POST/GET /pharmacy/prescriptions` | Session-bound ownership; safe projection omits storage keys, staff notes, audit/extraction fields, and other customer IDs. R2 URLs are short-lived; local raw paths are never returned. |
| Wellness catalogue | `ApiService.getCustomerWellnessProducts`, `getCustomerWellnessProduct` | `GET /customer/wellness-products?query=&categoryId=&page=&pageSize=`; `GET /customer/wellness-products/:id` | Customer-safe paginated records only; imported batch renders as `DEMO` with the required non-live inventory disclosure |
| Orders | `CustomerOrdersRepository`, `CustomerOrdersScreen` | `GET /customer/orders`; `GET /customer/orders/:id` | Backend derives customer identity from the principal and constrains detail by customer ownership; customer-safe recorded-purchase history only |
| Referrals | `CustomerReferralsScreen` | `GET /referrals/me` | Customer identity derives from session; code/history omit referred-customer IDs and internal commission/tree data |
| Activity/notifications | Customer timeline/inbox views | `GET /timeline/me`; `GET /notifications/me`; notification read APIs | Timeline and inbox resolve self; activity projection omits actors/raw metadata and unread count is server-authoritative |
| Profile/support | Profile/settings views | Profile/alternative contact/support/feedback APIs | Contacts and mutations are self-scoped; support/feedback persist through their existing APIs |

## Operations banner configuration

`GET /customer/dashboard` returns only eligible `OPERATIONS_CUSTOMER_BANNERS` records from the existing `commercial_settings` table. Each published dashboard record supplies its title, subtitle, image URL or bundled asset path, accessible description, and an internal customer CTA route. For an approved non-production database with no Operations setting, run `backend/prisma/demo-seeds/20260805_operations_customer_banners.sql`; it uses `ON CONFLICT DO NOTHING`, so it never replaces an Operations-managed configuration.

## Explicitly not bound

- Management-demo subscription history/mutation APIs, card history/replacement APIs, customer wallet top-up/statements, reward redemption/expiry, cart/checkout/order tracking, and referral sharing are not customer UI bindings until a customer-safe contract exists.
