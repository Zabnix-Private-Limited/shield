# SHIELD Phase 0 Component Inventory

**Date:** 2026-07-03  
**Phase:** 0 - Discovery and Inventory  
**Primary sources:** `frontend/lib/**/widgets/*.dart`, shared portal and shell files

## Baseline Totals

- Widget files discovered under `widgets` paths: `42`
- Cross-portal shell centerpiece: `frontend/lib/features/portal/presentation/screens/portal_shell.dart`

## Shared Foundation Widgets

- `frontend/lib/shared/widgets/app_button.dart`
- `frontend/lib/shared/widgets/app_card.dart`
- `frontend/lib/shared/widgets/app_page_frame.dart`
- `frontend/lib/shared/widgets/app_responsive.dart`
- `frontend/lib/shared/widgets/app_skeleton.dart`
- `frontend/lib/shared/widgets/customer_support_sheet.dart`
- `frontend/lib/shared/widgets/portal_support.dart`
- `frontend/lib/shared/widgets/shield_date_input_field.dart`
- `frontend/lib/shared/widgets/turnstile_challenge.dart`
- `frontend/lib/shared/widgets/turnstile_challenge_stub.dart`
- `frontend/lib/shared/widgets/turnstile_challenge_web.dart`

## Customer-Specific Shared Widgets

- `frontend/lib/features/customer/shared/widgets/bottom_navigation.dart`
- `frontend/lib/features/customer/shared/widgets/customer_app_bar.dart`
- `frontend/lib/features/customer/shared/widgets/customer_scaffold.dart`
- `frontend/lib/features/customer/shared/widgets/empty_state.dart`
- `frontend/lib/features/customer/shared/widgets/error_card.dart`
- `frontend/lib/features/customer/shared/widgets/glass_card.dart`
- `frontend/lib/features/customer/shared/widgets/loading_card.dart`
- `frontend/lib/features/customer/shared/widgets/network_error.dart`
- `frontend/lib/features/customer/shared/widgets/primary_button.dart`
- `frontend/lib/features/customer/shared/widgets/secondary_button.dart`
- `frontend/lib/features/customer/shared/widgets/section_header.dart`

## Agent Shared Widgets

- `frontend/lib/features/agent/shared/presentation/widgets/agent_experience_widgets.dart`
- `frontend/lib/features/agent/shared/presentation/widgets/agent_section_header.dart`

## Provider Shared Widgets

- `frontend/lib/features/provider/shared/presentation/widgets/provider_workspace_scaffold.dart`

## Feature-Specific Widget Clusters

### Customer dashboard

- Appointment, greeting, membership, notification, quick-action, activity, shimmer, and wallet-summary widgets exist as dedicated units.

### Customer wallet

- Balance, benefit summary, reward points, transaction list, transaction tile, filters, shimmer, and empty-state widgets exist as dedicated units.

## Component Findings

- Customer surfaces currently have the richest dedicated widget inventory.
- Agent now has a meaningful shared component layer, which is a good sign for maintainability.
- Provider has a reusable workspace scaffold, but internal admin, CRM, manager, and executive component layers are still concentrated in `portal_shell.dart` rather than split into dedicated role-level widget families.
- Phase 5 and later quality work should prefer building on these shared primitives instead of growing more one-off role-specific fragments inside `portal_shell.dart`.
