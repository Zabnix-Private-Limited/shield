# Customer membership activation audit

## Model and side effects

`customers.status`, `memberships.status`, and `shield_cards.status` are varchar lifecycle values. Current creation uses customer `PENDING` and membership `INACTIVE`; approval sets customer/membership/card `ACTIVE`, writes `customer_status_history`, and verifies a pending referral. The schema also has wallet, ledger, subscription, monthly-allocation, notification, and audit tables. Registration—not approval—currently creates wallets/credit accounts and optional configured preloads; activation must not create financial allocations or duplicate memberships.

`CustomerService.activate` is a reactivation helper and is unsafe for a broad pending batch because it has no eligibility gate, audit log, membership-plan check, or referral verification. The controlled command therefore handles only already-created memberships and never creates a card, wallet, subscription, ledger entry, or referral reward.

## Eligibility

Eligible rows are non-deleted customers in `PENDING`, `WAITING`, or `PENDING_APPROVAL` with nonblank first name, last name, mobile, agent code, an existing membership number, and an `ACTIVE` membership type. Suspended, archived, blocked, fraud-flagged, active, deleted, incomplete, missing-membership, or non-customer records are excluded. Staff cannot match because the command starts at `customers`, not `users`.

## Counts and recommendation

No live counts were queried: `backend/.env` points to an unverified remote Neon database. This is correctly treated as production-like. Run the supplied command only after independently proving a non-production target and explicitly setting `SHIELD_DATA_FIX_ENV=non-production`.

The command defaults to dry-run and performs per-customer transactions on apply. It updates customer/membership and an existing card, writes status history plus `audit_logs`, and is rerunnable because no longer-eligible ACTIVE rows are selected. Referral verification is intentionally not performed: it is outside the transaction in the existing service and no verified batch behavior exists; activation should not alter reward qualification.
