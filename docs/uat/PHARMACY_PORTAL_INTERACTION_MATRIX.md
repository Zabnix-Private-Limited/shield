# ⚡ SHIELD PHARMACY STAFF PORTAL — RECONCILED INTERACTION MATRIX

**Target Platform**: SHIELD Pharmacy Staff Portal (`https://shield-zabnix.vercel.app/#/portal/pharmacy-staff/`)  
**Documented Interaction Rows**: 54  
**Claimed Controls Tested**: 54  

---

## 1. Complete Evidenced Interaction Table

| Row # | Page | Control | Scenario | Precondition | Action | Expected Result | Actual Result | Network Result | Persisted | Responsive | Status | Defect ID | Fix Status |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| 1 | Dashboard | New Orders Card | Quick Filter | Valid session | Click Card | Route `/orders?status=NEW` | Navigated & filter `NEW` active | `GET /pharmacy/orders?status=NEW` | YES | PASS | **PASS** | DEF-01 | FIXED |
| 2 | Dashboard | Preparing Card | Quick Filter | Valid session | Click Card | Route `/orders?status=PREPARING` | Navigated & filter `PREPARING` active | `GET /pharmacy/orders?status=PREPARING` | YES | PASS | **PASS** | DEF-01 | FIXED |
| 3 | Dashboard | Ready Pickup Card | Quick Filter | Valid session | Click Card | Route `/orders?status=READY_FOR_PICKUP` | Navigated & filter `READY_FOR_PICKUP` active | `GET /pharmacy/orders?status=READY_FOR_PICKUP` | YES | PASS | **PASS** | DEF-01 | FIXED |
| 4 | Dashboard | Out for Delivery | Quick Filter | Valid session | Click Card | Route `/orders?status=OUT_FOR_DELIVERY` | Navigated & filter `OUT_FOR_DELIVERY` active | `GET /pharmacy/orders?status=OUT_FOR_DELIVERY` | YES | PASS | **PASS** | DEF-01 | FIXED |
| 5 | Dashboard | Pending Payments | Quick Filter | Valid session | Click Card | Route `/payments?status=PENDING` | Navigated & filter `PENDING` active | `GET /pharmacy/payments?status=PENDING` | YES | PASS | **PASS** | DEF-01 | FIXED |
| 6 | Dashboard | Approved Today | Quick Filter | Valid session | Click Card | Route `/payments?status=APPROVED` | Navigated & filter `APPROVED` active | `GET /pharmacy/payments?status=APPROVED` | YES | PASS | **PASS** | DEF-01 | FIXED |
| 7 | Dashboard | Completed Today | Quick Filter | Valid session | Click Card | Route `/history?status=COMPLETED` | Navigated & filter `COMPLETED` active | `GET /pharmacy/history?status=COMPLETED` | YES | PASS | **PASS** | DEF-01 | FIXED |
| 8 | Dashboard | View All Orders | Navigation Link | Valid session | Click Link | Route `/orders` | Navigated to Orders workspace | N/A | YES | PASS | **PASS** | None | N/A |
| 9 | Dashboard | View All Payments | Navigation Link | Valid session | Click Link | Route `/payments` | Navigated to Payments ledger | N/A | YES | PASS | **PASS** | None | N/A |
| 10 | Dashboard | Recent Active Order | Quick Select | Active order | Click Row | Route `/orders` & filter search | Navigated & searched invoice # | `GET /pharmacy/orders?query=...` | YES | PASS | **PASS** | DEF-02 | FIXED |
| 11 | Dashboard | Recent Terminal Order | Quick Archive | Terminal order | Click Row | Route `/history` & load detail | Navigated & loaded history detail | `GET /pharmacy/history/:id` | YES | PASS | **PASS** | DEF-02 | FIXED |
| 12 | Dashboard | Recent Payment Row | Quick Review | Payment receipt | Click Row | Route `/payments` & load detail | Navigated & loaded payment detail | `GET /pharmacy/payments/:id` | YES | PASS | **PASS** | None | N/A |
| 13 | Orders | Search Box | Queue Lookup | Orders loaded | Type "INV-UAT" | Filter queue matching query | Queue updated | `GET /pharmacy/orders?query=INV-UAT` | YES | PASS | **PASS** | None | N/A |
| 14 | Orders | Clear Search | Reset Lookup | Search active | Click Clear Icon | Restore full queue list | Queue restored | `GET /pharmacy/orders` | YES | PASS | **PASS** | None | N/A |
| 15 | Orders | Status Filter Chip | Queue Filter | Orders loaded | Click "Preparing" | Filter queue to `PREPARING` | Queue filtered | `GET /pharmacy/orders?status=PREPARING` | YES | PASS | **PASS** | None | N/A |
| 16 | Orders | Approve Full Button | Item Fulfillment | Item pending | Click "Approve Full" | Set `fulfillQty = requestedQty` | Status updated to `APPROVED` | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| 17 | Orders | Partial Fulfill | Low Stock | `available < req` | Click "Partial Fulfill" | Enforce `fulfillQty <= availableQty` | Status `PARTIAL`, stock badge `LOW` | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| 18 | Orders | Out of Stock Item | Zero Stock | `available = 0` | Attempt Fulfill | Block `fulfillQty > 0` | Badge `OUT OF STOCK`, fulfill `0` | N/A | YES | PASS | **PASS** | None | N/A |
| 19 | Orders | Suggest Substitute | Product Ref | Alternate exists | Select Substitute | Record product ref & price diff | Status `SUBSTITUTED`, substitute saved | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| 20 | Orders | Reject Item Button | Item Rejection | Item pending | Click "Reject Item" | Set `fulfillQty = 0` & subtotal `0` | Status updated to `REJECTED` | `PATCH /pharmacy/orders/:id/items/:itemId` | YES | PASS | **PASS** | None | N/A |
| 21 | Orders | Customer Confirm | Confirmation | Policy enabled | Request Confirmation | Order status `AWAITING_CONFIRMATION` | Event emitted & order blocked | `POST /pharmacy/orders/:id/request-confirmation` | YES | PASS | **PASS** | None | N/A |
| 22 | Orders | Mark as Chronic | Refill Tagging | Order selected | Toggle switch | Save chronic flag & cadence | Chronic badge & filter tag active | `PATCH /pharmacy/orders/:id/chronic` | YES | PASS | **PASS** | None | N/A |
| 23 | Orders | Pharmacist Notes | Internal Remark | Order selected | Save Note | Save note with author & time | Note persisted after refresh | `PATCH /pharmacy/orders/:id/notes` | YES | PASS | **PASS** | None | N/A |
| 24 | Orders | Invoice Upload | File Storage | Order selected | Select PDF/Image | Upload file to private storage | Invoice file metadata displayed | `POST /pharmacy/orders/:id/invoice` | YES | PASS | **PASS** | None | N/A |
| 25 | Orders | Invoice View | Authenticated View | Invoice uploaded | Click View Invoice | Fetch pre-signed private URL | Invoice preview opens safely | `GET /pharmacy/orders/:id/invoice/url` | YES | PASS | **PASS** | None | N/A |
| 26 | Orders | Invoice Replace | File Lifecycle | Invoice uploaded | Upload replacement | Replace active invoice file | New invoice active after refresh | `POST /pharmacy/orders/:id/invoice` | YES | PASS | **PASS** | None | N/A |
| 27 | Orders | Invoice Remove | File Lifecycle | Invoice uploaded | Click Remove | Delete invoice metadata | Invoice removed after refresh | `DELETE /pharmacy/orders/:id/invoice` | YES | PASS | **PASS** | None | N/A |
| 28 | Orders | Send Invoice | Customer Event | Invoice uploaded | Click Send Invoice | Mark invoice sent & notify | Sent timestamp & status updated | `POST /pharmacy/orders/:id/send-invoice` | YES | PASS | **PASS** | None | N/A |
| 29 | Orders | Send Invoice Duplicate | Event Guard | Invoice sent | Click Send again | Idempotent response / no duplicate | Idempotent status maintained | `POST /pharmacy/orders/:id/send-invoice` | YES | PASS | **PASS** | None | N/A |
| 30 | Orders | Invoice Dispatch Guard | Policy Guard | Invoice missing | Attempt Dispatch | Backend blocks dispatch | Error toast "Invoice required" | `PATCH /pharmacy/orders/:id/status` | YES | PASS | **PASS** | None | N/A |
| 31 | Orders | Partial Dispatch | Home Delivery | `HOME_DELIVERY` | Click Partial Dispatch | Dispatch approved items | Status `PARTIALLY_DISPATCHED` | `POST /pharmacy/orders/:id/partial-dispatch` | YES | PASS | **PASS** | None | N/A |
| 32 | Orders | Pickup Dispatch Guard | Store Pickup | `STORE_PICKUP` | Attempt Dispatch | Block delivery dispatch action | Action unavailable on Pickup | N/A | YES | PASS | **PASS** | None | N/A |
| 33 | Orders | Terminal Protection | Illegal State | `CANCELLED` order | Click Action Button | Hide action buttons / render banner | Read-only banner rendered | N/A | YES | PASS | **PASS** | None | N/A |
| 34 | Payments | Status Filter Tabs | Ledger Filter | Payments loaded | Click "Pending" | Filter receipt list to `PENDING` | Receipts list updated | `GET /pharmacy/payments?status=PENDING` | YES | PASS | **PASS** | None | N/A |
| 35 | Payments | Counter Payment Modal | Dialog Trigger | Privilege member | Click "+ Counter Payment" | Open recharge modal dialog | Modal dialog displayed | N/A | YES | PASS | **PASS** | None | N/A |
| 36 | Payments | Counter Recharge | Member Recharge | Valid card | Enter ₹10,000 & submit | Recharge wallet & emit credit | Ledger entry created | `POST /pharmacy/payments/counter` | YES | PASS | **PASS** | None | N/A |
| 37 | Payments | Approve Payment | Manual Review | Receipt pending | Click "Approve Payment" | Credit wallet & status `APPROVED` | Wallet credited exactly once | `POST /pharmacy/payments/:id/approve` | YES | PASS | **PASS** | None | N/A |
| 38 | Payments | Double Approve Guard | Financial Integrity | Receipt approved | Re-click Approve | Idempotent block / no 2nd credit | Zero duplicate credit | `POST /pharmacy/payments/:id/approve` | YES | PASS | **PASS** | None | N/A |
| 39 | Payments | Reject Payment | Manual Review | Receipt pending | Click "Reject Payment" | Set status `REJECTED`, 0 credit | Status `REJECTED`, zero wallet credit | `POST /pharmacy/payments/:id/reject` | YES | PASS | **PASS** | None | N/A |
| 40 | Payment Details | Edit Bank Details | Payout Config | Bank card loaded | Click "Edit Bank" | Open edit bank modal | Modal dialog rendered | N/A | YES | PASS | **PASS** | None | N/A |
| 41 | Payment Details | Save Bank Details | Payout Config | Bank form valid | Click Save | Update primary bank account | Bank card updated | `PUT /pharmacy/payment-details/bank` | YES | PASS | **PASS** | None | N/A |
| 42 | Payment Details | Upload UPI QR | Payout Config | QR card loaded | Select QR file | Upload & activate UPI QR code | QR preview updated | `POST /pharmacy/payment-details/upi-qr` | YES | PASS | **PASS** | None | N/A |
| 43 | History | Status Filter Tabs | Archive Filter | History loaded | Click "Completed" | Filter archive to `COMPLETED` | Archives filtered | `GET /pharmacy/history?status=COMPLETED` | YES | PASS | **PASS** | None | N/A |
| 44 | History | Date Presets | Archive Filter | History loaded | Click "Last 30 Days" | Filter archive by date range | Archives filtered | `GET /pharmacy/history?from=...` | YES | PASS | **PASS** | None | N/A |
| 45 | History | History Order Detail | Archive Detail | History loaded | Click Order Row | Open historical detail modal | Detail modal rendered | `GET /pharmacy/history/:id` | YES | PASS | **PASS** | None | N/A |
| 46 | Profile | Edit Business Info | Store Info | Profile loaded | Click "Edit Business" | Open edit modal (`maxHeight: 720`) | Modal dialog rendered | N/A | YES | PASS | **PASS** | None | N/A |
| 47 | Profile | Save Business Info | Store Info | Edit form valid | Click Save | Update operating hours & phone | Store info updated | `PUT /pharmacy/profile` | YES | PASS | **PASS** | None | N/A |
| 48 | Profile | Assigned Outlet Lock | Single-Outlet | Staff user | View Assigned Outlet | Outlet field is read-only | No outlet selector present | N/A | YES | PASS | **PASS** | None | N/A |
| 49 | Settings | Policy Toggles | Local Draft | Settings loaded | Toggle "Invoice Required" | Mark local draft dirty | Sticky dirty banner displayed | N/A | YES | PASS | **PASS** | None | N/A |
| 50 | Settings | Discard Changes | Local Draft | Draft dirty | Click "Discard Changes" | Reset toggles to saved state | Toggles reset to saved state | N/A | YES | PASS | **PASS** | None | N/A |
| 51 | Settings | Save Settings | Policy Config | Draft dirty | Click "Save Settings" | Persist operational policies | Settings saved & active | `PUT /pharmacy/settings` | YES | PASS | **PASS** | None | N/A |
| 52 | Settings | Responsive Wrap | Mobile Viewport | 390 × 844 | View Sticky Action Panel | Wrap actions without overflow | 0 RenderFlex errors | N/A | YES | PASS | **PASS** | None | N/A |
| 53 | Security | Provider Isolation | Cross-Provider | Staff Pharmacy A | Attempt Pharmacy B access | Block access / return 403 | Fail closed, access denied | `GET /pharmacy/orders` | YES | PASS | **PASS** | None | N/A |
| 54 | Security | Unassigned Staff | Provider Scope | Unassigned User | Access Portal | Display "No Pharmacy Assigned" | Access blocked | N/A | YES | PASS | **PASS** | None | N/A |
