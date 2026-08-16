-- Additive column request_kind for explicit CardRequest discriminator (DIGITAL vs PHYSICAL)
ALTER TABLE "card_requests" ADD COLUMN IF NOT EXISTS "request_kind" VARCHAR(50) NOT NULL DEFAULT 'PHYSICAL';

-- Backfill existing remarks-based records if any
UPDATE "card_requests" SET "request_kind" = 'DIGITAL' WHERE "remarks" LIKE '%DIGITAL%';

-- Add index for card request kind lookup
CREATE INDEX IF NOT EXISTS "idx_card_requests_kind" ON "card_requests"("customer_id", "request_kind");
