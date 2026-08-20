-- =============================================================================
-- SHIELD PHARMACY — COMPLETE UAT DATA SEED
-- File: backend/prisma/demo-seeds/20260819_full_app_uat_seed.sql
-- Date: 2026-08-19
-- Target Database Schema: current_schema.md (PostgreSQL 16+)
-- Purpose: Deterministic, transaction-safe, production-shaped UAT seed data
--          STRICTLY FOR SHIELD PHARMACY MODULE & PROVIDER PLATFORM.
-- Minimum Coverage: At least 5 records for every meaningful transactional state.
-- Idempotency: Structured with DO blocks using IF NOT EXISTS / WHERE NOT EXISTS checks.
-- DO NOT EXECUTE AUTOMATICALLY - MANUAL OWNER INGESTION ONLY.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- SECTION 1: PHARMACY SYSTEM ROLES & PERMISSIONS
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO roles (uuid, code, name, description, user_type, default_scope, is_system_role)
    SELECT gen_random_uuid(), 'ADMIN', 'Super Admin', 'Full unrestricted platform access', 'INTERNAL', 'GLOBAL', true
    WHERE NOT EXISTS (SELECT 1 FROM roles WHERE code = 'ADMIN');

    INSERT INTO roles (uuid, code, name, description, user_type, default_scope, is_system_role)
    SELECT gen_random_uuid(), 'PHARMACY_PROVIDER', 'Pharmacy Staff', 'Pharmacy counter sales, refills & prescription processing', 'PROVIDER', 'BRANCH', true
    WHERE NOT EXISTS (SELECT 1 FROM roles WHERE code = 'PHARMACY_PROVIDER');
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 2: PHARMACY OUTLETS & PROVIDERS
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_pharm1_biz_id BIGINT;
    v_pharm2_biz_id BIGINT;
    v_provider1_id BIGINT;
    v_provider2_id BIGINT;
BEGIN
    -- Outlets / Businesses
    IF NOT EXISTS (SELECT 1 FROM businesses WHERE code = 'BIZ-PHARM-001') THEN
        INSERT INTO businesses (uuid, code, name, business_type, status)
        VALUES (gen_random_uuid(), 'BIZ-PHARM-001', 'Sahakar Hyperpharmacy - Perinthalmanna Main Outlet', 'PHARMACY_STORE', 'ACTIVE')
        RETURNING id INTO v_pharm1_biz_id;
    ELSE
        SELECT id INTO v_pharm1_biz_id FROM businesses WHERE code = 'BIZ-PHARM-001';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM businesses WHERE code = 'BIZ-PHARM-002') THEN
        INSERT INTO businesses (uuid, code, name, business_type, status)
        VALUES (gen_random_uuid(), 'BIZ-PHARM-002', 'Sahakar Pharmacy - Manjeri Outlet', 'PHARMACY_STORE', 'ACTIVE')
        RETURNING id INTO v_pharm2_biz_id;
    ELSE
        SELECT id INTO v_pharm2_biz_id FROM businesses WHERE code = 'BIZ-PHARM-002';
    END IF;

    -- Service Providers
    IF NOT EXISTS (SELECT 1 FROM service_providers WHERE provider_name = 'Sahakar Main Pharmacy Provider') THEN
        INSERT INTO service_providers (uuid, business_id, provider_name, provider_type, status)
        VALUES (gen_random_uuid(), v_pharm1_biz_id, 'Sahakar Main Pharmacy Provider', 'PHARMACY', 'ACTIVE')
        RETURNING id INTO v_provider1_id;
    ELSE
        SELECT id INTO v_provider1_id FROM service_providers WHERE provider_name = 'Sahakar Main Pharmacy Provider';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM service_providers WHERE provider_name = 'Sahakar Manjeri Pharmacy Provider') THEN
        INSERT INTO service_providers (uuid, business_id, provider_name, provider_type, status)
        VALUES (gen_random_uuid(), v_pharm2_biz_id, 'Sahakar Manjeri Pharmacy Provider', 'PHARMACY', 'ACTIVE')
        RETURNING id INTO v_provider2_id;
    ELSE
        SELECT id INTO v_provider2_id FROM service_providers WHERE provider_name = 'Sahakar Manjeri Pharmacy Provider';
    END IF;

    -- Pharmacy Provider Settings
    IF NOT EXISTS (SELECT 1 FROM pharmacy_provider_settings WHERE provider_id = v_provider1_id) THEN
        INSERT INTO pharmacy_provider_settings (uuid, provider_id, settings)
        VALUES (gen_random_uuid(), v_provider1_id, '{"autoAcceptPrescriptions": false, "enableHomeDelivery": true, "maxDeliveryRadiusKm": 15}'::jsonb);
    END IF;

    -- Service Provider Payment Methods
    IF NOT EXISTS (SELECT 1 FROM service_provider_payment_methods WHERE provider_id = v_provider1_id AND method_type = 'BANK_ACCOUNT' AND deleted_at IS NULL) THEN
        INSERT INTO service_provider_payment_methods (
            uuid, provider_id, method_type, display_label, account_holder_name,
            bank_name, account_number, ifsc_code, branch_name, is_active, is_primary
        ) VALUES (
            gen_random_uuid(), v_provider1_id, 'BANK_ACCOUNT', 'Sahakar Pharmacy Main HDFC Account',
            'Sahakar Healthcare Initiative', 'HDFC Bank', '50100234567890', 'HDFC0001234',
            'Perinthalmanna Branch', true, true
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM service_provider_payment_methods WHERE provider_id = v_provider1_id AND method_type = 'UPI' AND deleted_at IS NULL) THEN
        INSERT INTO service_provider_payment_methods (
            uuid, provider_id, method_type, display_label, upi_id, is_active, is_primary
        ) VALUES (
            gen_random_uuid(), v_provider1_id, 'UPI', 'Sahakar Pharmacy UPI Merchant',
            'sahakarpharmacy@hdfcbank', true, false
        );
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 3: STAFF & TEST USERS (PHARMACY STAFF & ADMIN)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_admin_role_id BIGINT;
    v_pharm_role_id BIGINT;
    v_biz_pharm1_id BIGINT;
