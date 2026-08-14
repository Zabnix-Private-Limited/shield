-- Phase-1 customer support and CRM complaint lifecycle.  This migration is
-- additive: existing complaint rows keep their current status and history.

ALTER TABLE "complaints"
  ADD COLUMN "assigned_to_user_id" BIGINT,
  ADD COLUMN "assigned_at" TIMESTAMPTZ(6),
  ADD COLUMN "resolved_by_user_id" BIGINT,
  ADD COLUMN "resolved_at" TIMESTAMPTZ(6),
  ADD COLUMN "resolution_note" TEXT,
  ADD COLUMN "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE TABLE "complaint_lifecycle_events" (
  "id" BIGSERIAL PRIMARY KEY,
  "uuid" UUID NOT NULL,
  "complaint_id" BIGINT NOT NULL,
  "event_type" VARCHAR(50) NOT NULL,
  "actor_user_id" BIGINT,
  "from_assignee_user_id" BIGINT,
  "to_assignee_user_id" BIGINT,
  "note" TEXT,
  "customer_visible" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "complaint_lifecycle_events_uuid_key" UNIQUE ("uuid"),
  CONSTRAINT "complaint_lifecycle_events_complaint_id_fkey"
    FOREIGN KEY ("complaint_id") REFERENCES "complaints"("id") ON DELETE CASCADE,
  CONSTRAINT "complaint_lifecycle_events_actor_user_id_fkey"
    FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE SET NULL
);

ALTER TABLE "complaints"
  ADD CONSTRAINT "complaints_assigned_to_user_id_fkey"
    FOREIGN KEY ("assigned_to_user_id") REFERENCES "users"("id") ON DELETE SET NULL,
  ADD CONSTRAINT "complaints_resolved_by_user_id_fkey"
    FOREIGN KEY ("resolved_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL;

CREATE INDEX "idx_complaints_customer_status" ON "complaints" ("customer_id", "status");
CREATE INDEX "idx_complaints_assignee_status" ON "complaints" ("assigned_to_user_id", "status");
CREATE INDEX "idx_complaint_lifecycle_events_complaint_created"
  ON "complaint_lifecycle_events" ("complaint_id", "created_at");
CREATE INDEX "idx_complaint_lifecycle_events_visible_created"
  ON "complaint_lifecycle_events" ("customer_visible", "created_at");
