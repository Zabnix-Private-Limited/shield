# Vitamin supplements demo catalogue visibility

Verified product contract: `products` has `data_source`, `status`, and `is_demo_available`; it has no product-image or inventory relation. The customer endpoint is not allowed to return raw Prisma products.

## Customer visibility rule

`GET /customer/wellness-products` returns:

- active non-import products; or
- products with `data_source=LEGACY_XLS_20260805` only when `is_demo_available=true`.

Imported rows are returned with `catalogueKind=DEMO` and the backend-provided disclosure: “Demo products only — not live Sahakar inventory.” Internal import source, cost, margin, stock, and availability flags are omitted.

## Development data fix

- Publish: `psql "$DATABASE_URL" -f backend/prisma/product-imports/vitamin-supplements/08_publish_to_demo_catalogue.sql`
- Verify: `psql "$DATABASE_URL" -f backend/prisma/product-imports/vitamin-supplements/09_verify_demo_catalogue.sql`
- Roll back visibility only: `psql "$DATABASE_URL" -f backend/prisma/product-imports/vitamin-supplements/10_revert_demo_catalogue_visibility.sql`

Each file is transactional, targets only the stable legacy source identifier, and does not change product IDs, categories, pricing, provenance, or unrelated products. The applied development verification recorded 547 imported rows, 547 demo-visible rows, zero missing categories, zero invalid prices, and a second publish run that updated zero rows.
