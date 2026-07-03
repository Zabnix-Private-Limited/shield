# SHIELD Phase 0 Route Inventory

**Date:** 2026-07-03  
**Phase:** 0 - Discovery and Inventory  
**Primary sources:** `frontend/lib/app/routes/app_router.dart`, `frontend/lib/shared/services/portal_resolver.dart`, `docs/SHIELD Complete Route Map.md`, `docs/SHIELD Portal Navigation Map.md`

## Live GoRouter Baseline

### Public and Auth Entry Routes

- `/`
- `/customer/splash`
- `/customer/login`
- `/customer/otp`
- `/customer/register`
- `/internal/login`
- `/session-expired`

### Portal Contract Routes

- `/portal`
- `/portal/:role`
- `/portal/:role/:section`

### Legacy Compatibility Redirects

- `/documents`
- `/appointments`
- `/notifications`
- `/prescriptions`
- `/membership`
- `/transactions`
- `/settings`
- `/services`
- `/wallet`
- `/profile`
- `/more`

## Route Guard and Resolution Behavior

- `app_router.dart` uses auth-aware redirects for customer and internal sessions.
- `PortalResolver.resolvedHomeRoute()` chooses the role home route for the active session and falls back to `/customer/splash` when no session exists.
- `PortalResolver.guardPortalRoute(...)` prevents direct portal-role drift by redirecting to the active resolved role.

## Section Support Currently Enforced By `PortalResolver`

### Customer

- `dashboard`
- `profile`
- `settings`
- `notifications`
- `appointments`
- `documents`
- `membership`
- `services`
- `wallet`
- `prescriptions`

### Agent

- Customer sections above where shared
- `customers`
- `followups`
- `registration`
- `referrals`
- `performance`
- `reports`

### Provider

- Shared sections above where shared
- `queue`
- `customers`

## Declared Route Taxonomy vs Live Resolver Support

### Declared in frontend role metadata and navigation docs

- `customer`
- `agent`
- `provider`
- `crm-executive`
- `shield-executive`
- `manager`
- `super-admin`

### Actually supported by `PortalResolver._roleSupportsSection(...)`

- `customer`
- `agent`
- `provider`

## Route-Level Findings

- `docs/SHIELD Portal Navigation Map.md` declares CRM Executive, SHIELD Executive, Manager, and Super Admin role shells, but `PortalResolver` currently recognizes live section support only for customer, agent, and provider.
- `docs/SHIELD Complete Route Map.md` says `/` redirects to `/customer/splash`, while the live router now redirects to `PortalResolver.resolvedHomeRoute()` and lands on the active session home when authenticated.
- `app_router.dart` includes a live `/session-expired` recovery route, but that recovery surface is not called out in the current route-map docs.
- Phase 7 should treat route-doc drift and unsupported declared internal roles as first-class findings, not minor cleanup.