BEGIN
    SELECT id INTO v_admin_role_id FROM roles WHERE code = 'ADMIN';
    SELECT id INTO v_pharm_role_id FROM roles WHERE code = 'PHARMACY_PROVIDER';
    SELECT id INTO v_biz_pharm1_id FROM businesses WHERE code = 'BIZ-PHARM-001';

    -- Admin User
    INSERT INTO users (uuid, employee_code, first_name, last_name, mobile, email, role_id, status, user_type, access_scope, branch_business_id)
    SELECT gen_random_uuid(), 'EMP-ADM-001', 'SuperAdmin', 'SHIELD', '9900000001', 'admin@shieldhealth.in', v_admin_role_id, 'ACTIVE', 'INTERNAL', 'GLOBAL', v_biz_pharm1_id
    WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@shieldhealth.in');

    -- Pharmacy Staff User (Assigned to BIZ-PHARM-001)
    INSERT INTO users (uuid, employee_code, first_name, last_name, mobile, email, role_id, status, user_type, access_scope, branch_business_id)
    SELECT gen_random_uuid(), 'EMP-PHM-001', 'Suresh', 'Pharmacist', '9900000004', 'pharmacy.perinthalmanna@shieldhealth.in', v_pharm_role_id, 'ACTIVE', 'PROVIDER', 'BRANCH', v_biz_pharm1_id
    WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'pharmacy.perinthalmanna@shieldhealth.in');
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 4: CUSTOMERS & WALLETS (25 UAT CUSTOMERS)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    i INT;
    v_cust_id BIGINT;
    v_code VARCHAR(50);
    v_mob VARCHAR(20);
    v_fn VARCHAR(100);
    v_ln VARCHAR(100);
    v_status VARCHAR(50);
    v_admin_id BIGINT;
