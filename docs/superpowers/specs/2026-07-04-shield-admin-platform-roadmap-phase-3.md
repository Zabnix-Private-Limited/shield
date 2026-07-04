# SHIELD Admin Platform Roadmap

Date: 2026-07-04
Prerequisite baseline:
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-implementation-plan.md`
- `docs/superpowers/specs/2026-07-04-shield-admin-engine-architecture.md`
- `docs/superpowers/specs/2026-07-04-shield-platform-sdk-architecture.md`

## Status

### Completed

- Phase 1: Admin Portal Foundation
- Phase 2: Admin Architecture Extraction

### In Progress

- Phase 3: Feature Implementation
- Phase 3B: Super Admin v2 reset

## Phase 3 Goal

Replace every admin mock surface with a production-ready module using one consistent admin engine architecture:

`presentation -> application -> domain -> data -> api -> backend`

The shell, grouped IA, routing, workspace composition, portal integration, and RBAC entrypoints are now frozen platform infrastructure and should not be reworked during feature implementation.

Before more module-by-module API work, governance and system surfaces must drop their landing-page placeholders and adopt one compact console pattern.

## Phase 3B Milestones

### Phase 3B.1: Core Admin Engine Framework

- shared layout and shell primitives
- explicit subsystem boundaries for layout, workspace, data, action, form, and permission engines
- reusable toolbar and filter system
- view containers for table, form, metric, timeline, calendar, card, split, and tree surfaces
- centralized state handling for loading, empty, no-permission, offline, error, and success
- shared action lifecycle hooks for permission, validation, confirmation, API execution, audit, refresh, and toast handling
- design token ownership for spacing, typography, density, breakpoints, drawers, animations, and loading states
- align the engine with the wider package-first Platform SDK direction

### Phase 3B.2: Workspace Contract

- metadata-driven workspace definitions become the source of truth for module rendering
- the contract should describe:
  - id
  - title
  - datasource
  - layout
  - columns
  - forms
  - filters
  - tabs
  - actions
  - permissions
  - view modes
  - empty and error messaging
- registry-driven module ownership so sidebar and routing resolve through workspace definitions instead of direct module knowledge
- prepare complementary registries for navigation, search, permissions, actions, and routes

### Phase 3B.3: Backend Contracts

- define REST endpoints and DTOs before building production CRUD
- keep module stacks consistent:
  - controller
  - dto
  - service
  - repository
  - prisma
  - events
  - audit
  - permissions
- standardize response envelopes with `success`, `message`, `data`, `meta`, `filters`, `permissions`, and `links`
- prefer event-driven follow-up after mutations so audit, notifications, refresh, and cache invalidation remain composable
- steer widgets toward command-bus dispatch instead of direct service coupling

### Phase 3B.4: Module Migration

- migrate modules into the engine one by one after the framework and contracts are stable
- recommended first sequence:
  1. Settings
  2. Platform
  3. Audit
  4. Notifications

## Phase 3B Reset Rules

- No fake activity feeds
- No fake health percentages
- No navigation-only setting tiles
- No page-local dummy KPI cards
- No module-specific layout inventions when a shared table, form, toolbar, or split workspace can be used
- Use explicit empty states until live endpoints exist
- Keep backend ownership for labels, actions, tabs, filters, and status semantics

## Delivery Order

1. Dashboard
2. Customers
3. Memberships
4. Wallet
5. Providers
6. Services
7. Documents
8. Visits
9. CRM
10. Agents
11. Rewards
12. Referrals
13. Reports
14. Organization
15. Notifications
16. Audit
17. Availability
18. Insights
19. Platform
20. Settings

## First Migration Slice

These modules move first because they most strongly exposed the placeholder-pattern drift:

1. Settings
2. Platform
3. Audit
4. Notifications

## Required Feature Structure

Every admin feature module must follow this structure:

```text
feature/
├── api/
├── application/
├── data/
│   ├── datasources/
│   ├── dto/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── dialogs/
    ├── providers/
    ├── screens/
    └── widgets/
```

## Completion Checklist

### UI

- Loading state
- Empty state
- Error state
- No fake business or operational data
- No hand-built page logic when the workspace contract can describe the behavior
- Desktop responsive behavior
- Tablet-safe responsive behavior
- Search
- Filters
- Pagination where dataset size requires it
- Sorting where tables require it
- Confirmation patterns for destructive actions
- Bulk actions where list workflows require them

### Application

- Riverpod ownership
- Async loading and refresh
- Retry path
- Cache policy
- Error recovery without shell breakage

### Domain

- Entity layer
- Repository interface
- Validation rules
- Use cases when business logic grows beyond controller orchestration

### Data

- DTO mapping
- Datasource isolation
- Repository implementation
- Error parsing
- No duplicate live and mock implementations

### Backend

- Real API contract connected
- RBAC enforced server-side
- Validation enforced server-side
- Audit and activity events included where required
- Search, filtering, and pagination mapped without frontend-owned business semantics

### Quality

- `flutter analyze --no-pub`
- `flutter test`
- `npm run build`
- Documentation updated
- `log.md` updated

## Phase 4

After core feature implementation, move to Admin Platform Hardening:

- Permission Matrix
- Unified Activity Timeline
- Notification Center
- Global Search
- Command Palette
- Feature Flags
- Organization Context
- Background Jobs
- File Manager
- Analytics and BI
- System Health

## Phase 3C

After the first governance wave, expand into production operational modules:

- Customers
- Agents
- CRM
- Wallet
- Providers
- Documents

## Phase 3D

Then focus on:

- performance
- caching
- observability
- testing
- production hardening

## Phase 4

After the first production module wave, expand shared platform services:

- global search and command palette
- workflow engine
- background job framework
- shared media and document service

## Current Phase 3 Slice

This pass starts Phase 3 by converting the Admin Dashboard into a real vertical module with:

- `api`
- `data`
- `domain`
- `application`
- `presentation/providers`
- live backend integration through `/dashboard/role/super-admin/dashboard`
- in-memory cache policy
- Riverpod controller ownership
- loading, empty, error, refresh, and stale-data fallback states
