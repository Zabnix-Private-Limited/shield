-- =============================================================================
-- SHIELD PHARMACY — CONTROLLED DEVELOPMENT UAT SEED VERIFICATION (READ ONLY)
-- Date: 2026-08-19
-- Target Schema: PostgreSQL / SHIELD current_schema.md
-- Purpose: Read-only inspection queries to confirm seeded UAT data integrity
-- =============================================================================

-- 1. Check Primary Active Pharmacy Provider Identity & Payment Methods
SELECT 
    sp.id AS provider_id,
    sp.provider_name,
    sp.provider_type,
    sp.status,
    b.code AS business_code,
    b.name AS business_name
FROM service_providers sp
LEFT JOIN businesses b ON b.id = sp.business_id
WHERE sp.provider_type = 'PHARMACY' AND sp.status = 'ACTIVE'
ORDER BY sp.id ASC LIMIT 1;

SELECT 
    pm.id AS payment_method_id,
    pm.provider_id,
    pm.method_type,
    pm.display_label,
    pm.bank_name,
    pm.account_number,
    pm.upi_id,
    pm.is_active,
    pm.is_primary
FROM service_provider_payment_methods pm
WHERE pm.provider_id = (SELECT id FROM service_providers WHERE provider_type = 'PHARMACY' AND status = 'ACTIVE' ORDER BY id ASC LIMIT 1)
  AND pm.deleted_at IS NULL;

-- 2. Check UAT Customers & Wallets
SELECT 
    c.id AS customer_id,
    c.customer_code,
    c.first_name,
    c.last_name,
    c.mobile,
    c.status AS customer_status,
    w.id AS wallet_id,
    w.status AS wallet_status
FROM customers c
LEFT JOIN wallets w ON w.customer_id = c.id
WHERE c.customer_code LIKE 'UAT-CUST-%'
ORDER BY c.customer_code ASC;

-- 3. Check UAT Orders by Status, Purchase Kind, Fulfillment & Status Timestamps
SELECT 
    p.id AS purchase_id,
    p.invoice_number,
    p.order_status,
    p.purchase_kind,
    p.payable_amount,
    p.purchase_date,
    p.order_status_updated_at,
    p.billing_snapshot->>'fulfillmentPreference' AS fulfillment_preference,
    p.payment_status
FROM purchases p
WHERE p.invoice_number LIKE 'INV-UAT-%'
ORDER BY p.order_status_updated_at DESC;

-- 4. Aggregate Check: Active vs Terminal Orders Count
SELECT 
    p.order_status,
    COUNT(*) AS count,
    SUM(p.payable_amount) AS total_payable
FROM purchases p
WHERE p.invoice_number LIKE 'INV-UAT-%'
GROUP BY p.order_status
ORDER BY p.order_status;

-- 5. Check UAT Wallet Recharge Intents (Manual Payments) & Transaction Credits
SELECT 
    wri.id AS intent_id,
    wri.idempotency_key,
    wri.provider_reference,
    wri.payment_channel,
    wri.amount,
    wri.status AS intent_status,
    wri.reviewed_at,
    wri.credited_at,
    wt.id AS ledger_transaction_id,
    wt.transaction_type,
    wt.amount AS credited_amount,
    wt.reference_type
FROM wallet_recharge_intents wri
LEFT JOIN wallet_transactions wt ON wt.reference_type = 'MANUAL_RECHARGE_APPROVAL' AND wt.reference_id = wri.id
WHERE wri.idempotency_key LIKE 'UAT-RECHARGE-IDEMP-%'
ORDER BY wri.id ASC;
