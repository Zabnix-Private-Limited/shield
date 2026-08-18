# SHIELD Pharmacy MVP — Phase 2 Payment Details Audit & Database Migration Handoff

**Date**: 2026-08-18  
**Phase**: Phase 2 — Pharmacy Payment Details (Bank Accounts / UPI IDs / UPI QR Codes)  
**Status**: `DATABASE_OWNER_ACTION_REQUIRED = YES`

---

## 1. Schema Audit Findings
- **Audit Target**: `current_schema.md` & `backend/prisma/schema.prisma`.
- **Result**: No existing normalized table exists for storing provider payment destinations (Bank account numbers, IFSC codes, Account holder names, Branch names, UPI VPAs, and QR code storage references).
- **Governance Constraint**: Hiding financial transfer destinations inside arbitrary JSON fields or unrelated tables is explicitly prohibited. Proper database normalization is required.
- **Schema File Protection**: `current_schema.md` remains **UNCHANGED**.

---

## 2. Database Migration Scripts for Owner Execution

### A. FORWARD SQL

```sql
-- DATABASE SQL — OWNER MUST EXECUTE MANUALLY
-- Phase 2: Pharmacy Payment Details (Bank Accounts / UPI / QR Metadata)

CREATE TABLE IF NOT EXISTS "service_provider_payment_methods" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid DEFAULT gen_random_uuid() NOT NULL CONSTRAINT "service_provider_payment_methods_uuid_key" UNIQUE,
	"provider_id" bigint NOT NULL,
	"method_type" varchar(30) NOT NULL,
	"display_label" varchar(100),
	
	-- Bank Account Fields
	"account_holder_name" varchar(255),
	"bank_name" varchar(255),
	"account_number" varchar(50),
	"ifsc_code" varchar(20),
	"branch_name" varchar(255),
	
	-- UPI Fields
	"upi_id" varchar(120),
	
	-- QR Metadata
	"qr_storage_path" text,
	"qr_file_name" varchar(255),
	"qr_mime_type" varchar(50),
	
	-- State & Audit
	"is_active" boolean DEFAULT true NOT NULL,
	"is_primary" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"deleted_at" timestamp with time zone,
	
	CONSTRAINT "chk_sp_payment_methods_type" CHECK (((method_type)::text = ANY (ARRAY['BANK_ACCOUNT'::character varying, 'UPI'::character varying]::text[]))),
	CONSTRAINT "chk_sp_payment_methods_primary_active" CHECK (NOT is_primary OR is_active)
);

-- Foreign Key to service_providers
ALTER TABLE "service_provider_payment_methods" 
	ADD CONSTRAINT "sp_payment_methods_provider_id_fkey" 
	FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Indexes for performance & partial primary uniqueness per method_type
CREATE INDEX IF NOT EXISTS "idx_sp_payment_methods_provider_active" 
	ON "service_provider_payment_methods" ("provider_id", "is_active", "deleted_at");

CREATE UNIQUE INDEX IF NOT EXISTS "uq_sp_payment_methods_primary_bank" 
	ON "service_provider_payment_methods" ("provider_id", "method_type") 
	WHERE (is_primary = true AND deleted_at IS NULL);
```

---

### B. READ-ONLY VERIFICATION SQL

```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'service_provider_payment_methods' 
ORDER BY ordinal_position;
```

---

### C. ROLLBACK SQL

```sql
DROP TABLE IF EXISTS "service_provider_payment_methods" CASCADE;
```

---

## 3. Prisma Schema Model to Add (Post-Migration)

In `backend/prisma/schema.prisma`:

```prisma
model ServiceProviderPaymentMethod {
  id                BigInt            @id @default(autoincrement())
  uuid              String            @unique @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  providerId        BigInt            @map("provider_id")
  methodType        String            @map("method_type") @db.VarChar(30)
  displayLabel      String?           @map("display_label") @db.VarChar(100)

  // Bank Account fields
  accountHolderName String?           @map("account_holder_name") @db.VarChar(255)
  bankName          String?           @map("bank_name") @db.VarChar(255)
  accountNumber     String?           @map("account_number") @db.VarChar(50)
  ifscCode          String?           @map("ifsc_code") @db.VarChar(20)
  branchName        String?           @map("branch_name") @db.VarChar(255)

  // UPI fields
  upiId             String?           @map("upi_id") @db.VarChar(120)

  // QR Metadata
  qrStoragePath     String?           @map("qr_storage_path")
  qrFileName        String?           @map("qr_file_name") @db.VarChar(255)
  qrMimeType        String?           @map("qr_mime_type") @db.VarChar(50)

  // State & Audit
  isActive          Boolean           @default(true) @map("is_active")
  isPrimary         Boolean           @default(false) @map("is_primary")
  createdAt         DateTime          @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt         DateTime          @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(6)
  deletedAt         DateTime?         @map("deleted_at") @db.Timestamptz(6)

  provider          ServiceProvider   @relation(fields: [providerId], references: [id], onDelete: Cascade)

  @@index([providerId, isActive, deletedAt], map: "idx_sp_payment_methods_provider_active")
  @@map("service_provider_payment_methods")
}
```

---

## 4. Financial Invariants Asserted
- `WALLET_CREDIT_FROM_PHASE_2 = NO`
- `WALLET_RECHARGE_INTENT_MUTATION_FROM_PHASE_2 = NO`
- `PAYMENT_GATEWAY_IMPLEMENTED = NO`
