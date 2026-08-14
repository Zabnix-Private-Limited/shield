CREATE TABLE "wallet_recharge_intents" (
  "id" BIGSERIAL PRIMARY KEY,
  "uuid" UUID NOT NULL UNIQUE,
  "customer_id" BIGINT NOT NULL,
  "wallet_id" BIGINT NOT NULL,
  "amount" NUMERIC(15,2) NOT NULL,
  "idempotency_key" VARCHAR(120) NOT NULL UNIQUE,
  "provider_code" VARCHAR(80),
  "provider_reference" VARCHAR(160) UNIQUE,
  "status" VARCHAR(40) NOT NULL DEFAULT 'INITIATED',
  "failure_code" VARCHAR(100),
  "failure_reason" TEXT,
  "credited_at" TIMESTAMPTZ(6),
  "failed_at" TIMESTAMPTZ(6),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "wallet_recharge_intents_amount_positive" CHECK ("amount" > 0)
);
CREATE INDEX "idx_wallet_recharge_intents_customer_status" ON "wallet_recharge_intents" ("customer_id", "status", "created_at");
CREATE INDEX "idx_wallet_recharge_intents_wallet_status" ON "wallet_recharge_intents" ("wallet_id", "status");
ALTER TABLE "wallet_recharge_intents" ADD CONSTRAINT "wallet_recharge_intents_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE CASCADE;
ALTER TABLE "wallet_recharge_intents" ADD CONSTRAINT "wallet_recharge_intents_wallet_id_fkey" FOREIGN KEY ("wallet_id") REFERENCES "wallets"("id") ON DELETE RESTRICT;
