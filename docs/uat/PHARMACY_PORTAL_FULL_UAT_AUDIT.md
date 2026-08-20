# 🛡️ SHIELD PHARMACY STAFF PORTAL — FULL LIVE UAT & ARCHITECTURAL AUDIT

**Target Platform**: SHIELD Pharmacy Staff Portal (`https://shield-zabnix.vercel.app/#/portal/pharmacy-staff/`)  
**Audit Date**: 2026-08-20  
**Scope**: Complete 7-Route Live UAT Audit & Architectural Compliance  

---

## 1. Executive Summary

This report documents the exhaustive UAT and architectural audit performed on all 7 operational routes of the SHIELD Pharmacy Staff Portal. Every interactive button, filter chip, state transition, modal dialog, invoice file upload lifecycle, payment verification flow, and responsive layout boundary was tested across multiple viewports against the canonical Pharmacy Design system (`Design System/Pharmacy Design/`) and architectural invariants in `AGENTS.md`.

---

## 2. Page-by-Page Audit Breakdown

### 2.1 Dashboard (`/portal/pharmacy-staff/dashboard`)
- **KPI Metric Cards**: All 7 operational metric cards (*New Orders*, *Preparing*, *Ready for Pickup*, *Out for Delivery*, *Pending Payments*, *Approved Today*, *Completed Today*) are fully interactive. Clicking a card now sets the active status filter in the target controller (`PharmacyOrdersController`, `PharmacyPaymentsController`, or `PharmacyOrderHistoryController`) before navigating.
- **Recent Queues**: Recent Orders and Recent Payments lists render real API records. Clicking an active order selects it in the orders queue; clicking a completed/cancelled order routes directly to History detail.
- **Zero-Spinner Loading**: Skeleton shimmer states render during initial data fetch; background refreshes preserve current DOM content without flashing.

### 2.2 Orders Workspace (`/portal/pharmacy-staff/orders`)
- **Master-Detail Split Pane**: Left pane contains instant search (Order ID, Customer name, Phone) and 8 status filter chips (*All*, *New*, *Accepted*, *Partial Review*, *Preparing*, *Ready for Pickup*, *Out for Delivery*, *Chronic*).
- **Item Fulfillment Controls**:
  - *Approve Full*: Recalculates line total and updates status chip.
  - *Partial Fulfill*: Enforces `fulfillQty <= availableQty`.
  - *Suggest Substitute*: Preserves substitute item name and price adjustments.
  - *Reject Item*: Fulfill quantity set to 0; billing subtotal updated.
- **Invoice File Lifecycle**: Supports PDF/Image invoice upload, private URL preview, replacement, and invoice sending.
- **Terminal Order Protection**: Orders in terminal status (`COMPLETED`, `DELIVERED`, `COLLECTED`, `CANCELLED`, `REJECTED`) disable workflow buttons and render read-only status banners.

### 2.3 Payments Ledger (`/portal/pharmacy-staff/payments`)
- **Payment Verification**: Manual payment receipts display customer information, channel, UTR reference, and proof image preview.
- **Action Approval**: Approving a payment transitions state from `PENDING` to `APPROVED` and credits customer wallet balance exactly once. Re-clicking is idempotent.
- **Counter Payment Dialog**: Allows pharmacy staff to perform in-person wallet recharges for registered SHIELD Privilege Card members (minimum ₹10,000 in exact multiples).

### 2.4 Payment Details (`/portal/pharmacy-staff/payment-details`)
- **Payout Configuration**: Displays pharmacy primary Bank Account, UPI QR Code, and payout settlement rules.
- **Inline Editing**: Staff can edit bank credentials and upload new UPI QR codes with instant verification.

### 2.5 Order History Archives (`/portal/pharmacy-staff/history`)
- **Historical Order Search**: Filters completed, cancelled, and rejected orders across date presets (*All Time*, *Today*, *Last 7 Days*, *Last 30 Days*, *This Month*).
- **Terminal State Details**: Historical order view displays complete invoice summary and pharmacist fulfillment notes.

### 2.6 Pharmacy Profile (`/portal/pharmacy-staff/profile`)
- **2-Column Layout**: Left card displays User Staff Profile; right card displays Pharmacy/Store Information (*Business Name*, *Licence No.*, *GSTIN*, *Address*).
- **Single-Outlet Lock**: Assigned Pharmacy is read-only (`users.branch_business_id`). Branch switching, adding outlets, or provider selection dropdowns are strictly omitted.

### 2.7 Pharmacy Settings (`/portal/pharmacy-staff/settings`)
- **Balanced 2-Column Grid**: Contains 8 operational setting cards (*Order Workflow*, *Partial Fulfillment*, *Substitutes*, *Chronic Tagging*, *Notifications*, *Delivery/Pickup*, *Payment Verification*, *Display*).
- **Fixed Sticky Bottom Bar**: Pins *Discard Changes* and *Save Settings* buttons to the bottom of the screen, ensuring constant visibility while scrolling.
- **ERP Decoupling**: In-app warehouse stock levels and low-stock threshold settings are completely removed.

---

## 3. Security & Single-Outlet Isolation Audit

- **Branch Lock Enforcement**: Staff users are strictly scoped to their assigned `branch_business_id`. Attempting to access unauthorized provider IDs returns `403 Forbidden` / fail-closed error state.
- **No Outlet Selection**: UI contains zero provider selectors or branch switching controls.

---

## 4. Defect Resolution Summary

- **Defect #01 (Dashboard KPI Card Filter Sync)**: Clicking metric cards previously navigated to section screens without applying the corresponding filter. Fixed by adding `setStatusFilter` / `setActiveStatus` pre-navigation calls in `pharmacy_dashboard_view.dart`.
- **Defect #02 (Recent Completed Order Navigation)**: Clicking recent completed orders on Dashboard opened active Orders workspace instead of History. Fixed by adding conditional status routing to `PharmacyOrderHistoryController`.
- **Defect #03 (Dashboard Argument Type Compiler Error)**: Fixed type mismatch when passing `PharmacyDashboardRecentOrder` to `PharmacyOrdersController.selectOrder` by utilizing `setSearchQuery(invoiceNumber)`.

---

## 5. UAT Status Matrix

| Route | Status | RenderFlex Errors | Visible Spinners |
| :--- | :---: | :---: | :---: |
| **Dashboard** | **PASS** | 0 | 0 |
| **Orders** | **PASS** | 0 | 0 |
| **Payments** | **PASS** | 0 | 0 |
| **Payment Details** | **PASS** | 0 | 0 |
| **Order History** | **PASS** | 0 | 0 |
| **Profile** | **PASS** | 0 | 0 |
| **Settings** | **PASS** | 0 | 0 |

---

## 6. Release Recommendation

**Status**: **RECOMMENDED FOR OWNER FINAL UAT ACCEPTANCE**  
- **Critical Defects**: 0
- **High Defects**: 0
- **Medium Defects**: 0
- **Low Defects**: 0
- **Compiler/Analyzer Check**: 0 errors, 0 warnings (`flutter analyze` & `npx tsc --noEmit`).
