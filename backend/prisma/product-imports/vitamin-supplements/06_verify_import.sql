SELECT count(*) AS imported_staging_products FROM products WHERE data_source = 'LEGACY_XLS_20260805';
SELECT product_code, product_name, status FROM products WHERE data_source = 'LEGACY_XLS_20260805' ORDER BY product_code;
SELECT product_code, count(*) FROM products WHERE product_code LIKE 'LEGACY-XLS-%' GROUP BY 1 HAVING count(*) > 1;
SELECT count(*) AS products_without_category FROM products WHERE data_source = 'LEGACY_XLS_20260805' AND category_id IS NULL;
SELECT count(*) AS products_without_price FROM products WHERE data_source = 'LEGACY_XLS_20260805' AND (mrp IS NULL OR mrp < 0);
