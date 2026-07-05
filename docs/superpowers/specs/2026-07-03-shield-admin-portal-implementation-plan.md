# SHIELD Admin Portal Implementation Plan

Date: 2026-07-03
Linked spec: `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`
Linked architecture: `docs/superpowers/specs/2026-07-04-shield-admin-engine-architecture.md`
Linked platform SDK: `docs/superpowers/specs/2026-07-04-shield-platform-sdk-architecture.md`

## Goal

Implement the Admin Portal as a backend-ready admin engine inside the existing SHIELD portal shell while preserving the current agent, provider, and customer portal behavior.

## Phase Breakdown

### Phase 1: Shell and navigation

- expand `super-admin` route metadata to the new grouped sitemap
- update route support in `PortalResolver`
- route all super-admin content through one dedicated admin workspace module
- update super-admin sidebar groups to match the new IA

### Phase 2: Shared admin frontend system

- add reusable admin workspace file structure
- define shared admin surfaces for:
  - compact console headers
  - toolbars
  - split workspaces
  - status badges
  - tables
  - form sections
  - empty and error panels
  - backend-ready configuration and log surfaces

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

### Phase 3B: Super Admin v2 reset

- stop extending showcase-style module screens
- remove dummy operational data from governance and system modules
- add one compact admin engine pattern for:
  - title and actions
  - search
  - tabs
  - filters
  - split content panels
  - table-first operational surfaces
  - empty states that point to missing backend contracts
- migrate Settings, Notifications, Audit, and Platform first because they are the strongest examples of page-local placeholder design
- treat all future admin modules as backend-driven workspaces rather than bespoke mock screens

### Phase 3B.1: Core Admin Engine Framework

- Current status as of 2026-07-04:
  - shared engine primitives, navigation registry, capability registry, command bus, event bus, schema definitions, and action pipeline exist in code with focused tests
  - the live `AdminPortalWorkspace` now boots through a shared platform runtime that registers workspace, navigation, schema, and capability metadata before rendering a workspace
  - the old hardcoded builder switch has been replaced by runtime-backed registrations, but backend-owned section metadata and real repository implementations are still pending
- build the shared admin platform primitives before more module-specific API work
- treat this phase as the first implementation step of the wider SHIELD Platform SDK, not just a local admin refactor
- add reusable engine surfaces for:
  - admin layout
  - page header
  - toolbar
  - search
  - filters
  - tabs
  - sidebar
  - drawer
  - dialog
  - table
  - detail panel
  - form renderer
  - metric cards
  - status badges
  - pagination
  - bulk actions
  - permissions
- add explicit subsystem boundaries for:
  - layout engine
  - workspace engine
  - data engine
  - action engine
  - form engine
  - permission engine
- add design token ownership for:
  - spacing
  - elevation
  - radius
  - typography
  - icons
  - table density
  - toolbar heights
  - drawer widths
  - breakpoints
  - animations
  - loading states
- build toward shared package ownership for:
  - design system
  - engine
  - permissions
  - api
  - realtime
  - forms
  - tables
  - actions
  - workspace
  - navigation
  - search
  - upload
  - charts
  - notifications
  - logging
- establish the direction for shared domains so cross-app business logic is not reimplemented separately in admin, CRM, agent, provider, and customer modules

### Phase 3B.2: Workspace Contract

- define the metadata contract that tells the admin engine what to render instead of hardcoding page behavior
- design definitions for:
  - workspace id
  - datasource id
  - layout mode
  - columns
  - forms
  - filters
  - tabs
  - actions
  - permissions
  - empty states
  - supported view modes
- keep the engine responsible for rendering behavior while workspace definitions describe business-owned structure
- add registry-driven ownership so the sidebar and route resolver read from workspace registry metadata instead of hardcoding module knowledge
- prepare for parallel registries beyond workspace:
  - navigation registry
  - route registry
  - action registry
  - permission registry
  - search registry
  - capability registry

### Phase 3B.3: Backend Contracts

- define DTOs and REST contracts before expanding frontend CRUD
- require each migrated admin workspace to have:
  - repository contract
  - service contract
  - controller endpoints
  - DTOs
  - permission handling
  - audit integration
- standardize controller response envelopes for admin workspaces:
  - `success`
  - `message`
  - `data`
  - `meta`
  - `filters`
  - `permissions`
  - `links`
- prefer event-driven mutation follow-up over isolated UI callbacks so audit, refresh, notifications, and cache invalidation can compose cleanly
- introduce foundational platform services early:
  - feature flags
  - configuration service
  - versioned events
  - ID generation
  - policy evaluation
  - platform test harness
- introduce command-bus and event-bus expectations early so widgets do not become direct service callers as the platform grows

### Phase 3B.4: Module Migration

- migrate modules only after the shared framework and contracts are in place
- recommended first order:
  - Settings
  - Platform
  - Audit
  - Notifications

### Phase 3C: Operational Module Expansion

- Customers
- Agents
- CRM
- Wallet
- Providers
- Documents

### Phase 3D: Production Hardening

- performance
- caching
- observability
- testing
- production hardening

### Phase 4: Shared Platform Services

- global search and command palette
- workflow engine
- background job framework
- shared media and document service
- AI capability package
- integration framework and connectors

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
   - structured empty and error messaging
   - dense enterprise layouts
4. Do not use dummy business data or fake operational telemetry in production-facing admin modules.
5. When a backend contract is not ready, prefer a table or form shell with an explicit empty state over placeholder metrics, feed items, or hero cards.

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
- reject dummy operational data in governance and system modules

### Risk: future backend mismatch

Mitigation:

- align modules and language to existing backend domains and schema ownership docs

## Completion Criteria

- the docs and app reflect the same Admin Portal IA
- super-admin navigation is grouped and complete
- all top-level modules are rendered in the app
- `admin_portal_workspace.dart` contains composition only
- shared admin primitives live under `features/admin/shared`
- governance modules do not rely on fake activity feeds, fake uptime metrics, or navigation-only cards
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

## Phase 3A: Authentication Hardening

- freeze the now-working internal Google login architecture before expanding more admin modules
- keep authentication changes limited to hardening, cleanup, and regression prevention unless a fresh auth bug appears
- maintain `docs/superpowers/specs/2026-07-04-authentication-hardening-checklist.md` as the release contract for:
  - Google login
  - session restore
  - refresh persistence
  - logout and relogin
  - multi-tab behavior
  - role-based routing
  - deep-link survival
- prefer concise production observability:
  - keep milestone auth logs
  - avoid noisy per-route and per-resolver tracing
- treat Firebase popup COOP warnings as documented non-blocking behavior unless hosting/header changes provide a verified elimination path
- keep Firebase web startup clean by avoiding unnecessary global reCAPTCHA warmup when the active auth flow does not require it

## Phase 3B Activation

- Settings, Notifications, Audit, and Platform must move from landing-page-style placeholders to backend-ready console workspaces before more governance feature expansion
- use compact page headers and toolbar-first layouts for system and governance modules
- prefer tables, forms, filters, and empty states over hero banners, fake activity feeds, and showcase cards
- treat backend contracts as the source of truth for:
  - settings sections
  - notification tabs and actions
  - audit columns and filters
  - platform dependency labels and health semantics
- treat the next milestone as admin-engine infrastructure, not page delivery
