# 🔌 SHIELD PHARMACY — ACTUAL API CONTRACT MAP

**Target Platform**: SHIELD Pharmacy Staff Portal & NestJS Backend Controller  
**Source Controller**: `backend/src/pharmacy/pharmacy.controller.ts`  
**Frontend Repositories**: `frontend/lib/features/provider/pharmacy/data/`  

---

## 1. Source-of-Truth API Route Mapping

| Domain | UI Action | HTTP Method | Actual Controller Route | Controller Method | Service Method | Provider Scoped | Current Frontend Call | Match | Defect |
| :--- | :--- | :---: | :--- | :--- | :--- | :---: | :--- | :---: | :---: |
| Dashboard | Operations Summary | GET | `/pharmacy/dashboard` | `getPharmacyDashboard` | `paymentsService.getPharmacyDashboard` | YES | `ApiService.dio.get('/pharmacy/dashboard')` | **YES** | None |
| Orders | Fetch Orders Queue | GET | `/pharmacy/orders` | `listPharmacyOrders` | `pharmacyService.listPharmacyOrders` | YES | `ApiService.dio.get('/pharmacy/orders')` | **YES** | None |
| Orders | Orders Summary Counts | GET | `/pharmacy/orders/summary` | `getPharmacyOrdersSummary` | `pharmacyService.getPharmacyOrdersSummary` | YES | `ApiService.dio.get('/pharmacy/orders/summary')` | **YES** | None |
| Orders | Order Detail | GET | `/pharmacy/orders/:id` | `getPharmacyOrderDetail` | `pharmacyService.getPharmacyOrderDetail` | YES | `ApiService.dio.get('/pharmacy/orders/:id')` | **YES** | None |
| Orders | Update Order Status | PATCH | `/pharmacy/orders/:id/status` | `updateOrderStatus` | `pharmacyService.updateOrderStatus` | YES | `ApiService.dio.patch('/pharmacy/orders/:id/status')` | **YES** | None |
| Orders | Item Fulfillment Decision | PATCH | `/pharmacy/orders/:id/items/:itemId` | `updateOrderItemFulfillment` | `pharmacyService.updateOrderItemFulfillment` | YES | `ApiService.dio.patch('/pharmacy/orders/:id/items/:itemId')` | **YES** | None |
| Orders | Toggle Chronic Flag | PATCH | `/pharmacy/orders/:id/chronic` | `toggleChronicOrder` | `pharmacyService.toggleChronicOrder` | YES | `ApiService.dio.patch('/pharmacy/orders/:id/chronic')` | **YES** | None |
| Orders | Save Pharmacist Notes | POST | `/pharmacy/orders/:id/notes` | `savePharmacistNotes` | `pharmacyService.savePharmacistNotes` | YES | `ApiService.dio.post('/pharmacy/orders/:id/notes')` | **YES** | None |
| Orders | Request Customer Confirm | POST | `/pharmacy/orders/:id/request-customer-confirmation` | `requestCustomerConfirmation` | `pharmacyService.requestCustomerConfirmation` | YES | `ApiService.dio.post('/pharmacy/orders/:id/request-customer-confirmation')` | **YES** | None |
| Orders | Upload Invoice File | POST | `/pharmacy/orders/:id/invoice/upload` | `uploadOrderInvoiceFile` | `pharmacyService.uploadOrderInvoiceFile` | YES | `ApiService.dio.post('/pharmacy/orders/:id/invoice/upload')` | **YES** | None |
| Orders | Stream Invoice File | GET | `/pharmacy/orders/:id/invoice/file` | `getOrderInvoiceFile` | `pharmacyService.getOrderInvoiceFileStream` | YES | `ApiService.dio.get('/pharmacy/orders/:id/invoice/file')` | **YES** | None |
| Orders | Remove Invoice File | DELETE | `/pharmacy/orders/:id/invoice` | `removeOrderInvoice` | `pharmacyService.removeOrderInvoice` | YES | `ApiService.dio.delete('/pharmacy/orders/:id/invoice')` | **YES** | None |
| Orders | Send Invoice Event | POST | `/pharmacy/orders/:id/send-invoice` | `sendOrderInvoice` | `pharmacyService.sendOrderInvoice` | YES | `ApiService.dio.post('/pharmacy/orders/:id/send-invoice')` | **YES** | None |
| History | Order History Archives | GET | `/pharmacy/orders/history` | `listPharmacyOrderHistory` | `pharmacyService.listPharmacyOrderHistory` | YES | `ApiService.dio.get('/pharmacy/orders/history')` | **YES** | None |
| History | History Order Detail | GET | `/pharmacy/orders/history/:id` | `getPharmacyOrderHistoryDetail` | `pharmacyService.getPharmacyOrderHistoryDetail` | YES | `ApiService.dio.get('/pharmacy/orders/history/:id')` | **YES** | None |
| Payments | Fetch Payments List | GET | `/pharmacy/payments` | `listPayments` | `paymentsService.listPayments` | YES | `ApiService.dio.get('/pharmacy/payments')` | **YES** | None |
| Payments | Payment Detail | GET | `/pharmacy/payments/:id` | `getPaymentDetail` | `paymentsService.getPaymentDetail` | YES | `ApiService.dio.get('/pharmacy/payments/:id')` | **YES** | None |
| Payments | Search Customers | GET | `/pharmacy/customers/search` | `searchCustomers` | `paymentsService.searchCustomers` | YES | `ApiService.dio.get('/pharmacy/customers/search')` | **YES** | None |
| Payments | Counter Payment Submit | POST | `/pharmacy/payments/submit` | `submitManualPayment` | `paymentsService.submitManualPayment` | YES | `ApiService.dio.post('/pharmacy/payments/submit')` | **YES** | None |
| Payments | Approve Manual Payment | POST | `/pharmacy/payments/:id/approve` | `approvePayment` | `paymentsService.approvePayment` | YES | `ApiService.dio.post('/pharmacy/payments/:id/approve')` | **YES** | None |
| Payments | Reject Manual Payment | POST | `/pharmacy/payments/:id/reject` | `rejectPayment` | `paymentsService.rejectPayment` | YES | `ApiService.dio.post('/pharmacy/payments/:id/reject')` | **YES** | None |
| Payment Details | List Payout Methods | GET | `/pharmacy/payment-details` | `listPaymentDetails` | `paymentDetailsService.listPaymentMethods` | YES | `ApiService.dio.get('/pharmacy/payment-details')` | **YES** | None |
| Payment Details | Add Bank Account | POST | `/pharmacy/payment-details/bank-accounts` | `createBankAccount` | `paymentDetailsService.createBankAccount` | YES | `ApiService.dio.post('/pharmacy/payment-details/bank-accounts')` | **YES** | None |
| Payment Details | Update Bank Account | PATCH | `/pharmacy/payment-details/bank-accounts/:id` | `updateBankAccount` | `paymentDetailsService.updateBankAccount` | YES | `ApiService.dio.patch('/pharmacy/payment-details/bank-accounts/:id')` | **YES** | None |
| Payment Details | Add UPI ID | POST | `/pharmacy/payment-details/upi` | `createUpi` | `paymentDetailsService.createUpi` | YES | `ApiService.dio.post('/pharmacy/payment-details/upi')` | **YES** | None |
| Payment Details | Update UPI ID | PATCH | `/pharmacy/payment-details/upi/:id` | `updateUpi` | `paymentDetailsService.updateUpi` | YES | `ApiService.dio.patch('/pharmacy/payment-details/upi/:id')` | **YES** | None |
| Payment Details | Stream UPI QR Image | GET | `/pharmacy/payment-details/upi/:id/qr-image` | `getUpiQrImage` | `paymentDetailsService.getUpiQrImageStream` | YES | `ApiService.dio.get('/pharmacy/payment-details/upi/:id/qr-image')` | **YES** | None |
| Payment Details | Upload UPI QR Image | POST | `/pharmacy/payment-details/upi/:id/qr` | `uploadUpiQr` | `paymentDetailsService.uploadUpiQr` | YES | `ApiService.dio.post('/pharmacy/payment-details/upi/:id/qr')` | **YES** | None |
| Payment Details | Delete UPI QR Image | DELETE | `/pharmacy/payment-details/upi/:id/qr` | `removeUpiQr` | `paymentDetailsService.removeUpiQr` | YES | `ApiService.dio.delete('/pharmacy/payment-details/upi/:id/qr')` | **YES** | None |
| Payment Details | Set Primary Method | PATCH | `/pharmacy/payment-details/:id/primary` | `setPrimaryMethod` | `paymentDetailsService.setPrimaryMethod` | YES | `ApiService.dio.patch('/pharmacy/payment-details/:id/primary')` | **YES** | None |
| Payment Details | Toggle Active Status | PATCH | `/pharmacy/payment-details/:id/toggle-active` | `toggleActiveMethod` | `paymentDetailsService.toggleActiveMethod` | YES | `ApiService.dio.patch('/pharmacy/payment-details/:id/toggle-active')` | **YES** | None |
| Profile | Get Store Profile | GET | `/pharmacy/profile` | `getPharmacyProfile` | `pharmacyService.getPharmacyProfile` | YES | `ApiService.dio.get('/pharmacy/profile')` | **YES** | None |
| Profile | Update Store Profile | PATCH | `/pharmacy/profile` | `updatePharmacyProfile` | `pharmacyService.updatePharmacyProfile` | YES | `ApiService.dio.patch('/pharmacy/profile')` | **YES** | None |
| Settings | Get Store Settings | GET | `/pharmacy/settings` | `getPharmacySettings` | `pharmacyService.getPharmacySettings` | YES | `ApiService.dio.get('/pharmacy/settings')` | **YES** | None |
| Settings | Update Store Settings | PATCH | `/pharmacy/settings` | `updatePharmacySettings` | `pharmacyService.updatePharmacySettings` | YES | `ApiService.dio.patch('/pharmacy/settings')` | **YES** | None |
