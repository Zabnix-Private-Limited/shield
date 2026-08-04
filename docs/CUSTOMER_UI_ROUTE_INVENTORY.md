# Customer UI Route Inventory

## Auth

| Route | Screen | Access |
|---|---|---|
| `/customer/splash` | Session resolver | Public |
| `/customer/login` | Phone sign-in | Public |
| `/customer/otp` | OTP verification | Public |
| `/customer/register` | Customer registration | Verified phone only |

## Authenticated portal

Customer portal routes are rendered by `/portal/customer/:section` and guarded by the customer session.

| Section | Current implementation | Status |
|---|---|---|
| dashboard | `CustomerDashboardScreen` | API-backed |
| wallet | `CustomerWalletScreen` | API-backed |
| membership | `CustomerMembershipScreen` | API-backed |
| documents | `CustomerDocumentsScreen` | API-backed |
| prescriptions | `CustomerPrescriptionsScreen` | API-backed |
| services, appointments, profile, notifications, settings | Portal-shell customer views | Extract during redesign |
| recharge, book-appointment | Registered metadata sections | Workflow review required |

The five bottom-navigation destinations remain dashboard, wallet, services, appointments, and profile.
