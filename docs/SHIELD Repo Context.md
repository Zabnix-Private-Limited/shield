# SHIELD Repo Context

Last updated: 2026-08-04

## 1. What This Repository Is

SHIELD is a unified healthcare platform with one Flutter client and one NestJS backend, plus a Python prescription-intelligence service.

- Frontend: Flutter for Android, Web, and PWA targets.
- Backend: NestJS + Prisma + PostgreSQL.
- Supporting service: `backend/prescription_ai_service` for OCR / prescription parsing workflows.
- Source-of-truth schema file: `current_schema.md` at the repo root.

The repo is not organized as isolated apps for each role. It is converging toward shared, backend-driven portal platforms where the frontend renders metadata, navigation, sections, labels, workflow stages, and actions returned by the backend.

## 2. Top-Level Shape

### Frontend

- Entry: `frontend/lib/main.dart`
- Router: `frontend/lib/app/routes/app_router.dart`
- Shared role resolution: `frontend/lib/shared/services/portal_resolver.dart`
- Customer session: `frontend/lib/shared/services/customer_auth_session.dart`
- Internal session: `frontend/lib/shared/services/internal_auth_session.dart`
- Firebase bootstrap: `frontend/lib/shared/services/firebase_bootstrap_service.dart`

### Backend

- Entry: `backend/src/main.ts`
- Serverless adapter: `backend/api/index.ts`
- Root module: `backend/src/app.module.ts`
- Auth core: `backend/src/auth/**`
- Provider platform metadata: `backend/src/platform-metadata/**`
- Provider operational workspace: `backend/src/service-provider/**`
- Admin governance platform: `backend/src/admin-governance/**`
- Provider workspace metadata builder: `backend/src/operations-queue/provider-workspace-metadata.service.ts`

### Docs / Truth Sources

- Agent rules: `AGENTS.md`
- Current schema truth: `current_schema.md`
- Route docs: `docs/SHIELD Portal Navigation Map.md`, `docs/SHIELD Complete Route Map.md`
- Product / architecture docs: `docs/SHIELD *.docx.md`
- Audit / rollout docs: `docs/superpowers/**`

## 3. Runtime Architecture

### Frontend startup flow

`frontend/lib/main.dart` initializes:

1. Flutter bindings and runtime error hooks
2. web runtime error probe
3. Firebase
4. Hive
5. customer session restore
6. internal session restore
7. optional Sentry
8. `MaterialApp.router`

### Routing model

`frontend/lib/app/routes/app_router.dart` is the live route gatekeeper.

- `/` redirects to the resolved home route.
- Public customer auth routes live under `/customer/*`.
- Internal staff/provider/admin login lives at `/internal/login`.
- Role portal routes live under `/portal/:role/:section`.
- legacy convenience routes like `/documents`, `/appointments`, `/wallet` redirect into the resolved portal section.

The router enforces:

- unauthenticated users go to customer or internal login depending on route family
- customer sessions cannot enter internal routes
- internal sessions cannot enter customer-only routes
- portal role/section access is normalized through `PortalResolver`
- expired sessions are redirected through `/session-expired`

### Session model

There are two persisted auth tracks:

- `CustomerAuthSession`
  - stores customer access token, refresh token, customer id, mobile
  - restores session on app start
  - refreshes through backend refresh API
- `InternalAuthSession`
  - stores internal access token, refresh token, role code, user id, profile data
  - restores session on app start
  - resolves portal home role from backend role code

`PortalResolver` decides the active portal in this order:

1. internal session
2. customer session
3. fallback to `/customer/splash`

## 4. Portal Strategy

This repository is built around shared portal shells, not separate apps per role.

### Customer / agent / manager / provider / admin access

- Customer and most non-admin internal roles render through `frontend/lib/features/portal/presentation/screens/portal_shell.dart`
- `frontend/lib/features/portal/presentation/portal_role_data.dart` contains role and section definitions used by the shared shell
- `PortalResolver` guards which sections each role can open

### Provider platform

Provider workflows are split into two backend-fed layers:

