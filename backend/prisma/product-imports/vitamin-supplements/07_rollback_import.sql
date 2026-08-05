BEGIN;
-- Deletes only rows created by this identified staging import; never pre-existing products.
DELETE FROM products WHERE data_source = 'LEGACY_XLS_20260805' AND product_code LIKE 'LEGACY-XLS-%';
-- Categories are intentionally retained: schema has no provenance column, so automatic deletion could remove pre-existing data.
COMMIT;
