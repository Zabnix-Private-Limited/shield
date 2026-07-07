# SHIELD Flow Analysis
Date: 2026-07-07
Repository: `E:\K4NN4N\shield`
Schema authority: `current_schema.md`

## Flow Map Verdict

SHIELD has the correct high-level flow shape:

1. User authenticates through Firebase.
2. Nest verifies the Firebase identity and issues SHIELD JWTs.
3. Flutter persists the session.
4. GoRouter re-evaluates session state.
5. `PortalResolver` resolves customer/internal role.
6. `PortalShell` loads the role portal.
7. Admin screens route through backend-owned workspace contracts.
8. Provider/agent/customer screens load domain repositories/controllers.
9. Mutations call backend modules.
10. Notifications, audit, timeline, and realtime are partially connected.

The flow is not yet uniformly production-grade because backend mutation pipelines, audit propagation, notification propagation, scope enforcement, and frontend runtime behavior vary by domain.

## App Start Flow

| Step | Current implementation | Status | Risk |
| --- | --- | --- | --- |
| Flutter bootstrap | `frontend/lib/main.dart` initializes app-level error handlers and Firebase-related services. | OK | Debug/runtime logging still appears in production-adjacent paths. |
| Route initialization | `GoRouter` starts at `/`. | Good | Root redirects depend on session resolver correctness. |
| Auth session refresh | Router listens to customer session, internal session, and auth redirect notice. | Good | Long-lived sessions need revocation/retry coverage. |
| Portal resolution | `PortalResolver.current` checks internal session first, then customer session. | OK | Role mapping must remain backend-aligned. |
| Shell load | `/portal/:role/:section` creates `PortalShell(role, sectionKey)`. | Mixed | `PortalShell` is still too large and imports too many role screens. |

## Auth Flow

### Customer Auth

| Stage | Flow | Status |
| --- | --- | --- |
| Entry | `/customer/splash`, `/customer/login`, `/customer/otp`, `/customer/register` | Live |
| Identity | Firebase phone OTP | Live |
| Backend verification | `POST /auth/customer/login` and `POST /auth/customer/register` | Live |
| Session | `CustomerAuthSession` stores SHIELD access/refresh session | Live |
| Portal | Resolved to customer portal routes | Live |

Customer auth is structurally sound, but production readiness needs more explicit coverage for OTP resend timing, expired OTP recovery, registration validation, agent-code rules, duplicate phone handling, and session revocation.

### Internal Auth

| Stage | Flow | Status |
| --- | --- | --- |
| Entry | `/internal/login` | Live |
| Identity | Firebase Google sign-in | Live |
| Backend verification | `POST /auth/internal/login` | Live |
| Role | Backend user role and permissions loaded from roles/permissions tables | Live |
| Session | `InternalAuthSession` stores SHIELD session | Live |
| Portal | Resolved to admin/provider/agent/CRM-style role portal | Live |

Internal auth has a credible backend path. The biggest risk is inconsistent ABAC/scope enforcement after login, not the login itself.

## Routing and Navigation Flow

| Route family | Destination | Status | Notes |
| --- | --- | --- | --- |
| `/` | Redirects based on session | Live | Good bootstrap route. |
| `/customer/*` | Customer auth and direct customer shortcuts | Live | Some shortcuts redirect to resolved portal sections. |
| `/internal/login` | Internal login | Live | Debug-style traces remain in code. |
| `/portal/:role` | Redirects to dashboard | Live | Good role portal entry. |
| `/portal/:role/:section` | `PortalShell` | Live | Shell is still too central. |
| `/documents`, `/appointments`, `/wallet`, etc. | Compatibility redirects | Live | Useful, but should not become parallel routing architecture. |

## Portal Resolution Flow

| Role family | Current renderer path | Status |
| --- | --- | --- |
| Super admin/admin | `PortalShell` -> `AdminPortalWorkspace` -> admin runtime -> backend workspace contract | Best path |
| Provider | `PortalShell` -> provider-specific screens/controllers | Improving |
| Agent | `PortalShell` -> agent-specific screens/controllers | Useful but less systematic |
| Customer | `PortalShell` -> customer-specific screens | Coherent but not runtime-driven |

## Admin Workspace Flow

Admin flow:

```text
GoRouter
  -> PortalShell
  -> AdminPortalWorkspace
  -> AdminWorkspaceCatalog
  -> AdminPlatformRuntime
  -> AdminWorkspaceController
  -> AdminGovernanceWorkspaceRepository
  -> AdminGovernanceRemoteDataSource
  -> /admin/workspaces/{workspace}
  -> AdminBackendWorkspaceModule
```

