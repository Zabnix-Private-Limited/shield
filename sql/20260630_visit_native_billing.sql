ALTER TABLE "purchases"
ADD COLUMN "appointment_id" bigint,
ADD COLUMN "purchase_kind" varchar(50) DEFAULT 'GENERAL',
ADD COLUMN "payment_status" varchar(50) DEFAULT 'PENDING',
ADD COLUMN "payment_summary" jsonb,
ADD COLUMN "billing_snapshot" jsonb;

ALTER TABLE "purchase_items"
ADD COLUMN "item_type" varchar(50) DEFAULT 'MEDICINE',
ADD COLUMN "item_name" varchar(255),
ADD COLUMN "metadata" jsonb;

ALTER TABLE "purchases"
ADD CONSTRAINT "purchases_appointment_id_fkey"
FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "idx_purchases_appointment" ON "purchases" ("appointment_id");
CREATE INDEX "idx_purchases_kind" ON "purchases" ("purchase_kind");
CREATE INDEX "idx_purchases_payment_status" ON "purchases" ("payment_status");
