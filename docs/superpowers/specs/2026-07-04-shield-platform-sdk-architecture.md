# SHIELD Platform SDK Architecture

Date: 2026-07-04
Status: Active platform architecture spec
Linked docs:
- `docs/superpowers/specs/2026-07-04-shield-admin-engine-architecture.md`
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-implementation-plan.md`
- `docs/superpowers/specs/2026-07-04-shield-admin-platform-roadmap-phase-3.md`

## Purpose

This document defines the next architectural boundary for SHIELD: the admin foundation should evolve into a reusable platform SDK rather than remaining app-local admin infrastructure.

The long-term goal is for business modules to behave like plugins that depend on shared platform packages instead of owning their own routing, table behavior, forms, permissions, and layouts.

## Platform SDK rule

The platform should own:

- design language
- component behavior
- workspace lifecycle
- tables
- forms
- search
- navigation
- permissions
- actions
- real-time events
- uploads
- notifications
- logging

Business modules should own:

- definitions
- backend contracts
- domain-specific configuration
- module-specific business rules

## Target repository direction

```text
shield/
  apps/
    admin/
    customer/
    provider/
    crm/
    agent/
  packages/
    shield_design_system/
    shield_engine/
    shield_auth/
    shield_permissions/
    shield_api/
    shield_realtime/
    shield_forms/
    shield_tables/
    shield_actions/
    shield_workspace/
    shield_navigation/
    shield_search/
    shield_upload/
    shield_charts/
    shield_notifications/
    shield_logging/
  modules/
    customer/
    wallet/
    provider/
    branch/
    settings/
    audit/
    users/
    roles/
    reports/
    referrals/
    dashboard/
```

This is a target architecture and does not require an immediate repository-wide folder migration, but all new Phase 3B work should move toward this separation.

## Build order

The strict platform-first order should be:

1. Design system package
2. Reusable component library
3. Platform engine
4. Registry system
5. Command bus and event bus
6. Schema-driven table and form engines
7. Global search and command palette
8. Workflow engine and background job framework
9. Settings reference implementation
10. Remaining governance and operational modules

## Design system package

Build tokens before screens.

The design system should own tokens for:

- spacing
- radius
- elevation
- typography
- animation
- icons
- shadows
- breakpoints
- grid
- density
- transitions
- state colors
- semantic colors
- chart palette
- avatar rules
- status colors
- table density
- motion rules

Prefer token APIs such as:

- `AppSpacing.lg`
- `AppRadius.large`
- `AppTypography.titleLarge`
- `AppElevation.level2`

## Component library

Build reusable platform components before module pages.

Key families:

- buttons
- text fields
- search fields
- selects
- multi-selects
- data tables
- filter drawers
- sidebars
- top bars
- breadcrumbs
- badges
- avatars
- stat cards
- metric cards
- timelines
- drawers
- modals
- empty states
- error states
- loading states
- skeletons
- tabs
- wizards
- steppers
- activity feeds
- chart cards
- command palette
- quick actions
- context menus

## Registry system

The platform should be registry-driven.

Core registries should include:

- `WorkspaceRegistry`
- `NavigationRegistry`
- `PermissionRegistry`
- `SearchRegistry`
- `ActionRegistry`
- `RouteRegistry`

Preferred flow:

`Module -> register() -> registries -> app shell -> renderer`

No sidebar or router should own hardcoded knowledge of specific business modules once the registry system is in place.

## Command bus

Widgets should dispatch commands rather than call services directly.

Preferred flow:

`Widget -> Dispatch Action -> Command Bus -> Middleware -> Permission -> Validation -> Logging -> Analytics -> API`

This keeps platform policies centralized and UI components simpler.

## Event bus

Cross-module refresh behavior should be event-driven.

Preferred flow:

`Mutation -> Domain Event -> Event Bus -> listeners -> refresh / notify / audit / invalidate cache`

This avoids brittle manual refresh chains.

## Metadata layer

Modules should define metadata instead of handwritten pages.

Example direction:

```dart
WorkspaceDefinition(
  id: 'customers',
  datasource: CustomerDatasource(),
  toolbar: [...],
  filters: [...],
  table: [...],
  actions: [...],
  forms: [...],
)
```

The engine renders the definition.

## Schema-driven form engine

The form engine should support structured definitions:

`Section -> Card -> Row -> Field`

Field types should be extensible and include:

- text
- phone
- email
- dropdown
- date
- otp
- currency
- money
- textarea
- markdown
- json
- relation
- upload
- signature
- switch
- checkbox
- tags
- address
- location
- dynamic list

Validation should support:

- required
- regex
- async
- server
- permission
- dependency

## Universal table engine

The table engine should be shared and schema-driven.

Capabilities should include:

- column resize
- column hide
- frozen columns
- saved views
- quick filters
- server search
- grouping
- aggregation
- inline edit
- export
- infinite scroll where needed
- selection
- bulk actions
- pinned columns
- totals
- virtualization
- keyboard navigation

## Global search and command palette

The platform should support global search and action discovery through a command surface like `Ctrl + K`.

Targets should include:

- customers
- branches
- wallets
- providers
- reports
- users
- settings
- commands
- recent items
- favorites

## Workflow engine

Do not wait too long to model business workflows as configurable definitions.

The workflow engine should eventually support sequences such as:

`Customer Registered -> Assign CRM -> Send Welcome SMS -> Create Wallet -> Issue Card -> Notify Branch`

This enables future visual workflow tooling without forcing code rewrites.

## Background job framework

The platform should treat asynchronous work as first-class infrastructure.

Key workloads:

- OTP sends
- WhatsApp messages
- email delivery
- report generation
- PDF generation
- wallet reconciliation
- referral calculations
- notification fan-out
- daily summaries

Every background job should support:

- retries
- status tracking
- logs
- scheduling

## Media and document service

Uploads should be centralized, not module-specific.

The shared document service should support:

- file upload with chunking
- image optimization
- PDF preview
- version history
- access control
- signed URLs
- folder organization
- metadata and tags
- virus scanning later

This becomes the common backbone for KYC, prescriptions, invoices, reports, and certificates.

## Success condition

The platform SDK is succeeding when a new module mainly requires:

1. backend contracts
2. metadata definitions
3. registry registration
4. permission and action configuration

At that point SHIELD modules become plugins on top of a stable platform instead of collections of handcrafted screens.
