-- SHIELD Pharmacy Portal — Additive Hardening Migration for Normalized Fulfillment Tables
-- Migration Name: 20260819_pharmacy_advanced_fulfillment_hardening.sql
-- Description: Adds missing audit columns (rejected_quantity, decision_actor_id, substitute_quantity, proposed_by, customer_confirmation_status, visibility, mime_type, uploaded_by) and cleans up duplicate inline FK constraints.

-- 1. Purchase Item Fulfillments Hardening
ALTER TABLE "purchase_item_fulfillments" 
    ADD COLUMN IF NOT EXISTS "rejected_quantity" NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS "decision_reason" TEXT,
    ADD COLUMN IF NOT EXISTS "decision_actor_id" BIGINT REFERENCES "users"("id") ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS "authoritative_price" NUMERIC(12, 2);

-- 2. Purchase Item Substitutions Hardening
ALTER TABLE "purchase_item_substitutions" 
    ADD COLUMN IF NOT EXISTS "substitute_quantity" NUMERIC(10, 2) NOT NULL DEFAULT 1.00,
    ADD COLUMN IF NOT EXISTS "proposed_by" BIGINT REFERENCES "users"("id") ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS "customer_confirmation_status" VARCHAR(50) NOT NULL DEFAULT 'PENDING';

-- 3. Order Customer Confirmations Hardening
ALTER TABLE "order_customer_confirmations" 
    ADD COLUMN IF NOT EXISTS "purchase_item_id" BIGINT REFERENCES "purchase_items"("id") ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS "requested_by" BIGINT REFERENCES "users"("id") ON DELETE SET NULL;

-- 4. Order Pharmacist Notes Hardening
ALTER TABLE "order_pharmacist_notes" 
    ADD COLUMN IF NOT EXISTS "visibility" VARCHAR(50) NOT NULL DEFAULT 'INTERNAL';

-- 5. Order Invoices Hardening
ALTER TABLE "order_invoices" 
    ADD COLUMN IF NOT EXISTS "mime_type" VARCHAR(100) NOT NULL DEFAULT 'application/pdf',
    ADD COLUMN IF NOT EXISTS "file_size" BIGINT,
    ADD COLUMN IF NOT EXISTS "uploaded_by" BIGINT REFERENCES "users"("id") ON DELETE SET NULL;

-- Safe Idempotent Constraint Cleanup for Duplicate Inline FKs
DO $$ 
BEGIN
    -- Cleanup redundant duplicate inline constraint on purchase_item_fulfillments if present
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'purchase_item_fulfillments_purchase_item_id_fkey') THEN
        ALTER TABLE "purchase_item_fulfillments" DROP CONSTRAINT "purchase_item_fulfillments_purchase_item_id_fkey";
    END IF;
    -- Cleanup redundant duplicate inline constraint on purchase_item_substitutions if present
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'purchase_item_substitutions_purchase_item_id_fkey') THEN
        ALTER TABLE "purchase_item_substitutions" DROP CONSTRAINT "purchase_item_substitutions_purchase_item_id_fkey";
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'purchase_item_substitutions_substitute_product_id_fkey') THEN
        ALTER TABLE "purchase_item_substitutions" DROP CONSTRAINT "purchase_item_substitutions_substitute_product_id_fkey";
    END IF;
    -- Cleanup redundant duplicate inline constraint on order_chronic_refills if present
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'order_chronic_refills_purchase_id_fkey') THEN
        ALTER TABLE "order_chronic_refills" DROP CONSTRAINT "order_chronic_refills_purchase_id_fkey";
    END IF;
    -- Cleanup redundant duplicate inline constraint on order_customer_confirmations if present
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'order_customer_confirmations_purchase_id_fkey') THEN
        ALTER TABLE "order_customer_confirmations" DROP CONSTRAINT "order_customer_confirmations_purchase_id_fkey";
    END IF;
    -- Cleanup redundant duplicate inline constraint on order_invoices if present
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'order_invoices_purchase_id_fkey') THEN
        ALTER TABLE "order_invoices" DROP CONSTRAINT "order_invoices_purchase_id_fkey";
    END IF;
    -- Cleanup redundant duplicate inline constraint on order_pharmacist_notes if present
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'order_pharmacist_notes_purchase_id_fkey') THEN
        ALTER TABLE "order_pharmacist_notes" DROP CONSTRAINT "order_pharmacist_notes_purchase_id_fkey";
    END IF;
END $$;
