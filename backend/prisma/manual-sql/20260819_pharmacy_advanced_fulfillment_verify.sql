-- =============================================================================
-- SHIELD PHARMACY PORTAL — VERIFICATION SQL
-- DATE: 2026-08-19
-- READ-ONLY VERIFICATION OF ADVANCED FULFILLMENT INDEXES & METADATA
-- =============================================================================

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename IN ('purchases', 'purchase_items')
  AND indexname LIKE '%gin%';

SELECT id, invoice_number, order_status, billing_snapshot
FROM purchases
WHERE billing_snapshot IS NOT NULL
ORDER BY id DESC
LIMIT 5;
