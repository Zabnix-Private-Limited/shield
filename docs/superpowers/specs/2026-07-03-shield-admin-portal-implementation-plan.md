# SHIELD Admin Portal Implementation Plan

Date: 2026-07-03
Linked spec: `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`

## Goal

Implement the Admin Portal as a complete V1 frontend workspace inside the existing SHIELD portal shell while preserving the current agent, provider, and customer portal behavior.

## Phase Breakdown

### Phase 1: Shell and navigation

- expand `super-admin` route metadata to the new grouped sitemap
- update route support in `PortalResolver`
- route all super-admin content through one dedicated admin workspace module
- update super-admin sidebar groups to match the new IA

### Phase 2: Shared admin frontend system

- add reusable admin workspace file structure
- define shared admin surfaces for:
  - module headers
  - stat cards
  - command bars
  - split workspaces
  - status badges
  - activity feeds
  - timelines
  - tables
  - empty and health panels

### Phase 2A: Admin platform extraction

- move shared admin primitives into `frontend/lib/features/admin/shared/`
- keep `admin_portal_workspace.dart` as composition-only routing and module assembly
- standardize module packages under:
  - `dashboard`
  - `customers`
  - `agents`
  - `crm`
  - `providers`
  - `visits`
  - `documents`
  - `memberships`
  - `wallet`
  - `rewards`
  - `referrals`
  - `reports`
  - `organization`
  - `audit`
  - `settings`
- introduce reusable controller ownership for:
  - navigation
  - filters
  - search
  - selection
  - workspace state
  - permissions
- treat `AdminDataTable<T>` and shared workspace layouts as the default enterprise pattern instead of module-local table or panel implementations

### Phase 3: Core command-center modules

- dashboard
- customers
- agents
- providers
- documents
- visits

### Phase 4: Commercial and growth modules

- memberships
- wallet
- rewards
- referral network
- services
- availability

### Phase 5: Organization and governance modules

- branches
- employees
- roles
- reports
- insights
- audit
- notifications
- settings
- platform

## Implementation Strategy

1. Keep the new admin implementation isolated in `frontend/lib/features/admin/...`.
2. Minimize edits to the large shared `portal_shell.dart` file to:
   - import the admin workspace
   - route `super-admin` content into the admin workspace
   - update grouped nav metadata only
3. Treat the first implementation pass as a complete design-realization build:
   - strong visual hierarchy
   - consistent semantic colors
   - structured empty and health messaging
   - timeline-first entity workspaces
4. Use realistic seed content and enterprise layouts so later backend wiring becomes binding work instead of redesign work.

## File Plan

### New docs

- `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-implementation-plan.md`

### New frontend module

- `frontend/lib/features/admin/presentation/screens/admin_portal_workspace.dart`
- `frontend/lib/features/admin/shared/...`
- `frontend/lib/features/admin/*/presentation/screens/...`

### Existing frontend files to update

- `frontend/lib/features/portal/presentation/portal_role_data.dart`
- `frontend/lib/features/portal/presentation/screens/portal_shell.dart`
- `frontend/lib/shared/services/portal_resolver.dart`

## Validation Plan

### Focused validation

- `cd frontend && flutter analyze --no-pub lib/features/admin/presentation/screens/admin_portal_workspace.dart lib/features/portal/presentation/portal_role_data.dart lib/features/portal/presentation/screens/portal_shell.dart lib/shared/services/portal_resolver.dart`

### Broad frontend validation

- `cd frontend && flutter analyze --no-pub`
- `cd frontend && flutter test`

### Backend safety validation

- `cd backend && npm run build`

## Risks

### Risk: portal shell regression

Mitigation:

- keep shell edits minimal
- preserve existing customer, agent, and provider routing paths

### Risk: design inconsistency

Mitigation:

- centralize admin UI patterns in `features/admin/shared`

### Risk: half-refactored module ownership

Mitigation:

- keep workspace routing intact while extracting modules one by one
- allow only shared exports and module entrypoints to be imported by the workspace
- avoid leaving business UI inside `admin_portal_workspace.dart`

### Risk: giant one-off mockup instead of usable app structure

Mitigation:

- build each module as a reusable workspace pattern instead of static artboards

### Risk: future backend mismatch

Mitigation:

- align modules and language to existing backend domains and schema ownership docs

## Completion Criteria

- the docs and app reflect the same Admin Portal IA
- super-admin navigation is grouped and complete
- all top-level modules are rendered in the app
- `admin_portal_workspace.dart` contains composition only
- shared admin primitives live under `features/admin/shared`
- no existing portal experiences are broken

## Phase 3 Activation

- the Admin shell, grouped IA, routing, portal integration, and workspace composition are now frozen infrastructure
- Phase 3 work should move vertically one module at a time instead of horizontally polishing placeholder surfaces
- the first live slice in this phase is the Admin Dashboard using:
  - `api`
  - `data`
  - `domain`
  - `application`
  - `presentation/providers`
- future module work should follow the same feature contract documented in `docs/superpowers/specs/2026-07-04-shield-admin-platform-roadmap-phase-3.md`
