# SHIELD Admin Engine Architecture

Date: 2026-07-04
Status: Active foundation spec
Linked docs:
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-implementation-plan.md`
- `docs/superpowers/specs/2026-07-04-shield-admin-platform-roadmap-phase-3.md`
- `docs/superpowers/specs/2026-07-04-shield-super-admin-v2-reset.md`
- `docs/superpowers/specs/2026-07-04-shield-platform-sdk-architecture.md`

## Purpose

This document defines the internal application framework that powers the SHIELD Admin Platform.

It exists to prevent the shared admin foundation from becoming a giant catch-all service and to keep business rules out of the engine itself.

## Platform rule

The admin engine must stay framework-like:

- it renders
- it routes
- it manages shared state
- it standardizes actions
- it enforces presentation-level consistency

It must not become the place where business rules, module-specific workflows, or domain policy live.

## Relationship to the Platform SDK

The admin engine should be treated as one major subsystem inside the broader SHIELD Platform SDK.

That means:

- the admin engine is not the final top-level boundary
- packages should eventually own shared capabilities such as forms, tables, actions, search, uploads, notifications, and logging
- domains should own reusable business rules and entities that are shared across admin, CRM, agent, provider, and customer-facing modules
- business modules should depend on those platform capabilities instead of reinventing them inside admin feature folders

## Current implementation status

The current repository now has a live runtime bootstrap layer for the Super Admin shell:

- workspace, navigation, schema, and capability metadata are registered through one shared runtime bundle
- `AdminPortalWorkspace` mounts workspaces through that runtime and the shared workspace controller instead of a local hardcoded builder switch
- the runtime now accepts an injected schema repository, which is used by governance workspaces so backend payloads can replace static schema defaults without duplicating the runtime
- `settings`, `platform`, `audit`, and `notifications` now resolve through one shared governance datasource and renderer instead of four independent placeholder shells
- non-governance modules still depend on static schema and local module rendering, so broader schema-driven migration remains future work

## Six engine subsystems

### 1. Layout Engine

Owns:

- admin shell
- page layout
- sidebar layout
- top toolbar layout
- drawer layout
- dialog layout
- spacing and density composition

Examples:

- `AdminConsolePage`
- `AdminSidebar`
- `AdminToolbar`
- `AdminContent`

### 2. Workspace Engine

Owns:

- `WorkspaceDefinition`
- `WorkspaceRegistry`
- route resolution
- workspace view selection
- workspace mounting lifecycle

Rule:

- the engine knows how to render
- the workspace definition knows what to render

### 3. Data Engine

Owns:

- datasource contracts
- query state
- pagination
- filtering
- sorting
- search
- server refresh behavior
- cache invalidation hooks

Rule:

- pages do not invent their own query model

### 4. Action Engine

Owns:

- create
- update
- delete
- export
- approval
- audit-triggered actions
- confirmation flow
- refresh behavior
- toast and result handling

Standard lifecycle:

`Action -> Permission -> Validation -> Confirmation -> Event -> API -> Audit -> Refresh -> Toast`

### 5. Form Engine

Owns:

- dynamic forms
- validation
- sections
- field types
- conditional fields
- step flows
- attachments
- autosave hooks

Rule:

- CRUD forms should be definition-driven, not handwritten screen-by-screen

### 6. Permission Engine

Owns:

- RBAC visibility
- conditional actions
- conditional fields
- module access
- row-level and section-level gating

Rule:

- the permission engine consumes backend permission metadata
- it does not define the business permission catalog itself

## Registry model

The admin platform should be registry-driven.

The sidebar and router should not know individual modules directly.

Preferred flow:

`Sidebar -> WorkspaceRegistry -> WorkspaceDefinition -> Renderer`

Each workspace should register itself through the registry so new modules feel like plugins instead of core rewrites.

The registry model should eventually align with a broader capability registry exposed by the Platform SDK.

## Workspace interface direction

Every module should implement one shared workspace contract.

Example shape:

```dart
abstract class AdminWorkspace {
  String get id;
  String get title;
  IconData get icon;
  String get permissionKey;
  List<ViewDefinition> get views;
  List<ActionDefinition> get actions;
  DataSourceDefinition get datasource;
}
```

The exact type names may evolve, but the rule should remain:

- configuration first
- handcrafted screens second

## Plugin mindset

The admin engine should assume SHIELD will grow through domain plugins.

Examples:

- Settings plugin
- Audit plugin
- CRM plugin
- Wallet plugin
- Provider plugin
- Diagnostics plugin
- Pharmacy plugin
- Insurance plugin

The engine core should remain stable while plugins contribute:

- workspace definitions
- actions
- forms
- tables
- filters
- permissions

## View system

The engine must support more than tables.

Supported view families should include:

- table
- cards
- kanban
- timeline
- calendar
- metrics
- split view
- master-detail
- tree
- map later if required

This prevents module rewrites when workflows evolve.

## Shared workspace state

Every workspace should inherit a common state model:

- `loading`
- `refreshing`
- `empty`
- `error`
- `permissionDenied`
- `offline`
- `ready`

These should be engine-level concerns, not screen-local inventions.

## Standard backend response contract

Admin workspace endpoints should align on one response envelope:

```json
{
  "success": true,
  "message": "",
  "data": [],
  "meta": {
    "page": 1,
    "pageSize": 25,
    "total": 214
  },
  "filters": {},
  "permissions": {},
  "links": {}
}
```

Rules:

- use the same outer response contract across admin modules
- keep pagination and filter metadata predictable
- expose permissions in-band where the workspace needs them
- avoid module-specific envelope drift

## Event-driven interaction model

Do not wire module interactions through direct callback chains alone.

Preferred pattern:

`Mutation -> Domain Event -> Audit -> Workspace Refresh -> Notification -> Cache Invalidation`

This makes cross-module behavior easier to scale as SHIELD grows.

Event contracts should become versioned over time so consumers can evolve safely.

## Design token system

The engine should consume shared design tokens rather than magic numbers.

Tokens should cover:

- spacing
- elevation
- radius
- typography
- icons
- table density
- toolbar heights
- drawer width
- breakpoints
- animations
- loading states

## Suggested frontend structure

```text
frontend/lib/features/admin/
  shared/
    engine/
      workspace/
      datasource/
      actions/
      permissions/
      registry/
      routing/
    components/
      tables/
      forms/
      dialogs/
      filters/
      toolbars/
      cards/
      badges/
      charts/
      status/
      upload/
    layouts/
    models/
    services/
```

This structure may evolve, but the subsystem split should remain visible.

For the broader package direction, refer to:

- `docs/superpowers/specs/2026-07-04-shield-platform-sdk-architecture.md`

## Success condition

The engine is succeeding when adding a new admin module looks like:

1. define the data model and backend contracts
2. register a workspace definition
3. configure views, actions, filters, forms, and permissions
4. let the engine render a consistent production-ready module

At that point SHIELD stops behaving like a collection of admin pages and starts behaving like an extensible enterprise platform.
