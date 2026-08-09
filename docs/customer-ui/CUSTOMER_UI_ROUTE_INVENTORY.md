# Customer UI route inventory

Audited: 2026-08-09. This is a route-to-contract index; `CUSTOMER_UI_AUDIT.md` remains the detailed gap audit. Customer routes are rendered through `/portal/customer/:section` and use the authenticated customer session.

| Section | Screen | Backing contract | Status |
|---|---|---|---|
| `dashboard` | Customer dashboard | `GET /customer/dashboard` | Database-backed redesign in place |
| `membership` | Membership | `GET /customer/membership` | Supported identity, plan, validity, ledger summary; entitlement unavailable |
| `privilege-card` | Privilege Card | Membership, profile, `GET /customers/:id/card-profile`, `POST /customers/:id/card-requests` | Supported issued QR card and physical-card request/status |
| `wallet`, `wallet-history` | Cash Wallet | `GET /customer/wallet` | Database-backed read-only ledger/history |
| `rewards` | Reward Points | `GET /customer/wallet` filtered to `REWARD_POINTS` | Database-backed read-only balance/history |
| `services` | Customer provider discovery | Customer-safe provider categories/list/detail | `?type=&q=&page=&provider=` restores category, search, loaded page, and detail; no coverage/location/favourites/rating claims |
| `book-appointment` | Customer Booking | Customer-safe provider lookup/list and appointment create | Supports `?provider=&type=` revalidated preselection, preferred datetime request, notes, safe submit/success/error; no slots/quote/coverage |
| `appointments` | My Visits | Customer appointment list/cancel/reschedule | Extracted customer-self Visits feature with backend status filters, safe detail, cancel/reschedule where supported |
| `documents` | Documents archive | Customer-safe document list/upload/detail/download | `?type=PRESCRIPTION&provider=` preserves upload context; category/search, safe detail, and signed R2 view/download supported |
| `prescriptions` | Prescriptions archive | Customer-safe prescription documents and `POST/GET /pharmacy/prescriptions` | Services Pharmacy context or validated preferred Pharmacy; explicit review/consent and duplicate-safe request submission |
| `orders` | My Orders | `GET /customer/orders`; `GET /customer/orders/:id` | Principal-scoped recorded-purchase history and safe item details |
| `referrals` | Referral & Rewards | `GET /referrals/me` | Session-owned status/history |
| `activity` | Activity Timeline | `GET /timeline/me` | Customer-self read-only timeline |
| `notifications` | Notifications | `GET /notifications/me`; customer notification read APIs | Customer-self safe inbox/read flow with server unread count |
| `profile`, `account`, `settings` | Account | `GET/PATCH /customer/profile`, customer-self account APIs and owner-scoped sessions | Safe personal projection, addresses, typed contacts, dependents, preferred pharmacy and security controls |

## Explicitly absent routes

- Customer subscription entitlement, card history/replacement/lost/damaged card, wallet top-up, reward redemption/expiry, cart/checkout, order tracking/returns, and referral QR/share are not registered as completed customer workflows because a customer-safe backend contract has not been verified.
- No route uses shared customer records, locally fabricated financial data, or management-demo subscription APIs.
# Account profile completion — 2026-08-08

`/portal/customer/profile`, `/portal/customer/account`, and Settings security are the current supported account destinations. Personal profile uses `GET/PATCH /customer/profile`; address, family, contacts and pharmacy workflows remain within the Account workspace; session/device controls remain in Settings. No duplicate customer-ID route is required because all account ownership derives from the authenticated principal.
