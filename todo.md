# SHIELD DEFERRED CROSS-PORTAL WORK LOG

> **Scope Note**: Active implementation scope is strictly LIMITED TO the Pharmacy Portal. Customer/Agent/Admin/Doctor/Clinic/Lab UI and backend submission features are deferred per project governance.

---

## 1. Customer Portal — Customer Add Money / Wallet Recharge Submission Flow

- **Affected Portal**: Customer Portal (`frontend/lib/features/customer/` or future customer package)
- **Affected Pages/Components**:
  - `WalletScreen` / `AddMoneyModal`
  - `PharmacySelectorWidget`
  - `PaymentChannelSelectorWidget`
  - `BankUpiDestinationDisplayCard`
  - `ManualRechargeProofSubmissionForm`
  - `CustomerRechargeIntentStatusScreen`
- **Required Change**:
  1. Add "Add Money / Recharge Wallet" action on Customer Wallet dashboard.
  2. Implement pharmacy selection prompt allowing customers to select their preferred Pharmacy branch for manual payment.
  3. Fetch and display active payment destination snapshot (`BANK_TRANSFER` details or `UPI` ID) for the selected Pharmacy.
  4. Build input form for UTR / Reference Number entry and proof document (screenshot/receipt) upload to Cloudflare R2 (`proof_storage_path`).
  5. Support `PAY_AT_PHARMACY` intent creation with generated payment code for counter payment.
  6. Support `PAID_THROUGH_AGENT` intent creation when customer pays through an authorized SHIELD agent.
  7. Display live/pending recharge intent status list (`PENDING`, `APPROVED`, `REJECTED`) with clear audit messages and rejection feedback.
- **Full Backend POST Endpoint Contract Specification**:
  - **Endpoint**: `POST /api/v1/wallet/customer/recharge-intents`
  - **Request Body**:
    ```json
    {
      "amount": 500.0,
      "idempotencyKey": "cust-req-uuid-1234",
      "providerId": "50",
      "paymentMethodId": "20",
      "paymentChannel": "BANK_TRANSFER | UPI | PAY_AT_PHARMACY | PAID_THROUGH_AGENT",
      "referenceNumber": "UTR987654321",
      "proofStoragePath": "proofs/cust_100/recharge_1234.png"
    }
    ```
  - **Backend Validation Requirements (To be enabled in Customer Phase)**:
    - Validate `amount > 0`.
    - Validate `idempotencyKey` uniqueness per customer.
    - Validate `providerId` belongs to an active `PHARMACY` service provider.
    - Validate `paymentChannel` is one of `['BANK_TRANSFER', 'UPI', 'PAY_AT_PHARMACY', 'PAID_THROUGH_AGENT']`.
    - Validate `paymentMethodId` belongs to `providerId`, is active, and snapshot into `destinationSnapshot` JSON column.
    - Status default: `PENDING` (Never credit customer wallet balance on creation; balance is strictly updated upon Pharmacy Provider approval).
- **Future Test Suite Specification**:
  - Create `backend/src/wallet/customer-recharge-intent.spec.ts` during Customer Phase covering:
    1. Positive amount assertion (`BadRequestException` on `<= 0`).
    2. Idempotency key deduplication and key reuse mismatch rejection.
    3. Active pharmacy provider validation.
    4. Invalid payment channel rejection.
    5. Destination snapshot generation from `service_provider_payment_methods`.
    6. Customer principal context isolation.
    7. Zero-credit financial invariant (`status = PENDING`, no `cash_wallet_transactions` record on creation).
- **Database Dependencies**:
  - Table: `wallet_recharge_intents`
  - Unique Constraint: `idx_wallet_transactions_manual_recharge_unique`
- **Business Reason**: Active implementation scope is strictly Pharmacy Portal. Customer submission UI & backend contract expansion are deferred to Customer Portal Phase.
- **Priority**: `HIGH`
- **Blocks Pharmacy MVP**: `NO` (Pharmacy Portal can verify and process any submitted intents independently using existing Phase 3 `PharmacyPaymentsService` endpoints).
- **Suggested Future Phase**: Customer Portal Phase 2 (Financial Features & Wallet Operations).

