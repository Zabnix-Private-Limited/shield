# SHIELD Portal Navigation Map

Version: 2026-06-28

Grounded in:
- `current_schema.md` as the live database truth source
- `frontend/lib/app/routes/app_router.dart`
- `frontend/lib/features/portal/presentation/portal_role_data.dart`
- `backend/src/auth/rbac-catalog.ts`

## Freeze Decisions
- Customer experience remains portal-only, mobile-first, and effectively mobile-shaped even on desktop widths.
- Internal portals are desktop-first workspaces with persistent sidebar navigation and denser operational layouts.
- Customer and internal portals intentionally do not share the same navigation behavior or screen-density rules.
- Internal portals should inherit one reusable enterprise workspace shell: compact operations strip, KPI row, 70/30 work-vs-utility body, and lower analytics/table region.
- Canonical customer URLs stay under `/portal/customer/...`.
- The live frontend route contract is role-and-section based: `/portal/:role/:section`.
- Old standalone customer paths remain redirects only; no new standalone customer screens should be introduced.
- Frontend portal roles are a presentation shell taxonomy, not yet the final backend RBAC taxonomy.

## Canonical Frontend Entry

| Route | Behavior | Notes |
| --- | --- | --- |
| `/` | Redirects to `/portal/customer/dashboard` | Current app entry |
| `/portal/:role` | Redirects to `/portal/:role/dashboard` | Role shell bootstrap |
| `/portal/:role/:section` | Live portal screen route | Main route contract |

## Legacy Redirects Kept For Compatibility

| Legacy Route | Redirect Target |
| --- | --- |
| `/documents` | `/portal/customer/documents` |
| `/appointments` | `/portal/customer/appointments` |
| `/notifications` | `/portal/customer/notifications` |
| `/prescriptions` | `/portal/customer/prescriptions` |
| `/membership` | `/portal/customer/membership` |
| `/transactions` | `/portal/customer/wallet` |
| `/settings` | `/portal/customer/settings` |
| `/services` | `/portal/customer/services` |
| `/wallet` | `/portal/customer/wallet` |
| `/profile` | `/portal/customer/profile` |
| `/more` | `/portal/customer/dashboard` |

## Live Frontend Portal Roles

| Frontend Role | Route Key | Current Purpose | Backend RBAC Alignment |
| --- | --- | --- | --- |
| Customer | `customer` | Self-service member portal | `CUSTOMER` |
| Pharmacy Staff | `pharmacy-staff` | Pharmacy counter and billing shell | Closest to `PHARMACY_PROVIDER` |
| Clinic Staff | `clinic-staff` | General clinic and consultation shell | Currently aggregates `DOCTOR`, `LAB_PROVIDER`, `HOMECARE_PROVIDER`, `COSMETIC_PROVIDER`, `DIETITIAN` concerns |
| Dental Staff | `dental-staff` | Dental workflow shell | Closest to `DENTAL_PROVIDER` |
| CRM Executive | `crm-executive` | Follow-up and complaint shell | `CRM_EXECUTIVE` |
| SHIELD Executive | `shield-executive` | Central operations shell | Closest to `SHIELD_AGENT` plus central ops responsibilities |
| Manager | `manager` | Approval and oversight shell | No single exact backend role today; managerial overlay on operational roles |
| Super Admin | `super-admin` | Platform administration shell | Closest to `ADMIN` |

## Live Section Map By Frontend Role

| Frontend Role | Sections |
| --- | --- |
| Customer | `dashboard`, `wallet`, `services`, `appointments`, `documents`, `profile`, `membership`, `prescriptions`, `recharge`, `book-appointment`, `settings`, `notifications` |
| Pharmacy Staff | `dashboard`, `customers`, `verification`, `bills`, `prescriptions`, `qr-scan`, `history` |
| Clinic Staff | `dashboard`, `patients`, `appointments`, `consultations`, `reports`, `home-visits` |
| Dental Staff | `dashboard`, `patients`, `appointments`, `treatments`, `reports`, `history` |
| CRM Executive | `dashboard`, `customers`, `tasks`, `follow-ups`, `complaints`, `campaigns` |
| SHIELD Executive | `dashboard`, `approvals`, `memberships`, `wallet-ops`, `reversals`, `support` |
| Manager | `dashboard`, `approvals`, `reports`, `analytics`, `credit`, `retention` |
| Super Admin | `dashboard`, `users`, `roles`, `businesses`, `audit`, `system`, `membership-plans`, `reports`, `notification-center` |

## Navigation Guardrails
- New customer work should map into existing customer section keys before any new route is considered.
- New provider or admin work should prefer adding section content under the current shell route shape instead of inventing parallel router trees.
- Internal workflow portals should optimize for keyboard, mouse, search, dense lists/tables, and persistent navigation before visual flourish.
- New internal portal screens should inherit the shared workspace structure before adding role-specific variations.
- Backend RBAC expansion can continue independently, but frontend portal shells should only split further when a real workflow or access-control conflict demands it.
