# Vitamin supplements legacy import

This package profiles all 547 workbook rows and prepares 547 insert-only **STAGING** products. It does not make them live inventory. Run only in an approved non-production database with `psql -f 05_import_products.sql`, then `psql -f 06_verify_import.sql`.

The source SKU is `LEGACY-XLS-<source id>` because the schema has no barcode/SKU column. UUIDs are deterministically derived from that key, so no PostgreSQL extension is required.
