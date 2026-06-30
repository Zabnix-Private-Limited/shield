# SHIELD Complete Route Map

Version: 2026-06-28

Grounded in:
- `frontend/lib/app/routes/app_router.dart`
- `backend/src/main.ts`
- `backend/src/auth/shield-jwt-auth.guard.ts`
- `backend/src/*/*.controller.ts`

## Routing Baseline
- Frontend uses GoRouter.
- Backend currently has no global API prefix in `main.ts`; routes are mounted from controller paths directly.
- CORS is enabled for local Flutter web origins and standard auth/trace headers.
- Development-only localhost auth fallback exists in the JWT guard for customer-facing route prefixes only.

## Frontend Route Map

| Route | Type | Target |
| --- | --- | --- |
| `/` | Redirect | `/customer/splash` |
| `/customer/splash` | Live route | Customer splash/session restore |
| `/customer/login` | Live route | Customer OTP login |
| `/customer/otp` | Live route | Customer OTP verification |
| `/customer/register` | Live route | Customer registration |
| `/internal/login` | Live route | Internal Google sign-in |
| `/portal/:role` | Redirect | `/portal/:role/dashboard` |
| `/portal/:role/:section` | Live route | Portal shell |
| `/documents` | Redirect | `/portal/customer/documents` |
| `/appointments` | Redirect | `/portal/customer/appointments` |
| `/notifications` | Redirect | `/portal/customer/notifications` |
| `/prescriptions` | Redirect | `/portal/customer/prescriptions` |
| `/membership` | Redirect | `/portal/customer/membership` |
| `/transactions` | Redirect | `/portal/customer/wallet` |
| `/settings` | Redirect | `/portal/customer/settings` |
| `/services` | Redirect | `/portal/customer/services` |
| `/wallet` | Redirect | `/portal/customer/wallet` |
| `/profile` | Redirect | `/portal/customer/profile` |
| `/more` | Redirect | `/portal/customer/dashboard` |

## Backend Route Map

### Core

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/` | Public app root |
| GET | `/health` | Public health check |

### Auth

| Method | Path | Permission / Access |
| --- | --- | --- |
| POST | `/auth/customer/login` | Public login |
| POST | `/auth/internal/login` | Public login |
| POST | `/auth/refresh` | Authenticated session |
| POST | `/auth/logout` | Authenticated session |
| GET | `/auth/me` | Authenticated session |

### Customers

| Method | Path | Permission |
| --- | --- | --- |
| POST | `/customers` | `customers.create` |
| GET | `/customers/search` | `customers.view` |
| GET | `/customers/me` | `customers.view` |
| GET | `/customers/:id` | `customers.view` |
| PUT | `/customers/:id` | `customers.update` |
| POST | `/customers/:id/approve` | `customers.approve` |
| POST | `/customers/:id/suspend` | `customers.approve` |

### Wallets

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/wallets/:customerId` | `wallet.view` |
| POST | `/wallets/recharge` | `wallet.update` |
| POST | `/wallets/adjustments` | `wallet.update` |
| GET | `/wallets/:id/transactions` | `wallet.view` |
| POST | `/wallets/redeem-points` | `wallet.update` |

### Pricing and commercial controls

| Method | Path | Permission |
| --- | --- | --- |
| POST | `/pricing/evaluate` | `analytics.view` |
| GET | `/pricing/admin/config` | `settings.view` |
| GET | `/pricing/admin/audits` | `analytics.view` |
| POST | `/pricing/admin/service-rules` | `settings.update` |
| POST | `/pricing/admin/reward-rules` | `settings.update` |
| POST | `/pricing/admin/redemption-rules` | `settings.update` |
| POST | `/pricing/admin/settings` | `settings.update` |

### Master data

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/master-data/admin/catalog` | `settings.view` |
| GET | `/master-data/admin/bootstrap` | `settings.view` |
| GET | `/master-data/admin/:domain` | `settings.view` |

### Appointments

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/appointments` | `appointments.view` |
| POST | `/appointments` | `appointments.create` |
| GET | `/appointments/:id` | `appointments.view` |
| POST | `/appointments/:id/cancel` | `appointments.delete` |
| POST | `/appointments/:id/confirm` | `appointments.update` |

### Documents and document intelligence

| Method | Path | Permission |
| --- | --- | --- |
| POST | `/documents/upload` | `documents.create` |
| GET | `/documents` | `documents.view` |
| GET | `/documents/:id` | `documents.view` |
| GET | `/documents/:id/download` | `documents.view` |
| DELETE | `/documents/:id` | `documents.delete` |
| POST | `/document-intelligence/classify` | `documents.approve` |
| POST | `/document-intelligence/extract` | `documents.view` |
| POST | `/document-intelligence/validate` | `documents.view` |
| GET | `/document-intelligence/prescription-review/:documentId` | `medical_records.view` |
| POST | `/document-intelligence/prescription-review/:documentId/approve` | `medical_records.approve` |
| GET | `/document-intelligence/logs/:documentId` | `documents.view` |

### Notifications

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/notifications` | `notifications.view` |
| POST | `/notifications/:id/read` | `notifications.view` |
| POST | `/notifications/device-token` | `notifications.create` |
| POST | `/notifications/device-token/deactivate` | `notifications.update` |
| POST | `/notifications/send` | `notifications.create` |

### Dashboard

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/dashboard/customer` | `analytics.view` |
| GET | `/dashboard/staff` | `analytics.view` |
| GET | `/dashboard/crm` | `analytics.view` |
| GET | `/dashboard/management` | `analytics.view` |
| GET | `/dashboard/role/:role/:section` | `analytics.view` |

### Credit

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/credit/accounts/:id` | `wallet.view` |
| GET | `/credit/accounts/:id/transactions` | `wallet.view` |
| POST | `/credit/accounts/:id/approve` | `wallet.approve` |

### CRM

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/crm/activities` | `crm.view` |
| POST | `/crm/activities` | `crm.create` |
| GET | `/crm/tasks` | `crm.view` |
| POST | `/crm/tasks` | `crm.create` |
| PUT | `/crm/tasks/:id` | `crm.update` |
| GET | `/crm/complaints` | `crm.view` |
| POST | `/complaints` | `crm.create` |
| PUT | `/complaints/:id` | `crm.update` |
| POST | `/complaints/:id/resolve` | `crm.update` |

### Pharmacy

| Method | Path | Permission |
| --- | --- | --- |
| POST | `/products` | `providers.update` |
| GET | `/products/search` | `providers.view` |
| GET | `/products/:id` | `providers.view` |
| POST | `/pharmacy/purchases` | `providers.create` |
| GET | `/pharmacy/purchases` | `providers.view` |

### Referrals

| Method | Path | Permission |
| --- | --- | --- |
| GET | `/referrals/tree/:customerId` | `referrals.view` |
| GET | `/referrals/summary/:customerId` | `referrals.view` |
| POST | `/referrals/qualify` | `referrals.approve` |

### Support

| Method | Path | Permission / Access |
| --- | --- | --- |
| POST | `/support/contact` | Support flow |
| POST | `/support/feedback` | Support flow |

## Development Auth Bridge

The current JWT guard allows a development-only localhost fallback principal when no Bearer token is present and the request path starts with one of these prefixes:
- `/customers/`
- `/wallets/`
- `/appointments`
- `/documents`
- `/notifications`

That bridge is intentionally pinned to customer `1` and is not the final production auth model.
