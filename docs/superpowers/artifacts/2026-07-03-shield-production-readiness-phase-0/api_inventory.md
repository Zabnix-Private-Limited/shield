# SHIELD Phase 0 API Inventory

**Date:** 2026-07-03  
**Phase:** 0 - Discovery and Inventory  
**Primary sources:** `backend/src/app.module.ts`, `backend/src/*/*.controller.ts`, `docs/SHIELD Complete Route Map.md`, `backend/src/main.ts`

## Backend Surface Totals

- Controller files discovered: `24`
- Module files discovered: `24`
- Service files discovered: `34`
- Global API prefix in `backend/src/main.ts`: none configured

## Imported Backend Modules

- `AuthModule`
- `MasterDataModule`
- `PlatformMetadataModule`
- `PlatformCapabilitiesModule`
- `OperationsQueueModule`
- `ServiceProviderModule`
- `TimelineModule`
- `PrismaModule`
- `PricingModule`
- `ReferralModule`
- `AgentModule`
- `CustomerModule`
- `WalletModule`
- `CreditModule`
- `AppointmentModule`
- `DocumentModule`
- `CrmModule`
- `NotificationModule`
- `DashboardModule`
- `PharmacyModule`
- `StorageModule`
- `SupportModule`
- `RedisModule`

## Controller Inventory By Domain

- `app.controller.ts`: root and platform health surface
- `auth/auth.controller.ts`: customer and internal auth, refresh, logout, session identity
- `customer/customer.controller.ts`: customer creation, search, profile read and update
- `customer/customer-membership.controller.ts`: membership-linked customer operations
- `wallet/wallet.controller.ts`: wallet operations and transactions
- `wallet/customer-wallet.controller.ts`: customer wallet endpoints
- `credit/credit.controller.ts`: credit account flows
- `appointment/appointment.controller.ts`: appointment lifecycle
- `agent/agent.controller.ts`: agent operations
- `document/document.controller.ts`: upload, download, document intelligence, review
- `crm/crm.controller.ts`: CRM activities, tasks, complaints
- `notification/notification.controller.ts`: notification inbox and device-token flows
- `dashboard/dashboard.controller.ts`: staff, CRM, management, role dashboards
- `dashboard/customer-dashboard.controller.ts`: customer dashboard data
- `pharmacy/pharmacy.controller.ts`: pharmacy purchase and product flows
- `pricing/pricing.controller.ts`: pricing evaluation and commercial controls
- `master-data/master-data.controller.ts`: admin master-data catalog/bootstrap
- `platform-capabilities/platform-capabilities.controller.ts`: platform utility capabilities
- `platform-metadata/platform-metadata.controller.ts`: metadata delivery
- `operations-queue/operations-queue.controller.ts`: queue and provider-workspace operations
- `service-provider/service-provider.controller.ts`: provider-facing backend domain
- `referral/referral.controller.ts`: referral tree and reward qualification
- `support/support.controller.ts`: support and feedback intake
- `timeline/timeline.controller.ts`: timeline/history domain

## API Baseline Findings

- The backend is modular and broad enough to support a large ERP surface, but the frontend-visible internal role experience is not yet proven module-by-module.
- `docs/SHIELD Complete Route Map.md` is a useful baseline, but Phase 9 still needs controller-by-controller validation to confirm it is complete and current.
- No global `/api` prefix is applied in `backend/src/main.ts`, so route audits must use controller-mounted paths directly.
- Platform metadata and operations-queue modules are especially important for backend-owned workspace semantics and should be treated as central control surfaces in later phases.
