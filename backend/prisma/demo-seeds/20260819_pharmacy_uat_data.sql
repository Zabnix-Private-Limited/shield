-- =============================================================================
-- SHIELD PHARMACY — CONTROLLED DEVELOPMENT UAT SEED DATA
-- Date: 2026-08-19
-- Target Schema: PostgreSQL / SHIELD current_schema.md
-- Purpose: Populates realistic test dataset for real-data Pharmacy UAT
-- Idempotent / Safe: Uses DO blocks, WHERE NOT EXISTS / ON CONFLICT logic
-- =============================================================================

BEGIN;

-- 1. Ensure Payment Methods exist for Primary Active Pharmacy Provider
DO $$
DECLARE
    v_provider_id BIGINT;
BEGIN
    SELECT id INTO v_provider_id
    FROM service_providers
    WHERE provider_type = 'PHARMACY' AND status = 'ACTIVE'
    ORDER BY id ASC
    LIMIT 1;

    IF v_provider_id IS NULL THEN
        RAISE EXCEPTION 'No ACTIVE PHARMACY provider found in service_providers table.';
    END IF;

    -- Add Bank Account payment method if not existing
    IF NOT EXISTS (
        SELECT 1 FROM service_provider_payment_methods 
        WHERE provider_id = v_provider_id AND method_type = 'BANK_ACCOUNT' AND deleted_at IS NULL
    ) THEN
        INSERT INTO service_provider_payment_methods (
            uuid, provider_id, method_type, display_label, account_holder_name,
            bank_name, account_number, ifsc_code, branch_name, is_active, is_primary
        ) VALUES (
            gen_random_uuid(), v_provider_id, 'BANK_ACCOUNT', 'Sahakar Pharmacy Main HDFC Account',
            'Sahakar Healthcare Initiative', 'HDFC Bank', '50100234567890', 'HDFC0001234',
            'Perinthalmanna Branch', true, true
        );
    END IF;

    -- Add UPI payment method if not existing
    IF NOT EXISTS (
        SELECT 1 FROM service_provider_payment_methods 
        WHERE provider_id = v_provider_id AND method_type = 'UPI' AND deleted_at IS NULL
    ) THEN
        INSERT INTO service_provider_payment_methods (
            uuid, provider_id, method_type, display_label, upi_id, is_active, is_primary
        ) VALUES (
            gen_random_uuid(), v_provider_id, 'UPI', 'Sahakar Pharmacy UPI Merchant',
            'sahakarpharmacy@hdfcbank', true, false
        );
    END IF;
END $$;

-- 2. Create UAT Customers & Wallets
DO $$
DECLARE
    c1_id BIGINT;
    c2_id BIGINT;
    c3_id BIGINT;
    w1_id BIGINT;
    w2_id BIGINT;
    w3_id BIGINT;
BEGIN
    -- Customer 1
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_code = 'UAT-CUST-001') THEN
        INSERT INTO customers (uuid, customer_code, first_name, last_name, mobile, agent_code, status)
        VALUES (gen_random_uuid(), 'UAT-CUST-001', 'Ananya', 'Sharma', '9876543210', 'AGT-UAT', 'ACTIVE')
        RETURNING id INTO c1_id;
        
        INSERT INTO wallets (uuid, customer_id, status)
        VALUES (gen_random_uuid(), c1_id, 'ACTIVE');
    END IF;

    -- Customer 2
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_code = 'UAT-CUST-002') THEN
        INSERT INTO customers (uuid, customer_code, first_name, last_name, mobile, agent_code, status)
        VALUES (gen_random_uuid(), 'UAT-CUST-002', 'Vikram', 'Verma', '9876543211', 'AGT-UAT', 'ACTIVE')
        RETURNING id INTO c2_id;
        
        INSERT INTO wallets (uuid, customer_id, status)
        VALUES (gen_random_uuid(), c2_id, 'ACTIVE');
    END IF;

    -- Customer 3
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_code = 'UAT-CUST-003') THEN
        INSERT INTO customers (uuid, customer_code, first_name, last_name, mobile, agent_code, status)
        VALUES (gen_random_uuid(), 'UAT-CUST-003', 'Meera', 'Patel', '9876543212', 'AGT-UAT', 'ACTIVE')
        RETURNING id INTO c3_id;
        
        INSERT INTO wallets (uuid, customer_id, status)
        VALUES (gen_random_uuid(), c3_id, 'ACTIVE');
    END IF;
