# 📋 SHIELD PHARMACY — OWNER MANUAL UAT PACK & HANDOFF GUIDE

**Target Portal**: `https://shield-zabnix.vercel.app/#/portal/pharmacy-staff/`  
**Target Roles**: Pharmacy Staff / Pharmacist  
**Target Devices**: Web Desktop (Chrome/Edge), Web Mobile (iOS/Android Browser), Android APK  

---

## 📩 Instructions for Project Owner

As the human project owner executing final manual runtime UAT, you can record test results in this document or send back feedback containing:
- Screen recording / Screenshots
- Browser DevTools Console / Network logs
- Database query outputs (read-only)

When reporting an issue, cite the **Test ID** below for instant source resolution.

---

## 1. Dashboard Tests (`/portal/pharmacy-staff/dashboard`)

### `UAT-DASH-01`: KPI Card Navigation & Filter Synchronization
- **Precondition**: Logged in as Pharmacy Staff user assigned to UAT Pharmacy outlet.
- **What to Click**: Click **New Orders** metric card.
- **Expected UI Result**: Navigates to `/orders` with the `New` status filter tab active.
- **Expected Network Route**: `GET /pharmacy/orders?status=NEW`
- **Post-Refresh Check**: Refreshing `/orders` maintains `New` status filter.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-DASH-02`: Financial KPI Navigation
- **Precondition**: Dashboard loaded.
- **What to Click**: Click **Pending Payments** metric card.
- **Expected UI Result**: Navigates to `/payments` with the `Pending` status filter tab active.
- **Expected Network Route**: `GET /pharmacy/payments?status=PENDING`
- **Post-Refresh Check**: Refreshing `/payments` maintains `Pending` filter.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-DASH-03`: Recent Order Navigation (Active vs History)
- **Precondition**: Recent orders list populated on Dashboard.
- **What to Click**: Click a recent order with status `COMPLETED`.
- **Expected UI Result**: Navigates directly to `/history` and opens the completed order detail.
- **Expected Network Route**: `GET /pharmacy/orders/history/:id`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 2. Orders Workspace Tests (`/portal/pharmacy-staff/orders`)

### `UAT-ORD-01`: Low Stock Partial Fulfillment Enforcement
- **Precondition**: Active order containing item with `availableQty < requestedQty`.
- **What to Click**: Click **Partial Fulfill** on the low-stock item.
- **Expected UI Result**: Fulfill quantity is capped at `availableQty`; item badge displays `LOW STOCK`.
- **Expected Network Route**: `PATCH /pharmacy/orders/:id/items/:itemId`
- **Post-Refresh Check**: Refreshing page maintains partial fulfillment quantity and status.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-ORD-02`: Substitute Product Suggestion
- **Precondition**: Active order item requiring brand substitution.
- **What to Click**: Click **Suggest Substitute**, select alternate product reference, and save.
- **Expected UI Result**: Item displays substitute product name and price adjustment; status chip updates to `SUBSTITUTED`.
- **Expected Network Route**: `PATCH /pharmacy/orders/:id/items/:itemId`
- **Post-Refresh Check**: Reloading order detail retains substitute product name and unit price.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-ORD-03`: Customer Confirmation Request
- **Precondition**: Order requiring customer price change confirmation.
- **What to Click**: Click **Request Customer Confirmation**.
- **Expected UI Result**: Order status chip updates to `AWAITING_CONFIRMATION`; confirmation banner appears.
- **Expected Network Route**: `POST /pharmacy/orders/:id/request-customer-confirmation`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-ORD-04`: Partial Dispatch Enforcement
- **Precondition**: `HOME_DELIVERY` order with subset of items approved.
- **What to Click**: Click **Partial Dispatch**.
- **Expected UI Result**: Dispatches approved items; order status updates to `PARTIALLY_DISPATCHED`.
- **Expected Network Route**: `POST /pharmacy/orders/:id/partial-dispatch`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-ORD-05`: Store Pickup Dispatch Guard
- **Precondition**: `STORE_PICKUP` order.
- **What to Click**: Inspect contextual action bar.
- **Expected UI Result**: Delivery dispatch action is hidden or disabled.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 3. Invoice File Lifecycle Tests

