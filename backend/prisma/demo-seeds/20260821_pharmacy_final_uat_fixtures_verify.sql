-- =============================================================================
-- SHIELD PHARMACY — FINAL BLOCKED-UAT FIXTURE VERIFICATION (READ ONLY)
-- Date: 2026-08-21
-- This file contains SELECT / WITH SELECT statements only.
-- =============================================================================

-- 1. Businesses, active Pharmacy providers, and staff assignments.
SELECT
    b.code AS business_code,
    b.name AS business_name,
    sp.id AS provider_id,
    sp.provider_name,
    sp.provider_type,
    sp.status AS provider_status
FROM businesses b
LEFT JOIN service_providers sp
    ON sp.business_id = b.id
   AND sp.provider_type = 'PHARMACY'
WHERE b.code IN ('UAT-PHARMACY-PRIMARY', 'UAT-PHARMACY-SECONDARY')
ORDER BY b.code, sp.id;

SELECT
    u.employee_code,
    u.email,
    u.status AS user_status,
    u.user_type,
    u.access_scope,
    b.code AS assigned_business_code,
    r.code AS role_code
FROM users u
LEFT JOIN businesses b ON b.id = u.branch_business_id
LEFT JOIN roles r ON r.id = u.role_id
WHERE u.email IN (
    'uat-pharmacy-staff-primary@example.test',
    'uat-pharmacy-staff-secondary@example.test',
    'uat-pharmacy-staff-unassigned@example.test'
)
ORDER BY u.email;

-- 2. Eligible UAT member/card/wallet baseline.
WITH member_fixture AS (
    SELECT c.id AS customer_id, c.customer_code, c.status AS customer_status,
           m.id AS membership_id, m.membership_number, m.status AS membership_status,
           m.activation_date, m.expiry_date,
           sc.id AS shield_card_id, sc.card_number, sc.status AS card_status,
           ib.code AS issued_business_code,
           w.id AS wallet_id, w.status AS wallet_status
    FROM customers c
    LEFT JOIN memberships m ON m.customer_id = c.id
    LEFT JOIN shield_cards sc ON sc.customer_id = c.id
    LEFT JOIN businesses ib ON ib.id = sc.issued_business_id
    LEFT JOIN wallets w ON w.customer_id = c.id
    WHERE c.customer_code = 'UAT-PHARMACY-FINAL-CUSTOMER'
)
SELECT mf.*,
       COALESCE(SUM(CASE
           WHEN wt.sub_ledger_type = 'CASH' AND wt.transaction_type = 'RECHARGE' THEN wt.amount
           WHEN wt.sub_ledger_type = 'CASH' AND wt.transaction_type = 'DEBIT' THEN -wt.amount
           ELSE 0
       END), 0) AS wallet_cash_balance
FROM member_fixture mf
LEFT JOIN wallet_transactions wt ON wt.wallet_id = mf.wallet_id
GROUP BY mf.customer_id, mf.customer_code, mf.customer_status, mf.membership_id,
         mf.membership_number, mf.membership_status, mf.activation_date, mf.expiry_date,
         mf.shield_card_id, mf.card_number, mf.card_status, mf.issued_business_code,
         mf.wallet_id, mf.wallet_status;

-- 3. Pending payment intent status, provider association, and zero pre-credit proof.
WITH fixture_intents AS (
    SELECT wri.id, wri.idempotency_key, wri.provider_reference, wri.status,
           wri.amount, wri.payment_channel, wri.reference_number,
           wri.reviewed_by, wri.reviewed_at, wri.credited_at,
           wri.customer_id, wri.wallet_id, wri.provider_id,
           sp.provider_name, b.code AS provider_business_code
    FROM wallet_recharge_intents wri
    LEFT JOIN service_providers sp ON sp.id = wri.provider_id
    LEFT JOIN businesses b ON b.id = sp.business_id
    WHERE wri.idempotency_key IN (
        'UAT-PAYMENT-PENDING-A',
        'UAT-PAYMENT-PENDING-B',
        'UAT-PAYMENT-PENDING-C'
    )
)
SELECT fi.*,
       (
           SELECT COUNT(*) FROM wallet_transactions wt
           WHERE wt.reference_type = 'MANUAL_RECHARGE_APPROVAL'
             AND wt.reference_id = fi.id
       ) AS manual_approval_credit_rows,
       (
           SELECT COUNT(*) FROM cash_wallet_transactions cwt
           WHERE cwt.reference_type = 'MANUAL_RECHARGE_APPROVAL'
             AND cwt.reference_id = fi.id
       ) AS cash_approval_credit_rows
FROM fixture_intents fi
GROUP BY fi.id, fi.idempotency_key, fi.provider_reference, fi.status, fi.amount,
         fi.payment_channel, fi.reference_number, fi.reviewed_by, fi.reviewed_at,
         fi.credited_at, fi.customer_id, fi.wallet_id, fi.provider_id,
         fi.provider_name, fi.provider_business_code
ORDER BY fi.idempotency_key;

-- 4. Detect duplicate ledger references after the eventual approval tests.
SELECT
    wt.reference_type,
    wt.reference_id,
    COUNT(*) AS wallet_transaction_reference_count
FROM wallet_transactions wt
JOIN wallet_recharge_intents wri ON wri.id = wt.reference_id
WHERE wri.idempotency_key IN (
    'UAT-PAYMENT-PENDING-A',
    'UAT-PAYMENT-PENDING-B',
    'UAT-PAYMENT-PENDING-C'
)
  AND wt.reference_type = 'MANUAL_RECHARGE_APPROVAL'
GROUP BY wt.reference_type, wt.reference_id
ORDER BY wt.reference_id;
