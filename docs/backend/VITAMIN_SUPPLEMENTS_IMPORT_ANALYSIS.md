# Vitamin supplements import analysis

- Source: `E:\Chrome Downloads\qs\vitamin suppliments.xls`
- SHA-256: `36FB1F48577DC43D0E2260ADAF600350979E860B02E3C78A34948C0203B1A480`
- Reader/conversion: Python `xlrd` 2.0.1 read the original legacy BIFF `.xls` directly; no conversion and no modification.
- Worksheets: one visible worksheet, `Sheet`, 548 rows × 19 columns; 547 data rows; no merged cells, formula/error cells, hidden rows, or hidden columns detected.

All 547 rows pass the schema-compatible import validation. There are no blank rows, duplicate source IDs, duplicate names, duplicate alias names, negative MRP/stock, invalid GST/discount values, missing category, or missing required source fields. Categories are 350 `VITAMINS & SUPPLEMENTS-HW` and 197 `DIAGNOSTIC DEVICES & MONITORING EQUIPMENT-MDE`. GST is 0%, 5%, or 18%. The workbook has no SKU/barcode, URL, image, tax-table, or variant field.

The 33 names matching a conservative health-claim/device keyword check (for example BP monitors and `LIVER DETOX`) remain import-analysis items requiring manual review before any production approval. The customer demo catalogue exposes only neutral product identity, category, unit, and price; it does not expose health claims or source metadata. `PTR` is retained as cost price and MRP as both MRP and selling price because no approved retail pricing rule was supplied.

The 547-row batch is approved only for the non-production demo catalogue. It is identified by `data_source=LEGACY_XLS_20260805` and `is_demo_available=true`; this is not a live Sahakar inventory approval.
