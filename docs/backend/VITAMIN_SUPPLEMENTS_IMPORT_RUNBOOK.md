# Vitamin supplements import runbook

Purpose: load the inspected legacy workbook as non-live staging catalogue rows.

Preconditions: approved non-production database, `psql`, and review of `02_validation_report.csv` plus `03_rejected_rows.csv`. From `backend/prisma/product-imports/vitamin-supplements`, run `psql -v ON_ERROR_STOP=1 -f 05_import_products.sql`, then `psql -v ON_ERROR_STOP=1 -f 06_verify_import.sql`.

Expected result: 547 insert-only `LEGACY_XLS_20260805` rows on the first run, zero duplicates on rerun. No live Sahakar inventory is created. Roll back only this batch with `07_rollback_import.sql`; categories are deliberately retained because the schema cannot prove their provenance.
