-- SHIELD Pharmacy Portal — Verification Script for Additive Hardening Migration
-- Script Name: 20260819_pharmacy_advanced_fulfillment_hardening_verify.sql

SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND (
    (table_name = 'purchase_item_fulfillments' AND column_name IN ('rejected_quantity', 'decision_reason', 'decision_actor_id', 'authoritative_price')) OR
    (table_name = 'purchase_item_substitutions' AND column_name IN ('substitute_quantity', 'proposed_by', 'customer_confirmation_status')) OR
    (table_name = 'order_customer_confirmations' AND column_name IN ('purchase_item_id', 'requested_by')) OR
    (table_name = 'order_pharmacist_notes' AND column_name = 'visibility') OR
    (table_name = 'order_invoices' AND column_name IN ('mime_type', 'file_size', 'uploaded_by'))
  );
