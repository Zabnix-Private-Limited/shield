# FINAL DEFINITION OF DONE

The SHIELD Customer App redesign is complete only when all applicable gates below pass.

## Inventory

- Every current customer route is present in the matrix.
- Every required customer task in the matrix is implemented or has an explicitly approved, documented exclusion.
- Additional customer routes discovered in the repository were added to the matrix.
- No old inline/legacy view remains accidentally reachable with inconsistent UI unless explicitly documented during migration.

## Visual consistency

- Every page uses the approved design system.
- Home has the Operations carousel immediately below the header.
- Header shows Cash Wallet amount, Reward Points and notification state without overflow.
- Duplicate lower Dashboard wallet/reward cards remain removed.
- Profile and Settings are fully redesigned, not merely linked.
- No old generated poster/contact-sheet style leaked into the app.
- No screenshots are used as full-page backgrounds.
- Screenshot-QA evidence exists for every major route.

## Functionality

- Every visible button, tab, chip, row and navigation entry works or is truthfully disabled with an explanation.
- Authentication uses the real Firebase/customer session flow.
- Membership/card values are database-backed.
- Wallet and Reward Points use separate ledgers.
- SHIELD Benefit is not rendered as Cash Wallet.
- Services/providers are API-backed.
- Booking/visit mutations work without duplicates.
- Documents/prescriptions use secure authorized storage access.
- Products are database/API-backed.
- Cart/order totals are server-authoritative.
- Referral lifecycle is preserved.
- Notifications and activity use authenticated data.
- Profile/family/settings/support changes persist where supported.

## States

- Loading, populated, valid-zero, empty, error, retry, offline and session-expired behavior are implemented for every applicable page.
- Mutations have progress, success and failure states.
- No API failure is silently displayed as zero/empty.

## Security

- Negative cross-customer tests pass for all sensitive domains.
- No raw storage URLs or secrets are exposed.
- Customer-scoped caches clear on logout/account switch.
- Backend authorization remains authoritative.
- Financial/document/card/order/consent mutations are auditable.

## Responsive and accessibility

- Supported mobile widths have no overflow.
- Tablet and web are usable and visually consistent.
- Text scaling does not break critical layouts.
- Touch targets, focus order, semantics and contrast are acceptable.
- Keyboard and sticky actions do not hide form content.

## Engineering quality

- No parallel customer shell.
- No duplicated near-identical component systems.
- No business logic inside presentation widgets.
- No static customer financial/order/document data.
- No uncontrolled Prisma db push or destructive migration.
- Flutter formatting and analysis pass.
- Relevant Flutter tests pass.
- Backend compile/tests pass for changed contracts.
- Prisma validation passes for schema changes.
- `git diff --check` passes.

## Documentation and delivery

- Audit, route inventory, API bindings, component guide, state matrix, visual QA, accessibility checklist, backend gaps and implementation status are current.
- `log.md` has an append-only final entry.
- Final report lists files, routes, APIs, schema changes, tests, screenshots and approved remaining business decisions.
- The full customer walkthrough succeeds from authentication through Home, membership/card, wallet/rewards, services/booking, documents, shop/order, referrals, notifications, profile and settings.

Do not claim complete until every applicable gate is evidenced.
