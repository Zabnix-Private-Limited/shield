# Autonomous Agent Implementation Instructions — Pharmacy Design System

## Mission

Implement the SHIELD Pharmacy portal end-to-end using the design system in this directory as the canonical visual/interaction contract.

Do not implement the supplied screenshots as disconnected pages. Build a reusable responsive system.

## Mandatory reading order

1. `00_READ_FIRST.md`
2. `01_VISUAL_FOUNDATIONS.md`
3. `02_DESIGN_TOKENS.md`
4. `03_TYPOGRAPHY_ICONOGRAPHY.md`
5. `04_LAYOUT_RESPONSIVE_SYSTEM.md`
6. `05_COMPONENT_LIBRARY.md`
7. `06_NAVIGATION_APP_SHELL.md`
8. screen-specific files
9. backend/data requirements
10. acceptance criteria
11. every image in `references/`

## Design rule

The reference images are the canonical Pharmacy visual family.

DO NOT:
- create a different design for each screen
- invent a new color theme midway
- use arbitrary component radii
- simplify final UI back to basic unstyled lists
- leave dashboard rows/card actions partially clickable
- make desktop perfect while APK/mobile is unusable

## Implementation phases

### Phase A — Foundations
- tokens
- typography
- responsive helpers
- common Pharmacy primitives

### Phase B — Shell/navigation
- canonical Pharmacy routes
- sidebar
- mobile bottom nav
- header/user actions

### Phase C — Dashboard redesign
- clickable KPI cards
- clickable recent rows
- View All actions
- polished states

### Phase D — Orders workspace
- queue
- advanced order detail
- per-item decisions
- low stock
- no stock
- partial fulfillment
- substitution
- chronic order
- notes
- pricing/billing
- invoice
- customer confirmation
- partial dispatch

Only enable actions supported by real backend contracts.

### Phase E — Payments / Payment Details
Preserve financial integrity and secure QR delivery.

### Phase F — History

### Phase G — Profile / Settings

### Phase H — compact/tablet adaptation
Every screen must have deliberate mobile/tablet composition.

## Backend discipline

Before new business features:
- inspect schema
- inspect existing API
- extend rather than duplicate
- identify DB needs

Never modify `current_schema.md`.

If DB changes are needed:
- create owner-review SQL under approved repo location
- stop for owner execution
- verify read-only afterward

## Push notifications

Every successful user-impacting mutation should invoke the appropriate backend notification event when the platform supports the channel.

Do not send notifications before a transaction succeeds.

## Cross-portal discipline

Current package defines Pharmacy implementation.

If a Pharmacy action requires Customer/other portal UI work outside current approved scope:
- implement required shared/backend dependency if strictly necessary
- record consuming portal UI work in root `todo.md`
- do not silently redesign another portal

## Web/APK

All Pharmacy features must have a valid interaction model for:
- desktop web
- tablet
- mobile APK

No web-only file or hover assumptions.

## Owner testing mode

When the owner says they will perform all tests:
- do not run browser automation
- do not run broad test suites unless asked
- implement source changes
- hand off exact changed files and manual verification targets
- do not claim runtime PASS

## Completion language

Do not say `PHARMACY_MVP_COMPLETE = YES` merely because the screenshots look similar.

Completion requires:
- real workflows
- real backend data
- web usable
- APK/mobile usable
- owner UAT acceptance
