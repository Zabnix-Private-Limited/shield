# CURRENT STATE HANDOFF

This section is a starting summary, not a substitute for inspecting Git history and the current working tree. Repository inspection overrides any stale statement below.

## Known architecture

- Flutter customer frontend
- Riverpod state management
- GoRouter navigation
- Dio/API repositories
- Hive/local caching where already used
- Firebase phone authentication for customers
- NestJS backend
- Prisma/PostgreSQL persistence
- Cloudflare R2 document storage
- Firebase Cloud Messaging notifications
- RBAC, scope enforcement and audit logging
- Active customer portal rendered through `/portal/customer/:section`

## Known shared customer foundation

The repository has or recently introduced equivalents of:

- `CustomerScaffold`
- `CustomerAppBar`
- `CustomerBottomNavigation`
- `CustomerDesignTokens`
- Shared loading, empty and error widgets
- Dashboard repository and cache
- Wallet repository
- Membership repository

Use the actual names in the repository. Extend existing components rather than creating duplicate shells.

## Known completed or partially completed work

The following work was reported as implemented and should be preserved unless a verified defect is found:

- Compact customer header
- Duplicate written SHIELD wordmark removed, leaving the compact SHIELD mark
- Header Cash Wallet amount and Reward Points count visible at supported mobile widths
- Notification badge
- Dashboard hierarchy corrected
- Operations carousel positioned first after the header
- Operations banner content database-backed through the existing commercial/settings mechanism
- Three non-production demo banners seeded without overwriting existing Operations configuration
- Duplicate lower Dashboard Wallet and Reward cards removed
- Visits, Documents and Updates/Activity summaries retained
- Dashboard empty states for no appointments and no recent ledger activity
- Dedicated Reward Points route using authenticated wallet data and the `REWARD_POINTS` ledger
- Wellness catalogue disclosure: `Demo products only — not live Sahakar inventory.`
- Profile and Settings routes exist, though their visual redesign and extraction may remain incomplete

Known recent commits reported in the previous work stream include:

- `80adc32 customer-header-wordmark-fix`
- `0314152 operations-banner-demo-seed`
- `a4d2c16 customer-dashboard-empty-states`
- `b7085ac label-wellness-demo-catalogue`
- `e48ce13 customer-dashboard-hierarchy-fix`
- `6e34eef record-operations-banner-seed`

Verify these commits locally. Do not assume every prior change is on the current branch.

## Known audit summary

Recent audit information indicated:

- Authentication screens exist but visual alignment and auth-state QA remain.
- Dashboard is API-backed and has the shared header, membership-first structure and Operations carousel; screenshot QA remains.
- Membership exists, but card lifecycle, QR, request/status/history and complete subscription-entitlement pages may be missing.
- Wallet exists, but add-funds, statement and transaction-detail routes may be incomplete.
- Reward Points live balance and activity exist; redemption and expiry need verified backend rules/contracts.
- Services, appointments, profile, notifications and settings have historically been embedded inside a large portal shell and require careful extraction without losing behavior.
- Documents and prescriptions are customer-scoped, but upload/view/share/pharmacy linkage and visual QA may remain incomplete.
- Wellness product APIs and purchase models exist, while customer cart/checkout/order route completeness must be verified.
- Referral, activity, full card lifecycle and family/dependent customer APIs may have gaps.

## Concurrent-work protection

Backend membership activation and product-data import work may occur separately. The UI agent must:

- Inspect `git status` before every phase.
- Preserve unrelated backend changes.
- Never reset, revert, stash or overwrite user-owned or concurrent-agent work without explicit authorization.
- Consume final API contracts instead of hardcoding temporary values.
- Never modify `E:\K4NN4N\shield\Design reference`.
