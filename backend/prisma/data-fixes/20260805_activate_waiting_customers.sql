-- DRY-RUN/REVIEW ONLY: use the controlled TypeScript command for application.
-- This query is intentionally limited to customer rows with an existing active-plan membership.
BEGIN;
WITH eligible AS (
  SELECT c.id FROM customers c
  JOIN memberships m ON m.customer_id = c.id
  JOIN membership_types mt ON mt.id = m.membership_type_id AND mt.status = 'ACTIVE'
  WHERE c.deleted_at IS NULL
    AND c.status IN ('PENDING', 'WAITING', 'PENDING_APPROVAL')
    AND NULLIF(BTRIM(c.first_name), '') IS NOT NULL
    AND NULLIF(BTRIM(c.last_name), '') IS NOT NULL
    AND NULLIF(BTRIM(c.mobile), '') IS NOT NULL
    AND NULLIF(BTRIM(c.agent_code), '') IS NOT NULL
    AND NULLIF(BTRIM(m.membership_number), '') IS NOT NULL
)
SELECT count(*) AS eligible_customers FROM eligible;
-- No UPDATE is deliberately included: membership activation requires status history and audit records.
ROLLBACK;
