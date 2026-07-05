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

## Current 3B.1 checkpoint

The repo has now crossed the first live runtime threshold for the admin portion of the SDK:

- shared workspace, navigation, capability, command, and event primitives are implemented and tested
- the Super Admin shell now enters through a platform runtime bootstrap instead of resolving modules from a page-local switch
- workspace registration currently ships with default schema metadata and no-op data repositories so the engine can own lifecycle and metadata without inventing fake backend payloads
- the next milestone remains backend-owned workspace metadata, real repositories, and contract-driven governance modules

Business modules should own:

- definitions
- backend contracts
- domain-specific configuration
- module-specific business rules

## Domain layer

Insert a domain layer between packages and modules.

Target direction:

```text
apps/
packages/
domains/
modules/
```

Suggested domain families:

- `identity`
- `customer`
- `wallet`
- `provider`
- `laboratory`
- `pharmacy`
- `inventory`
- `referral`
- `billing`
- `notification`
- `audit`

Each domain should own:

- business rules
- entities
- services
- events
- repositories
- contracts

Modules should sit on top of domains rather than re-implement domain logic independently in each portal.

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
  domains/
    identity/
    customer/
    wallet/
    provider/
    laboratory/
    pharmacy/
    inventory/
    referral/
    billing/
    notification/
    audit/
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

## Capability registry model

In addition to specialized engines, the platform should think in terms of capabilities.

Examples:

- navigation
- forms
- tables
- charts
- search
- files
- notifications
- realtime
- export
- import
- workflow
- analytics
- permissions
- AI
- reporting

Modules should increasingly declare required capabilities rather than wiring those systems manually.

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
9. Feature flag and configuration services
10. Settings reference implementation
11. Remaining governance and operational modules

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
- `CapabilityRegistry`

Preferred flow:

`Module -> register() -> registries -> app shell -> renderer`

No sidebar or router should own hardcoded knowledge of specific business modules once the registry system is in place.

## Command bus

Widgets should dispatch commands rather than call services directly.

Preferred flow:

`Widget -> Dispatch Action -> Command Bus -> Middleware -> Permission -> Validation -> Logging -> Analytics -> API`

This keeps platform policies centralized and UI components simpler.

## Feature flag system

Feature rollout should be a first-class platform service, not a late-stage patch.

Flags should be enforceable by:

- environment
- tenant
- organization
- branch
- role
- user

This is especially important for staged delivery of wallet changes, AI features, provider integrations, and operational tooling.

## Configuration service

Avoid hardcoded runtime configuration values in modules.

The platform should expose a configuration service with layered overrides:

`Global -> Tenant -> Organization -> Branch -> User`

Configuration examples:

- currency
- date format
- timezone
- branch settings
- password policies
- OTP timeout
- upload limits
- invoice numbering
- dashboard preferences

## Event bus

Cross-module refresh behavior should be event-driven.

Preferred flow:

`Mutation -> Domain Event -> Event Bus -> listeners -> refresh / notify / audit / invalidate cache`

This avoids brittle manual refresh chains.

Events should be versioned, for example:

- `CustomerRegistered.v1`
- `WalletCredited.v2`
- `BranchCreated.v1`

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

## AI as a platform capability

AI should be treated as another platform package rather than a special one-off module.

Suggested package direction:

- `shield_ai`

Potential capabilities:

- summarization
- semantic search
- OCR
- document extraction
- chatbot
- recommendations
- anomaly detection
- report generation

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

## Integration framework

Third-party integrations should be modeled through connector contracts rather than embedded directly in domains.

Examples:

- payment connectors
- SMS connectors
- email connectors
- WhatsApp connectors
- printer connectors
- barcode connectors
- lab equipment connectors
- government API connectors

Domains should remain provider-agnostic wherever possible.

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

## Centralized ID generation

The platform should provide a shared identifier service for human-readable business IDs.

Examples:

- `CUS-000001`
- `WAL-000001`
- `LAB-000001`
- `REF-000001`
- `ORD-000001`

ID strategy should be centrally configurable rather than invented table by table.

## Policy engine

Permissions answer whether a user may attempt an action.

Policies answer whether the action is allowed under current business conditions.

Example policy dimensions:

- time window
- amount limit
- branch match
- invoice state
- membership state
- provider compatibility

This keeps authorization separate from business constraints.

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

## Platform test harness

The SDK should provide reusable testing primitives instead of forcing each module to invent its own harness.

Examples:

- mock workspace
- mock registry
- mock permissions
- mock API
- mock events
- mock navigation
- mock storage

This lowers the cost of testing new modules built on the platform.

## Success condition

The platform SDK is succeeding when a new module mainly requires:

1. backend contracts
2. metadata definitions
3. registry registration
4. permission and action configuration

At that point SHIELD modules become plugins on top of a stable platform instead of collections of handcrafted screens.
