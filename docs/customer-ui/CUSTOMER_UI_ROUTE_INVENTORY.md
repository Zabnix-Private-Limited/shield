# Customer UI route inventory

Audited: 2026-08-05. This is a route-to-contract index; `CUSTOMER_UI_AUDIT.md` remains the detailed gap audit. Customer routes are rendered through `/portal/customer/:section` and use the authenticated customer session.

| Section | Screen | Backing contract | Status |
|---|---|---|---|
| `dashboard` | Customer dashboard | `GET /customer/dashboard` | Database-backed redesign in place |
| `membership` | Membership | `GET /customer/membership` | Supported identity, plan, validity, ledger summary; entitlement unavailable |
| `privilege-card` | Privilege Card | Membership, profile, `GET /customers/:id/card-profile`, `POST /customers/:id/card-requests` | Supported issued QR card and physical-card request/status |
| `wallet`, `wallet-history` | Cash Wallet | `GET /customer/wallet` | Database-backed read-only ledger/history |
| `rewards` | Reward Points | `GET /customer/wallet` filtered to `REWARD_POINTS` | Database-backed read-only balance/history |
| `services` | Customer provider discovery | Customer-safe provider categories/list/detail | `?type=&q=&page=&provider=` restores category, search, loaded page, and detail; no coverage/location/favourites/rating claims |
| `book-appointment` | Existing booking | Membership, providers, appointments | Preserved booking flow |
| `appointments` | My Visits | Customer appointment list/cancel/reschedule | Supported customer-self operations |
| `documents`, `prescriptions` | Archive | Customer document APIs and signed downloads | Supported owned documents and prescription upload |
| `orders` | My Orders | `GET /pharmacy/purchases?customer_id=` | Customer-scoped read-only history |
| `referrals` | Referral & Rewards | `GET /referrals/summary/:customerId` | Customer-scoped status/history |
| `activity` | Activity Timeline | `GET /timeline/me` | Customer-self read-only timeline |
| `notifications` | Notifications | Customer notification read APIs | Customer-self read/mutation flow |
| `profile`, `settings` | Account | Profile, alternative contacts, support and feedback APIs | Supported persisted actions only |

## Explicitly absent routes

- Customer subscription entitlement, card history/replacement/lost/damaged card, wallet top-up, reward redemption/expiry, cart/checkout, order tracking/returns, and referral QR/share are not registered as completed customer workflows because a customer-safe backend contract has not been verified.
- No route uses shared customer records, locally fabricated financial data, or management-demo subscription APIs.
