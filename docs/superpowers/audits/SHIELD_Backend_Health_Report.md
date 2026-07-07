# SHIELD Backend Health Report
Date: 2026-07-07
Repository: `E:\K4NN4N\shield`
Scope: NestJS backend, Prisma, auth/RBAC, domain modules, wallet, documents, appointments, notifications, platform contracts
Schema authority: `current_schema.md`

## Backend Verdict

The backend is broad and materially useful. It has modules for the major SHIELD business domains, Prisma models aligned by table count with the current schema, RBAC guards, Firebase identity verification, wallet/pricing/referral logic, document intelligence, provider queues, admin workspaces, and platform capabilities.

It is not yet hardened enough for full production confidence.

Backend health score: 72 / 100

## Module Inventory

`AppModule` imports these major modules:

| Module | Purpose | Status |
| --- | --- | --- |
| `AuthModule` | Firebase verification, SHIELD JWTs, sessions, RBAC catalog, guards | Strong foundation |
| `MasterDataModule` | Catalog/bootstrap metadata | OK |
| `PlatformMetadataModule` | Backend-owned provider workspace metadata | Good direction |
| `PlatformCapabilitiesModule` | Print, reports, realtime platform services | Partial |
| `AdminGovernanceModule` | Backend-owned admin workspaces and customer command metadata | Strong but large |
| `OperationsQueueModule` | Provider/CRM/admin queues | Good direction |
| `ServiceProviderModule` | Provider management and patient workspace | Useful but large |
| `TimelineModule` | Patient/visit timeline aggregation | Good concept |
| `PrismaModule` | Database access | Core |
| `PricingModule` | Pricing, benefits, rewards, wallet evaluation | Critical foundation |
| `ReferralModule` | Delayed referral reward lifecycle | Good |
| `AgentModule` | Agent workspace/preferences/customers | Partial |
| `CustomerModule` | Customer CRUD, dashboard, membership, registration | Core |
| `WalletModule` | Customer/admin/provider wallet APIs and ledger services | Critical |
| `CreditModule` | Credit accounts/transactions | Partial |
| `AppointmentModule` | Appointments, visit workspace, prescription copy | Core |
| `DocumentModule` | Upload, classification, extraction, prescription intelligence | Core |
| `CrmModule` | CRM activities/tasks | Partial |
| `NotificationModule` | Notifications and push token paths | Partial |
| `DashboardModule` | Customer/staff dashboard data | OK |
| `PharmacyModule` | Products/purchases/provider billing support | Partial |
| `StorageModule` | R2/S3-compatible storage | Core |
| `SupportModule` | Contact/feedback/complaints | OK |
| `RedisModule` | Cache/realtime/session support | Partial |

## API Surface

The backend exposes controller paths for:

| Domain | Evidence | Status |
| --- | --- | --- |
| Admin workspaces | `@Controller('admin/workspaces')` with settings, platform, dashboard, customers, agents, CRM, visits, documents, memberships, wallet, rewards, referrals, providers, services, availability, branches, employees, roles, reports, insights, audit, notifications. | Strong breadth |
| Auth | `POST /auth/customer/login`, `/auth/customer/register`, `/auth/internal/login`, `/auth/refresh`, session endpoints. | Live |
| Wallet | `@Controller('wallets')`, customer wallet controller. | Live |
| Appointments | `@Controller('appointments')` list/create/detail/cancel/workspace flows. | Live |
| Documents | upload, list, classification, extraction, validation, prescription review. | Live |
| CRM | activities/tasks. | Partial |
| Notifications | list/read/token paths. | Partial |
| Platform | print templates/generate, reports, realtime. | Partial |
| Operations queue | provider, CRM, admin queues. | Live |

## Auth and RBAC Health

| Feature | Status | Notes |
| --- | --- | --- |
| Firebase customer phone provider requirement | Implemented in auth service. | Good. |
| Firebase internal Google provider requirement | Implemented in auth service. | Good. |
| SHIELD access token verification | `ShieldJwtAuthGuard` global guard. | Good. |
| Permission guard | `ShieldAuthorizationGuard` global guard. | Good. |
| RBAC catalog bootstrap | `AuthBootstrapService.ensureCatalog()` exists. | Good. |
| Role/permission session snapshot | Auth service merges role permissions into principal/session. | Good. |
| Agent scope service | Exists. | Needs full negative tests. |
| Provider scope service | Exists. | Needs full negative tests. |
| ABAC enforcement consistency | Partial. | Some endpoints use scope services; must be audited per endpoint. |

### Auth/RBAC Risks

| Risk | Severity | Recommendation |
| --- | --- | --- |
| Missing permission errors expose raw permission keys. | Medium | Keep backend precise, but frontend should humanize permission denial. |
| Scope checks are not visibly universal. | Critical | Add tests proving agents/providers cannot cross customer/branch boundaries. |
| No visible rate limiting in `main.ts`. | High | Add throttling for auth, OTP, upload, wallet, and mutation endpoints. |
| No visible global validation pipe in `main.ts`. | High | Add DTO validation and reject unknown properties. |

## Wallet and Ledger Health

