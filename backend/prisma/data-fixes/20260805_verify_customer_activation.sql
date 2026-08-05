SELECT c.status AS customer_status, m.status AS membership_status, count(*)
FROM customers c LEFT JOIN memberships m ON m.customer_id = c.id
WHERE c.deleted_at IS NULL GROUP BY 1, 2 ORDER BY 1, 2;

SELECT count(*) AS batch_audits FROM audit_logs
WHERE action = 'CUSTOMER_MEMBERSHIP_BATCH_ACTIVATED';
