# Backend & Data Requirements for the Design

This file defines backend capabilities implied by the Pharmacy UI. It is not permission to modify the database automatically.

## Database governance

- Never modify `current_schema.md` automatically.
- Read it as owner-maintained schema truth.
- If schema changes are required, generate forward SQL for owner execution.
- Verification SQL must be read-only.
- Do not run Prisma migrate/db push against owner DB unless explicitly authorized.

## Dashboard

Need:
- active order bucket counts
- pending payment count
- approved today count + amount
- completed today count + amount
- recent orders
- recent payment requests

Scope:
- active Pharmacy provider only
- no cross-provider leakage

## Order detail

Need:
- order
- customer identity
- items
- requested qty
- price
- source
- fulfillment
- status
- status timestamp
- payment state
- notes
- address snapshot where relevant

## New fulfillment capabilities

The advanced UI may require persistent data/contracts for:

### Per-item decision
- requested qty
- approved/fulfill qty
- rejected qty
- decision status
- rejection reason
- substitution relation
- price used
- decision timestamp/user

### Partial fulfillment
Order aggregate state derived from item decisions.

### Substitute
- original item
- substitute item/product
- proposed price
- customer confirmation state
- reason
- confirmed timestamp

### Chronic order
- chronic flag
- optional repeat/refill cadence
- note
- tagged by/at

### Invoice
- private storage path
- file name
- MIME type
- uploaded by/at
- sent to customer at
- order linkage

### Notes
- author
- visibility
- text
- timestamp

Do not cram long-lived structured workflow state into JSON merely to avoid proper schema design unless existing architecture intentionally uses snapshots.

## Status mutations

Requirements:
- explicit legal transition matrix
- same-status no-op
- status timestamp changes only on real transition
- terminal cannot reopen without explicit workflow
- partial fulfillment states explicit
- concurrency-safe where two staff may act

## Payments

Preserve:
- atomic approval
- only APPROVED credits wallet
- exactly-once ledger behavior
- rejection no credit
- provider scope

## Notification events

Backend should emit/persist or dispatch events from successful state mutations, not from button clicks before transaction success.

## File security

Every private document/QR:
- authorization checked
- provider/customer scope checked
- safe content type
- no arbitrary storage path access
- no public bucket workaround

## API evolution

When adding fields/actions:
- version/extend without breaking existing APK clients
- prefer additive payload changes
- handle old client compatibility
- coordinate web and APK release behavior
