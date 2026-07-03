# SHIELD Phase 0 Screen Inventory

**Date:** 2026-07-03  
**Phase:** 0 - Discovery and Inventory  
**Scope:** Frontend screen files and role-facing portal surfaces grounded in `frontend/lib`

## Baseline

- Total `*screen.dart` files discovered: `30`
- Primary route shell: `frontend/lib/features/portal/presentation/screens/portal_shell.dart`
- Shared recovery route screen: `frontend/lib/app/routes/route_recovery_screen.dart`

## Customer Screens

- `frontend/lib/features/customer/auth/presentation/screens/customer_login_screen.dart`
- `frontend/lib/features/customer/auth/presentation/screens/customer_otp_screen.dart`
- `frontend/lib/features/customer/auth/presentation/screens/customer_register_screen.dart`
- `frontend/lib/features/customer/auth/presentation/screens/customer_splash_screen.dart`
- `frontend/lib/features/customer/dashboard/presentation/screens/dashboard_screen.dart`
- `frontend/lib/features/customer/documents/presentation/screens/customer_documents_screen.dart`
- `frontend/lib/features/customer/membership/presentation/screens/membership_screen.dart`
- `frontend/lib/features/customer/prescriptions/presentation/screens/customer_prescriptions_screen.dart`
- `frontend/lib/features/customer/wallet/presentation/screens/wallet_screen.dart`

## Provider Screens

- `frontend/lib/features/provider/auth/presentation/screens/internal_login_screen.dart`
- `frontend/lib/features/provider/dashboard/presentation/screens/provider_dashboard_screen.dart`
- `frontend/lib/features/provider/queue/presentation/screens/provider_queue_screen.dart`
- `frontend/lib/features/provider/customers/presentation/screens/provider_customers_screen.dart`
- `frontend/lib/features/provider/appointments/presentation/screens/provider_appointments_screen.dart`
- `frontend/lib/features/provider/documents/presentation/screens/provider_documents_screen.dart`
- `frontend/lib/features/provider/prescriptions/presentation/screens/provider_prescriptions_screen.dart`
- `frontend/lib/features/provider/profile/presentation/screens/provider_profile_screen.dart`
- `frontend/lib/features/provider/settings/presentation/screens/provider_settings_screen.dart`

## Agent Screens

- `frontend/lib/features/agent/dashboard/presentation/screens/agent_dashboard_screen.dart`
- `frontend/lib/features/agent/customers/presentation/screens/agent_customers_screen.dart`
- `frontend/lib/features/agent/registration/presentation/screens/agent_registration_screen.dart`
- `frontend/lib/features/agent/followups/presentation/screens/agent_followups_screen.dart`
- `frontend/lib/features/agent/appointments/presentation/screens/agent_appointments_screen.dart`
- `frontend/lib/features/agent/referrals/presentation/screens/agent_referrals_screen.dart`
- `frontend/lib/features/agent/documents/presentation/screens/agent_documents_screen.dart`
- `frontend/lib/features/agent/notifications/presentation/screens/agent_notifications_screen.dart`
- `frontend/lib/features/agent/performance/presentation/screens/agent_performance_screen.dart`
- `frontend/lib/features/agent/reports/presentation/screens/agent_reports_screen.dart`
- `frontend/lib/features/agent/settings/presentation/screens/agent_settings_screen.dart`

## Portal-Shell-Driven Internal Surfaces

These roles are declared in frontend metadata but do not currently have dedicated screen files outside `portal_shell.dart`:

- `crm-executive`
- `shield-executive`
- `manager`
- `super-admin`

## Key Findings

- Customer, provider, and agent flows have concrete screen inventories.
- CRM, executive, manager, and super-admin surfaces are primarily represented through `portal_shell.dart` and portal metadata rather than dedicated feature screen files.
- Role completeness work in later phases must treat `portal_shell.dart` as a major verification surface for internal roles, not assume feature folders exist for every declared role.
- The current inventory supports the user's maturity assessment: provider and agent have deeper dedicated surface area than CRM, manager, executive, and admin.
