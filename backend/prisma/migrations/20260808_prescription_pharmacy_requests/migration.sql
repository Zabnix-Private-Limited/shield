-- Additive prescription-to-pharmacy request workflow. Apply through the
-- repository migration process only; this migration is intentionally not run
-- by application builds or deployments.
CREATE TABLE prescription_pharmacy_requests (
  id bigserial PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  customer_id bigint NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  document_id bigint NOT NULL REFERENCES documents(id) ON DELETE RESTRICT,
  provider_id bigint NOT NULL REFERENCES service_providers(id) ON DELETE RESTRICT,
  status varchar(50) NOT NULL DEFAULT 'SUBMITTED',
  customer_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_prescription_pharmacy_requests_customer
  ON prescription_pharmacy_requests(customer_id, created_at DESC);
CREATE INDEX idx_prescription_pharmacy_requests_provider_status
  ON prescription_pharmacy_requests(provider_id, status);
CREATE INDEX idx_prescription_pharmacy_requests_document
  ON prescription_pharmacy_requests(document_id);
CREATE UNIQUE INDEX uq_prescription_pharmacy_requests_open
  ON prescription_pharmacy_requests(document_id, provider_id)
  WHERE status = 'SUBMITTED';
