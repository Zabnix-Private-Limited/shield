# SHIELD Schema Alignment Report
Date: 2026-07-07
Repository: `E:\K4NN4N\shield`
Authoritative schema: `current_schema.md`
Compared against: `backend/prisma/schema.prisma`, backend service usage, frontend display assumptions

## Verdict

The schema situation is structurally better than expected: `current_schema.md` lists 52 tables and Prisma exposes 52 models mapped to those same table families.

That does not mean schema alignment is complete.

The main risk is not missing whole tables. The main risk is invariant drift: wallet ledger semantics, hidden benefit visibility, branch-restricted SHIELD card usage, referral reward timing, soft delete behavior, audit immutability, and approval workflows must be enforced consistently by backend services, DTOs, and tests.

Schema alignment score: 78 / 100 structurally, 61 / 100 for invariant proof.

## Table and Model Count

| Source | Count | Status |
| --- | ---: | --- |
| `current_schema.md` `CREATE TABLE` entries | 52 | Current database truth |
| Prisma `model` entries | 52 | Structurally aligned by count |

## Current Schema Tables

| Table | Prisma model | Domain |
| --- | --- | --- |
| `appointments` | `Appointment` | Appointments/visits |
| `audit_logs` | `AuditLog` | Audit |
| `auth_devices` | `AuthDevice` | Auth/session security |
| `auth_sessions` | `AuthSession` | Auth/session security |
| `benefit_ledger_transactions` | `BenefitLedgerTransaction` | Hidden SHIELD benefit ledger |
| `businesses` | `Business` | Branch/business registry |
| `cash_wallet_transactions` | `CashWalletTransaction` | Cash wallet ledger |
| `commercial_settings` | `CommercialSetting` | Pricing/settings |
| `complaints` | `Complaint` | Support/complaints |
| `consultations` | `Consultation` | Visit consultation |
| `credit_accounts` | `CreditAccount` | Credit |
| `credit_transactions` | `CreditTransaction` | Credit |
| `crm_activities` | `CrmActivity` | CRM |
| `crm_tasks` | `CrmTask` | CRM/follow-ups |
| `customer_contacts` | `CustomerContact` | Customer contacts |
| `customer_status_history` | `CustomerStatusHistory` | Customer lifecycle |
| `customers` | `Customer` | Customer master |
| `dental_records` | `DentalRecord` | Clinical records |
| `departments` | `Department` | Organization/provider type |
| `device_push_tokens` | `DevicePushToken` | Push notifications |
| `document_classifications` | `DocumentClassification` | Document intelligence |
| `document_extractions` | `DocumentExtraction` | Document intelligence |
| `document_processing_logs` | `DocumentProcessingLog` | Document intelligence |
| `documents` | `Document` | Documents/storage |
| `lab_reports` | `LabReport` | Lab records |
| `login_history` | `LoginHistory` | Auth audit |
| `membership_types` | `MembershipType` | Membership plans |
| `memberships` | `Membership` | Customer memberships |
| `notifications` | `Notification` | Notification center |
| `permissions` | `Permission` | RBAC |
| `prescriptions` | `Prescription` | Prescriptions |
| `pricing_rule_audits` | `PricingRuleAudit` | Pricing traceability |
| `product_categories` | `ProductCategory` | Pharmacy catalog |
| `products` | `Product` | Pharmacy catalog |
| `agent_preferences` | `AgentPreference` | Agent settings/preferences |
| `agent_branch_assignments` | `AgentBranchAssignment` | Agent branch scope |
| `provider_profile_branch_assignments` | `ProviderProfileBranchAssignment` | Provider branch scope |
| `provider_profiles` | `ProviderProfile` | Provider profile |
| `purchase_items` | `PurchaseItem` | Pharmacy purchases |
| `purchases` | `Purchase` | Pharmacy purchases |
| `referral_reward_events` | `ReferralRewardEvent` | Referral lifecycle |
| `reward_point_rules` | `RewardPointRule` | Rewards |
| `reward_point_transactions` | `RewardPointTransaction` | Reward ledger |
| `reward_redemption_rules` | `RewardRedemptionRule` | Rewards |
| `role_permissions` | `RolePermission` | RBAC |
| `roles` | `Role` | RBAC |
| `service_benefit_rules` | `ServiceBenefitRule` | Benefits/pricing |
| `service_providers` | `ServiceProvider` | Provider organization |
| `shield_cards` | `ShieldCard` | Card usage/branch restriction |
| `users` | `User` | Internal users/staff |
| `wallet_transactions` | `WalletTransaction` | Generic/legacy wallet transactions |
| `wallets` | `Wallet` | Wallet identity/status |

