-- SHIELD Pharmacy Portal — Verification Script for Normalized Advanced Fulfillment Tables
-- Script Name: 20260819_pharmacy_advanced_fulfillment_normalized_verify.sql

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'purchase_item_fulfillments',
    'purchase_item_substitutions',
    'order_chronic_refills',
    'order_pharmacist_notes',
    'order_invoices',
    'order_customer_confirmations'
  );
