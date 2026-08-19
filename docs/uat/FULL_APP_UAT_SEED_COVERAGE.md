# SHIELD Pharmacy — UAT Seed Data Coverage Matrix

**Date**: 2026-08-19  
**Database Reference**: `current_schema.md` (PostgreSQL 16+)  
**Scope**: **STRICTLY PHARMACY MODULE & PROVIDER PLATFORM ONLY**  
**Seed Script Path**: `backend/prisma/demo-seeds/20260819_full_app_uat_seed.sql`  
**Verification Script Path**: `backend/prisma/demo-seeds/20260819_full_app_uat_seed_verify.sql`  

---

## 1. Test Accounts & Pharmacy Credentials

| Role / Identity | Full Name | Mobile | Email | Employee Code | Assigned Branch / Outlet |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Pharmacy Provider Staff** | Suresh Pharmacist | `9900000004` | `pharmacy.perinthalmanna@shieldhealth.in` | `EMP-PHM-001` | `BIZ-PHARM-001` (Sahakar Hyperpharmacy Main) |
| **Super Admin** | SuperAdmin SHIELD | `9900000001` | `admin@shieldhealth.in` | `EMP-ADM-001` | `GLOBAL` |
| **Customer UAT User** | Aarav Nambiar | `9876500001` | `aarav.nambiar1@uat.shield.in` | `UAT-CUST-001` | Customer App |

---

## 2. Seed Data Coverage Matrix (Minimum 5 Records per Workflow State)

| Entity / Table | Total Records | Workflow States Covered | Status Gate Result |
| :--- | :---: | :--- | :---: |
| `businesses` | 2 | `BIZ-PHARM-001` (Perinthalmanna Main), `BIZ-PHARM-002` (Manjeri) | **PASS** |
| `service_providers` | 2 | `Sahakar Main Pharmacy Provider`, `Sahakar Manjeri Pharmacy Provider` | **PASS** |
| `pharmacy_provider_settings` | 1 | Perinthalmanna Main Outlet configuration | **PASS** |
| `service_provider_payment_methods` | 2 | `BANK_ACCOUNT` (HDFC), `UPI` (Merchant QR) | **PASS** |
| `users` | 2 | `ADMIN` (1), `PHARMACY_PROVIDER` (1) | **PASS** |
| `customers` | 25 | `ACTIVE` (20), `INACTIVE` (5) | **PASS** |
| `wallets` | 25 | `ACTIVE` (25) | **PASS** |
| `customer_addresses` | 25 | `HOME` (25) | **PASS** |
| `product_categories` | 3 | `Essential Medicines`, `Chronic Care`, `OTC Healthcare` | **PASS** |
| `products` | 5 | Medicine Strips & Bottles | **PASS** |
| `purchases` | **45** | `PLACED` (5), `ACCEPTED` (5), `PARTIAL_REVIEW` (5), `PREPARING` (5), `READY_FOR_PICKUP` (5), `OUT_FOR_DELIVERY` (5), `COMPLETED` (5), `CANCELLED` (5), `REJECTED` (5) | **PASS (>=5)** |
| `purchase_items` | 45 | Pharmacy Medicine Items | **PASS** |
| `purchase_item_fulfillments` | 45 | `APPROVED` (25), `PENDING` (20) | **PASS** |
| `order_pharmacist_notes` | 45 | Counter Pharmacist Notes | **PASS** |
| `order_chronic_refills` | 45 | 30-Day Repeat Refill Tags | **PASS** |
| `order_customer_confirmations` | 45 | `CONFIRMED` (25), `PENDING` (20) | **PASS** |
| `order_invoices` | 5 | Invoice PDFs for `COMPLETED` orders | **PASS** |
| `store_change_requests` | **15** | `PENDING` (5), `APPROVED` (5), `REJECTED` (5) | **PASS (>=5)** |
| `documents` | 20 | Prescription Documents | **PASS** |
| `prescription_pharmacy_requests` | **20** | `SUBMITTED` (5), `ACCEPTED` (5), `REJECTED` (5), `FULFILLED` (5) | **PASS (>=5)** |
| `wallet_recharge_intents` | **20** | `INITIATED` (5), `APPROVED` (5), `REJECTED` (5), `FAILED` (5) | **PASS (>=5)** |
| `wallet_transactions` | 5 | `CREDIT` / `CASH` (5) | **PASS** |
| `cash_wallet_transactions` | 5 | `RECHARGE` (5) | **PASS** |

---

## 3. Ingestion Instructions

```bash
# Apply Pharmacy UAT seed to local/Neon PostgreSQL DB:
psql -h localhost -U postgres -d shield_dev -f backend/prisma/demo-seeds/20260819_full_app_uat_seed.sql

# Execute verification queries:
psql -h localhost -U postgres -d shield_dev -f backend/prisma/demo-seeds/20260819_full_app_uat_seed_verify.sql
```
