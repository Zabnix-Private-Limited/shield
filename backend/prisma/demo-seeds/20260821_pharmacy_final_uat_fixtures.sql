-- =============================================================================
-- SHIELD PHARMACY — FINAL BLOCKED-UAT FIXTURES (OWNER EXECUTION ONLY)
-- Date: 2026-08-21
-- Purpose: Minimal deterministic fixtures for payment exact-once and provider
--          isolation UAT. Do not execute from an application build or deploy.
-- Safety: Idempotent natural keys only; no non-UAT record is updated.
-- =============================================================================

BEGIN;

DO $$
DECLARE
    v_pharmacy_role_id BIGINT;
    v_primary_business_id BIGINT;
    v_secondary_business_id BIGINT;
    v_primary_provider_id BIGINT;
    v_membership_type_id BIGINT;
    v_customer_id BIGINT;
    v_wallet_id BIGINT;
    v_payment_method_id BIGINT;
BEGIN
    SELECT id INTO v_pharmacy_role_id
    FROM roles
    WHERE code = 'PHARMACY_PROVIDER';

    IF v_pharmacy_role_id IS NULL THEN
        RAISE EXCEPTION 'Required PHARMACY_PROVIDER role is missing.';
    END IF;

    INSERT INTO businesses (uuid, code, name, business_type, status)
    SELECT gen_random_uuid(), 'UAT-PHARMACY-PRIMARY', 'SHIELD UAT Primary Pharmacy', 'PHARMACY_STORE', 'ACTIVE'
    WHERE NOT EXISTS (
        SELECT 1 FROM businesses WHERE code = 'UAT-PHARMACY-PRIMARY'
    );

    INSERT INTO businesses (uuid, code, name, business_type, status)
    SELECT gen_random_uuid(), 'UAT-PHARMACY-SECONDARY', 'SHIELD UAT Secondary Pharmacy', 'PHARMACY_STORE', 'ACTIVE'
    WHERE NOT EXISTS (
        SELECT 1 FROM businesses WHERE code = 'UAT-PHARMACY-SECONDARY'
    );

    SELECT id INTO v_primary_business_id
    FROM businesses WHERE code = 'UAT-PHARMACY-PRIMARY';
    SELECT id INTO v_secondary_business_id
    FROM businesses WHERE code = 'UAT-PHARMACY-SECONDARY';

    INSERT INTO service_providers (uuid, business_id, provider_name, provider_type, status)
    SELECT gen_random_uuid(), v_primary_business_id, 'SHIELD UAT Primary Pharmacy Provider', 'PHARMACY', 'ACTIVE'
    WHERE NOT EXISTS (
        SELECT 1 FROM service_providers
        WHERE business_id = v_primary_business_id
          AND provider_type = 'PHARMACY'
          AND provider_name = 'SHIELD UAT Primary Pharmacy Provider'
    );

    INSERT INTO service_providers (uuid, business_id, provider_name, provider_type, status)
    SELECT gen_random_uuid(), v_secondary_business_id, 'SHIELD UAT Secondary Pharmacy Provider', 'PHARMACY', 'ACTIVE'
    WHERE NOT EXISTS (
        SELECT 1 FROM service_providers
        WHERE business_id = v_secondary_business_id
          AND provider_type = 'PHARMACY'
          AND provider_name = 'SHIELD UAT Secondary Pharmacy Provider'
    );

    SELECT id INTO v_primary_provider_id
    FROM service_providers
    WHERE business_id = v_primary_business_id
      AND provider_type = 'PHARMACY'
      AND status = 'ACTIVE'
      AND provider_name = 'SHIELD UAT Primary Pharmacy Provider';

    IF v_primary_provider_id IS NULL THEN
        RAISE EXCEPTION 'Primary UAT Pharmacy provider was not resolved.';
    END IF;

    INSERT INTO service_provider_payment_methods (
        uuid, provider_id, method_type, display_label, upi_id, is_active, is_primary
    )
    SELECT gen_random_uuid(), v_primary_provider_id, 'UPI',
           'SHIELD UAT Primary UPI', 'shield.uat.primary@example.test', true, true
    WHERE NOT EXISTS (
        SELECT 1 FROM service_provider_payment_methods
        WHERE provider_id = v_primary_provider_id
          AND method_type = 'UPI'
          AND upi_id = 'shield.uat.primary@example.test'
          AND deleted_at IS NULL
    );

    INSERT INTO users (
        uuid, employee_code, first_name, last_name, mobile, email, role_id,
        status, user_type, access_scope, branch_business_id
    )
    SELECT gen_random_uuid(), 'UAT-PHARM-STAFF-PRIMARY', 'SHIELD UAT', 'Primary Staff',
           '9000000101', 'uat-pharmacy-staff-primary@example.test', v_pharmacy_role_id,
           'ACTIVE', 'PROVIDER', 'BRANCH', v_primary_business_id
    WHERE NOT EXISTS (
        SELECT 1 FROM users WHERE email = 'uat-pharmacy-staff-primary@example.test'
    );

    INSERT INTO users (
        uuid, employee_code, first_name, last_name, mobile, email, role_id,
        status, user_type, access_scope, branch_business_id
    )
    SELECT gen_random_uuid(), 'UAT-PHARM-STAFF-SECONDARY', 'SHIELD UAT', 'Secondary Staff',
           '9000000102', 'uat-pharmacy-staff-secondary@example.test', v_pharmacy_role_id,
           'ACTIVE', 'PROVIDER', 'BRANCH', v_secondary_business_id
    WHERE NOT EXISTS (
        SELECT 1 FROM users WHERE email = 'uat-pharmacy-staff-secondary@example.test'
    );

    INSERT INTO users (
        uuid, employee_code, first_name, last_name, mobile, email, role_id,
        status, user_type, access_scope, branch_business_id
    )
    SELECT gen_random_uuid(), 'UAT-PHARM-STAFF-UNASSIGNED', 'SHIELD UAT', 'Unassigned Staff',
           '9000000103', 'uat-pharmacy-staff-unassigned@example.test', v_pharmacy_role_id,
           'ACTIVE', 'PROVIDER', 'BRANCH', NULL
    WHERE NOT EXISTS (
        SELECT 1 FROM users WHERE email = 'uat-pharmacy-staff-unassigned@example.test'
    );

    INSERT INTO membership_types (
        uuid, code, name, joining_fee, discount_percentage, credit_eligible, status
    )
    SELECT gen_random_uuid(), 'UAT-PRIVILEGE-FINAL', 'SHIELD UAT Privilege Membership',
           0.00, 0.00, true, 'ACTIVE'
    WHERE NOT EXISTS (
        SELECT 1 FROM membership_types WHERE code = 'UAT-PRIVILEGE-FINAL'
    );

    SELECT id INTO v_membership_type_id
    FROM membership_types
    WHERE code = 'UAT-PRIVILEGE-FINAL';

    INSERT INTO customers (
        uuid, customer_code, first_name, last_name, mobile, email, status,
        agent_code, onboarding_source
    )
    SELECT gen_random_uuid(), 'UAT-PHARMACY-FINAL-CUSTOMER', 'SHIELD UAT', 'Payment Member',
           '9000000201', 'uat-pharmacy-payment-member@example.test', 'ACTIVE',
           'AGT-UAT', 'NEW_REGISTRATION'
    WHERE NOT EXISTS (
        SELECT 1 FROM customers WHERE customer_code = 'UAT-PHARMACY-FINAL-CUSTOMER'
    );

    SELECT id INTO v_customer_id
    FROM customers
    WHERE customer_code = 'UAT-PHARMACY-FINAL-CUSTOMER';

    INSERT INTO memberships (
        uuid, customer_id, membership_type_id, membership_number, joining_fee,
        activation_date, expiry_date, status
    )
    SELECT gen_random_uuid(), v_customer_id, v_membership_type_id,
           'UAT-PRIVILEGE-FINAL-001', 0.00, CURRENT_DATE,
           CURRENT_DATE + INTERVAL '365 days', 'ACTIVE'
    WHERE NOT EXISTS (
        SELECT 1 FROM memberships WHERE customer_id = v_customer_id
    );

    INSERT INTO shield_cards (
        uuid, customer_id, card_number, qr_code, status, issued_business_id, issued_at
    )
    SELECT gen_random_uuid(), v_customer_id, 'SHIELD-UAT-FINAL-001',
           'SHIELD-UAT-FINAL-QR-001', 'ISSUED', v_primary_business_id, CURRENT_TIMESTAMP
    WHERE NOT EXISTS (
        SELECT 1 FROM shield_cards WHERE customer_id = v_customer_id
    );

    INSERT INTO wallets (uuid, customer_id, status)
    SELECT gen_random_uuid(), v_customer_id, 'ACTIVE'
    WHERE NOT EXISTS (
        SELECT 1 FROM wallets WHERE customer_id = v_customer_id
    );

    SELECT id INTO v_wallet_id FROM wallets WHERE customer_id = v_customer_id;

    SELECT id INTO v_payment_method_id
    FROM service_provider_payment_methods
    WHERE provider_id = v_primary_provider_id
      AND method_type = 'UPI'
      AND is_active = true
      AND deleted_at IS NULL
    ORDER BY is_primary DESC, id
    LIMIT 1;

    IF v_payment_method_id IS NULL THEN
        RAISE EXCEPTION 'Primary UAT Pharmacy UPI payment method was not resolved.';
    END IF;

    INSERT INTO wallet_recharge_intents (
        uuid, customer_id, wallet_id, provider_id, payment_method_id,
        payment_channel, reference_number, amount, idempotency_key,
        provider_code, provider_reference, status, destination_snapshot
    )
    SELECT gen_random_uuid(), v_customer_id, v_wallet_id, v_primary_provider_id,
           v_payment_method_id, 'UPI', 'UAT-UTR-FINAL-A-10000', 10000.00,
           'UAT-PAYMENT-PENDING-A', 'SHIELD_UAT_MANUAL', 'UAT-PAYMENT-PENDING-A',
           'PENDING', jsonb_build_object('fixture', 'UAT-PAYMENT-PENDING-A', 'channel', 'UPI')
    WHERE NOT EXISTS (
        SELECT 1 FROM wallet_recharge_intents WHERE idempotency_key = 'UAT-PAYMENT-PENDING-A'
    );

    INSERT INTO wallet_recharge_intents (
        uuid, customer_id, wallet_id, provider_id, payment_method_id,
        payment_channel, reference_number, amount, idempotency_key,
        provider_code, provider_reference, status, destination_snapshot
    )
    SELECT gen_random_uuid(), v_customer_id, v_wallet_id, v_primary_provider_id,
           v_payment_method_id, 'UPI', 'UAT-UTR-FINAL-B-20000', 20000.00,
           'UAT-PAYMENT-PENDING-B', 'SHIELD_UAT_MANUAL', 'UAT-PAYMENT-PENDING-B',
           'PENDING', jsonb_build_object('fixture', 'UAT-PAYMENT-PENDING-B', 'channel', 'UPI')
    WHERE NOT EXISTS (
        SELECT 1 FROM wallet_recharge_intents WHERE idempotency_key = 'UAT-PAYMENT-PENDING-B'
    );

    INSERT INTO wallet_recharge_intents (
        uuid, customer_id, wallet_id, provider_id, payment_method_id,
        payment_channel, reference_number, amount, idempotency_key,
        provider_code, provider_reference, status, destination_snapshot
    )
    SELECT gen_random_uuid(), v_customer_id, v_wallet_id, v_primary_provider_id,
           v_payment_method_id, 'UPI', 'UAT-UTR-FINAL-C-30000', 30000.00,
           'UAT-PAYMENT-PENDING-C', 'SHIELD_UAT_MANUAL', 'UAT-PAYMENT-PENDING-C',
           'PENDING', jsonb_build_object('fixture', 'UAT-PAYMENT-PENDING-C', 'channel', 'UPI')
    WHERE NOT EXISTS (
        SELECT 1 FROM wallet_recharge_intents WHERE idempotency_key = 'UAT-PAYMENT-PENDING-C'
    );
END $$;

COMMIT;
