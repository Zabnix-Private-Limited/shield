-- Phase 3 Forward SQL: Manual Payments & Recharge Verification Enhancements
-- Adds provider_id, payment_method_id, payment_channel, reference_number, proof_storage_path, reviewed_by, reviewed_at, rejection_reason, and destination_snapshot columns to wallet_recharge_intents

ALTER TABLE "wallet_recharge_intents" 
	ADD COLUMN IF NOT EXISTS "provider_id" bigint,
	ADD COLUMN IF NOT EXISTS "payment_method_id" bigint,
	ADD COLUMN IF NOT EXISTS "payment_channel" varchar(50) DEFAULT 'BANK_TRANSFER',
	ADD COLUMN IF NOT EXISTS "reference_number" varchar(120),
	ADD COLUMN IF NOT EXISTS "proof_storage_path" text,
	ADD COLUMN IF NOT EXISTS "reviewed_by" bigint,
	ADD COLUMN IF NOT EXISTS "reviewed_at" timestamp with time zone,
	ADD COLUMN IF NOT EXISTS "rejection_reason" text,
	ADD COLUMN IF NOT EXISTS "destination_snapshot" jsonb;

-- Foreign key constraints
ALTER TABLE "wallet_recharge_intents" 
	ADD CONSTRAINT "wallet_recharge_intents_provider_id_fkey" 
	FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "wallet_recharge_intents" 
	ADD CONSTRAINT "wallet_recharge_intents_payment_method_id_fkey" 
	FOREIGN KEY ("payment_method_id") REFERENCES "service_provider_payment_methods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "wallet_recharge_intents" 
	ADD CONSTRAINT "wallet_recharge_intents_reviewed_by_fkey" 
	FOREIGN KEY ("reviewed_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Index for pharmacy provider payment verification queries
CREATE INDEX IF NOT EXISTS "idx_wallet_recharge_intents_provider_status" 
	ON "wallet_recharge_intents" ("provider_id", "status", "created_at");
