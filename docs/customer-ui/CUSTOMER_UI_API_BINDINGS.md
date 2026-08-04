# Customer UI API bindings

All entries use the authenticated customer session. Flutter route guards improve UX only; backend ownership and role checks remain authoritative.

| Feature | Flutter binding | API contract | Customer-data rule |
|---|---|---|---|
| Dashboard/header | `DashboardRepository` | `GET /customer/dashboard` | Dashboard bundle belongs to the principal; header derives CASH and reward totals from it |
| Membership/Card | `MembershipRepository`, `ApiService` | `GET /customer/membership`; `GET /customers/:id/card-profile`; `POST /customers/:id/card-requests` | Customer-self card profile/request; QR payload is server-issued |
| Cash Wallet/Rewards | `WalletRepository` | `GET /customer/wallet` | CASH and `REWARD_POINTS` are separate ledgers; `SHIELD_BENEFIT` is not customer-visible balance |
| Providers/booking | `ApiService` in customer services view | `GET /service-providers`; customer appointment create | UI submits only selected active provider; backend binds appointment to customer principal |
| Visits | `ApiService` | Customer appointments list/cancel/reschedule | Backend verifies customer ownership for every mutation |
| Documents/prescriptions | Customer document screens | Customer document read/upload/detail/signed download APIs | Customer-owned document checks; storage paths never render in Flutter |
| Wellness catalogue | `ApiService.getCustomerWellnessProducts` | `GET /customer/wellness-products` | Seeded demo products remain API/database-derived and marked in their data source |
| Orders | `CustomerOrdersScreen` | `GET /pharmacy/purchases?customer_id=` | Read-only customer purchase history; no cart/checkout contract |
| Referrals | `CustomerReferralsScreen` | `GET /referrals/summary/:customerId` | Customer-scoped lifecycle history; no client reward calculation |
| Activity/notifications | Customer timeline/inbox views | `GET /timeline/me`; notification read APIs | Timeline resolves self; notification mutations are ownership-scoped |
| Profile/support | Profile/settings views | Profile/alternative contact/support/feedback APIs | Contacts and mutations are self-scoped; support/feedback persist through their existing APIs |

## Explicitly not bound

- Management-demo subscription APIs, card history/replacement APIs, customer wallet top-up/statements, reward redemption/expiry, cart/checkout/order tracking, and referral sharing are not customer UI bindings until a customer-safe contract exists.
