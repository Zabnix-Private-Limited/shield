-- =============================================================================
-- SHIELD PHARMACY PORTAL — ADVANCED FULFILLMENT SCHEMA EXTENSIONS
-- DATE: 2026-08-19
-- PURPOSE: Forward SQL definitions for dedicated index & JSON field integrity
-- =============================================================================

-- Ensure JSON GIN indexes for fast query filtering on purchase metadata & billing snapshots
CREATE INDEX IF NOT EXISTS idx_purchases_billing_snapshot_gin ON purchases USING gin (billing_snapshot);
CREATE INDEX IF NOT EXISTS idx_purchase_items_metadata_gin ON purchase_items USING gin (metadata);

-- Index for chronic order query performance
CREATE INDEX IF NOT EXISTS idx_purchases_chronic ON purchases ((billing_snapshot->>'isChronic')) WHERE billing_snapshot->>'isChronic' = 'true';

-- Comment on forward schema capabilities
COMMENT ON COLUMN purchases.billing_snapshot IS 'Stores order-level fulfillment metadata including pharmacist notes, chronic status, invoice URL, and customer confirmation states.';
COMMENT ON COLUMN purchase_items.metadata IS 'Stores per-item fulfillment decisions, stock statuses, substitute product details, and decision reasons.';
