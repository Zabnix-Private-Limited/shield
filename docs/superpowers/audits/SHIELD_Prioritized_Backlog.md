# SHIELD Prioritized Backlog
Date: 2026-07-07
Repository: `E:\K4NN4N\shield`
Basis: production readiness audit, schema alignment, frontend/backend health, previous UI/UX audit

## Backlog Rules

- `current_schema.md` remains the database source of truth.
- Do not add mock/prototype data to production-facing flows.
- Do not bypass repositories, runtime contracts, RBAC, audit, or ledger rules.
- Do not expand the portal shell as the main UI owner.
- Do not expose `SHIELD_BENEFIT` as customer spendable wallet balance.
- Do not run Prisma schema application as part of normal builds.

## Critical Backlog

| ID | Item | Why it is critical | Estimate | Dependencies |
| --- | --- | --- | --- | --- |
| C1 | Add Prisma vs `current_schema.md` drift check in CI. | Prevents silent schema mismatch and invented database assumptions. | 2-4 days | Parser/script plus CI job |
| C2 | Add wallet ledger invariant tests. | Financial trust depends on no stored balance, no hidden benefit exposure, no overdraft, no ledger mixing. | 4-7 days | Wallet service fixtures |
| C3 | Define canonical wallet transaction source policy. | Typed ledger tables and generic `wallet_transactions` coexist. | 2-3 days | Schema report decisions |
| C4 | Enforce hidden benefit visibility at backend DTO layer. | Frontend filtering is not enough for financial privacy. | 2-4 days | Wallet response DTOs |
| C5 | Add pricing/final payable test suite. | Benefit, membership discount, reward redemption, and final payable must be deterministic. | 4-7 days | Pricing fixtures |
| C6 | Add referral lifecycle tests. | Rewards must remain delayed and status-driven. | 3-5 days | Wallet/reward fixtures |
| C7 | Add RBAC/ABAC negative endpoint tests. | Agents/providers must not cross customer, branch, or provider scope. | 5-10 days | Auth fixtures |
| C8 | Add global backend validation pipe and DTO validation. | Prevents malformed mutation payloads reaching services. | 3-6 days | DTO definitions |
| C9 | Add rate limiting and security headers. | Required for auth, OTP, upload, wallet, support, reports, and public endpoints. | 2-4 days | Nest middleware/throttler |
| C10 | Centralize mutation pipeline: validate, authorize, execute, audit, notify, refresh. | Production workflows need consistent side effects. | 7-14 days | Command/action metadata |
| C11 | Audit and replace hard deletes on soft-delete tables. | `current_schema.md` requires soft delete support. | 3-6 days | Table soft-delete matrix |
| C12 | Enforce `shield_cards.issued_business_id` branch restriction. | Card utilization rules are business-critical. | 3-5 days | Pricing/wallet/card service integration |
| C13 | Add full CI gate for backend build/tests and frontend analyze/tests/goldens. | Production cannot rely on manual confidence. | 2-5 days | CI runner setup |

## High Backlog

| ID | Item | Why it matters | Estimate | Dependencies |
| --- | --- | --- | --- | --- |
| H1 | Split `admin-governance.service.ts` by workspace domain. | Prevent backend-driven UI service from becoming a monolith. | 5-10 days | Existing workspace contract tests |
| H2 | Finish portal shell slimming. | Shell still imports and branches over too many role screens. | 5-10 days | Role runtime adapters |
| H3 | Make admin wallet workspace ledger-first with full action workflow. | Wallet is trust-critical and cannot be generic table-only. | 4-8 days | C2-C4 |
| H4 | Make admin CRM queue-first. | CRM as generic records is operationally weak. | 4-8 days | Operations queue contracts |
| H5 | Make admin reports workflow-driven. | Reports need choose, filters, columns, preview, export, history, schedules. | 5-10 days | Platform report service |
| H6 | Make admin memberships lifecycle-first. | Renew, upgrade, freeze, cancel, benefit usage, history are core workflows. | 5-10 days | Membership service commands |
| H7 | Make admin providers approval/compliance-first. | Provider governance needs approval, documents, licenses, branch/service assignment. | 5-10 days | Provider service commands |
| H8 | Add document approval/rejection audit tests. | Document intelligence must be accountable. | 3-6 days | Document workflow DTOs |
| H9 | Add file upload size/type/security checks. | Healthcare documents are high-risk input. | 3-6 days | Storage/document service |
| H10 | Add appointment lifecycle state machine tests. | Prevent invalid status transitions. | 3-6 days | Appointment fixtures |
| H11 | Remove/gate frontend debug logging. | Production UI/runtime should not leak diagnostics. | 1-3 days | Logging utility |
| H12 | Add frontend permission-denied states and action hiding tests. | Backend is authoritative; frontend should reflect permissions safely. | 3-6 days | Admin contract fixtures |
| H13 | Expand provider customer workspace tests. | Decomposition must be protected. | 2-4 days | Provider test harness |
| H14 | Harden customer wallet UI tests for benefit invisibility. | Prevents financial trust regression. | 2-4 days | Wallet widget fixtures |