## Structural Alignment

| Domain | Alignment status | Notes |
| --- | --- | --- |
| Customers | Aligned | Customer, contacts, status history, memberships, card, wallet relations exist. |
| Wallet | Mixed | All ledger tables exist, but generic `wallet_transactions` remains alongside typed ledger tables. |
| Membership | Aligned structurally | Lifecycle/business rules need service/test proof. |
| Providers | Aligned structurally | Provider profile and branch assignments exist. |
| Agents | Aligned structurally | Preferences and branch assignments exist. |
| Documents | Aligned structurally | Classification, extraction, processing logs, documents exist. |
| Appointments/consultations | Aligned structurally | Appointment and consultation models exist. |
| Prescriptions/lab/dental | Aligned structurally | Domain record models exist. |
| Pricing/rewards/referrals | Aligned structurally | Rules, audits, referral events, reward transactions exist. |
| Auth/RBAC | Aligned structurally | Users, roles, permissions, role_permissions, auth sessions/devices, login history exist. |
| Notifications | Aligned structurally | Notifications and device push tokens exist. |
| Audit | Aligned structurally | `audit_logs` exists. |

## Critical Invariants From `current_schema.md`

| Invariant | Current implementation signal | Risk | Required proof |
| --- | --- | --- | --- |
| Wallet balances must be calculated from ledger rows, not stored balances. | `WalletService` and `PricingService` calculate from transaction rows. | Good direction, but legacy table fallback may confuse canonical source. | Unit tests for cash/reward/benefit balances and no stored balance usage. |
| `SHIELD_BENEFIT` is hidden company-funded credit and must not be shown as customer balance. | Customer wallet UI hides benefit from visible balance and filters recent entries. | Any endpoint/UI can regress. | Contract tests and widget tests for hidden benefit visibility. |
| `wallet_transactions.sub_ledger_type` separates `CASH`, `REWARD_POINTS`, `SHIELD_BENEFIT`. | Prisma maps `sub_ledger_type`; backend references it. | Generic table plus typed tables creates dual-source risk. | Document canonical write/read policy and enforce it. |
| `wallet_transactions.is_customer_visible` must be honored. | Schema has column; frontend filters benefit. | Backend should not rely only on frontend filtering. | Backend DTO tests. |
| SHIELD cards must enforce branch restriction using `issued_business_id`. | Schema has `issued_business_id`; Prisma maps it. | Enforcement path must be proven in service logic. | Negative tests for cross-branch utilization. |
| Referral rewards are delayed and status-driven. | `ReferralService` uses `PENDING`, `VERIFIED`, `QUALIFIED`, `REWARDED`, `REJECTED`. | Good, but must be protected from shortcut credits. | Lifecycle tests from registration to reward/reject. |
| Audit logs are append-only. | `audit_logs` table exists and admin customer actions record audit. | Not universal across mutations. | Mutation pipeline tests requiring audit rows. |
| Soft delete support exists where schema supports `deleted_at`. | Table-level support appears in schema families. | Service delete methods may hard-delete in some areas. | Audit every `delete` call and replace with soft delete where required. |

## Wallet Alignment Details

Current schema wallet tables:

