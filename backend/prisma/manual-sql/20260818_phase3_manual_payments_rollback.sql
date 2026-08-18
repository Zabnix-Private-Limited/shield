-- Phase 3 Rollback SQL: Manual Payments & Recharge Verification Enhancements

ALTER TABLE "wallet_recharge_intents" 
	DROP CONSTRAINT IF EXISTS "wallet_recharge_intents_provider_id_fkey",
	DROP CONSTRAINT IF EXISTS "wallet_recharge_intents_payment_method_id_fkey",
	DROP CONSTRAINT IF EXISTS "wallet_recharge_intents_reviewed_by_fkey",
	DROP COLUMN IF EXISTS "provider_id",
	DROP COLUMN IF EXISTS "payment_method_id",
	DROP COLUMN IF EXISTS "payment_channel",
	DROP COLUMN IF EXISTS "reference_number",
	DROP COLUMN IF EXISTS "proof_storage_path",
	DROP COLUMN IF EXISTS "reviewed_by",
	DROP COLUMN IF EXISTS "reviewed_at",
	DROP COLUMN IF EXISTS "rejection_reason",
	DROP COLUMN IF EXISTS "destination_snapshot";

DROP INDEX IF EXISTS "idx_wallet_recharge_intents_provider_status";
