-- Management-demo workflow additions. Prepared only; do not apply this migration
-- to a shared or production database without an approved backup and rollout.

ALTER TABLE "customers"
  ADD COLUMN "onboarding_source" varchar(50) NOT NULL DEFAULT 'NEW_REGISTRATION';

ALTER TABLE "products"
  ADD COLUMN "mrp" numeric(15,2),
  ADD COLUMN "selling_price" numeric(15,2),
  ADD COLUMN "cost_price" numeric(15,2),
  ADD COLUMN "margin_percentage" numeric(5,2),
  ADD COLUMN "stock_quantity" numeric(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN "is_demo_available" boolean NOT NULL DEFAULT false,
  ADD COLUMN "data_source" varchar(50) NOT NULL DEFAULT 'PRIMARY',
  ADD COLUMN "status" varchar(50) NOT NULL DEFAULT 'ACTIVE';

ALTER TABLE "purchases"
  ADD COLUMN "order_status" varchar(50) NOT NULL DEFAULT 'PLACED';

CREATE TABLE "customer_import_batches" (
  "id" bigserial PRIMARY KEY,
  "uuid" uuid NOT NULL UNIQUE,
  "business_id" bigint NOT NULL REFERENCES "businesses"("id"),
  "status" varchar(50) NOT NULL DEFAULT 'PENDING_APPROVAL',
  "requested_by" bigint REFERENCES "users"("id"),
  "approved_by" bigint REFERENCES "users"("id"),
  "requested_at" timestamptz NOT NULL DEFAULT now(),
  "approved_at" timestamptz,
  "imported_at" timestamptz,
  "source_file_name" varchar(255),
  "row_count" integer NOT NULL DEFAULT 0,
  "notes" text
);

CREATE TABLE "customer_import_rows" (
  "id" bigserial PRIMARY KEY,
  "batch_id" bigint NOT NULL REFERENCES "customer_import_batches"("id") ON DELETE CASCADE,
  "external_customer_id" varchar(100) NOT NULL,
  "mobile" varchar(20) NOT NULL,
  "full_name" varchar(255),
  "payload" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "matched_customer_id" bigint REFERENCES "customers"("id"),
  "status" varchar(50) NOT NULL DEFAULT 'PENDING',
  "created_at" timestamptz NOT NULL DEFAULT now(),
  UNIQUE ("batch_id", "external_customer_id")
);

CREATE TABLE "card_requests" (
  "id" bigserial PRIMARY KEY,
  "uuid" uuid NOT NULL UNIQUE,
  "customer_id" bigint NOT NULL REFERENCES "customers"("id"),
  "membership_id" bigint REFERENCES "memberships"("id"),
  "business_id" bigint REFERENCES "businesses"("id"),
  "status" varchar(50) NOT NULL DEFAULT 'REQUESTED',
  "requested_by" bigint REFERENCES "users"("id"),
  "reviewed_by" bigint REFERENCES "users"("id"),
  "requested_at" timestamptz NOT NULL DEFAULT now(),
  "reviewed_at" timestamptz,
  "remarks" text
);

CREATE TABLE "membership_subscriptions" (
  "id" bigserial PRIMARY KEY,
  "uuid" uuid NOT NULL UNIQUE,
  "customer_id" bigint NOT NULL UNIQUE REFERENCES "customers"("id"),
  "membership_id" bigint REFERENCES "memberships"("id"),
  "plan_name" varchar(255) NOT NULL,
  "customer_contribution_paise" bigint NOT NULL DEFAULT 1000000,
  "shield_benefit_paise" bigint NOT NULL DEFAULT 100000,
  "total_entitlement_paise" bigint NOT NULL DEFAULT 1100000,
  "status" varchar(50) NOT NULL DEFAULT 'DRAFT',
  "starts_on" date,
  "ends_on" date,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  CHECK ("customer_contribution_paise" >= 0),
  CHECK ("shield_benefit_paise" >= 0),
  CHECK ("total_entitlement_paise" = "customer_contribution_paise" + "shield_benefit_paise")
);

CREATE TABLE "subscription_monthly_allocations" (
  "id" bigserial PRIMARY KEY,
  "subscription_id" bigint NOT NULL REFERENCES "membership_subscriptions"("id") ON DELETE CASCADE,
  "month_start" date NOT NULL,
  "allocation_paise" bigint NOT NULL,
  "carry_forward_paise" bigint NOT NULL DEFAULT 0,
  "used_paise" bigint NOT NULL DEFAULT 0,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  UNIQUE ("subscription_id", "month_start"),
  CHECK ("allocation_paise" >= 0),
  CHECK ("carry_forward_paise" >= 0),
  CHECK ("used_paise" >= 0)
);

CREATE TABLE "activity_events" (
  "id" bigserial PRIMARY KEY,
  "uuid" uuid NOT NULL UNIQUE,
  "customer_id" bigint REFERENCES "customers"("id"),
  "activity_type" varchar(80) NOT NULL,
  "related_entity_type" varchar(100),
  "related_entity_id" bigint,
  "business_id" bigint REFERENCES "businesses"("id"),
  "provider_id" bigint REFERENCES "service_providers"("id"),
  "agent_user_id" bigint REFERENCES "users"("id"),
  "crm_user_id" bigint REFERENCES "users"("id"),
  "status" varchar(50) NOT NULL DEFAULT 'PENDING',
  "description" text NOT NULL,
  "created_by" bigint REFERENCES "users"("id"),
  "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE "commission_events" (
  "id" bigserial PRIMARY KEY,
  "uuid" uuid NOT NULL UNIQUE,
  "customer_id" bigint REFERENCES "customers"("id"),
  "source_type" varchar(80) NOT NULL,
  "originating_level" varchar(30) NOT NULL,
  "pool_paise" bigint NOT NULL,
  "status" varchar(50) NOT NULL DEFAULT 'PENDING',
  "created_by" bigint REFERENCES "users"("id"),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  CHECK ("pool_paise" >= 0)
);

CREATE TABLE "commission_allocations" (
  "id" bigserial PRIMARY KEY,
  "commission_event_id" bigint NOT NULL REFERENCES "commission_events"("id") ON DELETE CASCADE,
  "recipient_level" varchar(30) NOT NULL,
  "recipient_user_id" bigint REFERENCES "users"("id"),
  "percentage" numeric(5,2) NOT NULL,
  "amount_paise" bigint NOT NULL,
  "status" varchar(50) NOT NULL DEFAULT 'PENDING',
  "created_at" timestamptz NOT NULL DEFAULT now(),
  CHECK ("percentage" >= 0),
  CHECK ("amount_paise" >= 0)
);

CREATE INDEX "idx_customer_import_batches_business" ON "customer_import_batches" ("business_id", "status");
CREATE INDEX "idx_customer_import_rows_mobile" ON "customer_import_rows" ("mobile");
CREATE INDEX "idx_card_requests_customer" ON "card_requests" ("customer_id", "status");
CREATE INDEX "idx_subscription_allocations_month" ON "subscription_monthly_allocations" ("month_start");
CREATE INDEX "idx_activity_events_customer" ON "activity_events" ("customer_id", "created_at");
CREATE INDEX "idx_activity_events_type" ON "activity_events" ("activity_type", "created_at");
CREATE INDEX "idx_commission_events_status" ON "commission_events" ("status", "created_at");
