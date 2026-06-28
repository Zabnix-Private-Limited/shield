# SHIELD Backend Domain Boundaries

Version: 2026-06-28

Grounded in:
- `backend/src/app.module.ts`
- `backend/src/auth/rbac-catalog.ts`
- `backend/src/wallet/wallet.service.ts`
- `backend/src/pricing/pricing.service.ts`
- `current_schema.md`

## Core Boundary Rules
- SHIELD is a modular monolith; domain boundaries should stay clear even though deployment is unified.
- `current_schema.md` outranks older assumptions about table shape and table existence.
- Pricing and wallet behavior must remain centralized, not reimplemented feature-by-feature.
- Service providers are a shared domain, not duplicated role-specific backoffice systems.
- Customer-visible wallet state must exclude hidden SHIELD benefit remainder.

## Domain Map

| Domain | Current Module(s) | Owns | Must Not Own |
| --- | --- | --- | --- |
| Auth and access control | `auth` | login, token verification, current principal, RBAC role catalog, permission scope | pricing rules, wallet math, customer business logic |
| Customer | `customer` | customer profile, onboarding, approval lifecycle, status changes, self profile | wallet ledger math, pricing calculations |
| Membership | customer + dashboard + schema-owned membership tables today | `memberships`, `membership_types`, `shield_cards` lifecycle | provider-specific workflow branching |
| Wallet | `wallet` | ledger writes, wallet summary, transaction history, reward-point redemption mechanics | service pricing policy, customer-facing hidden-benefit exposure |
| Pricing / commercial engine | `pricing` | service benefit rules, reward point rules, redemption rules, commercial settings, pricing audits | direct UI concerns, per-feature pricing forks |
| Master data | `master-data` | centralized read-first access to existing master tables and derived type catalogs | workflow execution logic, transactional writes in unrelated domains |
| Credit | `credit` | credit account read/approval workflows | wallet ledger internals |
| Appointment scheduling | `appointment` | appointment CRUD, status changes | clinical report storage, wallet pricing policy |
| Documents and medical records | `document`, `storage` | file intake, storage, extraction, validation, prescription-intelligence workflow | CRM outreach logic, wallet logic |
| Notifications | `notification` | notification delivery, device tokens, send/read flows | business rule decisions for why something happened |
| CRM and support | `crm`, `support` | activities, tasks, complaints, contact and feedback flows | membership pricing, provider billing |
| Pharmacy and service execution | `pharmacy` | product lookup, purchase posting, provider-side billing flow | pricing policy definition, wallet balance source of truth |
| Referral lifecycle | `referral` | referral tree, reward event progression, qualification and reward status | direct reward-point rule ownership |
| Reporting and dashboard | `dashboard` | aggregated role views and reporting surfaces | canonical operational writes |
| Infrastructure | `prisma`, `redis` | database and cache plumbing | business decisions |

## Database Alignment Notes

| Area | Live Shape | Boundary Decision |
| --- | --- | --- |
| Wallet runtime | `cash_wallet_transactions`, `reward_point_transactions`, `benefit_ledger_transactions` | These are the runtime source of truth for ledger behavior |
| Pricing audit | `pricing_rule_audits` | Pricing owns write semantics; others consume read views only |
| Reward config | `reward_point_rules`, `reward_redemption_rules` | Pricing owns configuration and interpretation |
| Commercial toggles | `commercial_settings` | Pricing owns preload and similar commercial switches |
| Legacy wallet table | `wallet_transactions` still exists in schema snapshot | Treat as legacy/coexistence surface; do not re-center new runtime logic on it |

## Role Taxonomy Boundary
- Backend RBAC roles are the authoritative access taxonomy.
- Frontend portal roles are a condensed shell taxonomy for current navigation.
- Any future split of frontend shells should be driven by backend permission or workflow pressure, not by aesthetic duplication.

## Freeze Guidance For Next Implementation Order
- `master-data` should build on centralized owners listed above.
- `business-process-engine` should orchestrate existing domains rather than absorb their logic.
- `rule-engine` should extend pricing/commercial ownership, not compete with it.
- `timeline`, `document-center`, `notification-center`, `activity/audit`, `dashboard/report`, and `search` should consume domain outputs without taking over their write paths.
