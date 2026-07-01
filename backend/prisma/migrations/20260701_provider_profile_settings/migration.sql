CREATE TABLE "provider_profiles" (
  "id" BIGSERIAL PRIMARY KEY,
  "uuid" UUID NOT NULL,
  "user_id" BIGINT NOT NULL,
  "display_name" VARCHAR(255),
  "contact_email" VARCHAR(255),
  "contact_phone" VARCHAR(20),
  "profile_photo_storage_path" TEXT,
  "profile_photo_file_name" VARCHAR(255),
  "signature_storage_path" TEXT,
  "signature_file_name" VARCHAR(255),
  "qualifications" TEXT,
  "specialization" VARCHAR(255),
  "registration_details" JSONB,
  "consultation_availability" JSONB,
  "working_hours" JSONB,
  "notification_preferences" JSONB,
  "print_preferences" JSONB,
  "theme_preference" VARCHAR(50),
  "language_preference" VARCHAR(20),
  "default_printer" VARCHAR(255),
  "timezone" VARCHAR(100),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" TIMESTAMPTZ(6)
);

CREATE UNIQUE INDEX "provider_profiles_uuid_key"
  ON "provider_profiles" ("uuid");

CREATE UNIQUE INDEX "provider_profiles_user_id_key"
  ON "provider_profiles" ("user_id");

ALTER TABLE "provider_profiles"
  ADD CONSTRAINT "provider_profiles_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "provider_profile_branch_assignments" (
  "provider_profile_id" BIGINT NOT NULL,
  "business_id" BIGINT NOT NULL,
  "is_primary" BOOLEAN NOT NULL DEFAULT FALSE,
  "assigned_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("provider_profile_id", "business_id")
);

CREATE INDEX "idx_provider_profile_branch_business"
  ON "provider_profile_branch_assignments" ("business_id");

ALTER TABLE "provider_profile_branch_assignments"
  ADD CONSTRAINT "provider_profile_branch_assignments_profile_fkey"
  FOREIGN KEY ("provider_profile_id") REFERENCES "provider_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "provider_profile_branch_assignments"
  ADD CONSTRAINT "provider_profile_branch_assignments_business_fkey"
  FOREIGN KEY ("business_id") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
