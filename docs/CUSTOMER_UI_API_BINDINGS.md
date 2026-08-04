# Customer UI API Bindings

| Customer feature | API | Repository/controller | Data rule |
|---|---|---|---|
| Dashboard | `GET /customer/dashboard` | `DashboardRepository` / `DashboardController` | Authenticated customer only; cached per customer |
| Operations banners | `GET /customer/dashboard` → `banners` | `DashboardRepository` / `OperationsBannerCarousel` | `OPERATIONS_CUSTOMER_BANNERS` commercial setting; published, eligible, date-active customer records only |
| Wallet | `GET /customer/wallet` | `WalletRepository` / `WalletController` | Ledger-derived cash and reward balances |
| Wallet history | `GET /customer/wallet` | `WalletRepository` / `CustomerWalletScreen(showFullHistory: true)` | Customer-scoped API transaction list; no client-side running balance |
| Membership | `GET /customer/membership` | `MembershipRepository` / `MembershipController` | Membership/card data only |
| Profile | Customer profile API | `ApiService` | Authenticated customer only |
| Documents | `GET /documents?customer_id=` | `ApiService` | Customer-scoped archive |
| Notifications | `GET /notifications?customer_id=` | `ApiService` | Customer-scoped inbox |
| Purchases | `GET /pharmacy/purchases?customer_id=` | `ApiService` | Customer-scoped order history; customer UI incomplete |
| Wellness catalogue | `GET /customer/wellness-products` | `ApiService.getCustomerWellnessProducts` / customer Services | Authenticated customer only; returns only `is_demo_available=true`, `status=DEMO` seeded records |
| Appointments | `POST /appointments`, cancellation endpoint | `ApiService` | Customer-scoped booking/cancellation |

Do not expose `SHIELD_BENEFIT` as cash. Do not replace these APIs with Flutter lists. Operations banners, catalogue/cart presentation, and full card lifecycle require verified backend contracts before UI implementation.

## Operations banner configuration

Operations uses the existing `POST /pricing/admin/settings` contract with `code: OPERATIONS_CUSTOMER_BANNERS`, `value_type: JSON`, and a JSON array in `value_text`. Each record must supply `id`, `title`, `subtitle`, `imageUrl`, `altText`, `ctaLabel`, `ctaRoute`, `placement: DASHBOARD`, `audience` (`ALL_CUSTOMERS` or `CUSTOMER`), `priority`, `status: PUBLISHED`, and optional `startAt` / `endAt`. Only internal `/portal/customer/...` CTA routes are accepted.
# Wallet transaction detail rule

Wallet and reward transaction details render the backend transaction type, ledger, amount, timestamp, remarks and reference metadata only. Flutter does not calculate or display an authoritative historical balance-after value.