---

## 2. Agent Portal — Agent-Assisted Manual Payment Workflow

- **Affected Portal**: Agent Portal (`frontend/lib/features/agent/`)
- **Affected Pages/Components**:
  - `AgentCustomerManagementScreen`
  - `AgentCollectCashForm`
  - `AgentRechargeSubmissionModal`
- **Required Change**:
  1. Allow SHIELD Agents to initiate manual wallet recharge on behalf of enrolled customers under `PAID_THROUGH_AGENT` channel.
  2. Capture agent ID, collection receipt, and optional pharmacy branch assignment.
  3. Submit `wallet_recharge_intents` record linked to customer with agent audit metadata.
- **Backend / API Dependencies**:
  - `POST /api/v1/wallet/agent/recharge-intents` or extended `POST /api/v1/wallet/customer/recharge-intents` with agent auth context.
- **Database Dependencies**:
  - Table: `wallet_recharge_intents` (`payment_channel = 'PAID_THROUGH_AGENT'`, `reviewed_by` / `metadata`)
- **Business Reason**: Agent UI is outside current Pharmacy implementation scope.
- **Priority**: `MEDIUM`
- **Blocks Pharmacy MVP**: `NO`
- **Suggested Future Phase**: Agent Portal Phase 2.

---

## 3. Customer Portal — Order Substitution & Chronic Refill Confirmation UI

- **Affected Portal**: Customer Portal (`frontend/lib/features/customer/`)
- **Affected Pages/Components**:
  - `CustomerOrderTrackingScreen`
  - `SubstitutionApprovalSheet`
  - `ChronicRefillSubscriptionWidget`
- **Required Change**:
  1. Display pharmacist substitution proposals (original brand vs proposed alternate brand, price difference, reason).
  2. Allow customer to accept or decline proposed substitution.
  3. Display chronic refill reminder schedules and manage subscription preferences.
- **Backend / API Dependencies**:
  - `POST /api/v1/customer/orders/:id/confirm-substitution`
- **Priority**: `MEDIUM`
- **Blocks Pharmacy MVP**: `NO` (Pharmacy Portal emits substitution requests and records audit history independently).
- **Suggested Future Phase**: Customer Portal Phase 3.

---

## 4. Customer Portal — Invoice PDF Viewer & Chronic Refill Response
- **Affected Portal**: Customer Portal (`frontend/lib/features/customer/`)
- **Affected Pages/Components**:
  - `CustomerOrderDetailScreen`
  - `InvoicePdfViewerSheet`
  - `ChronicRefillResponseWidget`
- **Required Change**:
  1. Display dispatched invoice PDF for completed/dispatched pharmacy orders.
  2. Allow customer to view chronic refill schedules generated by pharmacy staff.
- **Priority**: `MEDIUM`
- **Blocks Pharmacy MVP**: `NO` (Pharmacy Portal generates, uploads, and dispatches invoice metadata independently).
- **Suggested Future Phase**: Customer Portal Phase 3.

---

## 5. Super Admin Portal — Pharmacy Staff Outlet Assignment
- **Affected Portal**: SHIELD Super Admin (`frontend/lib/features/admin/`)
- **Affected Pages/Components**:
  - `StaffUserManagementScreen`
  - `PharmacyBranchAssignmentModal`
- **Required Change**:
  1. Super Admin selects exactly one Business / outlet for a Pharmacy Staff user.
  2. Persist to `users.branch_business_id`.
  3. Changing assignment immediately changes the provider scope after the appropriate session refresh / re-login.
  4. Pharmacy Staff cannot self-assign or switch.
- **Priority**: `HIGH`
- **Blocks Pharmacy MVP**: `NO` (Owner can assign through existing admin / database tooling).
- **Suggested Future Phase**: Admin Portal Phase 1.



