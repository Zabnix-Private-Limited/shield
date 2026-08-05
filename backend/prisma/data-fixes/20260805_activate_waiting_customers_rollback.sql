-- No automatic rollback: activation may verify a referral and drive external operations.
-- Use the audit_logs rows produced by this batch and a staff-approved, customer-specific reversal.
SELECT id, entity_id, old_data, new_data, created_at
FROM audit_logs WHERE action = 'CUSTOMER_MEMBERSHIP_BATCH_ACTIVATED' ORDER BY id DESC;