| Table | Purpose | Production concern |
| --- | --- | --- |
| `wallets` | Wallet identity/status for customer. | Should not store spendable balances. |
| `cash_wallet_transactions` | Cash ledger. | Must be append-only and auditable. |
| `reward_point_transactions` | Reward point ledger. | Must not be confused with cash. |
| `benefit_ledger_transactions` | Internal SHIELD benefit support. | Hidden from customer balance. |
| `wallet_transactions` | Generic ledger/legacy compatibility. | Dangerous unless canonical policy is explicit. |
| `pricing_rule_audits` | Final payable audit evidence. | Must be mandatory on billing flows. |

### Wallet Mismatch/Risk List

| Risk | Type | Recommendation |
| --- | --- | --- |
| Typed ledger tables and generic wallet table coexist. | Design ambiguity | Define canonical transaction source per domain and add tests. |
| Benefit ledger can be calculated but should not be exposed as customer balance. | Visibility invariant | Enforce at backend response layer and frontend tests. |
| `is_customer_visible` should be applied server-side. | API invariant | Filter customer wallet responses in backend before DTO return. |
| Branch restrictions must use `shield_cards.issued_business_id`. | Business invariant | Add service-level guard and negative tests. |

## Document Alignment Details

Current schema supports:

| Table | Flow role |
| --- | --- |
| `documents` | Stored file metadata and ownership |
| `document_classifications` | Type/classification output |
| `document_extractions` | OCR/AI extracted data |
| `document_processing_logs` | Processing history |
| `prescriptions` | Prescription records linked to customer/provider/document |
| `lab_reports` | Lab report records |
| `dental_records` | Dental record records |

### Document Risks

| Risk | Recommendation |
| --- | --- |
| Approval/rejection audit is not proven for every document mutation. | Require audit row for status changes. |
| File security constraints are not visible in schema comparison. | Enforce MIME, size, virus scan/future classification policy in service. |
| Document intelligence retries need durable status model. | Use processing logs and explicit retry state. |

## Auth/RBAC Alignment Details

Current schema supports:

| Table | Role |
| --- | --- |
| `users` | Internal users/staff/providers/admins |
| `roles` | Role definitions |
| `permissions` | Permission catalog |
| `role_permissions` | Role-permission relation |
| `auth_sessions` | Persistent SHIELD sessions |
| `auth_devices` | Device/session security |
| `login_history` | Login audit |
| `agent_branch_assignments` | Agent scope |
| `provider_profile_branch_assignments` | Provider scope |

### RBAC/ABAC Risks

| Risk | Recommendation |
| --- | --- |
| Permission checks exist, but scope checks must be proven per endpoint. | Add ABAC negative tests for agent/provider/customer boundaries. |
| Branch scope uses multiple sources (`users.branch_business_id`, branch assignment tables). | Define precedence and enforce consistently. |
| Raw permission keys can leak to UI. | Return user-friendly denial text while logging exact keys server-side. |

## Soft Delete and Delete Behavior

The schema rules require soft delete support. Backend services must be audited for direct `delete` calls.

Known risk signal:

| Area | Risk |
| --- | --- |
| Service provider removal | Search evidence shows `prisma.serviceProvider.delete`. This should be checked against `current_schema.md` soft delete expectations. |
| Other domain removes | Need project-wide audit of `.delete(` and `.deleteMany(`. |

Recommendation:

1. Add a schema invariant test that lists all soft-delete tables.
2. Add a static check that blocks hard delete on soft-delete tables.
3. Require audit reason for all soft deletes.

## Schema Drift Automation Needed

Manual alignment is not enough. Add a CI script that:

1. Parses `current_schema.md` table names, columns, indexes, and constraints.
2. Parses Prisma model names, mapped table names, mapped columns, relations, indexes, and constraints.
3. Fails on missing/extra tables or columns unless explicitly waived.
4. Flags type mismatches.
5. Flags nullable/default mismatches.
6. Flags missing unique/index definitions.
7. Flags schema invariants that Prisma cannot encode directly.

## Schema Alignment Conclusion

SHIELD has a broad, mostly aligned data model. The production problem is not table absence; it is invariant enforcement. Treat `current_schema.md` as the contract, Prisma as an implementation detail, and backend services/tests as the enforcement layer.