This is the healthiest business UI flow in the repo.

### Admin Flow Strengths

| Strength | Impact |
| --- | --- |
| Backend workspace endpoints exist for all major admin modules. | Allows Flutter to render instead of hardcoding screens. |
| Customers have forms/actions/bulk actions endpoint support. | Command metadata architecture is emerging. |
| Shared table, toolbar, renderer, and controller exist. | Fixes can improve many modules at once. |
| Query state persistence has started. | Better enterprise ergonomics. |

### Admin Flow Risks

| Risk | Impact |
| --- | --- |
| `AdminWorkspaceCatalog` still has fallback schemas. | Useful for backward compatibility, but production should prefer backend-owned contracts. |
| Many modules still render through generic backend workspace data. | They may be live but not deep enough for real operations. |
| Mutation pipeline is strongest for customers and weaker elsewhere. | Admin modules can look complete while remaining workflow-thin. |
| `admin-governance.service.ts` is very large. | Backend runtime could become a monolith. |

## Customer Registration Flow

Expected flow:

```text
Customer enters phone
  -> Firebase OTP
  -> Nest customer register/login
  -> mandatory agent_code validation
  -> customer row
  -> membership/wallet/card bootstrap as applicable
  -> customer session
  -> portal dashboard
```

### Current Status

| Area | Status | Risk |
| --- | --- | --- |
| OTP login/register UI | Live | Needs continued UX polish. |
| Backend auth endpoints | Live | Need more validation tests. |
| Mandatory agent code | Required by project rule; backend registration must keep enforcing it. | Must be tested with negative cases. |
| Wallet bootstrap | Present through customer/wallet service paths. | Hidden benefit preload must never become visible customer balance. |
| Membership/card bootstrap | Present in customer service logic. | Some generated identifiers appear string-derived and should be reviewed for collision/format guarantees. |

## Wallet Transaction Flow

Expected production flow:

```text
Wallet operation requested
  -> authorize
  -> validate ledger type
  -> calculate current balance from ledger entries
  -> write append-only transaction row
  -> write audit
  -> publish notification/timeline event
  -> return updated wallet summary
```

### Current Status

| Layer | Current behavior | Status |
| --- | --- | --- |
| Schema | `wallets`, `wallet_transactions`, `cash_wallet_transactions`, `reward_point_transactions`, `benefit_ledger_transactions`, `pricing_rule_audits` exist. | Strong model breadth |
| Backend | `WalletService` calculates across cash/reward/benefit ledger entries and handles legacy wallet transactions. | Good but risky compatibility path |
| Pricing | `PricingService` calculates cash, reward points, hidden benefit, membership discounts, reward redemption, final payable. | Strong foundation |
| Customer frontend | Cash and reward points are visible; internal benefit is explained as behind-the-scenes support and hidden from spendable balance. | Improved |
| Provider frontend | Billing/wallet tab separates cash and reward summary but still exposes provider-side benefit context. | Acceptable if provider-only |

### Wallet Risks

| Risk | Severity |
| --- | --- |
| Legacy `wallet_transactions` compatibility can blur source-of-truth semantics if not guarded. | High |
| Hidden benefit must never appear as customer spendable balance. | Critical |
| Wallet mutations need uniform audit and approval handling. | Critical |
| Financial operations require concurrency/race tests. | Critical |
| `shield_cards.issued_business_id` branch restriction must be enforced in service logic, not only in schema/docs. | Critical |

## Document Intelligence Flow

Expected flow:

```text
Upload
  -> R2/storage original file
  -> documents row
  -> classification/extraction rows
  -> processing logs
  -> validation/approval
  -> prescription/lab/medical record linkage
  -> audit/timeline/notification
```

### Current Status

| Area | Status |
| --- | --- |
| Upload endpoint | Present under document controller. |
| Classification endpoint | Present. |
| Extraction endpoint | Present. |
| Prescription review endpoint | Present. |
| AI service integration | `PrescriptionIntelligenceService` has tests for remote upload/error. |
| Storage | Cloudflare R2-compatible storage service exists. |

### Document Risks

| Risk | Severity |
| --- | --- |
| Approval/rejection workflows need stronger audit and reason enforcement. | High |
| Preview/download authorization needs explicit negative tests. | High |
| Document intelligence failure/retry state must be user-visible. | Medium |
| File upload scanning/size/type enforcement needs production proof. | High |

## Appointment, Visit, Consultation Flow

Expected flow:

```text
Create appointment
  -> provider/customer scope validation
  -> optional pricing/wallet evaluation
  -> appointment status lifecycle
  -> consultation workspace
  -> prescription/document linkage
  -> completion/cancellation/reschedule
  -> notification/timeline/audit
```

