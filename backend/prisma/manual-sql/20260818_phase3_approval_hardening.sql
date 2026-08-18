-- Phase 3 Manual Payment Approval Hardening
-- Creates a partial unique index on wallet_transactions for MANUAL_RECHARGE_APPROVAL references
-- Guarantees database-enforced ledger idempotency preventing duplicate wallet credits

CREATE UNIQUE INDEX IF NOT EXISTS "idx_wallet_transactions_manual_recharge_unique"
ON "wallet_transactions" ("reference_type", "reference_id")
WHERE "reference_type" = 'MANUAL_RECHARGE_APPROVAL' AND "reference_id" IS NOT NULL;
