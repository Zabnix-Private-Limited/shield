BEGIN;

UPDATE products
SET is_demo_available = false
WHERE data_source = 'LEGACY_XLS_20260805'
  AND is_demo_available = true;

COMMIT;

SELECT count(*) AS demo_visible_imported_products
FROM products
WHERE data_source = 'LEGACY_XLS_20260805'
  AND is_demo_available = true;
