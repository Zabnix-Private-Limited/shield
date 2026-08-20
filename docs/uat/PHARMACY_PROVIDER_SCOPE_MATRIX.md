# 🔒 SHIELD PHARMACY — PROVIDER SCOPE & ISOLATION MATRIX

**Target Domain**: Single-Outlet Authorization & Provider Scope Enforcement  
**Source Guard**: `backend/src/auth/provider-scope.service.ts`  
**Source Controller**: `backend/src/pharmacy/pharmacy.controller.ts`  

---

## 1. Provider Isolation Enforcement Map

| Endpoint | HTTP Method | Scope Resolver | Assigned Business Used | Arbitrary Provider Input Accepted | Cross-Provider Protected | Status |
| :--- | :---: | :--- | :---: | :---: | :---: | :---: |
| `/pharmacy/dashboard` | GET | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders` | GET | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/summary` | GET | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/:id` | GET | `ProviderScopeService.assertProviderCanAccessOrder` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/:id/status` | PATCH | `ProviderScopeService.assertProviderCanAccessOrder` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/:id/items/:itemId` | PATCH | `ProviderScopeService.assertProviderCanAccessOrder` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/:id/invoice/upload` | POST | `ProviderScopeService.assertProviderCanAccessOrder` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/:id/invoice/file` | GET | `ProviderScopeService.assertProviderCanAccessOrder` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/:id/send-invoice` | POST | `ProviderScopeService.assertProviderCanAccessOrder` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/history` | GET | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/orders/history/:id` | GET | `ProviderScopeService.assertProviderCanAccessOrder` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/payments` | GET | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/payments/:id` | GET | `ProviderScopeService.assertProviderCanAccessPayment` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/payments/:id/approve` | POST | `ProviderScopeService.assertProviderCanAccessPayment` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/payments/:id/reject` | POST | `ProviderScopeService.assertProviderCanAccessPayment` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/payment-details` | GET | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/profile` | GET / PATCH | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |
| `/pharmacy/settings` | GET / PATCH | `ProviderScopeService.resolveAssignedPharmacyId` | `users.branch_business_id` | NO | **YES (403 Fail-Closed)** | **SOURCE_VERIFIED** |

---

## 2. Unassigned Staff Handling

> [!NOTE]
> If a Pharmacy Staff user has no assigned `branch_business_id` in `users`, `ProviderScopeService` throws `ForbiddenException("No pharmacy assigned to staff account")`. The frontend intercepts this state and displays the **No Pharmacy Assigned** fail-closed page.