1. Operational workspace data
   - fetched by `frontend/lib/features/provider/shared/data/provider_portal_repository.dart`
   - controlled by `ProviderPortalController`
   - backed by `backend/src/service-provider/service-provider.controller.ts`

2. Platform metadata
   - fetched from `GET /platform/workspace/provider`
   - backed by `backend/src/platform-metadata/platform-metadata.controller.ts`
   - shaped by `PlatformMetadataService`
   - built in detail by `ProviderWorkspaceMetadataService`

`ProviderPortalController` is a major orchestration class. It merges workspace payloads, loads patient workspace detail, manages realtime wiring, and exposes UI-ready sections like summary, queues, labels, filters, quick actions, dashboard widgets, timeline, billing, and patient workspace data.

The provider system is intentionally one shared provider platform. Provider type should change metadata, module registry, stages, labels, and actions, not fork the UI into separate role-specific apps.

### Admin platform

Admin is moving onto a backend/workspace engine rather than hardcoded pages.

Core runtime pieces:

- `frontend/lib/features/admin/presentation/registry/admin_platform_runtime.dart`
- `frontend/lib/features/admin/shared/controllers/admin_workspace_controller.dart`
- `frontend/lib/features/admin/shared/engine/workspace/admin_workspace_registry.dart`
- `frontend/lib/features/admin/shared/engine/navigation/admin_navigation_registry.dart`

The admin runtime registers workspaces, navigation, schemas, and capability bindings, then creates `AdminWorkspaceController` instances that drive workspace rendering and actions.

On the backend, `backend/src/admin-governance/**` is the platform-facing governance slice and `backend/src/platform-capabilities/**` exposes shared print, report, and realtime platform surfaces.

## 5. Backend Module Shape

`backend/src/app.module.ts` wires these main domains:

- `AuthModule`
- `CustomerModule`
- `WalletModule`
- `CreditModule`
- `AppointmentModule`
- `AgentModule`
- `DocumentModule`
- `CrmModule`
- `NotificationModule`
- `DashboardModule`
- `PharmacyModule`
- `PricingModule`
- `ReferralModule`
- `MasterDataModule`
- `ServiceProviderModule`
- `PlatformMetadataModule`
- `PlatformCapabilitiesModule`
- `AdminGovernanceModule`
- `OperationsQueueModule`
- `TimelineModule`
- `StorageModule`
- `RedisModule`
- `PrismaModule`

This is a broad modular monolith rather than a microservice split.

## 6. Auth and Identity Model

Backend auth is centered in `backend/src/auth/auth.service.ts`.

Major flows:

- customer login with Firebase phone auth token
- customer registration with mandatory `agent_code`
- internal login with Firebase Google sign-in token
- refresh-token-based persistent sessions
- logout and session revocation
- profile fetch
- session history and login history

### Local web phone OTP

`localhost` is authorized in Firebase for this project, but SHIELD deliberately
blocks browser phone OTP there unless the Flutter app is compiled in debug mode
with `ALLOW_LOCAL_WEB_PHONE_AUTH=true`. This switch enables the real Firebase
OTP flow only; it does not bypass Firebase verification, backend JWT issuance,
or authorization. It defaults to `false` and release builds remain blocked by
the `kDebugMode` requirement.

```powershell
cd frontend
flutter run -d chrome --dart-define=ALLOW_LOCAL_WEB_PHONE_AUTH=true
```

Important backend auth types live in `backend/src/auth/auth.types.ts`.

Key identity concepts:

- user types: `CUSTOMER`, `EMPLOYEE`, `SERVICE_PROVIDER`, `SYSTEM`
- access scopes: `GLOBAL`, `ORGANIZATION`, `CLUSTER`, `BRANCH`, `SELF`
- principals carry role code, user type, scope, permissions, Firebase identity, and optional customer/user ids

Persistent auth state is modeled in schema tables such as:

- `auth_devices`
- `auth_sessions`
- `login_history`
- `device_push_tokens`

## 7. Schema Context That Shapes The Code

`current_schema.md` shows the current database surface as raw SQL DDL.

High-impact schema families:

