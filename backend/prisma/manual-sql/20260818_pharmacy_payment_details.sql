-- Phase 2 Archival SQL: Service Provider Payment Methods
-- Table for storing Bank Accounts and UPI/QR destination configurations per service provider

CREATE TABLE IF NOT EXISTS "service_provider_payment_methods" (
	"id" bigserial PRIMARY KEY,
	"uuid" uuid DEFAULT gen_random_uuid() NOT NULL CONSTRAINT "service_provider_payment_methods_uuid_key" UNIQUE,
	"provider_id" bigint NOT NULL,
	"method_type" varchar(30) NOT NULL,
	"display_label" varchar(100),
	"account_holder_name" varchar(255),
	"bank_name" varchar(255),
	"account_number" varchar(50),
	"ifsc_code" varchar(20),
	"branch_name" varchar(255),
	"upi_id" varchar(120),
	"qr_storage_path" text,
	"qr_file_name" varchar(255),
	"qr_mime_type" varchar(50),
	"is_active" boolean DEFAULT true NOT NULL,
	"is_primary" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "chk_sp_payment_methods_type" CHECK (((method_type)::text = ANY (ARRAY['BANK_ACCOUNT'::character varying, 'UPI'::character varying]::text[]))),
	CONSTRAINT "chk_sp_payment_methods_primary_active" CHECK (NOT is_primary OR is_active)
);

ALTER TABLE "service_provider_payment_methods" 
	ADD CONSTRAINT "sp_payment_methods_provider_id_fkey" 
	FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "idx_sp_payment_methods_provider_active" 
	ON "service_provider_payment_methods" ("provider_id", "is_active", "deleted_at");

CREATE UNIQUE INDEX IF NOT EXISTS "uq_sp_payment_methods_primary_bank" 
	ON "service_provider_payment_methods" ("provider_id", "method_type") 
	WHERE (is_primary = true AND deleted_at IS NULL);
