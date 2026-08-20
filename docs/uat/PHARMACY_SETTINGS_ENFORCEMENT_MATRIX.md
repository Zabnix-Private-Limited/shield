# ⚙️ SHIELD PHARMACY — SETTINGS POLICY ENFORCEMENT MATRIX

**Target Domain**: Pharmacy Operational Policies & Settings Enforcement  
**Source DTO**: `backend/src/pharmacy/dto/pharmacy_settings.dto.ts`  
**Source Service**: `backend/src/pharmacy/pharmacy.service.ts`  

---

## 1. Operational Settings Enforcement Map

| Setting Key | Persisted | Backend Consumer | Service Method | Server-Side Enforced | Frontend Consumer | Status | Owner UAT Scenario |
| :--- | :---: | :--- | :--- | :---: | :--- | :---: | :--- |
| `autoAcceptOrders` | YES | `PharmacyService` | `createCustomerOrder` | **YES** | Order Queue Status Badges | **SOURCE_VERIFIED** | Submit customer order and verify if auto-accepted |
| `requireInvoiceBeforeDispatch` | YES | `PharmacyService` | `updateOrderStatus` | **YES** | Dispatch Button Handler Guard | **SOURCE_VERIFIED** | Attempt status transition `PREPARING -> READY` without invoice |
| `allowPartialFulfillment` | YES | `PharmacyService` | `updateOrderItemFulfillment` | **YES** | Item Decision Form Controls | **SOURCE_VERIFIED** | Submit partial quantity on item decision |
| `allowPartialDispatch` | YES | `PharmacyService` | `partialDispatchOrder` | **YES** | Partial Dispatch Button | **SOURCE_VERIFIED** | Dispatch approved items while remaining items pending |
| `suggestSubstitutes` | YES | `PharmacyService` | `updateOrderItemFulfillment` | **YES** | Substitute Brand Selection Form | **SOURCE_VERIFIED** | Propose alternate brand medicine on low stock item |
| `requireCustomerConfirmation` | YES | `PharmacyService` | `requestCustomerConfirmation` | **YES** | Confirmation Request Banner | **SOURCE_VERIFIED** | Propose price change / substitution and trigger confirmation |
| `enableChronicTagging` | YES | `PharmacyService` | `toggleChronicOrder` | **YES** | Order Badge & Chronic Queue Filter | **SOURCE_VERIFIED** | Toggle "Mark as Chronic" and verify queue filter |
| `defaultRefillCadenceDays` | YES | `PharmacyService` | `toggleChronicOrder` | **YES** | Refill Cadence Indicator | **SOURCE_VERIFIED** | Check default cadence value in chronic tag summary |
| `newOrderSoundAlerts` | YES | App Audio Engine | Browser Sound Manager | **FRONTEND-ONLY** | Dashboard Sound Alert Chime | **SOURCE_VERIFIED** | Receive new order push event with audio chime |
| `paymentSubmissionAlerts` | YES | App Notification | Notification Manager | **FRONTEND-ONLY** | Notification Bell Badge | **SOURCE_VERIFIED** | Submit manual payment receipt and check bell badge |
| `enableHomeDelivery` | YES | `PharmacyService` | `createCustomerOrder` | **YES** | Checkout Fulfillment Mode Selector | **SOURCE_VERIFIED** | Submit home delivery order when mode enabled vs disabled |
| `enableStorePickup` | YES | `PharmacyService` | `createCustomerOrder` | **YES** | Checkout Fulfillment Mode Selector | **SOURCE_VERIFIED** | Submit store pickup order when mode enabled vs disabled |
| `mandatoryManualVerification` | YES | `PharmacyPaymentsService` | `submitManualPayment` | **YES (PROTECTED)** | Counter Payment Form | **SOURCE_VERIFIED** | Submit manual payment receipt; verify manual approval required |
| `requireUtrProof` | YES | `PharmacyPaymentsService` | `submitManualPayment` | **YES** | Payment Proof Upload Form | **SOURCE_VERIFIED** | Submit manual payment without UTR reference |
| `dateFormat` | YES | UI Formatter | `DateFormatUtil` | **FRONTEND-ONLY** | Date Display Elements | **SOURCE_VERIFIED** | Change date format and check order placed timestamp format |
| `timeFormat` | YES | UI Formatter | `TimeFormatUtil` | **FRONTEND-ONLY** | Time Display Elements | **SOURCE_VERIFIED** | Change time format and check order timestamp format |

---

## 2. Safety Audit: Manual Payment Integrity

> [!IMPORTANT]
> **Manual Verification Guard Invariant**: Changing `mandatoryManualVerification` to `FALSE` in Pharmacy Settings **does NOT** trigger automatic wallet credit. All manual payments and counter recharges require backend staff approval or explicit authorized counter transaction processing (`PharmacyPaymentsService.approvePayment`).
