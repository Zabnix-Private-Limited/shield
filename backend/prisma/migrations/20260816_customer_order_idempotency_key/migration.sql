-- Additive unique index for Customer order idempotency key concurrency safety
CREATE UNIQUE INDEX IF NOT EXISTS "purchases_customer_invoice_key" ON "purchases"("customer_id", "invoice_number") WHERE "invoice_number" IS NOT NULL;
