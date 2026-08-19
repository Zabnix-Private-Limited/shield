-- FORWARD EXECUTABLE SQL: Pharmacy Provider Settings Table
-- DO NOT EXECUTE ON LIVE DB AUTOMATICALLY (DATABASE_OWNER_ACTION_REQUIRED = YES)
-- DO NOT EDIT current_schema.md

CREATE TABLE IF NOT EXISTS "pharmacy_provider_settings" (
    "id" BIGSERIAL PRIMARY KEY,
    "uuid" UUID NOT NULL DEFAULT gen_random_uuid(),
    "provider_id" BIGINT NOT NULL UNIQUE,
    "settings" JSONB NOT NULL DEFAULT '{}'::jsonb,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "fk_pharmacy_provider_settings_provider" FOREIGN KEY ("provider_id") REFERENCES "service_providers"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "idx_pharmacy_provider_settings_provider_id" ON "pharmacy_provider_settings"("provider_id");
