# SHIELD Super Admin v2 Reset

Date: 2026-07-04
Status: Active
Linked docs:
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-implementation-plan.md`
- `docs/superpowers/specs/2026-07-04-shield-admin-platform-roadmap-phase-3.md`
- `docs/superpowers/specs/2026-07-04-shield-platform-sdk-architecture.md`

## Why this reset exists

The current Super Admin frontend is visually strong but structurally still behaves like a collection of showcase pages. Governance and system modules such as Settings, Notifications, Audit, and Platform rely on hero banners, static cards, fake inbox content, and fake health metrics instead of backend-ready console surfaces.

This reset changes the direction from page-by-page mock expansion to one reusable metadata-driven admin operating model.

## Product rule

Super Admin must feel like an operating system for SHIELD, not like a set of marketing pages.

That means:

- compact titles instead of giant hero sections
- toolbar-first workflows
- tables and forms instead of decorative cards
- empty states instead of fake data
- backend-owned semantics instead of frontend-authored labels and actions

## Naming rule

Do not frame this foundation as a generic page renderer in the codebase or docs.

Position it as the foundation of the admin platform, for example:

- Admin Engine
- Control Center Framework
- Portal Engine

Inside that foundation, workspace definitions, layout systems, registries, permissions, actions, renderers, and data sources should be separate concerns.

The broader package-first direction for SHIELD is documented separately in the Platform SDK architecture spec.

## Modules in scope first

1. Settings
2. Notifications
3. Audit
4. Platform

These four modules are the first conversion slice because they most clearly revealed the landing-page drift.

## Phase 3B milestones

### Phase 3B.1: Core Admin Engine Framework

Build reusable platform primitives before more module delivery:

- Admin layout
- Workspace shell
- Page header
- Toolbar
- Search
- Filters
- Tabs
- Sidebar
- Drawer
- Dialog
- Table
- Detail panel
- Form renderer
- Metric cards
- Status badges
- Pagination
- Bulk actions
- Permissions

### Phase 3B.2: Workspace Contract

The most important contract in this reset is the definition that tells the engine what to render.

Instead of hardcoding pages, define metadata such as:

- workspace id
- datasource id
- title
- layout
- columns
- forms
- filters
- tabs
- actions
- permissions
- view modes
- empty and error states

The engine should own how rendering works. The workspace definition should own what appears.

### Phase 3B.3: Backend Contracts

Define DTOs and endpoints before production UI wiring for each migrated workspace.

Preferred backend chain:

`Prisma -> Repository -> Service -> Controller -> DTO -> Swagger -> Frontend repository -> Riverpod provider -> UI`

### Phase 3B.4: Module Migration

Only after the framework and contracts are stable should modules migrate one by one.

Recommended order:

1. Settings
2. Platform
3. Audit
4. Notifications

## Required workspace structure

Every governance or system module should prefer this layout:

```text
Title + actions
Search / tabs / filters
Primary content
Split panels for detail, forms, logs, or operational metadata
Explicit empty state when live data is not connected
```

## Backend-owned contract requirements

The backend should eventually own:

- navigation and section registries
- form section registries
- action definitions
- tabs
- filters
- table columns when business semantics matter
- statuses and severity labels
- empty-state copy where workflow guidance is business-owned

Flutter should own:

- rendering
- responsive behavior
- accessibility
- loading / error transitions
- presentation formatting only

## Screen-specific direction

### Settings

- Replace navigation tiles with a real settings navigator plus editable detail panel
- Bind live forms to:
  - `/admin/settings/company`
  - `/admin/settings/security`
  - `/admin/settings/branding`
  - `/admin/settings/storage`
  - `/admin/settings/api`
- Every save path should be auditable

### Notifications

- Replace the fake inbox with:
  - Templates
  - Broadcasts
  - Campaigns
  - Delivery logs
  - Queue views
- Prefer table-first operations with recipient and delivery evidence

### Audit

- Replace the activity feed with a real audit table
- Backend should auto-ingest audit events from middleware or service-layer logging
- Filters, exports, and field retention should be server-driven

### Platform

- Replace fake uptime and queue cards with one health endpoint
- Render dependencies such as:
  - Database
  - Redis / Valkey
  - Firebase
  - R2
  - Email
  - SMS
  - Push
  - Queue
  - Cron
- Show empty states until live telemetry exists

## View types the engine must support

Do not limit the admin engine to table rendering only.

It should be able to support:

- Table
- Cards
- Kanban
- Timeline
- Calendar
- Metrics
- Split view
- Master and detail
- Tree
- Map later if needed

This allows different modules to evolve without rewriting the foundation.

## Action system rule

Actions should not be raw button callbacks spread through pages.

Each admin action should support a shared lifecycle:

`Action -> Permission -> Validation -> Confirmation -> Audit -> API -> Toast -> Refresh`

This is especially important for destructive or high-trust workflows.

## Frontend implementation rule

Do not add more bespoke admin page layouts while this reset is active.

Any new governance or system screen should either:

1. use the shared compact console page and toolbar pattern, or
2. extend the admin engine if a new reusable pattern is required

## Done means

This reset is complete when:

- the four in-scope modules no longer use hero banners or fake operational content
- shared compact console scaffolds exist in `frontend/lib/features/admin/shared/`
- governance screens render backend-ready empty states instead of placeholder data
- future module work can register a workspace definition instead of designing a new page from scratch
