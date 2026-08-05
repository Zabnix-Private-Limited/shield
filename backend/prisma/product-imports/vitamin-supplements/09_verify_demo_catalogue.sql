SELECT
  count(*) AS imported_products,
  count(*) FILTER (WHERE is_demo_available) AS demo_visible_products,
  count(*) FILTER (WHERE category_id IS NULL) AS missing_category_products,
  count(*) FILTER (WHERE selling_price IS NULL OR selling_price < 0) AS invalid_price_products
FROM products
WHERE data_source = 'LEGACY_XLS_20260805';

SELECT product_code, count(*)
FROM products
WHERE data_source = 'LEGACY_XLS_20260805'
GROUP BY product_code
HAVING count(*) > 1;
