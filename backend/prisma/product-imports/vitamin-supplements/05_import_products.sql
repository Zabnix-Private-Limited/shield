-- Run with psql from this directory. Staging-only legacy catalogue import; never production.
BEGIN;
CREATE TEMP TABLE vitamin_import (
 source_row integer, product_code text, product_name text, brand text, category_name text, unit text,
 mrp numeric(15,2), selling_price numeric(15,2), cost_price numeric(15,2), margin_percentage numeric(5,2), stock_quantity numeric(12,2),
 source_hsn_code text, source_gst_percent numeric(5,2), source_alias_name text, source_generic_name text, source_sub_category text, source_created_date text
) ON COMMIT DROP;
\copy vitamin_import FROM '04_normalized_products.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
-- Categories have no uniqueness constraint, so only insert a missing exact name.
INSERT INTO product_categories (name)
SELECT DISTINCT v.category_name FROM vitamin_import v
WHERE NOT EXISTS (SELECT 1 FROM product_categories c WHERE c.name = v.category_name);
-- Insert only: legacy rows remain STAGING and cannot overwrite manually-maintained catalogue data.
INSERT INTO products (uuid, product_code, product_name, brand, category_id, unit, mrp, selling_price, cost_price, margin_percentage, stock_quantity, is_demo_available, data_source, status)
SELECT (substr(md5(v.product_code),1,8)||'-'||substr(md5(v.product_code),9,4)||'-4'||substr(md5(v.product_code),14,3)||'-8'||substr(md5(v.product_code),18,3)||'-'||substr(md5(v.product_code),21,12))::uuid, v.product_code, v.product_name, NULLIF(v.brand, ''), c.id, v.unit, v.mrp, v.selling_price, v.cost_price, v.margin_percentage, v.stock_quantity, false, 'LEGACY_XLS_20260805', 'STAGING'
FROM vitamin_import v JOIN product_categories c ON c.name = v.category_name
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.product_code = v.product_code);
COMMIT;
