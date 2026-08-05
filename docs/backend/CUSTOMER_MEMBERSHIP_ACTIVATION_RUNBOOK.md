# Waiting customer activation runbook

Purpose: activate only verified waiting customer memberships in a non-production database.

1. Confirm the database is non-production; never rely only on the hostname.
2. Set `SHIELD_DATA_FIX_ENV=non-production` and run `npm run customers:activate-waiting -- --dry-run` from `backend`.
3. Review only aggregate counts; the command intentionally prints no PII.
4. Run `npm run customers:activate-waiting -- --apply`, then `psql -f prisma/data-fixes/20260805_verify_customer_activation.sql`.

The command is transaction-safe per customer and preserves active rows. No automatic rollback exists because a lifecycle reversal needs staff approval. Use `20260805_activate_waiting_customers_rollback.sql` to identify audit records and reverse customers individually.
