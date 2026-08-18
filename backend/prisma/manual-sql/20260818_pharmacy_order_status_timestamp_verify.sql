-- Verification SQL: Verify order_status_updated_at column exists in purchases table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'purchases' AND column_name = 'order_status_updated_at';
