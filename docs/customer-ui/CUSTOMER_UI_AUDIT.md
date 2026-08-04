# SHIELD Customer UI Audit

Last audited: 2026-08-04. The customer portal is protected by the customer JWT/session and rendered through `/portal/customer/:section`.

| Route/section | Current screen | Binding | Redesign/gap |
|---|---|---|---|
| `/customer/login`, `/otp`, `/register` | Customer auth screens | Firebase phone OTP + customer auth repository | Visual alignment and auth-state QA remain |
| `dashboard` | `CustomerDashboardScreen` | `DashboardRepository`, cache, `GET /customer/dashboard` | Shared header, membership-first layout and Operations carousel implemented; screenshot QA pending |
| `membership` | `CustomerMembershipScreen` | `MembershipRepository`, `GET /customer/membership` | Membership identity/number/status/validity, live cash-ledger summary, loading/error/refresh implemented; subscription entitlement is unavailable pending a customer-safe API |
| `privilege-card` | `CustomerPrivilegeCardScreen` | `MembershipRepository`, `GET /customer/membership`, authenticated customer profile | Digital card and real QR payload supported when issued; physical-card history/replacement workflows lack verified customer APIs |
| `wallet` | `CustomerWalletScreen` | `WalletRepository`, `GET /customer/wallet` | Cash wallet and scoped transaction history exist; add-funds, exportable statements and transaction-detail routes lack verified customer contracts |
| `wallet-history` | `CustomerWalletScreen(showFullHistory: true)` | `WalletRepository`, `GET /customer/wallet` | Full customer-scoped transaction list; reachable from Wallet when additional visible records exist; statement export remains unsupported |
| `rewards` | `CustomerRewardPointsScreen` | `WalletRepository`, `GET /customer/wallet`, `REWARD_POINTS` ledger only | Live balance and activity are implemented; redemption/expiry require dedicated backend contracts |
| `services` | Inline `_CustomerServicesView` | Live provider/profile APIs; `GET /customer/wellness-products` | Wellness catalogue is database-backed seeded demo data; laboratory/home-care and diet-plan catalogues remain unavailable until customer-safe contracts exist |
| `appointments` | Inline `_CustomerAppointmentsView` | Appointment APIs | Customer owns only self-scoped list/read/cancel/reschedule actions; provider consultation and billing workflows are backend staff-only. Booking and visit-detail screens need feature extraction/visual redesign |
| `documents` | `CustomerDocumentsScreen` | `GET /documents` | Upload/view/share and visual QA remain |
| `prescriptions` | `CustomerPrescriptionsScreen` | Customer-scoped documents | Upload/viewer/pharmacy linkage refinement remains |
| shop/cart/orders | No customer feature routes | `GET /wellness/products`, purchases API exists | Database-backed catalogue/cart/order UI missing |
| referral/activity | No dedicated customer routes | Referral tree and summary endpoints enforce customer ownership | Customer APIs and screens missing |
| `notifications` | Inline `_CustomerNotificationsView` | `GET /notifications`, `POST /notifications/mark-all-read`; read mutations are ownership-scoped | Filter/read states are live; extract from the portal shell incrementally |
| `profile`, `settings` | Inline portal views | Customer profile API/session | Family, contacts, privacy, security and support screens need extraction |

## Shared foundation

`CustomerScaffold`, `CustomerAppBar`, `CustomerBottomNavigation`, shared error/empty/loading widgets, and `CustomerDesignTokens` provide the active customer shell. Header balances are derived from the existing dashboard bundle; SHIELD benefit is never rendered as cash.

## Known blockers

- No verified customer API contract yet for full rewards, customer wellness cart/checkout, referral/activity, card lifecycle, or family/dependents.
- Operations carousel is database-backed through `commercial_settings` (`OPERATIONS_CUSTOMER_BANNERS`) and correctly renders an empty state when Operations has published no eligible banners.
- The current customer services, visits, profile, notifications, and settings implementations are embedded in the large portal shell and must be extracted incrementally to preserve behavior.