## Medium Backlog

| ID | Item | Why it matters | Estimate | Dependencies |
| --- | --- | --- | --- | --- |
| M1 | Normalize frontend copy with a shared product-language test list. | Prevents raw IDs, timestamps, and developer copy from returning. | 2-5 days | Formatter/copy registry |
| M2 | Add keyboard shortcut and focus model for admin tables. | Enterprise admin users need keyboard speed. | 3-6 days | Admin data table |
| M3 | Add URL persistence tests for admin search/filter/sort/page. | Query state should survive refresh/share. | 2-4 days | Admin workspace controller |
| M4 | Add saved views for admin runtime. | Helps operators reuse filtered workspaces. | 5-8 days | Backend saved view table or existing settings |
| M5 | Improve PWA offline read states. | Field/provider users need clear offline behavior. | 3-7 days | Cache policy |
| M6 | Design safe offline mutation outbox for non-financial actions only. | Offline writes need conflict safety. | 7-14 days | Command pipeline |
| M7 | Split agent settings into smaller owners. | Reduces screen complexity. | 3-5 days | Existing tests |
| M8 | Standardize agent list/detail/action patterns. | Brings agent closer to admin runtime quality. | 5-10 days | Shared components |
| M9 | Strengthen provider document/prescription preview UX. | Provider productivity depends on fast review. | 4-8 days | Document APIs |
| M10 | Improve customer registration step flow. | Reduces onboarding friction. | 4-8 days | Auth/register validation |
| M11 | Add monitoring dashboards and alert rules. | Sentry is not enough without operations process. | 3-7 days | Deployment environment |
| M12 | Add report/export async status UI. | Large exports need reliable feedback. | 4-8 days | Platform report service |

## Low Backlog

| ID | Item | Why it matters | Estimate | Dependencies |
| --- | --- | --- | --- | --- |
| L1 | Add visual polish pass for internal spacing/density. | Improves perceived quality after functional risks are covered. | 3-6 days | Runtime components |
| L2 | Add empty-state copy catalog. | Keeps empty states helpful and consistent. | 1-3 days | Shared UI language |
| L3 | Add chart textual alternatives. | Improves accessibility. | 2-4 days | Chart components |
| L4 | Improve customer document grouping. | Better self-service clarity. | 2-4 days | Document data |
| L5 | Improve customer membership benefit explanations. | Reduces support load. | 2-4 days | Membership data |
| L6 | Add report template descriptions. | Better operator comprehension. | 1-3 days | Reports metadata |

## Backend-Specific Next Steps

1. Add DTOs and validation for auth, wallet, appointments, documents, provider profile, admin actions.
2. Add invariant tests for wallet, pricing, referrals, card branch restrictions.
3. Add ABAC negative tests for provider/agent/customer scope.
4. Split admin governance service.
5. Centralize command audit/notification/event emission.
6. Add soft-delete enforcement.
7. Add production security middleware.

## Frontend-Specific Next Steps

1. Finish portal shell slimming.
2. Remove/gate debug logging.
3. Expand admin runtime tests for query persistence and permission-aware actions.
4. Harden wallet UI tests.
5. Normalize provider/agent list-detail patterns.
6. Add keyboard/focus behavior for admin tables.
7. Improve offline and realtime state surfaces.

## Schema-Specific Next Steps

1. Write schema drift script.
2. Add soft-delete table matrix.
3. Add canonical wallet ledger policy.
4. Add hidden benefit response contract.
5. Add branch restriction contract for SHIELD card utilization.
6. Add audit mutation requirements per table/domain.

## Recommended Execution Order

| Order | Work |
| ---: | --- |
| 1 | Schema drift check and wallet invariant tests |
| 2 | RBAC/ABAC negative tests |
| 3 | Validation, rate limiting, security headers |
| 4 | Command/audit/notification pipeline |
| 5 | Admin wallet/CRM/reports/memberships/providers workflow depth |
| 6 | Portal shell slimming |
| 7 | Provider/agent runtime normalization |
| 8 | PWA/offline and realtime resilience |
| 9 | UI polish and copy regression tests |

## Backlog Conclusion

The next milestone is not more screens. The next milestone is proof and enforcement. SHIELD should become boringly reliable in wallet, identity, document, appointment, audit, and permission behavior before expanding more product surface.

