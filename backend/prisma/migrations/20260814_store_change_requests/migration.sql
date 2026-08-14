CREATE TABLE "store_change_requests" (
  "id" BIGSERIAL PRIMARY KEY,
  "uuid" UUID NOT NULL UNIQUE,
  "customer_id" BIGINT NOT NULL,
  "previous_provider_id" BIGINT,
  "requested_provider_id" BIGINT NOT NULL,
  "reason" TEXT NOT NULL,
  "status" VARCHAR(50) NOT NULL DEFAULT 'PENDING',
  "review_reason" TEXT,
  "reviewed_by" BIGINT,
  "submitted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "reviewed_at" TIMESTAMPTZ(6),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "idx_store_change_requests_customer_status"
  ON "store_change_requests" ("customer_id", "status");
CREATE INDEX "idx_store_change_requests_status_submitted"
  ON "store_change_requests" ("status", "submitted_at");
CREATE UNIQUE INDEX "uq_store_change_requests_one_pending_per_customer"
  ON "store_change_requests" ("customer_id")
  WHERE "status" = 'PENDING';

ALTER TABLE "store_change_requests"
  ADD CONSTRAINT "store_change_requests_customer_id_fkey"
  FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE CASCADE;
ALTER TABLE "store_change_requests"
  ADD CONSTRAINT "store_change_requests_previous_provider_id_fkey"
  FOREIGN KEY ("previous_provider_id") REFERENCES "service_providers"("id") ON DELETE SET NULL;
ALTER TABLE "store_change_requests"
  ADD CONSTRAINT "store_change_requests_requested_provider_id_fkey"
  FOREIGN KEY ("requested_provider_id") REFERENCES "service_providers"("id") ON DELETE RESTRICT;
ALTER TABLE "store_change_requests"
  ADD CONSTRAINT "store_change_requests_reviewed_by_fkey"
  FOREIGN KEY ("reviewed_by") REFERENCES "users"("id") ON DELETE SET NULL;
