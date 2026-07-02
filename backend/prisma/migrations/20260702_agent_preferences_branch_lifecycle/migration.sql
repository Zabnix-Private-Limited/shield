CREATE TABLE "agent_preferences" (
  "id" BIGSERIAL PRIMARY KEY,
  "uuid" UUID NOT NULL,
  "user_id" BIGINT NOT NULL,
  "theme_preference" VARCHAR(50),
  "language_preference" VARCHAR(20),
  "timezone" VARCHAR(100),
  "availability" JSONB,
  "working_hours" JSONB,
  "working_area" JSONB,
  "emergency_contact" JSONB,
  "notification_preferences" JSONB,
  "dashboard_layout" JSONB,
  "profile_preferences" JSONB,
  "device_preferences" JSONB,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" TIMESTAMPTZ(6)
);

CREATE UNIQUE INDEX "agent_preferences_uuid_key"
  ON "agent_preferences" ("uuid");

CREATE UNIQUE INDEX "agent_preferences_user_id_key"
  ON "agent_preferences" ("user_id");

ALTER TABLE "agent_preferences"
  ADD CONSTRAINT "agent_preferences_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "agent_branch_assignments" (
  "id" BIGSERIAL PRIMARY KEY,
  "uuid" UUID NOT NULL,
  "user_id" BIGINT NOT NULL,
  "business_id" BIGINT NOT NULL,
  "status" VARCHAR(50) NOT NULL DEFAULT 'PENDING',
  "is_primary" BOOLEAN NOT NULL DEFAULT FALSE,
  "requested_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "approved_at" TIMESTAMPTZ(6),
  "transferred_at" TIMESTAMPTZ(6),
  "inactive_at" TIMESTAMPTZ(6),
  "notes" TEXT,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX "agent_branch_assignments_uuid_key"
  ON "agent_branch_assignments" ("uuid");

CREATE UNIQUE INDEX "agent_branch_assignments_user_business_key"
  ON "agent_branch_assignments" ("user_id", "business_id");

CREATE INDEX "idx_agent_branch_assignment_user"
  ON "agent_branch_assignments" ("user_id");

CREATE INDEX "idx_agent_branch_assignment_business"
  ON "agent_branch_assignments" ("business_id");

CREATE INDEX "idx_agent_branch_assignment_status"
  ON "agent_branch_assignments" ("status");

ALTER TABLE "agent_branch_assignments"
  ADD CONSTRAINT "agent_branch_assignments_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "agent_branch_assignments"
  ADD CONSTRAINT "agent_branch_assignments_business_id_fkey"
  FOREIGN KEY ("business_id") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
