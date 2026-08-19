-- SHIELD Pharmacy Portal — Normalized Advanced Fulfillment & Workflow Persistence Schema Migration
-- Migration Name: 20260819_pharmacy_advanced_fulfillment_normalized.sql
-- Description: Adds normalized tables for purchase item fulfillments, substitute product relations, chronic order tracking, pharmacist notes timeline, invoice records, and customer confirmations.

-- 1. Purchase Item Fulfillments Table
CREATE TABLE IF NOT EXISTS "purchase_item_fulfillments" (
    "id" BIGSERIAL PRIMARY KEY,
    "purchase_item_id" BIGINT NOT NULL REFERENCES "purchase_items"("id") ON DELETE CASCADE,
    "approved_quantity" NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    "dispatched_quantity" NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    "remaining_quantity" NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    "stock_status" VARCHAR(50) NOT NULL DEFAULT 'FULL_STOCK',
    "decision_status" VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "fk_purchase_item_fulfillment_item" FOREIGN KEY ("purchase_item_id") REFERENCES "purchase_items"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_purchase_item_fulfillments_item_id" ON "purchase_item_fulfillments"("purchase_item_id");

-- 2. Purchase Item Substitutions Table
CREATE TABLE IF NOT EXISTS "purchase_item_substitutions" (
    "id" BIGSERIAL PRIMARY KEY,
    "purchase_item_id" BIGINT NOT NULL REFERENCES "purchase_items"("id") ON DELETE CASCADE,
    "substitute_product_id" BIGINT REFERENCES "products"("id") ON DELETE SET NULL,
    "substitute_name" VARCHAR(255) NOT NULL,
    "substitute_unit_price" NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    "decision_reason" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "fk_purchase_item_substitutions_item" FOREIGN KEY ("purchase_item_id") REFERENCES "purchase_items"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_purchase_item_substitutions_prod" FOREIGN KEY ("substitute_product_id") REFERENCES "products"("id") ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "idx_purchase_item_substitutions_item_id" ON "purchase_item_substitutions"("purchase_item_id");

-- 3. Order Chronic Refills Table
CREATE TABLE IF NOT EXISTS "order_chronic_refills" (
    "id" BIGSERIAL PRIMARY KEY,
    "purchase_id" BIGINT NOT NULL REFERENCES "purchases"("id") ON DELETE CASCADE,
    "is_chronic" BOOLEAN NOT NULL DEFAULT TRUE,
    "repeat_interval_days" INT NOT NULL DEFAULT 30,
    "tagged_by" BIGINT REFERENCES "users"("id") ON DELETE SET NULL,
    "tagged_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "fk_order_chronic_refills_purchase" FOREIGN KEY ("purchase_id") REFERENCES "purchases"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_order_chronic_refills_purchase_id" ON "order_chronic_refills"("purchase_id");

-- 4. Order Pharmacist Notes Table (Timeline Audit)
CREATE TABLE IF NOT EXISTS "order_pharmacist_notes" (
    "id" BIGSERIAL PRIMARY KEY,
    "purchase_id" BIGINT NOT NULL REFERENCES "purchases"("id") ON DELETE CASCADE,
    "notes" TEXT NOT NULL,
    "author_id" BIGINT REFERENCES "users"("id") ON DELETE SET NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "fk_order_pharmacist_notes_purchase" FOREIGN KEY ("purchase_id") REFERENCES "purchases"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_order_pharmacist_notes_purchase_id" ON "order_pharmacist_notes"("purchase_id");

-- 5. Order Invoices Table (Cloudflare R2 Private Storage Key)
CREATE TABLE IF NOT EXISTS "order_invoices" (
    "id" BIGSERIAL PRIMARY KEY,
    "purchase_id" BIGINT NOT NULL REFERENCES "purchases"("id") ON DELETE CASCADE,
    "storage_key" VARCHAR(500) NOT NULL,
    "file_name" VARCHAR(255) NOT NULL DEFAULT 'Pharmacy_Invoice.pdf',
    "uploaded_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sent_at" TIMESTAMPTZ,
    CONSTRAINT "fk_order_invoices_purchase" FOREIGN KEY ("purchase_id") REFERENCES "purchases"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_order_invoices_purchase_id" ON "order_invoices"("purchase_id");

-- 6. Order Customer Confirmations Table
CREATE TABLE IF NOT EXISTS "order_customer_confirmations" (
    "id" BIGSERIAL PRIMARY KEY,
    "purchase_id" BIGINT NOT NULL REFERENCES "purchases"("id") ON DELETE CASCADE,
    "confirmation_status" VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    "reason" TEXT,
    "requested_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "confirmed_at" TIMESTAMPTZ,
    CONSTRAINT "fk_order_customer_confirmations_purchase" FOREIGN KEY ("purchase_id") REFERENCES "purchases"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "idx_order_customer_confirmations_purchase_id" ON "order_customer_confirmations"("purchase_id");
