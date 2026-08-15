# Customer Portal Final Pre-UAT Audit — 2026-08-15

## Executive result

**READY_FOR_MANUAL_UAT** at source level. Deployment, Firebase/device, timing, and the unapplied performance-index migration remain external gates.

## Route and contract matrix

| Area | Route / contract | Classification | Source evidence / gate |
|---|---|---|---|
| Auth | `/customer/login`, `/customer/otp` | EXTERNAL_UAT_REQUIRED | Firebase Phone Auth and SHIELD session source; OTP/device provider verification remains external. |
| Dashboard | `/portal/customer/dashboard`, `GET /customer/dashboard` | VERIFIED_COMPLETE | customer-keyed SWR cache, deduplication, count projections and bounded previews. |
| Membership/card | `/portal/customer/membership`, application/card APIs | VERIFIED_COMPLETE | application, real membership and real card are distinct nullable entities. |
| Wallet/rewards | wallet, history and rewards routes | VERIFIED_COMPLETE | ledger-backed balances; customer redemption is BUSINESS_DECISION_REQUIRED. |
| Services/booking | services, booking, appointments | VERIFIED_COMPLETE | cached provider discovery and bounded customer appointment path. |
| Documents/prescriptions/orders | respective customer routes | VERIFIED_COMPLETE | owned metadata lists and on-demand document handling; no checkout claim. |
| Referrals/notifications/activity | respective customer routes | VERIFIED_COMPLETE | principal-owned data, inbox pagination and bounded activity pages. |
| Account/store change/support | respective customer routes | VERIFIED_COMPLETE | customer-owned preference, pending-request guard and support history contract. |

## Security, cache and performance

- Customer controllers derive customer identity from the authenticated principal.
- Dashboard cache is customer-keyed/versioned and is replaced by authoritative refresh; logout/account-switch isolation is a manual UAT gate.
- Startup defers non-critical Firebase work. Dashboard, Services and Activity retain their current bounded/de-duplicated source behavior.

## Business decisions

- Customer payment checkout, signed webhook settlement and refunds: BUSINESS_DECISION_REQUIRED.
- Customer reward redemption policy: BUSINESS_DECISION_REQUIRED.
- Physical-card print/replacement/shipping policy: BUSINESS_DECISION_REQUIRED. Digital-card visibility remains based on real card state.

## Migration and external UAT

- 20260814 functional Customer/membership migrations: owner-applied and verified.
- `20260815_customer_performance_indexes`: MIGRATION_PENDING; not applied by this audit.
- Required owner UAT: cold/warm startup, Firebase OTP, authenticated route actions, cache isolation, FCM delivery/deep links, responsive layouts and deployment timing.

## Test matrix

- Backend focused Customer/membership contracts: 30 passing Jest tests across customer service/account/membership/store-change, dashboard and timeline controller suites.
- Flutter focused Customer batches: 38 passing tests across membership/card, access/services/booking/visits, wallet, dashboard, documents, prescriptions, orders, referrals, store change, account and app-bar coverage.
- `flutter analyze lib/features/customer`: PASS.
- `npx tsc --noEmit` and `npx nest build`: PASS.
- Broad Agent Customer 360 has one existing deprecated Flutter form-field API informational finding; it is not a Customer Portal or Agent Membership source defect and is outside this scope lock.
