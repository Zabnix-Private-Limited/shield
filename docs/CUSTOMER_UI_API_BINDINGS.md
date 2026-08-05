# Customer UI API Bindings

| Customer feature | API | Repository/controller | Data rule |
|---|---|---|---|
| Dashboard | `GET /customer/dashboard` | `DashboardRepository` / `DashboardController` | Authenticated customer only; cached per customer |
| Operations banners | `GET /customer/dashboard` → `banners` | `DashboardRepository` / `OperationsBannerCarousel` | `OPERATIONS_CUSTOMER_BANNERS` commercial setting; published, eligible, date-active customer records only |
| Wallet | `GET /customer/wallet` | `WalletRepository` / `WalletController` | Ledger-derived cash and reward balances |
| Wallet history | `GET /customer/wallet` | `WalletRepository` / `CustomerWalletScreen(showFullHistory: true)` | Customer-scoped API transaction list; no client-side running balance |
| Membership | `GET /customer/membership` | `MembershipRepository` / `MembershipController` | Membership/card data only |
| Profile | Customer profile API | `ApiService` | Authenticated customer only |
| Documents | `GET /documents?customer_id=`, `GET /documents/:id`, `GET /documents/:id/download` | `ApiService` | Customer-scoped archive. Customer document IDs are ownership-checked before read/download/intelligence access; list/detail/upload responses omit the private storage path and downloads use a signed URL. |
| Notifications | `GET /notifications?customer_id=`, `POST /notifications/:id/read`, `POST /notifications/mark-all-read`, `POST /notifications/device-token/deactivate` | `ApiService` | Customer list, individual/bulk read, and device-token deactivation actions are pinned to the authenticated customer |
| Referrals | `GET /referrals/tree/:customerId`, `GET /referrals/summary/:customerId` | `ApiService` | Customer requests must use the authenticated customer ID; cross-customer referral requests are rejected |
| Referral & Rewards | `GET /referrals/summary/:customerId` | `ApiService.getReferralSummary` / `CustomerReferralsScreen` | Read-only referral code, counts, available points, and delayed-lifecycle history for the authenticated customer |
| Purchases | `GET /pharmacy/purchases?customer_id=` | `ApiService` | Customer-scoped order history; customer UI incomplete |
| Wellness catalogue | `GET /customer/wellness-products` | `ApiService.getCustomerWellnessProducts` / customer Services | Authenticated customer only; returns only `is_demo_available=true`, `status=DEMO` seeded records |
| My Orders | `GET /pharmacy/purchases?customer_id=` | `ApiService.getCustomerPurchases` / `CustomerOrdersScreen` | Missing customer context fails closed; customer ID is verified against the authenticated customer by the backend; read-only purchase history only |
| Appointments | `GET/POST /appointments`, `GET /appointments/:id`, cancellation/reschedule endpoints | `ApiService` | Customer principal is forced to self context; read/cancel/reschedule require appointment ownership. Consultation, billing, invoice, and prescription endpoints are staff-only. |
| Activity Timeline | `GET /timeline/me` | `ApiService.getCustomerTimeline` / `TimelineController` | The endpoint accepts no customer ID and derives the timeline only from the authenticated customer principal. |
| Alternative contact | `GET /customers/:id/alternative-contacts`, `POST /customers/:id/alternative-contact`, `DELETE /customers/:id/alternative-contacts/:contactId` | `ApiService` / `CustomerController` | A customer may only read, save, or remove alternative contacts for their own authenticated customer ID. Deletion is restricted to matching non-primary contacts; an alternative mobile must be a different, valid 10-digit number, and formatting is normalized to prevent duplicates. |
| Customer account | `GET/POST/PATCH/DELETE /customer/addresses`, `GET/POST/PATCH/DELETE /customer/dependents`, `GET/POST/PATCH/DELETE /customer/contacts`, `GET/PATCH /customer/preferences`, `GET /customer/pharmacies`, `GET/PUT/DELETE /customer/preferred-provider` | `CustomerAccountRepository` / `CustomerAccountController` | Identity is derived from the JWT customer principal; resource IDs are always constrained by that customer. Address, dependent, contact, preference, and preferred-provider mutations create append-only audit entries. Pharmacy selection accepts active `PHARMACY` providers only. |

Do not expose `SHIELD_BENEFIT` as cash. Do not replace these APIs with Flutter lists. Operations banners, catalogue/cart presentation, and full card lifecycle require verified backend contracts before UI implementation.

Customer principals cannot use the staff-only `GET /customers/search` or `GET /customers/existing-by-mobile` lookup endpoints, even though they have `customers.view` for their own profile data.

## Operations banner configuration

Operations uses the existing `POST /pricing/admin/settings` contract with `code: OPERATIONS_CUSTOMER_BANNERS`, `value_type: JSON`, and a JSON array in `value_text`. Each record must supply `id`, `title`, `subtitle`, `imageUrl`, `altText`, `ctaLabel`, `ctaRoute`, `placement: DASHBOARD`, `audience` (`ALL_CUSTOMERS` or `CUSTOMER`), `priority`, `status: PUBLISHED`, and optional `startAt` / `endAt`. Only internal `/portal/customer/...` CTA routes are accepted.
# Wallet transaction detail rule

Wallet and reward transaction details render the backend transaction type, ledger, amount, timestamp, remarks and reference metadata only. Flutter does not calculate or display an authoritative historical balance-after value.
