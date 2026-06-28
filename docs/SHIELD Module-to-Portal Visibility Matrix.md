# SHIELD Module-to-Portal Visibility Matrix

Version: 2026-06-28

Legend:
- `Primary`: direct working surface in the current portal shell
- `Secondary`: visible as supporting context or read-only dependency
- `Hidden`: backend exists or may exist, but should not surface directly in that portal
- `Future`: intended later but not yet a live first-class surface

## Matrix

| Module / Domain | Customer | Pharmacy Staff | Clinic Staff | Dental Staff | CRM Executive | SHIELD Executive | Manager | Super Admin |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Customer profile | Primary | Primary | Primary | Primary | Primary | Primary | Secondary | Secondary |
| Membership and card | Primary | Secondary | Secondary | Secondary | Secondary | Primary | Secondary | Primary |
| Wallet cash and points | Primary | Secondary | Secondary | Hidden | Secondary | Primary | Secondary | Secondary |
| Hidden benefit ledger | Hidden | Hidden | Hidden | Hidden | Hidden | Secondary | Secondary | Secondary |
| Credit accounts | Secondary | Hidden | Hidden | Hidden | Hidden | Secondary | Primary | Secondary |
| Appointments | Primary | Secondary | Primary | Primary | Secondary | Secondary | Secondary | Hidden |
| Consultations and clinical notes | Hidden | Hidden | Primary | Secondary | Hidden | Hidden | Secondary | Hidden |
| Dental treatments and history | Hidden | Hidden | Hidden | Primary | Hidden | Hidden | Secondary | Hidden |
| Documents and medical records | Primary | Primary | Primary | Primary | Secondary | Secondary | Secondary | Secondary |
| Notifications | Primary | Secondary | Secondary | Secondary | Secondary | Secondary | Secondary | Primary |
| Referral graph and rewards | Primary | Hidden | Hidden | Hidden | Secondary | Secondary | Secondary | Hidden |
| CRM tasks and follow-ups | Hidden | Hidden | Hidden | Hidden | Primary | Secondary | Secondary | Hidden |
| Complaints and support cases | Secondary | Hidden | Hidden | Hidden | Primary | Primary | Secondary | Secondary |
| Pharmacy billing and purchase posting | Hidden | Primary | Hidden | Hidden | Hidden | Secondary | Secondary | Hidden |
| Pricing and commercial controls | Hidden | Hidden | Hidden | Hidden | Hidden | Secondary | Secondary | Primary |
| Audit logs | Hidden | Hidden | Hidden | Hidden | Hidden | Secondary | Secondary | Primary |
| Org setup: users, roles, businesses, departments, providers | Hidden | Hidden | Hidden | Hidden | Hidden | Hidden | Secondary | Primary |
| Reporting and analytics | Hidden | Secondary | Secondary | Secondary | Secondary | Secondary | Primary | Primary |

## Freeze Notes
- Customer-facing visibility must stay constrained to customer-safe data: no hidden benefit balance exposure.
- Provider shells should operate against centralized masters and operational APIs, not their own copied admin systems.
- Management and super-admin portals are the only valid homes for cross-cutting configuration and governance surfaces.