END $$;

-- 3. Seed UAT Order Matrix (12 purchases covering all statuses, dates, fulfillments, sources)
DO $$
DECLARE
    v_provider_id BIGINT;
    c1_id BIGINT;
    c2_id BIGINT;
    c3_id BIGINT;
    p_id BIGINT;
    v_now TIMESTAMPTZ := CURRENT_TIMESTAMP;
    v_today_start TIMESTAMPTZ := (CURRENT_DATE AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'UTC';
BEGIN
    SELECT id INTO v_provider_id FROM service_providers WHERE provider_type = 'PHARMACY' AND status = 'ACTIVE' ORDER BY id ASC LIMIT 1;
    SELECT id INTO c1_id FROM customers WHERE customer_code = 'UAT-CUST-001';
    SELECT id INTO c2_id FROM customers WHERE customer_code = 'UAT-CUST-002';
    SELECT id INTO c3_id FROM customers WHERE customer_code = 'UAT-CUST-003';

    -- 1. PLACED (New) - PRESCRIPTION - COLLECT_FROM_PHARMACY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-001') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c1_id, v_provider_id, 'INV-UAT-001', 450.00, 0.00, 450.00,
            v_now - interval '1 hour', 'PRESCRIPTION', 'PENDING', 'PLACED', v_now - interval '1 hour',
            jsonb_build_object('customerName', 'Ananya Sharma', 'fulfillmentPreference', 'COLLECT_FROM_PHARMACY'),
            jsonb_build_object('fulfillmentPreference', 'COLLECT_FROM_PHARMACY', 'itemCount', 2)
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Paracetamol 650mg', 'MEDICINE', 2, 25.00, 50.00),
               (p_id, 'Amoxicillin 500mg Capsule', 'MEDICINE', 10, 40.00, 400.00);
    END IF;

    -- 2. ACCEPTED (New) - WELLNESS - HOME_DELIVERY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-002') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c2_id, v_provider_id, 'INV-UAT-002', 280.00, 0.00, 280.00,
            v_now - interval '2 hours', 'WELLNESS', 'PAID', 'ACCEPTED', v_now - interval '1.5 hours',
            jsonb_build_object('customerName', 'Vikram Verma', 'deliveryAddress', 'Flat 4B, Emerald Heights, Perinthalmanna'),
            jsonb_build_object('fulfillmentPreference', 'HOME_DELIVERY', 'deliveryAddress', 'Flat 4B, Emerald Heights, Perinthalmanna')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Omega 3 Fish Oil 1000mg', 'WELLNESS', 1, 280.00, 280.00);
    END IF;

    -- 3. PREPARING - MANUAL_ITEMS - HOME_DELIVERY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-003') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c3_id, v_provider_id, 'INV-UAT-003', 150.00, 0.00, 150.00,
            v_now - interval '3 hours', 'MANUAL_ITEMS', 'PAID', 'PREPARING', v_now - interval '2 hours',
            jsonb_build_object('customerName', 'Meera Patel', 'deliveryAddress', 'House 12, Main Street, Manjeri'),
            jsonb_build_object('fulfillmentPreference', 'HOME_DELIVERY', 'deliveryAddress', 'House 12, Main Street, Manjeri')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Vitamin C 500mg Chewable', 'MEDICINE', 3, 50.00, 150.00);
    END IF;

    -- 4. READY_FOR_PICKUP - WELLNESS - COLLECT_FROM_PHARMACY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-004') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c1_id, v_provider_id, 'INV-UAT-004', 560.00, 0.00, 560.00,
            v_now - interval '4 hours', 'WELLNESS', 'PAID', 'READY_FOR_PICKUP', v_now - interval '3 hours',
            jsonb_build_object('customerName', 'Ananya Sharma', 'fulfillmentPreference', 'COLLECT_FROM_PHARMACY'),
            jsonb_build_object('fulfillmentPreference', 'COLLECT_FROM_PHARMACY')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Multivitamin Health Supplement', 'WELLNESS', 2, 280.00, 560.00);
    END IF;

    -- 5. OUT_FOR_DELIVERY - PRESCRIPTION - HOME_DELIVERY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-005') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c2_id, v_provider_id, 'INV-UAT-005', 320.00, 0.00, 320.00,
            v_now - interval '5 hours', 'PRESCRIPTION', 'PAID', 'OUT_FOR_DELIVERY', v_now - interval '2.5 hours',
            jsonb_build_object('customerName', 'Vikram Verma', 'deliveryAddress', 'Flat 4B, Emerald Heights, Perinthalmanna'),
            jsonb_build_object('fulfillmentPreference', 'HOME_DELIVERY', 'deliveryAddress', 'Flat 4B, Emerald Heights, Perinthalmanna')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Metformin 500mg SR Tablet', 'MEDICINE', 4, 80.00, 320.00);
    END IF;

    -- 6. COMPLETED Today (Asia/Kolkata) - PRESCRIPTION - HOME_DELIVERY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-006') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c1_id, v_provider_id, 'INV-UAT-006', 650.00, 0.00, 650.00,
            v_now - interval '4 hours', 'PRESCRIPTION', 'PAID', 'COMPLETED', v_now - interval '1 hour',
            jsonb_build_object('customerName', 'Ananya Sharma', 'deliveryAddress', '21 Baker Street, Perinthalmanna'),
            jsonb_build_object('fulfillmentPreference', 'HOME_DELIVERY', 'deliveryAddress', '21 Baker Street, Perinthalmanna')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Blood Pressure Monitor Kit', 'WELLNESS', 1, 650.00, 650.00);
    END IF;

    -- 7. COMPLETED Yesterday (Asia/Kolkata) - MANUAL_ITEMS - COLLECT_FROM_PHARMACY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-007') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c3_id, v_provider_id, 'INV-UAT-007', 210.00, 0.00, 210.00,
            v_today_start - interval '1 day' + interval '2 hours', 'MANUAL_ITEMS', 'PAID', 'COMPLETED',
            v_today_start - interval '1 day' + interval '5 hours',
            jsonb_build_object('customerName', 'Meera Patel', 'fulfillmentPreference', 'COLLECT_FROM_PHARMACY'),
            jsonb_build_object('fulfillmentPreference', 'COLLECT_FROM_PHARMACY')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Antacid Suspension 200ml', 'MEDICINE', 1, 210.00, 210.00);
    END IF;

    -- 8. COMPLETED 5 Days Ago (Last 7 Days) - WELLNESS - HOME_DELIVERY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-008') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c2_id, v_provider_id, 'INV-UAT-008', 840.00, 0.00, 840.00,
            v_today_start - interval '5 days' + interval '1 hour', 'WELLNESS', 'PAID', 'COMPLETED',
            v_today_start - interval '5 days' + interval '4 hours',
            jsonb_build_object('customerName', 'Vikram Verma', 'deliveryAddress', 'Flat 4B, Emerald Heights, Perinthalmanna'),
            jsonb_build_object('fulfillmentPreference', 'HOME_DELIVERY', 'deliveryAddress', 'Flat 4B, Emerald Heights, Perinthalmanna')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Protein Powder 500g Jar', 'WELLNESS', 1, 840.00, 840.00);
    END IF;

    -- 9. COMPLETED 15 Days Ago (Last 30 Days) - PRESCRIPTION - COLLECT_FROM_PHARMACY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-009') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c1_id, v_provider_id, 'INV-UAT-009', 1120.00, 0.00, 1120.00,
            v_today_start - interval '15 days' + interval '1 hour', 'PRESCRIPTION', 'PAID', 'COMPLETED',
            v_today_start - interval '15 days' + interval '3 hours',
            jsonb_build_object('customerName', 'Ananya Sharma', 'fulfillmentPreference', 'COLLECT_FROM_PHARMACY'),
            jsonb_build_object('fulfillmentPreference', 'COLLECT_FROM_PHARMACY')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Insulin Glargine 100IU/ml Cartridge', 'MEDICINE', 2, 560.00, 1120.00);
    END IF;

    -- 10. COMPLETED 45 Days Ago (Outside 30 Days) - MANUAL_ITEMS - HOME_DELIVERY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-010') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c3_id, v_provider_id, 'INV-UAT-010', 190.00, 0.00, 190.00,
            v_today_start - interval '45 days' + interval '1 hour', 'MANUAL_ITEMS', 'PAID', 'COMPLETED',
            v_today_start - interval '45 days' + interval '4 hours',
            jsonb_build_object('customerName', 'Meera Patel', 'deliveryAddress', 'House 12, Main Street, Manjeri'),
            jsonb_build_object('fulfillmentPreference', 'HOME_DELIVERY', 'deliveryAddress', 'House 12, Main Street, Manjeri')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Cough Syrup 100ml', 'MEDICINE', 2, 95.00, 190.00);
    END IF;

    -- 11. CANCELLED Today - WELLNESS - HOME_DELIVERY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-011') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c2_id, v_provider_id, 'INV-UAT-011', 400.00, 0.00, 400.00,
            v_now - interval '3 hours', 'WELLNESS', 'REFUNDED', 'CANCELLED', v_now - interval '1 hour',
            jsonb_build_object('customerName', 'Vikram Verma', 'cancellationReason', 'Customer requested cancellation before dispatch'),
            jsonb_build_object('cancellationReason', 'Customer requested cancellation before dispatch', 'fulfillmentPreference', 'HOME_DELIVERY')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Digital Thermometer', 'WELLNESS', 1, 400.00, 400.00);
    END IF;

    -- 12. REJECTED Yesterday - PRESCRIPTION - COLLECT_FROM_PHARMACY
    IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-012') THEN
        INSERT INTO purchases (
            uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount, payable_amount,
            purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
            billing_snapshot, payment_summary
        ) VALUES (
            gen_random_uuid(), c1_id, v_provider_id, 'INV-UAT-012', 350.00, 0.00, 350.00,
            v_today_start - interval '1 day' + interval '2 hours', 'PRESCRIPTION', 'REJECTED', 'REJECTED',
            v_today_start - interval '1 day' + interval '4 hours',
            jsonb_build_object('customerName', 'Ananya Sharma', 'rejectionReason', 'Uploaded prescription image unclear and expired'),
            jsonb_build_object('rejectionReason', 'Uploaded prescription image unclear and expired', 'fulfillmentPreference', 'COLLECT_FROM_PHARMACY')
        ) RETURNING id INTO p_id;

        INSERT INTO purchase_items (purchase_id, item_name, item_type, quantity, unit_price, total_price)
        VALUES (p_id, 'Antibiotic Eye Drops', 'MEDICINE', 1, 350.00, 350.00);
    END IF;

END $$;

-- 4. Seed Wallet Recharge Intents (Manual Payments)
DO $$
DECLARE
    v_provider_id BIGINT;
    c1_id BIGINT;
    c2_id BIGINT;
    c3_id BIGINT;
    w1_id BIGINT;
    w2_id BIGINT;
    w3_id BIGINT;
    bank_pm_id BIGINT;
    upi_pm_id BIGINT;
    v_now TIMESTAMPTZ := CURRENT_TIMESTAMP;
    v_today_start TIMESTAMPTZ := (CURRENT_DATE AT TIME ZONE 'Asia/Kolkata') AT TIME ZONE 'UTC';
BEGIN
    SELECT id INTO v_provider_id FROM service_providers WHERE provider_type = 'PHARMACY' AND status = 'ACTIVE' ORDER BY id ASC LIMIT 1;

    SELECT id INTO c1_id FROM customers WHERE customer_code = 'UAT-CUST-001';
    SELECT id INTO c2_id FROM customers WHERE customer_code = 'UAT-CUST-002';
    SELECT id INTO c3_id FROM customers WHERE customer_code = 'UAT-CUST-003';

    SELECT id INTO w1_id FROM wallets WHERE customer_id = c1_id;
    SELECT id INTO w2_id FROM wallets WHERE customer_id = c2_id;
    SELECT id INTO w3_id FROM wallets WHERE customer_id = c3_id;

    SELECT id INTO bank_pm_id FROM service_provider_payment_methods WHERE provider_id = v_provider_id AND method_type = 'BANK_ACCOUNT' AND deleted_at IS NULL LIMIT 1;
    SELECT id INTO upi_pm_id FROM service_provider_payment_methods WHERE provider_id = v_provider_id AND method_type = 'UPI' AND deleted_at IS NULL LIMIT 1;

    -- Intent 1: PENDING (UPI)
    IF NOT EXISTS (SELECT 1 FROM wallet_recharge_intents WHERE idempotency_key = 'UAT-RECHARGE-IDEMP-001') THEN
        INSERT INTO wallet_recharge_intents (
            uuid, customer_id, wallet_id, amount, idempotency_key, provider_code, provider_reference,
            status, provider_id, payment_method_id, payment_channel, reference_number,
            created_at, updated_at, destination_snapshot
        ) VALUES (
            gen_random_uuid(), c1_id, w1_id, 500.00, 'UAT-RECHARGE-IDEMP-001', 'SHIELD_MANUAL', 'UAT-PAY-REF-001',
            'PENDING', v_provider_id, upi_pm_id, 'UPI', 'UPI/20260819/990011',
            v_now - interval '3 hours', v_now - interval '3 hours',
            jsonb_build_object('upiId', 'sahakarpharmacy@hdfcbank', 'displayLabel', 'Sahakar Pharmacy UPI Merchant')
        );
    END IF;

    -- Intent 2: PENDING (Bank Transfer)
    IF NOT EXISTS (SELECT 1 FROM wallet_recharge_intents WHERE idempotency_key = 'UAT-RECHARGE-IDEMP-002') THEN
        INSERT INTO wallet_recharge_intents (
            uuid, customer_id, wallet_id, amount, idempotency_key, provider_code, provider_reference,
            status, provider_id, payment_method_id, payment_channel, reference_number,
            created_at, updated_at, destination_snapshot
        ) VALUES (
            gen_random_uuid(), c2_id, w2_id, 1200.00, 'UAT-RECHARGE-IDEMP-002', 'SHIELD_MANUAL', 'UAT-PAY-REF-002',
            'PENDING', v_provider_id, bank_pm_id, 'BANK_TRANSFER', 'NEFT/HDFC/88442211',
            v_now - interval '2 hours', v_now - interval '2 hours',
            jsonb_build_object('accountNumber', '50100234567890', 'ifscCode', 'HDFC0001234', 'bankName', 'HDFC Bank')
        );
    END IF;

    -- Intent 3: APPROVED Today (Bank Transfer) + Ledger Credit
    IF NOT EXISTS (SELECT 1 FROM wallet_recharge_intents WHERE idempotency_key = 'UAT-RECHARGE-IDEMP-003') THEN
        DECLARE
            intent3_id BIGINT;
        BEGIN
            INSERT INTO wallet_recharge_intents (
                uuid, customer_id, wallet_id, amount, idempotency_key, provider_code, provider_reference,
                status, provider_id, payment_method_id, payment_channel, reference_number,
                reviewed_at, credited_at, created_at, updated_at, destination_snapshot
            ) VALUES (
                gen_random_uuid(), c3_id, w3_id, 1000.00, 'UAT-RECHARGE-IDEMP-003', 'SHIELD_MANUAL', 'UAT-PAY-REF-003',
                'APPROVED', v_provider_id, bank_pm_id, 'BANK_TRANSFER', 'IMPS/HDFC/55667788',
                v_now - interval '1 hour', v_now - interval '1 hour', v_now - interval '4 hours', v_now - interval '1 hour',
                jsonb_build_object('accountNumber', '50100234567890', 'ifscCode', 'HDFC0001234')
            ) RETURNING id INTO intent3_id;

            INSERT INTO wallet_transactions (
                uuid, wallet_id, transaction_type, sub_ledger_type, amount,
                reference_type, reference_id, remarks, is_customer_visible, created_at
            ) VALUES (
                gen_random_uuid(), w3_id, 'CREDIT', 'CASH', 1000.00,
                'MANUAL_RECHARGE_APPROVAL', intent3_id, 'Manual payment approval for UAT Intent #3',
                true, v_now - interval '1 hour'
            );
        END;
    END IF;

    -- Intent 4: REJECTED Yesterday
    IF NOT EXISTS (SELECT 1 FROM wallet_recharge_intents WHERE idempotency_key = 'UAT-RECHARGE-IDEMP-004') THEN
        INSERT INTO wallet_recharge_intents (
            uuid, customer_id, wallet_id, amount, idempotency_key, provider_code, provider_reference,
            status, provider_id, payment_method_id, payment_channel, reference_number,
            reviewed_at, rejection_reason, created_at, updated_at, destination_snapshot
        ) VALUES (
            gen_random_uuid(), c1_id, w1_id, 300.00, 'UAT-RECHARGE-IDEMP-004', 'SHIELD_MANUAL', 'UAT-PAY-REF-004',
            'REJECTED', v_provider_id, upi_pm_id, 'UPI', 'UPI/INVALID/000000',
            v_today_start - interval '1 day' + interval '4 hours', 'Invalid transaction reference number not found in bank statement',
            v_today_start - interval '1 day' + interval '2 hours', v_today_start - interval '1 day' + interval '4 hours',
            jsonb_build_object('upiId', 'sahakarpharmacy@hdfcbank')
        );
    END IF;

END $$;

COMMIT;
