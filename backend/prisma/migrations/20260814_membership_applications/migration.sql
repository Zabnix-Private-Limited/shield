CREATE TABLE "membership_applications" (
  "id" BIGSERIAL PRIMARY KEY,
  "uuid" UUID NOT NULL UNIQUE,
  "customer_id" BIGINT NOT NULL,
  "status" VARCHAR(50) NOT NULL DEFAULT 'PENDING',
  "reference" VARCHAR(100) NOT NULL UNIQUE,
  "review_reason" TEXT,
  "reviewed_by" BIGINT,
  "submitted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "reviewed_at" TIMESTAMPTZ(6),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "idx_membership_applications_customer_status"
  ON "membership_applications" ("customer_id", "status");
CREATE INDEX "idx_membership_applications_submitted_at"
  ON "membership_applications" ("submitted_at");

ALTER TABLE "membership_applications"
  ADD CONSTRAINT "membership_applications_customer_id_fkey"
  FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE CASCADE;
ALTER TABLE "membership_applications"
  ADD CONSTRAINT "membership_applications_reviewed_by_fkey"
  FOREIGN KEY ("reviewed_by") REFERENCES "users"("id") ON DELETE SET NULL;
