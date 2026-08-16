-- Additive narrow unique index for Customer order idempotency key concurrency safety
CREATE UNIQUE INDEX IF NOT EXISTS "purchases_customer_invoice_key"
ON "purchases"("customer_id", "invoice_number")
WHERE "purchase_kind" = 'CUSTOMER_ORDER' AND "invoice_number" LIKE 'ORD-KEY-%';
