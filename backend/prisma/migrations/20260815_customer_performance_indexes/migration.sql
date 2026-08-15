-- Customer dashboard and portal list projections.
-- Apply only through the approved database release process.

CREATE INDEX "idx_appointments_customer_date"
  ON "appointments" ("customer_id", "appointment_date" DESC);

CREATE INDEX "idx_appointments_customer_status"
  ON "appointments" ("customer_id", "status");

CREATE INDEX "idx_documents_customer_created"
  ON "documents" ("customer_id", "created_at" DESC);

CREATE INDEX "idx_notifications_customer_status"
  ON "notifications" ("customer_id", "status");

CREATE INDEX "idx_notifications_customer_sent"
  ON "notifications" ("customer_id", "sent_at" DESC);