- customer and membership: `customers`, `memberships`, `membership_types`, `shield_cards`
- staff / RBAC / provider identity: `users`, `roles`, `permissions`, `role_permissions`, `provider_profiles`, `provider_profile_branch_assignments`
- wallet / benefits / rewards: `wallets`, `wallet_transactions`, `benefit_ledger_transactions`, `cash_wallet_transactions`, `reward_point_transactions`, `reward_redemption_rules`, `service_benefit_rules`, `pricing_rule_audits`
- care delivery: `appointments`, `consultations`, `prescriptions`, `lab_reports`, `dental_records`
- documents / intelligence: `documents`, `document_classifications`, `document_extractions`, `document_processing_logs`
- CRM / support / follow-up: `crm_activities`, `crm_tasks`, `complaints`, `notifications`
- commerce / billing: `purchases`, `purchase_items`, `products`, `product_categories`

Schema facts that matter architecturally:

- wallet balances are ledger-driven, not stored as a durable balance field
- `wallet_transactions.sub_ledger_type` separates wallet sub-ledgers
- referral rewards are event/status driven through `referral_reward_events`
- customer onboarding requires `agent_code`
- provider identity is tied through `users` plus `provider_profiles`
- branch-aware enforcement exists through fields like `branch_business_id` and `shield_cards.issued_business_id`

When code, docs, and assumptions disagree, this file is the repo truth source for current schema state.

## 8. Realtime / Platform Capability Layer

The backend has a shared platform surface under `backend/src/platform-capabilities/**`.

It currently centralizes:

- report metadata and report execution
- print templates and generation
- realtime stream endpoint and publish helpers

This layer is already consumed by admin governance and provider workflows, which is a strong signal that the repo is standardizing cross-portal capabilities instead of repeating them per feature.

## 9. Areas That Carry The Most Complexity

If you are onboarding or debugging, these files carry the most architectural weight:

### Frontend

- `frontend/lib/app/routes/app_router.dart`
- `frontend/lib/shared/services/portal_resolver.dart`
- `frontend/lib/shared/services/customer_auth_session.dart`
- `frontend/lib/shared/services/internal_auth_session.dart`
- `frontend/lib/features/portal/presentation/screens/portal_shell.dart`
- `frontend/lib/features/provider/shared/presentation/controllers/provider_portal_controller.dart`
- `frontend/lib/features/admin/presentation/registry/admin_platform_runtime.dart`
- `frontend/lib/features/admin/shared/controllers/admin_workspace_controller.dart`

### Backend

- `backend/src/main.ts`
- `backend/src/app.module.ts`
- `backend/src/auth/auth.service.ts`
- `backend/src/auth/auth.controller.ts`
- `backend/src/platform-metadata/platform-metadata.service.ts`
- `backend/src/platform-metadata/platform-metadata.controller.ts`
- `backend/src/service-provider/service-provider.controller.ts`
- `backend/src/operations-queue/provider-workspace-metadata.service.ts`
- `backend/src/admin-governance/admin-governance.service.ts`

## 10. Practical Read Order For Future Work

For repo-grounded work, this is the fastest read order:

1. `AGENTS.md`
2. `current_schema.md`
3. `frontend/lib/app/routes/app_router.dart`
4. `frontend/lib/shared/services/portal_resolver.dart`
5. `backend/src/app.module.ts`
6. `backend/src/auth/auth.service.ts`
7. the portal-specific area you are changing:
   - provider: `frontend/lib/features/provider/**` + `backend/src/service-provider/**` + `backend/src/platform-metadata/**`
   - admin: `frontend/lib/features/admin/**` + `backend/src/admin-governance/**`
   - customer: `frontend/lib/features/customer/**` + `backend/src/customer/**`
   - documents: `frontend/lib/features/**/documents/**` + `backend/src/document/**`

## 11. Short Repo Summary

SHIELD is a modular monolith with:

- one Flutter app
- one NestJS backend
- one schema truth source
- dual auth tracks for customer and internal users
- a shared route/portal model
- a backend-driven provider platform
- an admin workspace engine in active migration toward backend-owned contracts

The most important architectural direction is this: business semantics are being pulled into backend metadata and shared platform services, while Flutter becomes the renderer and interaction shell.