BEGIN
    SELECT id INTO v_admin_id FROM users WHERE email = 'admin@shieldhealth.in';

    FOR i IN 1..25 LOOP
        v_code := 'UAT-CUST-' || LPAD(i::text, 3, '0');
        v_mob := '9876500' || LPAD(i::text, 3, '0');
        v_fn := CASE i % 5
            WHEN 1 THEN 'Aarav'
            WHEN 2 THEN 'Ananya'
            WHEN 3 THEN 'Karthik'
            WHEN 4 THEN 'Devi'
            ELSE 'Siddharth' END;
        v_ln := CASE i % 4
            WHEN 1 THEN 'Nambiar'
            WHEN 2 THEN 'Menon'
            WHEN 3 THEN 'Pillai'
            ELSE 'Kurup' END;
        v_status := CASE 
            WHEN i <= 20 THEN 'ACTIVE'
            ELSE 'INACTIVE' END;

        IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_code = v_code) THEN
            INSERT INTO customers (
                uuid, customer_code, aadhaar_number, first_name, last_name, dob, gender,
                mobile, email, address_line1, city, district, state, pincode, status,
                agent_code, onboarding_source, created_by
            ) VALUES (
                gen_random_uuid(), v_code, '7890' || LPAD(i::text, 8, '0'), v_fn, v_ln,
                ('1985-05-15'::date + (i || ' days')::interval)::date,
                CASE WHEN i % 2 = 0 THEN 'FEMALE' ELSE 'MALE' END,
                v_mob, LOWER(v_fn) || '.' || LOWER(v_ln) || i || '@uat.shield.in',
                'House No. ' || i || ', Sahakar Nagar', 'Perinthalmanna', 'Malappuram', 'Kerala', '679322',
                v_status, 'AGT-UAT', 'AGENT_ONBOARDING', v_admin_id
            ) RETURNING id INTO v_cust_id;

            -- Create Wallet for each Customer
            INSERT INTO wallets (uuid, customer_id, status)
            VALUES (gen_random_uuid(), v_cust_id, 'ACTIVE');

            -- Create Customer Address
            INSERT INTO customer_addresses (uuid, customer_id, label, address_line1, city, district, state, pincode, is_default)
            VALUES (gen_random_uuid(), v_cust_id, 'HOME', 'House No. ' || i || ', Sahakar Nagar', 'Perinthalmanna', 'Malappuram', 'Kerala', '679322', true);
        END IF;
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 5: PRODUCT CATALOG (CATEGORIES & MEDICINE PRODUCTS)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_cat1_id BIGINT;
    v_cat2_id BIGINT;
    v_cat3_id BIGINT;
BEGIN
    -- Product Categories
    IF NOT EXISTS (SELECT 1 FROM product_categories WHERE name = 'Essential Medicines') THEN
        INSERT INTO product_categories (name) VALUES ('Essential Medicines') RETURNING id INTO v_cat1_id;
    ELSE
        SELECT id INTO v_cat1_id FROM product_categories WHERE name = 'Essential Medicines';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM product_categories WHERE name = 'Chronic Care') THEN
        INSERT INTO product_categories (name) VALUES ('Chronic Care') RETURNING id INTO v_cat2_id;
    ELSE
        SELECT id INTO v_cat2_id FROM product_categories WHERE name = 'Chronic Care';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM product_categories WHERE name = 'OTC Healthcare') THEN
        INSERT INTO product_categories (name) VALUES ('OTC Healthcare') RETURNING id INTO v_cat3_id;
    ELSE
        SELECT id INTO v_cat3_id FROM product_categories WHERE name = 'OTC Healthcare';
    END IF;

    -- Products
    IF NOT EXISTS (SELECT 1 FROM products WHERE product_code = 'MED-UAT-001') THEN
        INSERT INTO products (uuid, product_code, product_name, brand, category_id, unit, mrp, selling_price, cost_price, margin_percentage, stock_quantity, status)
        VALUES (gen_random_uuid(), 'MED-UAT-001', 'Paracetamol 650mg Suppress', 'Sahakar Pharma', v_cat1_id, 'STRIP', 45.00, 40.00, 25.00, 37.50, 500.00, 'ACTIVE');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM products WHERE product_code = 'MED-UAT-002') THEN
        INSERT INTO products (uuid, product_code, product_name, brand, category_id, unit, mrp, selling_price, cost_price, margin_percentage, stock_quantity, status)
        VALUES (gen_random_uuid(), 'MED-UAT-002', 'Amoxicillin 500mg Capsule', 'Sahakar Pharma', v_cat1_id, 'STRIP', 120.00, 105.00, 70.00, 33.33, 300.00, 'ACTIVE');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM products WHERE product_code = 'MED-UAT-003') THEN
        INSERT INTO products (uuid, product_code, product_name, brand, category_id, unit, mrp, selling_price, cost_price, margin_percentage, stock_quantity, status)
        VALUES (gen_random_uuid(), 'MED-UAT-003', 'Metformin 500mg SR', 'Sahakar Pharma', v_cat2_id, 'STRIP', 65.00, 55.00, 35.00, 36.36, 450.00, 'ACTIVE');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM products WHERE product_code = 'MED-UAT-004') THEN
        INSERT INTO products (uuid, product_code, product_name, brand, category_id, unit, mrp, selling_price, cost_price, margin_percentage, stock_quantity, status)
        VALUES (gen_random_uuid(), 'MED-UAT-004', 'Amlodipine 5mg Tablet', 'Sahakar Pharma', v_cat2_id, 'STRIP', 50.00, 42.00, 28.00, 33.33, 600.00, 'ACTIVE');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM products WHERE product_code = 'MED-UAT-005') THEN
        INSERT INTO products (uuid, product_code, product_name, brand, category_id, unit, mrp, selling_price, cost_price, margin_percentage, stock_quantity, status)
        VALUES (gen_random_uuid(), 'MED-UAT-005', 'Vitamin C 500mg Chewable', 'Sahakar Pharma', v_cat3_id, 'BOTTLE', 150.00, 130.00, 90.00, 30.77, 200.00, 'ACTIVE');
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 6: PHARMACY PURCHASES & ORDERS (MIN 5 PER ORDER STATUS)
-- Covered Statuses (9): PLACED, ACCEPTED, PARTIAL_REVIEW, PREPARING, READY_FOR_PICKUP, OUT_FOR_DELIVERY, COMPLETED, CANCELLED, REJECTED
-- Total Purchases Seeded: 9 x 5 = 45 Orders
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_provider_id BIGINT;
    v_p1_id BIGINT;
    v_p2_id BIGINT;
    v_admin_id BIGINT;
    v_cust_rec RECORD;
    i INT := 0;
    v_purchase_id BIGINT;
    v_item_id BIGINT;
    v_statuses TEXT[] := ARRAY['PLACED', 'ACCEPTED', 'PARTIAL_REVIEW', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'COMPLETED', 'CANCELLED', 'REJECTED'];
    s TEXT;
    k INT;
