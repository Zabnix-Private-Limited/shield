-- Phase 2 Archival Verification SQL: Service Provider Payment Methods

SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'service_provider_payment_methods' 
ORDER BY ordinal_position;
