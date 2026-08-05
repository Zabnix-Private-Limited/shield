BEGIN;

UPDATE products
SET is_demo_available = true
WHERE data_source = 'LEGACY_XLS_20260805'
  AND is_demo_available = false;

COMMIT;

SELECT
  count(*) FILTER (WHERE is_demo_available) AS demo_visible_imported_products,
  count(*) FILTER (WHERE NOT is_demo_available) AS hidden_imported_products
FROM products
WHERE data_source = 'LEGACY_XLS_20260805';
