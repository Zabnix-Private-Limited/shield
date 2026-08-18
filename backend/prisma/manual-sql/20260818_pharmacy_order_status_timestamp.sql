-- Forward SQL: Add order_status_updated_at column to purchases table
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS order_status_updated_at TIMESTAMPTZ(6) NULL;
