# SHIELD Phase 0 RBAC Surface Inventory

**Date:** 2026-07-03  
**Phase:** 0 - Discovery and Inventory  
**Primary sources:** `backend/src/auth/rbac-catalog.ts`, `frontend/lib/shared/models/shield_role.dart`, `docs/SHIELD Portal Navigation Map.md`

## Backend Role Inventory

### Human Roles

- `ADMIN`
- `SHIELD_AGENT`
- `CRM_EXECUTIVE`
- `PHARMACY_PROVIDER`
- `LAB_PROVIDER`
- `DOCTOR`
- `HOMECARE_PROVIDER`
- `DENTAL_PROVIDER`
- `COSMETIC_PROVIDER`
- `DIETITIAN`
- `CUSTOMER`

### System Roles

- `SYSTEM`
- `BACKGROUND_WORKER`
- `NOTIFICATION_SERVICE`
- `WEBHOOK_SERVICE`

## Permission Resource Inventory

- `customers`
- `wallet`
- `membership`
- `appointments`
- `medical_records`
- `documents`
- `reports`
- `crm`
- `agents`
- `providers`
- `referrals`
- `analytics`
- `settings`
- `notifications`

## Frontend Portal Role Inventory

- `customer`
- `agent`
- `provider`
- `pharmacy-staff`
- `clinic-staff`
- `dental-staff`
- `crm-executive`
- `shield-executive`
- `manager`
- `super-admin`

## Backend-To-Frontend Mapping Baseline

### Direct or implemented mappings

- `CUSTOMER` -> `customer`
- `SHIELD_AGENT` -> `agent`
- `CRM_EXECUTIVE` -> `crm-executive`
- `ADMIN` -> `super-admin`
- `PHARMACY_PROVIDER`, `LAB_PROVIDER`, `DOCTOR`, `HOMECARE_PROVIDER`, `DENTAL_PROVIDER`, `COSMETIC_PROVIDER`, `DIETITIAN` -> `provider`

### Partial or unresolved presentation mappings

- `shield-executive`: declared in frontend taxonomy and navigation docs, but no direct backend role mapping exists in `SHIELDRole.fromBackendRoleCode(...)`
- `manager`: declared in frontend taxonomy and navigation docs, but no single exact backend role mapping exists today
- `pharmacy-staff`, `clinic-staff`, `dental-staff`: accepted as route aliases but normalized into the unified `provider` shell

## RBAC Findings

- The backend RBAC catalog is richer and more explicit than the current frontend route resolver support.
- Frontend role taxonomy includes presentation-only or future-facing shells that do not yet have proven backend-role resolution or verified route support.
- Phase 8 should produce the full permission matrix by role, screen, route, and backend action, but this inventory already shows where the cross-layer mismatches are likely to surface first.