| Feature | Status | Notes |
| --- | --- | --- |
| Ledger-based balance calculation | Implemented in `WalletService` and `PricingService`. | Strong. |
| Separate cash transaction table | Exists. | Good. |
| Separate reward point transaction table | Exists. | Good. |
| Separate hidden benefit ledger table | Exists. | Good. |
| Generic legacy `wallet_transactions` support | Still present. | Risky. |
| Customer-visible filter semantics | Schema has `is_customer_visible`; frontend filters hidden benefit. | Needs backend enforcement tests. |
| Referral rewards | Delayed lifecycle exists: pending, verified, qualified, rewarded/rejected. | Good. |
| Pricing audits | Model/table exists. | Critical for traceability. |

### Wallet Risks

| Risk | Severity |
| --- | --- |
| Legacy and typed wallet ledgers can diverge unless there is one canonical read/write policy. | Critical |
| Hidden benefit can be accidentally exposed if any endpoint returns it as available balance. | Critical |
| Concurrent wallet updates need transaction and race-condition tests. | Critical |
| Wallet adjustments/refunds/approvals need a uniform workflow. | High |
| Branch restriction on SHIELD card utilization must be enforced in service code. | Critical |

## Pricing, Benefits, and Referral Health

| Area | Status | Notes |
| --- | --- | --- |
| Service benefit rules | Present. | Good foundation. |
| Reward point rules | Present. | Good foundation. |
| Reward redemption rules | Present. | Good foundation. |
| Pricing evaluation | Calculates benefit, membership discount, reward redemption, final payable. | Strong. |
| Referral reward status | Status-driven with delayed reward. | Good. |
| Pricing audit rows | Present. | Must be mandatory for all final payable operations. |

### Pricing Risks

| Risk | Severity |
| --- | --- |
| Rule engine is service-layer code, not yet a fully isolated policy engine. | Medium |
| Every billing/visit/purchase flow must call the same pricing service. | Critical |
| Benefit visibility rules must be enforced at response DTO level. | Critical |

## Document Intelligence Health

| Feature | Status | Notes |
| --- | --- | --- |
| Upload endpoint | Present. | Good. |
| Storage service | Present. | R2/S3-compatible. |
| Classification | Present. | Good. |
| Extraction | Present. | Good. |
| Processing logs | Schema/table exists. | Good. |
| Prescription intelligence | Service and tests exist. | Good start. |
| Approval/review endpoints | Present for document intelligence/prescription review. | Partial. |

### Document Risks

| Risk | Severity |
| --- | --- |
| File size/type/security scanning is not proven in this audit. | Critical |
| Approval/rejection reason/audit enforcement needs stronger tests. | High |
| Download URL authorization must be tested. | High |
| OCR/AI failure retry state needs consistent API and UI behavior. | Medium |

## Appointment and Visit Health

| Feature | Status |
| --- | --- |
| List/create/find/cancel | Present |
| Reschedule/update lifecycle paths | Present |
| Consultation workspace | Present |
| Prescription copy to open visit | Present |
| Notification side effects | Present in parts |

### Appointment Risks

| Risk | Severity |
| --- | --- |
| Appointment status lifecycle should be formalized and tested as a state machine. | High |
| Provider/customer scope checks need negative tests. | Critical |
| Billing/wallet coupling needs strict invariant tests. | Critical |

## Admin Governance Health

| Area | Status |
| --- | --- |
| Backend workspace contracts | Present for all admin modules. |
| Customer forms/actions/bulk actions | Present. |
| Permissions in contracts | Present. |
| Audit for customer workspace actions | Present in service. |
| Generic workspace metrics/tables | Present. |

### Admin Governance Risks

| Risk | Severity |
| --- | --- |
| `admin-governance.service.ts` is too large and should be split by workspace domain. | High |
| Customers have deeper command metadata than other modules. | High |
| Reports/CRM/wallet/memberships/providers need richer workflows. | Critical |

## Backend Security Posture

| Area | Status | Recommendation |
| --- | --- | --- |
| CORS | Custom allow-list exists. | Good, keep explicit. |
| JWT auth | Global guard exists. | Good. |
| Permission guard | Global guard exists. | Good. |
| Validation | Not visible globally in `main.ts`. | Add `ValidationPipe` and DTOs. |
| Rate limiting | Not visible globally in `main.ts`. | Add throttling. |
| Helmet/security headers | Not visible globally in `main.ts`. | Add helmet or platform equivalent. |
| Audit | Exists but not universal. | Centralize. |
| Observability | Sentry module exists. | Add dashboards/alerts/runbooks. |
| Secrets | Env loader reads secrets. | Add startup validation for required production secrets. |

## Backend Test Health

| Test area | Current evidence |
| --- | --- |
| App controller | Basic test exists. |
| Env helper | Tests exist. |
| Admin governance controller | Tests exist. |
| Prescription intelligence | Tests exist. |
| E2E | Default app e2e test exists but still expects `Hello World!`. |

Backend tests are far below what this domain needs.

Missing tests:

| Missing test family | Severity |
| --- | --- |
| Wallet ledger invariants | Critical |
| Pricing final payable rules | Critical |
| Hidden benefit visibility | Critical |
| Referral reward lifecycle | Critical |
| RBAC/ABAC negative tests | Critical |
| Document approval/rejection/audit | High |
| Appointment lifecycle and billing | High |
| Admin workspace action pipeline | High |

## Backend Conclusion

The backend is promising and materially useful. The domain vocabulary is correct. The data model is broad. The admin workspace API is strategically strong. But production hardening now depends on validation, rate limiting, workflow standardization, invariant testing, and splitting the largest services before they become permanent platform debt.