### Current Status

| Area | Status |
| --- | --- |
| Appointment list/create/detail/cancel | Present. |
| Reschedule and workspace flows | Present. |
| Consultation workspace | Present. |
| Prescription copy to open visit | Present. |
| Notifications | Used in appointment service for appointment messaging. |

### Appointment Risks

| Risk | Severity |
| --- | --- |
| Status lifecycle should be formally validated as a state machine. | High |
| Provider/customer scope should have negative tests. | High |
| Billing/wallet interaction around visits needs stronger invariant tests. | Critical |
| Calendar/list UI behavior needs better consistency across portals. | Medium |

## Prescription Flow

Expected flow:

```text
Prescription document upload or creation
  -> document intelligence extraction
  -> provider review
  -> approve/reject
  -> prescription row
  -> patient/customer visibility
  -> print/export
```

### Current Status

| Area | Status |
| --- | --- |
| Prescription intelligence service | Present and tested for service success/failure. |
| Provider prescription screen | Exists. |
| Customer prescription screen | Exists. |
| Appointment copy/reuse | Present. |

### Prescription Risks

| Risk | Severity |
| --- | --- |
| Versioning/review lifecycle is not clearly proven end-to-end. | High |
| Clinical safety checks are not visible as a formal rules layer. | High |
| Print/download authorization needs tests. | Medium |

## Provider Operations Flow

Expected flow:

```text
Provider login
  -> provider scope resolution
  -> provider queue
  -> patient workspace
  -> documents/notes/billing/timeline/prescriptions tabs
  -> appointment or document action
  -> audit/notification/timeline
```

### Current Status

Provider customer workspace has been decomposed into shell/header/tabs. This is a meaningful improvement. Provider queue exists and is the right operational center.

### Provider Risks

| Risk | Severity |
| --- | --- |
| Provider controller remains large. | High |
| Provider screens outside customers are still simple/bespoke. | Medium |
| Provider scope enforcement must be tested across patient, document, wallet, appointment, and timeline data. | Critical |
| Debug traces remain in provider auth/controller paths. | Medium |

## Agent Operations Flow

Expected flow:

```text
Agent login
  -> agent workspace
  -> customers/follow-ups/documents/referrals/registration
  -> create customer or update task
  -> audit/timeline/notification
```

### Current Status

Agent module has broad screens and targeted tests, including documents, follow-ups, accessibility, responsiveness, settings, and golden coverage.

### Agent Risks

| Risk | Severity |
| --- | --- |
| Agent screens remain screen-specific rather than runtime-driven. | Medium |
| Agent settings screen is still large. | Medium |
| Follow-up urgency and CRM-style task flow need stronger product behavior. | High |
| Agent scope enforcement needs backend negative tests. | High |

## Notifications and Realtime Flow

| Flow | Status | Risk |
| --- | --- | --- |
| Notification storage | `notifications` and `device_push_tokens` exist. | Good |
| Firebase push bootstrap | Frontend and backend services exist. | Good |
| Realtime channel | Platform realtime service/channel exists. | Partial |
| Action-triggered notifications | Present in some paths. | Not universal |
| Offline fallback | Partial cache/session behavior. | Weak |

Notifications should be treated as a command-pipeline output, not as a manually called side effect per service.

## Broken or Risky Connections

| Connection | Problem | Recommendation |
| --- | --- | --- |
| Auth -> ABAC scope | Permissions exist, but scope enforcement is not uniformly proven. | Add negative tests for every scoped endpoint. |
| Mutations -> audit | Some admin customer actions audit; not universal. | Centralize command audit pipeline. |
| Mutations -> notifications | Some services notify; not universal. | Centralize notification events through event bus. |
| Wallet -> branch restriction | Schema has `issued_business_id`; enforcement must be proven. | Add service-level guard and tests. |
| Frontend -> backend contracts | Admin follows contracts; provider/agent/customer are mixed. | Expand runtime-like contracts gradually outside admin. |
| Realtime -> UI refresh | Realtime exists but not proven as a reliable UI invalidation path. | Add fallback polling and connection-state UI. |
| Offline -> mutation recovery | Cache exists; queued mutations are not mature. | Build explicit offline outbox for safe domains only. |

## Flow Conclusion

The app starts and routes correctly. Core business flows exist. The dangerous parts are not missing screens; they are missing proof and uniformity. Production readiness depends on making every critical mutation flow through the same validate, authorize, execute, audit, notify, refresh pipeline, then proving the whole route from session to database mutation to UI refresh.