### `UAT-INV-01`: Invoice File Upload
- **Precondition**: Active order selected.
- **What to Click**: Click **Browse Files** under Upload Bill / Invoice card and select a PDF/Image file.
- **Expected UI Result**: File uploads cleanly; invoice filename, size, and uploaded timestamp display.
- **Expected Network Route**: `POST /pharmacy/orders/:id/invoice/upload` (Multer Multipart)
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-INV-02`: Authenticated Private Invoice Viewing
- **Precondition**: Order with uploaded invoice file.
- **What to Click**: Click **View Invoice**.
- **Expected UI Result**: Authenticated pre-signed private URL stream opens invoice file in new browser tab / viewer.
- **Expected Network Route**: `GET /pharmacy/orders/:id/invoice/file`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-INV-03`: Invoice Replacement & Removal
- **Precondition**: Order with uploaded invoice file.
- **What to Click**: Click **Replace Invoice** (or **Remove Invoice**).
- **Expected UI Result**: Replacing uploads new file; removing deletes invoice metadata after refresh.
- **Expected Network Route**: `POST /pharmacy/orders/:id/invoice/upload` / `DELETE /pharmacy/orders/:id/invoice`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-INV-04`: Send Invoice & Duplicate Guard
- **Precondition**: Order with valid uploaded invoice.
- **What to Click**: Click **Send Invoice** twice.
- **Expected UI Result**: First click marks invoice sent and emits push notification; second click is idempotent.
- **Expected Network Route**: `POST /pharmacy/orders/:id/send-invoice`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-INV-05`: Mandatory Invoice Dispatch Guard
- **Precondition**: `requireInvoiceBeforeDispatch = true` in Pharmacy Settings; order without invoice.
- **What to Click**: Attempt status transition `PREPARING -> READY_FOR_PICKUP`.
- **Expected UI Result**: Status change blocked; user-friendly error toast displays `"Invoice file is required before dispatch"`.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 4. Payments Ledger Tests (`/portal/pharmacy-staff/payments`)

### `UAT-PAY-01`: Manual Payment Approval & Wallet Credit
- **Precondition**: Pending manual payment receipt.
- **What to Click**: Click **Approve Payment**.
- **Expected UI Result**: Payment status transitions `PENDING -> APPROVED`; customer wallet credited exactly once.
- **Expected Network Route**: `POST /pharmacy/payments/:id/approve`
- **Post-Refresh Check**: Customer wallet balance increases by exact payment amount.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-PAY-02`: Duplicate Approval Protection
- **Precondition**: Payment receipt already marked `APPROVED`.
- **What to Click**: Attempt double-click or re-approve.
- **Expected UI Result**: Action blocked; no secondary wallet credit occurs.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-PAY-03`: Counter Wallet Recharge (Privilege Card Member)
- **Precondition**: Registered SHIELD Privilege Card / Membership holder.
- **What to Click**: Click **+ Accept Counter Payment**, enter ₹10,000, and submit.
- **Expected UI Result**: Counter recharge succeeds; customer wallet credited ₹10,000 + 10% promotional benefit.
- **Expected Network Route**: `POST /pharmacy/payments/submit`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 5. Payment Details Tests (`/portal/pharmacy-staff/payment-details`)

### `UAT-SET-BANK`: Add / Edit Bank Credentials
- **Precondition**: Payment Details page loaded.
- **What to Click**: Click **Edit Bank Account**, update IFSC/Account No., and click Save.
- **Expected UI Result**: Primary Bank Account card updates immediately.
- **Expected Network Route**: `PATCH /pharmacy/payment-details/bank-accounts/:id`
- **Post-Refresh Check**: Bank details persist after page reload.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-SET-UPI`: Upload & Stream UPI QR Code
- **Precondition**: Payment Details page loaded.
- **What to Click**: Click **Upload QR Image**, select QR code file, and save.
- **Expected UI Result**: UPI QR image uploads and streams in preview card.
- **Expected Network Route**: `POST /pharmacy/payment-details/upi/:id/qr` / `GET /pharmacy/payment-details/upi/:id/qr-image`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 6. History Archive Tests (`/portal/pharmacy-staff/history`)

### `UAT-HIST-01`: Archive Status & Date Range Presets
- **Precondition**: History page loaded.
- **What to Click**: Click **Completed** status tab and **Last 30 Days** date preset.
- **Expected UI Result**: Archival queue filters completed orders from the last 30 days.
- **Expected Network Route**: `GET /pharmacy/orders/history?status=COMPLETED&from=...&to=...`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 7. Profile & Outlet Lock Tests (`/portal/pharmacy-staff/profile`)

### `UAT-PROF-01`: Single-Outlet Assigned Pharmacy Lock
- **Precondition**: Profile page loaded.
- **What to Inspect**: Inspect Pharmacy / Store Information card.
- **Expected UI Result**: Outlet information is read-only. No branch selection dropdown or outlet switcher exists.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

### `UAT-PROF-02`: Edit Operating Hours & Store Phone
- **Precondition**: Profile page loaded.
- **What to Click**: Click **Edit Business Details**, update phone/hours, and save.
- **Expected UI Result**: Store details update; dialog closes cleanly without overflow.
- **Expected Network Route**: `PATCH /pharmacy/profile`
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 8. Settings Policy Enforcement Tests (`/portal/pharmacy-staff/settings`)

### `UAT-SETT-01`: Sticky Action Bar Responsive Layout
- **Precondition**: Settings page loaded on mobile screen (390px width).
- **What to Inspect**: Sticky bottom action panel.
- **Expected UI Result**: Discard Changes and Save Settings buttons wrap cleanly without RenderFlex errors.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:

---

## 9. Security & Provider Isolation Tests

### `UAT-SEC-01`: Cross-Provider Authorization Fail-Closed
- **Precondition**: Logged in as Staff for Pharmacy A.
- **What to Test**: Attempt direct URL / API request accessing Pharmacy B order ID.
- **Expected UI Result**: Access denied with plain-language error message; backend returns `403 Forbidden`.
- **Result Box**: `[ ] PASS   [ ] FAIL` — Notes:
