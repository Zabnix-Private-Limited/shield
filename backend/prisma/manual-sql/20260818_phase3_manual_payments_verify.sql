-- Phase 3 Verification SQL: Manual Payments & Recharge Verification Enhancements

SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'wallet_recharge_intents' 
ORDER BY ordinal_position;
