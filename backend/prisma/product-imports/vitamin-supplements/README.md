# Vitamin supplements legacy import

This package profiles all 547 workbook rows and prepares 547 insert-only products. After explicit management approval, `20260805_publish_legacy_wellness_catalogue.sql` promotes only this import batch to the active Wellness catalogue.

The source SKU is `LEGACY-XLS-<source id>` because the schema has no barcode/SKU column. UUIDs are deterministically derived from that key, so no PostgreSQL extension is required.
