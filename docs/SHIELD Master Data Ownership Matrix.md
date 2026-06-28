# SHIELD Master Data Ownership Matrix

Version: 2026-06-28

Grounded in:
- `current_schema.md`
- `backend/src/app.module.ts`
- `backend/src/pricing/pricing.service.ts`
- `backend/src/wallet/wallet.service.ts`
- `backend/src/auth/rbac-catalog.ts`

## Ownership Rules
- `current_schema.md` is the live source of truth for master-data table existence.
- Service providers remain a centralized domain; do not duplicate provider masters per portal.
- Pricing, benefits, reward earning, reward redemption, and preload behavior stay centralized in pricing/commercial control data.
- Wallet balances are operationally derived data, not master data.
- The first backend operations-layer increment is the read-first `master-data` module, which exposes only table-backed masters and clearly marks planned gaps instead of inventing them.

## Matrix

| Master Data Area | Live Tables | Owning Domain | Primary Maintainers | Notes |
| --- | --- | --- | --- | --- |
| Roles | `roles`, `permissions`, `role_permissions` | Auth | Super Admin | Backend RBAC truth is richer than current frontend shell roles |
| Users and staff identity | `users` | Auth | Super Admin | Includes `role_id`, `department_id`, `branch_business_id`, auth-provider state |
| Businesses and branches | `businesses` | Admin / org setup | Super Admin | Branch identity anchor for operational scoping |
| Departments | `departments` | Admin / org setup | Super Admin | Staff and business grouping master |
| Service providers | `service_providers` | Centralized provider domain | Super Admin, provider admins later | Must not be split into duplicated per-role CRUD islands |
| Membership plan types | `membership_types` | Membership | Super Admin, central ops | Fee, discount, credit eligibility master |
| Service commercial rules | `service_benefit_rules` | Pricing | Super Admin, commercial admins later | Service type is the unique rule key |
| Reward earning rules | `reward_point_rules` | Pricing | Super Admin, commercial admins later | Action-code driven reward master |
| Reward redemption rules | `reward_redemption_rules` | Pricing | Super Admin, commercial admins later | Controls points-to-credit conversion |
| Commercial settings | `commercial_settings` | Pricing | Super Admin, commercial admins later | Preload and other commercial toggles belong here |
| Products | `products`, `product_categories` | Pharmacy / catalog | Pharmacy operations, catalog admins later | Central product master reused by pharmacy workflows |
| Membership instances | `memberships`, `shield_cards` | Membership operations | SHIELD Executive, Manager | Transactional records derived from membership masters |
| Customer records | `customers`, `customer_contacts`, `customer_status_history` | Customer domain | SHIELD Agent, CRM, SHIELD Executive | Core entity, not master-data setup |
| Notification templates and config | No dedicated template table yet; runtime uses notification/system config surfaces | Notification / system config | Super Admin | Treat as pending control area, not ad hoc per-feature config |

## What Is Not Master Data

| Area | Why |
| --- | --- |
| `wallets` | Account instance per customer, not reusable reference data |
| `cash_wallet_transactions`, `reward_point_transactions`, `benefit_ledger_transactions` | Immutable operational ledgers |
| `pricing_rule_audits` | Immutable audit trail of applied pricing decisions |
| `appointments`, `consultations`, `documents`, `notifications`, `purchases`, `purchase_items`, `crm_tasks`, `crm_activities`, `complaints` | Operational workflow records |
| `referral_reward_events` | Lifecycle event stream, not reference data |

## Freeze Guidance
- Future admin UI work should target these ownership boundaries instead of inventing feature-local settings tables.
- If a new configurable business rule affects price, preload, benefit, or reward behavior, it should land in pricing-owned control data first.
