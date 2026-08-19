-- =============================================================================
-- SHIELD PHARMACY — UAT SEED VERIFICATION QUERIES
-- File: backend/prisma/demo-seeds/20260819_full_app_uat_seed_verify.sql
-- Date: 2026-08-19
-- Target Database Schema: current_schema.md (PostgreSQL 16+)
-- Purpose: Read-only verification queries to validate that at least 5 records
--          exist per meaningful transactional status across all SHIELD Pharmacy tables.
-- =============================================================================

SELECT '--- SECTION 1: PHARMACY OUTLETS & USERS ---' AS section;
SELECT b.code AS business_code, b.name AS outlet_name, COUNT(u.id) AS assigned_staff_count
FROM businesses b
LEFT JOIN users u ON u.branch_business_id = b.id
WHERE b.business_type = 'PHARMACY_STORE'
GROUP BY b.code, b.name;

SELECT sp.provider_name, sp.provider_type, sp.status
FROM service_providers sp
WHERE sp.provider_type = 'PHARMACY';

SELECT '--- SECTION 2: PRODUCTS & CATALOG ---' AS section;
SELECT c.name AS category_name, COUNT(p.id) AS product_count
FROM product_categories c
JOIN products p ON p.category_id = c.id
GROUP BY c.name;

SELECT '--- SECTION 3: PURCHASES & ORDERS BY STATUS ---' AS section;
SELECT order_status, COUNT(*) AS record_count,
       CASE WHEN COUNT(*) >= 5 THEN 'PASS (>=5)' ELSE 'WARNING (<5)' END AS uat_gate_status
FROM purchases
GROUP BY order_status
ORDER BY order_status;

SELECT '--- SECTION 4: STORE CHANGE REQUESTS BY STATUS ---' AS section;
SELECT status, COUNT(*) AS record_count,
       CASE WHEN COUNT(*) >= 5 THEN 'PASS (>=5)' ELSE 'WARNING (<5)' END AS uat_gate_status
FROM store_change_requests
GROUP BY status;

SELECT '--- SECTION 5: PRESCRIPTION PHARMACY REQUESTS BY STATUS ---' AS section;
SELECT status, COUNT(*) AS record_count,
       CASE WHEN COUNT(*) >= 5 THEN 'PASS (>=5)' ELSE 'WARNING (<5)' END AS uat_gate_status
FROM prescription_pharmacy_requests
GROUP BY status;

SELECT '--- SECTION 6: WALLET RECHARGE INTENTS BY STATUS ---' AS section;
SELECT status, COUNT(*) AS record_count,
       CASE WHEN COUNT(*) >= 5 THEN 'PASS (>=5)' ELSE 'WARNING (<5)' END AS uat_gate_status
FROM wallet_recharge_intents
GROUP BY status;

-- Summary UAT Status Gate Report Matrix
SELECT 
    table_name,
    status_value,
    record_count,
    CASE WHEN record_count >= 5 THEN 'PASS (>=5)' ELSE 'WARNING (<5)' END AS uat_gate_status
FROM (
    SELECT 'purchases' AS table_name, order_status AS status_value, COUNT(*) AS record_count FROM purchases GROUP BY order_status
    UNION ALL
    SELECT 'store_change_requests', status, COUNT(*) FROM store_change_requests GROUP BY status
    UNION ALL
    SELECT 'prescription_pharmacy_requests', status, COUNT(*) FROM prescription_pharmacy_requests GROUP BY status
    UNION ALL
    SELECT 'wallet_recharge_intents', status, COUNT(*) FROM wallet_recharge_intents GROUP BY status
) status_summary
ORDER BY table_name, status_value;
