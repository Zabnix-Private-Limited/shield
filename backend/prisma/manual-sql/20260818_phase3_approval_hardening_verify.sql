-- Phase 3 Manual Payment Approval Hardening Verification Script
-- Read-only verification query checking partial unique index existence on wallet_transactions

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'wallet_transactions'
  AND indexname = 'idx_wallet_transactions_manual_recharge_unique';
