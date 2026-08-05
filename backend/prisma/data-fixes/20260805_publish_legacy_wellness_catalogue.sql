-- Management-approved publication of only this reviewed non-production import batch.
BEGIN;
UPDATE products
SET status = 'ACTIVE', is_demo_available = false
WHERE data_source = 'LEGACY_XLS_20260805'
  AND status = 'STAGING'
  AND product_code LIKE 'LEGACY-XLS-%';
COMMIT;