BEGIN
    SELECT id INTO v_provider_id FROM service_providers WHERE provider_name = 'Sahakar Main Pharmacy Provider';
    SELECT id INTO v_p1_id FROM products WHERE product_code = 'MED-UAT-001';
    SELECT id INTO v_p2_id FROM products WHERE product_code = 'MED-UAT-002';
    SELECT id INTO v_admin_id FROM users WHERE email = 'admin@shieldhealth.in';

    FOREACH s IN ARRAY v_statuses LOOP
        FOR k IN 1..5 LOOP
            i := i + 1;
            SELECT id INTO v_cust_rec FROM customers ORDER BY id ASC OFFSET (i % 20) LIMIT 1;

            IF NOT EXISTS (SELECT 1 FROM purchases WHERE invoice_number = 'INV-UAT-' || s || '-' || k) THEN
                INSERT INTO purchases (
                    uuid, customer_id, provider_id, invoice_number, total_amount, discount_amount,
                    payable_amount, purchase_date, purchase_kind, payment_status, order_status, order_status_updated_at,
                    billing_snapshot
                ) VALUES (
                    gen_random_uuid(), v_cust_rec.id, v_provider_id, 'INV-UAT-' || s || '-' || k,
                    500.00, 50.00, 450.00, now() - (i || ' days')::interval, 'PHARMACY_PRESCRIPTION',
                    CASE WHEN s = 'COMPLETED' THEN 'PAID' ELSE 'PENDING' END, s, now() - (i || ' hours')::interval,
                    jsonb_build_object(
                        'isChronic', (i % 3 = 0),
                        'fulfillmentPreference', CASE WHEN i % 2 = 0 THEN 'HOME_DELIVERY' ELSE 'COLLECT_FROM_PHARMACY' END,
                        'subtotal', 500.00,
                        'discount', 50.00,
                        'finalPayable', 450.00
                    )
                ) RETURNING id INTO v_purchase_id;

                -- Purchase Item 1: Paracetamol 650mg Suppress
                INSERT INTO purchase_items (purchase_id, product_id, quantity, unit_price, total_price, item_type, item_name)
                VALUES (v_purchase_id, v_p1_id, 2.00, 40.00, 80.00, 'MEDICINE', 'Paracetamol 650mg Suppress')
                RETURNING id INTO v_item_id;

                INSERT INTO purchase_item_fulfillments (purchase_item_id, approved_quantity, dispatched_quantity, remaining_quantity, stock_status, decision_status, decision_reason, decision_actor_id, authoritative_price)
                VALUES (
                    v_item_id, 2.00,
                    CASE WHEN s = 'COMPLETED' THEN 2.00 ELSE 0.00 END,
                    CASE WHEN s = 'COMPLETED' THEN 0.00 ELSE 2.00 END,
                    'FULL_STOCK',
                    CASE WHEN s IN ('ACCEPTED', 'PARTIAL_REVIEW', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'COMPLETED') THEN 'APPROVED' ELSE 'PENDING' END,
                    'In-stock verified by counter pharmacist', v_admin_id, 40.00
                );

                -- Purchase Item 2: Amoxicillin 500mg Capsule
                INSERT INTO purchase_items (purchase_id, product_id, quantity, unit_price, total_price, item_type, item_name)
                VALUES (v_purchase_id, v_p2_id, 10.00, 15.00, 150.00, 'MEDICINE', 'Amoxicillin 500mg Capsule')
                RETURNING id INTO v_item_id;

                INSERT INTO purchase_item_fulfillments (purchase_item_id, approved_quantity, dispatched_quantity, remaining_quantity, stock_status, decision_status, decision_reason, decision_actor_id, authoritative_price)
                VALUES (
                    v_item_id,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 5.00 ELSE 10.00 END,
                    CASE WHEN s = 'COMPLETED' THEN 10.00 ELSE 0.00 END,
                    CASE WHEN s = 'COMPLETED' THEN 0.00 ELSE (CASE WHEN s = 'PARTIAL_REVIEW' THEN 5.00 ELSE 10.00 END) END,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'LOW_STOCK' ELSE 'FULL_STOCK' END,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'PARTIAL' WHEN s IN ('ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'COMPLETED') THEN 'APPROVED' ELSE 'PENDING' END,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'Partial stock available (5/10 units)' ELSE 'Full stock available in inventory' END,
                    v_admin_id, 15.00
                );

                -- Purchase Item 3: Vitamin C 500mg Chewable
                INSERT INTO purchase_items (purchase_id, product_id, quantity, unit_price, total_price, item_type, item_name)
                VALUES (v_purchase_id, NULL, 1.00, 120.00, 120.00, 'WELLNESS', 'Vitamin C 500mg Chewable')
                RETURNING id INTO v_item_id;

                INSERT INTO purchase_item_fulfillments (purchase_item_id, approved_quantity, dispatched_quantity, remaining_quantity, stock_status, decision_status, decision_reason, decision_actor_id, authoritative_price)
                VALUES (
                    v_item_id, 1.00,
                    CASE WHEN s = 'COMPLETED' THEN 1.00 ELSE 0.00 END,
                    CASE WHEN s = 'COMPLETED' THEN 0.00 ELSE 1.00 END,
                    'FULL_STOCK',
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'SUBSTITUTED' WHEN s IN ('ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'COMPLETED') THEN 'APPROVED' ELSE 'PENDING' END,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'Substituted with C-Celin 500mg Chewable' ELSE 'Wellness supplement verified' END,
                    v_admin_id, 120.00
                );

                -- Purchase Item 4: Pantoprazole 40mg Gastro-Resistant
                INSERT INTO purchase_items (purchase_id, product_id, quantity, unit_price, total_price, item_type, item_name)
                VALUES (v_purchase_id, NULL, 1.00, 150.00, 150.00, 'MEDICINE', 'Pantoprazole 40mg Gastro-Resistant')
                RETURNING id INTO v_item_id;

                INSERT INTO purchase_item_fulfillments (purchase_item_id, approved_quantity, dispatched_quantity, remaining_quantity, stock_status, decision_status, decision_reason, decision_actor_id, authoritative_price)
                VALUES (
                    v_item_id,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 0.00 ELSE 1.00 END,
                    CASE WHEN s = 'COMPLETED' THEN 1.00 ELSE 0.00 END,
                    CASE WHEN s = 'COMPLETED' THEN 0.00 ELSE (CASE WHEN s = 'PARTIAL_REVIEW' THEN 0.00 ELSE 1.00 END) END,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'OUT_OF_STOCK' ELSE 'FULL_STOCK' END,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'REJECTED' WHEN s IN ('ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'COMPLETED') THEN 'APPROVED' ELSE 'PENDING' END,
                    CASE WHEN s = 'PARTIAL_REVIEW' THEN 'Item temporarily out of stock' ELSE 'Medicine verified in stock' END,
                    v_admin_id, 150.00
                );

                -- Pharmacist Notes
                INSERT INTO order_pharmacist_notes (purchase_id, notes, author_id, visibility)
                VALUES (v_purchase_id, 'Verified prescription dosage and stock availability for status ' || s, v_admin_id, 'INTERNAL');

                -- Chronic Refill Tagging
                INSERT INTO order_chronic_refills (purchase_id, is_chronic, repeat_interval_days, tagged_by)
                VALUES (v_purchase_id, true, 30, v_admin_id);

                -- Customer Order Confirmation
                INSERT INTO order_customer_confirmations (purchase_id, confirmation_status, reason, purchase_item_id, requested_by, confirmed_at)
                VALUES (
                    v_purchase_id,
                    CASE WHEN s IN ('ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'COMPLETED') THEN 'CONFIRMED' ELSE 'PENDING' END,
                    'Item substitution accepted by customer', v_item_id, v_admin_id,
                    CASE WHEN s IN ('ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'COMPLETED') THEN now() ELSE NULL END
                );

                -- Order Invoice for Completed Orders
                IF s = 'COMPLETED' THEN
                    INSERT INTO order_invoices (purchase_id, storage_key, file_name, uploaded_at, mime_type, file_size, uploaded_by)
                    VALUES (v_purchase_id, 'invoices/INV-UAT-' || s || '-' || k || '.pdf', 'Pharmacy_Invoice_' || k || '.pdf', now(), 'application/pdf', 1048576, v_admin_id);
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 7: STORE CHANGE REQUESTS (MIN 5 PER STATUS)
-- Covered Statuses (3): PENDING, APPROVED, REJECTED
-- Total Requests Seeded: 15 Requests
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_cust_rec RECORD;
    v_pharm1_id BIGINT;
    v_pharm2_id BIGINT;
    v_admin_id BIGINT;
    i INT := 0;
    v_status VARCHAR(50);
BEGIN
    SELECT id INTO v_pharm1_id FROM service_providers WHERE provider_name = 'Sahakar Main Pharmacy Provider';
    SELECT id INTO v_pharm2_id FROM service_providers WHERE provider_name = 'Sahakar Manjeri Pharmacy Provider';
    SELECT id INTO v_admin_id FROM users WHERE email = 'admin@shieldhealth.in';

    FOR v_cust_rec IN SELECT id FROM customers ORDER BY id ASC LIMIT 15 LOOP
        i := i + 1;
        v_status := CASE 
            WHEN i <= 5 THEN 'PENDING'
            WHEN i <= 10 THEN 'APPROVED'
            ELSE 'REJECTED' END;

        IF NOT EXISTS (SELECT 1 FROM store_change_requests WHERE customer_id = v_cust_rec.id) THEN
            INSERT INTO store_change_requests (
                uuid, customer_id, previous_provider_id, requested_provider_id, reason, status, review_reason, reviewed_by, submitted_at, reviewed_at
            ) VALUES (
                gen_random_uuid(), v_cust_rec.id, v_pharm1_id, v_pharm2_id, 'Relocated residence closer to Manjeri pharmacy outlet', v_status,
                CASE WHEN v_status = 'REJECTED' THEN 'Invalid proof of address provided for Manjeri branch' ELSE 'Store change UAT request approved' END,
                v_admin_id, now() - (i || ' days')::interval, CASE WHEN v_status = 'PENDING' THEN NULL ELSE now() END
            );
        END IF;
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 8: PRESCRIPTION PHARMACY REQUESTS (MIN 5 PER STATUS)
-- Covered Statuses (4): SUBMITTED, ACCEPTED, REJECTED, FULFILLED
-- Total Requests Seeded: 20 Requests
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_cust_rec RECORD;
    v_pharm1_id BIGINT;
    v_doc_id BIGINT;
    v_admin_id BIGINT;
    v_status VARCHAR(50);
BEGIN
    SELECT id INTO v_pharm1_id FROM service_providers WHERE provider_name = 'Sahakar Main Pharmacy Provider';
    SELECT id INTO v_admin_id FROM users WHERE email = 'admin@shieldhealth.in';

    FOR v_cust_rec IN SELECT id FROM customers ORDER BY id ASC LIMIT 20 LOOP
        IF NOT EXISTS (SELECT 1 FROM documents WHERE customer_id = v_cust_rec.id AND file_name = 'UAT_Prescription_' || v_cust_rec.id || '.pdf') THEN
            INSERT INTO documents (uuid, customer_id, uploaded_by, document_type, file_name, storage_path, file_size, mime_type, status)
            VALUES (gen_random_uuid(), v_cust_rec.id, v_admin_id, 'PRESCRIPTION', 'UAT_Prescription_' || v_cust_rec.id || '.pdf', 'docs/rx_' || v_cust_rec.id || '.pdf', 524288, 'application/pdf', 'APPROVED')
            RETURNING id INTO v_doc_id;

            v_status := CASE 
                WHEN v_cust_rec.id <= 5 THEN 'SUBMITTED'
                WHEN v_cust_rec.id <= 10 THEN 'ACCEPTED'
                WHEN v_cust_rec.id <= 15 THEN 'REJECTED'
                ELSE 'FULFILLED' END;

            INSERT INTO prescription_pharmacy_requests (uuid, customer_id, document_id, provider_id, status, customer_notes)
            VALUES (gen_random_uuid(), v_cust_rec.id, v_doc_id, v_pharm1_id, v_status, 'Please fulfill 30-day chronic refill supply for prescription #' || v_cust_rec.id);
        END IF;
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- SECTION 9: WALLET RECHARGE INTENTS & TRANSACTIONS (PHARMACY CUSTOMERS)
-- Covered Statuses (4): INITIATED, APPROVED, REJECTED, FAILED
-- Total Intents Seeded: 20 Recharge Intents
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_cust_rec RECORD;
    v_w_id BIGINT;
    v_admin_id BIGINT;
    v_provider_id BIGINT;
    i INT := 0;
    v_status VARCHAR(50);
BEGIN
    SELECT id INTO v_admin_id FROM users WHERE email = 'admin@shieldhealth.in';
    SELECT id INTO v_provider_id FROM service_providers WHERE provider_type = 'PHARMACY' LIMIT 1;

    FOR v_cust_rec IN SELECT id FROM customers ORDER BY id ASC LIMIT 20 LOOP
        i := i + 1;
        SELECT id INTO v_w_id FROM wallets WHERE customer_id = v_cust_rec.id;

        v_status := CASE 
            WHEN i <= 5 THEN 'INITIATED'
            WHEN i <= 10 THEN 'APPROVED'
            WHEN i <= 15 THEN 'REJECTED'
            ELSE 'FAILED' END;

        IF NOT EXISTS (SELECT 1 FROM wallet_recharge_intents WHERE customer_id = v_cust_rec.id AND idempotency_key = 'IDEM-UAT-RECHARGE-' || i) THEN
            INSERT INTO wallet_recharge_intents (
                uuid, customer_id, wallet_id, amount, idempotency_key, provider_code, provider_reference,
                status, created_at, provider_id, payment_channel, reference_number, reviewed_by, reviewed_at, rejection_reason
            ) VALUES (
                gen_random_uuid(), v_cust_rec.id, v_w_id, 2500.00, 'IDEM-UAT-RECHARGE-' || i, 'HDFC_BANK', 'REF-BANK-UAT-' || i,
                v_status, now() - (i || ' hours')::interval, v_provider_id, 'BANK_TRANSFER', 'UTR-UAT-' || LPAD(i::text, 6, '0'),
                v_admin_id, CASE WHEN v_status = 'INITIATED' THEN NULL ELSE now() END, CASE WHEN v_status = 'REJECTED' THEN 'Payment UTR verification mismatch' ELSE NULL END
            );

            IF v_status = 'APPROVED' THEN
                INSERT INTO wallet_transactions (uuid, wallet_id, transaction_type, sub_ledger_type, amount, remarks, created_by, is_customer_visible)
                VALUES (gen_random_uuid(), v_w_id, 'CREDIT', 'CASH', 2500.00, 'Pharmacy Wallet Cash Recharge Approved', v_admin_id, true);

                INSERT INTO cash_wallet_transactions (uuid, wallet_id, transaction_type, amount, remarks, created_by)
                VALUES (gen_random_uuid(), v_w_id, 'RECHARGE', 2500.00, 'Cash Recharge Verified at Pharmacy', v_admin_id);
            END IF;
        END IF;
    END LOOP;
END $$;

COMMIT;
-- =============================================================================
-- END OF PHARMACY UAT SEED SCRIPT
-- =============================================================================
