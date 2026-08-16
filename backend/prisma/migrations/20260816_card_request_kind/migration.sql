-- Additive column request_kind for explicit CardRequest discriminator (DIGITAL vs PHYSICAL)
ALTER TABLE "card_requests" ADD COLUMN IF NOT EXISTS "request_kind" VARCHAR(50) NOT NULL DEFAULT 'PHYSICAL';

-- Enforce request_kind domain CHECK constraint
ALTER TABLE "card_requests" DROP CONSTRAINT IF EXISTS "chk_card_requests_kind";
ALTER TABLE "card_requests" ADD CONSTRAINT "chk_card_requests_kind" CHECK ("request_kind" IN ('DIGITAL', 'PHYSICAL'));

-- Backfill existing remarks-based records if any
UPDATE "card_requests" SET "request_kind" = 'DIGITAL' WHERE "remarks" LIKE '%DIGITAL%';

-- Add index for card request kind lookup
CREATE INDEX IF NOT EXISTS "idx_card_requests_kind" ON "card_requests"("customer_id", "request_kind");
