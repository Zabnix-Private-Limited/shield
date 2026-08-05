# Vitamin supplements column mapping

| Source | Target | Transformation / rejection |
| --- | --- | --- |
| id | products.product_code | `LEGACY-XLS-<integer id>`; reject blank/duplicate source ID |
| Name | products.product_name | trim/collapse whitespace; reject blank |
| Patent | products.brand | trim; null when blank |
| Category | product_categories.name, products.category_id | exact normalized category; reject blank |
| packing | products.unit | `<number> pack`; reject nonnumeric |
| MRP | products.mrp, selling_price | decimal(15,2); reject negative/non-numeric |
| PTR | products.cost_price | decimal(15,2); reject nonnumeric |
| Stock | products.stock_quantity | decimal(12,2); reject negative/non-numeric |
| id/name/category and prices | metadata/provenance | no metadata column exists; `data_source=LEGACY_XLS_20260805`; demo visibility is the explicit `is_demo_available` flag |
| Alias Name, Sub Category, Generic Name, Hsn Code, GST%, Disc%, PTS, Lcost, Created Date, Rep, Type | none | retained in normalized CSV for review; no matching schema column |

The current schema has no product images, variants, separate prices/inventory, units, tax, manufacturer, or batch-provenance tables. No defaults are invented beyond the existing `products` scalar fields. The Flutter catalogue uses its existing neutral wellness icon fallback; no commercial product imagery was downloaded.
