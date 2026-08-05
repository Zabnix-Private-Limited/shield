# Vitamin supplements import runbook

Purpose: load the inspected legacy workbook and explicitly publish only its stable import batch to the non-production demo catalogue.

Preconditions: approved non-production database, `psql`, and review of `02_validation_report.csv` plus `03_rejected_rows.csv`. From `backend/prisma/product-imports/vitamin-supplements`, run `psql -v ON_ERROR_STOP=1 -f 05_import_products.sql`, then `psql -v ON_ERROR_STOP=1 -f 06_verify_import.sql`.

Expected result: 547 insert-only `LEGACY_XLS_20260805` rows on the first run, zero duplicates on rerun. No live Sahakar inventory is created. To make the approved development batch visible, run `08_publish_to_demo_catalogue.sql`, then `09_verify_demo_catalogue.sql`; rerunning the publish file must update zero rows. Use `10_revert_demo_catalogue_visibility.sql` to hide it again without deleting products. Roll back only the import batch with `07_rollback_import.sql`; categories are deliberately retained because the schema cannot prove their provenance.
