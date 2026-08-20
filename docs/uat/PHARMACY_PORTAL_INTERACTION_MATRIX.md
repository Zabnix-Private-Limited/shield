# ⚡ SHIELD PHARMACY STAFF PORTAL — INTERACTION MATRIX

**Target Platform**: SHIELD Pharmacy Staff Portal (`https://shield-zabnix.vercel.app/#/portal/pharmacy-staff/`)  
**Total Controls Tested**: 48  
**Total Workflows Tested**: 14  

---

## 1. Exhaustive Control & Workflow Test Matrix

| Page | Control | Scenario | Precondition | Action | Expected Result | Actual Result | Network Result | Persisted | Responsive | Status | Defect ID | Fix Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| Dashboard | New Orders Card | Quick Filter | Valid session | Click Card | Route to `/orders` with filter `NEW` | Filter `NEW` applied | `GET /pharmacy/orders?status=NEW` | YES | PASS | **PASS** | DEF-01 | FIXED |
| Dashboard | Preparing Card | Quick Filter | Valid session | Click Card | Route to `/orders` with filter `PREPARING` | Filter `PREPARING` applied | `GET /pharmacy/orders?status=PREPARING` | YES | PASS | **PASS** | DEF-01 | FIXED |
| Dashboard | Ready Pickup Card | Quick Filter | Valid session | Click Card | Route to `/orders` with filter `READY_FOR_PICKUP` | Filter `READY_FOR_PICKUP` applied | `GET /pharmacy/orders?status=READY_FOR_PICKUP` | YES | PASS | **PASS** | DEF-01 | FIXED |
| Dashboard | Out for Delivery Card | Quick Filter | Valid session | Click Card | Route to `/orders` with filter `OUT_FOR_DELIVERY` | Filter `OUT_FOR_DELIVERY` applied | `GET /pharmacy/orders?status=OUT_FOR_DELIVERY` | YES | PASS | **PASS** | DEF-01 | FIXED |
| Dashboard | Pending Payments Card | Quick Filter | Valid session | Click Card | Route to `/payments` with filter `PENDING` | Filter `PENDING` applied | `GET /pharmacy/payments?status=PENDING` | YES | PASS | **PASS** | DEF-01 | FIXED |
| Dashboard | Approved Today Card | Quick Filter | Valid session | Click Card | Route to `/payments` with filter `APPROVED` | Filter `APPROVED` applied | `GET /pharmacy/payments?status=APPROVED` | YES | PASS | **PASS** | DEF-01 | FIXED |
| Dashboard | Completed Today Card | Quick Filter | Valid session | Click Card | Route to `/history` with filter `COMPLETED` | Filter `COMPLETED` applied | `GET /pharmacy/history?status=COMPLETED` | YES | PASS | **PASS** | DEF-01 | FIXED |
| Dashboard | Recent Active Order | Quick Select | Active order exists | Click Order Row | Route to `/orders` and select order | Order selected in queue | `GET /pharmacy/orders` | YES | PASS | **PASS** | DEF-02 | FIXED |
| Dashboard | Recent Completed Order | Quick Archive | Completed order exists | Click Order Row | Route to `/history` and load detail | History detail loaded | `GET /pharmacy/history/:id` | YES | PASS | **PASS** | DEF-02 | FIXED |
| Orders | Search Box | Order Lookup | Queue loaded | Type "INV-UAT" | Filter queue matching query | Queue updated | `GET /pharmacy/orders?query=INV-UAT` | YES | PASS | **PASS** | None | N/A |
| Orders | Status Filter Chip | Queue Filter | Queue loaded | Click "Preparing" | Display only preparing orders | Queue updated | `GET /pharmacy/orders?status=PREPARING` | YES | PASS | **PASS** | None | N/A |
| Orders | Approve Full Button | Item Fulfillment | Item pending | Click "Approve Full" | Set `fulfillQty = requestedQty` | Status updated to `APPROVED` | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| Orders | Partial Fulfill Button | Item Fulfillment | Item pending | Click "Partial Fulfill" | Set `fulfillQty <= availableQty` | Status updated to `PARTIAL` | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| Orders | Suggest Substitute | Item Substitution | Item pending | Select Substitute | Record substitute name & price | Status updated to `SUBSTITUTED` | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| Orders | Reject Item Button | Item Rejection | Item pending | Click "Reject Item" | Set `fulfillQty = 0` | Status updated to `REJECTED` | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| Orders | Mark as Chronic | Order Tagging | Order selected | Toggle switch | Persist chronic flag & date | Badge updated | `PATCH /pharmacy/orders/:id/chronic` | YES | PASS | **PASS** | None | N/A |
| Orders | Pharmacist Notes | Internal Remarks | Order selected | Type note & Save | Save note with timestamp | Note saved & displayed | `PATCH /pharmacy/orders/:id/notes` | YES | PASS | **PASS** | None | N/A |
| Orders | Invoice Upload | Bill File Lifecycle | Order selected | Select PDF/Image | Upload file to private R2 storage | Invoice file metadata displayed | `POST /pharmacy/orders/:id/invoice` | YES | PASS | **PASS** | None | N/A |
| Orders | Send Invoice | Customer Event | Invoice uploaded | Click "Send Invoice" | Dispatch invoice notification | Timestamp & status updated | `POST /pharmacy/orders/:id/send-invoice` | YES | PASS | **PASS** | None | N/A |
| Orders | Approve Order | Status Flow | Items reviewed | Click "Approve Order" | Move status `NEW -> ACCEPTED` | Order status updated | `PATCH /pharmacy/orders/:id/status` | YES | PASS | **PASS** | None | N/A |
| Orders | Start Preparing | Status Flow | Order accepted | Click "Start Preparing" | Move status `ACCEPTED -> PREPARING` | Order status updated | `PATCH /pharmacy/orders/:id/status` | YES | PASS | **PASS** | None | N/A |
| Orders | Ready for Pickup | Status Flow | Order preparing | Click "Ready for Pickup" | Move status `PREPARING -> READY` | Order status updated | `PATCH /pharmacy/orders/:id/status` | YES | PASS | **PASS** | None | N/A |
| Orders | Mark Completed | Terminal Flow | Order ready | Click "Mark Completed" | Move status `READY -> COMPLETED` | Order moved to terminal state | `PATCH /pharmacy/orders/:id/status` | YES | PASS | **PASS** | None | N/A |
| Payments | Status Tabs | Ledger Filter | Payments loaded | Click "Pending" | Filter pending payment receipts | List updated | `GET /pharmacy/payments?status=PENDING` | YES | PASS | **PASS** | None | N/A |
| Payments | Accept Counter Payment | Wallet Recharge | Member card | Click "+ Accept Counter Payment" | Open recharge modal dialog | Modal rendered | N/A | YES | PASS | **PASS** | None | N/A |
| Payments | Submit Recharge | Member Recharge | Recharge form | Enter ₹10,000 & submit | Perform counter wallet recharge | Receipt created & auto-approved | `POST /pharmacy/payments/counter` | YES | PASS | **PASS** | None | N/A |
| Payments | Approve Payment | Manual Review | Receipt pending | Click "Approve Payment" | Approve receipt & credit wallet | Status `APPROVED`, wallet credited | `POST /pharmacy/payments/:id/approve` | YES | PASS | **PASS** | None | N/A |
| Payments | Reject Payment | Manual Review | Receipt pending | Click "Reject Payment" | Reject receipt with reason | Status `REJECTED`, 0 wallet credit | `POST /pharmacy/payments/:id/reject` | YES | PASS | **PASS** | None | N/A |
| Payment Details | Edit Bank Details | Payout Config | Details loaded | Click "Edit Bank" | Open edit modal dialog | Modal rendered | N/A | YES | PASS | **PASS** | None | N/A |
| Payment Details | Save Bank Details | Payout Config | Bank form | Submit updated bank details | Update primary bank account | Bank card updated | `PUT /pharmacy/payment-details/bank` | YES | PASS | **PASS** | None | N/A |
| Payment Details | Upload UPI QR | Payout Config | Details loaded | Select QR image | Upload & activate UPI QR | QR preview updated | `POST /pharmacy/payment-details/upi-qr` | YES | PASS | **PASS** | None | N/A |
| History | Status Tabs | Archive Filter | History loaded | Click "Cancelled" | Display cancelled order archives | Archives filtered | `GET /pharmacy/history?status=CANCELLED` | YES | PASS | **PASS** | None | N/A |
| History | Date Presets | Archive Filter | History loaded | Click "Last 30 Days" | Filter archives by date range | Archives filtered | `GET /pharmacy/history?from=...` | YES | PASS | **PASS** | None | N/A |
| History | Order Row | Archive Detail | History loaded | Click Order Row | Open history detail modal | Detail modal rendered | `GET /pharmacy/history/:id` | YES | PASS | **PASS** | None | N/A |
| Profile | Edit Business Info | Store Info | Profile loaded | Click "Edit Business Details" | Open edit modal (`maxHeight: 720`) | Modal rendered | N/A | YES | PASS | **PASS** | None | N/A |
| Profile | Save Business Info | Store Info | Edit form | Save store hours / phone | Update store details | Store card updated | `PUT /pharmacy/profile` | YES | PASS | **PASS** | None | N/A |
| Settings | Workflow Toggles | Policy Config | Settings loaded | Toggle "Auto-accept" | Update draft settings state | Dirty banner displayed | N/A | YES | PASS | **PASS** | None | N/A |
| Settings | Discard Changes | Policy Config | Unsaved changes | Click "Discard Changes" | Reset toggles to saved state | Settings reset | N/A | YES | PASS | **PASS** | None | N/A |
| Settings | Save Settings | Policy Config | Unsaved changes | Click "Save Settings" | Persist operational policies | Settings saved | `PUT /pharmacy/settings` | YES | PASS | **PASS** | None | N/A |
