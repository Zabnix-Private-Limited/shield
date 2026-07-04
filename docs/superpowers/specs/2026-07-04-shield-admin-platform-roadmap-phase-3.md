# SHIELD Admin Platform Roadmap

Date: 2026-07-04
Prerequisite baseline:
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-design-spec-v1.md`
- `docs/superpowers/specs/2026-07-03-shield-admin-portal-implementation-plan.md`

## Status

### Completed

- Phase 1: Admin Portal Foundation
- Phase 2: Admin Architecture Extraction

### In Progress

- Phase 3: Feature Implementation

## Phase 3 Goal

Replace every admin mock surface with a production-ready module using one consistent vertical architecture:

`presentation -> application -> domain -> data -> api -> backend`

The shell, grouped IA, routing, workspace composition, portal integration, and RBAC entrypoints are now frozen platform infrastructure and should not be reworked during feature implementation.

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
