-- Customer-account capabilities. Deliberately additive; apply through the
-- repository migration workflow, never through an automatic schema push.
ALTER TABLE customer_contacts
  ADD COLUMN IF NOT EXISTS contact_type varchar(30) NOT NULL DEFAULT 'ALTERNATIVE',
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

CREATE TABLE IF NOT EXISTS customer_addresses (
  id bigserial PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  customer_id bigint NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  label varchar(50) NOT NULL DEFAULT 'HOME',
  address_line1 text NOT NULL,
  address_line2 text,
  city varchar(100), district varchar(100), state varchar(100), pincode varchar(20),
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), deleted_at timestamptz
);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer ON customer_addresses(customer_id, deleted_at);

CREATE TABLE IF NOT EXISTS customer_dependents (
  id bigserial PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  customer_id bigint NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  first_name varchar(255) NOT NULL, last_name varchar(255), relation varchar(100) NOT NULL,
  dob date, gender varchar(20),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), deleted_at timestamptz
);
CREATE INDEX IF NOT EXISTS idx_customer_dependents_customer ON customer_dependents(customer_id, deleted_at);

CREATE TABLE IF NOT EXISTS customer_preferences (
  id bigserial PRIMARY KEY,
  uuid uuid NOT NULL UNIQUE,
  customer_id bigint NOT NULL UNIQUE REFERENCES customers(id) ON DELETE CASCADE,
  notification_preferences jsonb,
  language varchar(20), theme varchar(30), preferred_provider_id bigint,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
