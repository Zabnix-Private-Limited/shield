-- READ-ONLY VERIFICATION SQL: Verify pharmacy_provider_settings table structure
-- DO NOT EXECUTE DDL or WRITES

SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'pharmacy_provider_settings'
ORDER BY ordinal_position;

SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'pharmacy_provider_settings';
