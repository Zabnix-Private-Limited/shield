# 2026-07-05 Admin Interaction Audit

## Scope

- Repository: `frontend/lib/features/admin/**`
- Audit target: every visible interactive-looking control in the Admin Portal
- Audit method: inspect module screens, shared admin chrome, runtime renderer, and backend workspace fetch path
- Status basis:
  - `Completed`: executes a real runtime, repository, backend, or navigation behavior
  - `Partial`: visible and partly wired, but missing full enterprise behavior
  - `Not Implemented`: visible but decorative, inert, local-only, or placeholder-backed
  - `Blocked`: meaningful behavior requires backend contract or runtime metadata not yet present

## Shared Findings

### Component
`AdminWorkspaceHeader` primary and secondary actions

### Current State
- Visible
- Shared owner
- Empty callbacks in `admin_workspace_header.dart`
- Affects all `AdminPage` / backend-rendered modules

### Expected Behaviour
- Dispatch real workspace action metadata
- Refresh, navigate, open drawer/dialog, or mutate through runtime
- Hide when action contract is absent

### Backend Needed
- Action descriptors, not just labels

### Priority
Critical

### Status
Not Implemented

### Component
Toolbar search

### Current State
- Visible
- Shared owner
- Rendered as styled text, not input, in `admin_search_bar.dart`
- No debounce
- No repository reload

### Expected Behaviour
- Editable search input
- Debounced workspace reload
- Persist query in workspace state and URL when applicable
- Clear action

### Backend Needed
- Already exists for dashboard, customers, settings, platform, audit, notifications
- Missing for prototype modules

### Priority
Critical

### Status
Not Implemented

### Component
Toolbar tabs

### Current State
- Visible
- Shared owner
- First tab styled active, but no selection behavior
- No data reload

### Expected Behaviour
- Select tab
- Update workspace state
- Reload repository with tab context
- Preserve active tab on refresh

### Backend Needed
- Already exists for backend-driven modules
- Missing for prototype modules

### Priority
Critical

### Status
Not Implemented

### Component
Filter chips

### Current State
- Visible
- Shared owner
- Decorative only in `admin_filter_bar.dart`
- No selection or clear behavior

### Expected Behaviour
- Toggle filter
- Update workspace state
- Reload repository
- Preserve filter state

### Backend Needed
- Already exists for backend-driven modules
- Missing for prototype modules

### Priority
Critical

### Status
Not Implemented

### Component
Entity cards, KPI cards, timeline rows, empty-state actions, data-table headers/rows

### Current State
- Visible across multiple modules
- Shared owner
- No click, drilldown, sort, pagination, row selection, or actionable empty-state CTA

### Expected Behaviour
- Cards drill into filtered workspaces or details
- KPI and metrics open filtered datasets
- Timeline items navigate to source entity/audit/document
- Table supports sorting, pagination, selection, refresh, and row detail
- Empty states expose real actions

### Backend Needed
- Drilldown targets and row action metadata

### Priority
Critical

### Status
Blocked

## Dashboard

### Component
Header actions

### Current State
- Backend data exists
- Buttons render from backend labels
- Shared empty callbacks

### Expected Behaviour
- `Refresh workspace`
- `Open approvals` / `Open activity` through runtime action metadata

### Backend Needed
- Action descriptors for dashboard header

### Priority
Critical

### Status
Not Implemented

### Component
Search, tabs, filters

### Current State
- Backend hints, tabs, and filters exist
- Shared toolbar controls are decorative

### Expected Behaviour
- Search alerts, activity, and branch summary data
- Switch `Overview`, `Alerts`, `Activity`, `Branches`
- Filter by `Live`, `Review`, `Healthy`

### Backend Needed
- Already exists

### Priority
Critical

### Status
Partial

### Component
KPI cards

### Current State
- Live backend metrics render
- No drilldown behavior

### Expected Behaviour
- Open filtered views for approvals, alerts, workload, and health

### Backend Needed
- Metric drilldown metadata

### Priority
High

### Status
Blocked

### Component
Panel list items and table rows

### Current State
- Backend-driven content renders
- No row click, sort, or pagination

### Expected Behaviour
- Open alert/activity detail
- Sort tabular datasets
- Drill into target workspace

### Backend Needed
- Row action metadata and paging/sort contract

### Priority
High

### Status
Blocked

## Customers

### Component
Header actions

### Current State
- Backend labels exist
- Shared empty callbacks

### Expected Behaviour
- `Create customer`
- `Review approvals`

### Backend Needed
- Action descriptors and command metadata

### Priority
Critical

### Status
Not Implemented

### Component
Search, tabs, filters

### Current State
- Backend contract exists
- Shared toolbar is decorative

### Expected Behaviour
- Search customers by name, code, branch, membership, wallet, CRM signals
- Switch tabs such as `Overview`, `Approvals`, `Wallet`, `Documents`, `Timeline`
- Filter by `ACTIVE`, `PENDING`, `SUSPENDED`, `REJECTED`

### Backend Needed
- Already exists

### Priority
Critical

### Status
Partial

### Component
Customer list cards

### Current State
- Backend-driven cards render
- No selection or detail opening

### Expected Behaviour
- Select customer
- Open master-detail workspace
- Sync URL/runtime state

### Backend Needed
- Card action metadata or list-detail selection contract

### Priority
Critical

### Status
Blocked

### Component
Timeline, wallet, documents, appointments, CRM panels

### Current State
- Backend content renders
- No navigation into related record

### Expected Behaviour
- Open linked customer, document, appointment, audit, or CRM record

### Backend Needed
- Related-entity targets in payload

### Priority
High

### Status
Blocked

## Memberships

### Component
Header actions

### Current State
- Visible
- Local prototype screen
- No runtime/repository/backend path

### Expected Behaviour
- Create plan
- Review renewals

### Backend Needed
- Workspace contract and repository integration

### Priority
Critical

### Status
Blocked

### Component
Plan cards and health rows

### Current State
- Decorative
- Static data

### Expected Behaviour
- Open plan detail
- Filter renewals
- Open expiry/audit queues

### Backend Needed
- Membership workspace endpoint

### Priority
Critical

### Status
Blocked

## Agents

### Component
Header actions

### Current State
- Visible
- Local prototype screen
- No runtime wiring

### Expected Behaviour
- Add agent
- Assign branch

### Backend Needed
- Agent workspace contract

### Priority
Critical

### Status
Blocked

### Component
Section tabs

### Current State
- Visible
- Decorative

### Expected Behaviour
- Switch overview, customers, performance, follow-ups, visits, attendance, documents, timeline

### Backend Needed
- Agent tab contract

### Priority
Critical

### Status
Blocked

### Component
Agent cards, KPI strip, detail rows, timeline

### Current State
- Static mock data
- No selection, drilldown, or navigation

### Expected Behaviour
- Open agent workspace
- Drill into assigned customers, visits, follow-ups, attendance, and documents

### Backend Needed
- Agent list/detail/timeline contract

### Priority
Critical

### Status
Blocked

## Providers

### Component
Header actions

### Current State
- Visible
- Local prototype screen
- No runtime wiring

### Expected Behaviour
- Add provider
- Map branch

### Backend Needed
- Provider workspace contract

### Priority
Critical

### Status
Blocked

### Component
Section tabs

### Current State
- Decorative

### Expected Behaviour
- Switch profile, availability, services, bookings, reviews, documents, timeline, payments

### Backend Needed
- Provider tab contract

### Priority
Critical

### Status
Blocked

### Component
Provider cards, KPI strip, timeline

### Current State
- Static mock data
- No detail or navigation

### Expected Behaviour
- Open provider workspace
- Drill into bookings, availability, compliance, documents, reviews

### Backend Needed
- Provider list/detail/timeline contract

### Priority
Critical

### Status
Blocked

## Wallet

### Component
Header actions

### Current State
- Visible
- Local prototype screen
- No runtime wiring

### Expected Behaviour
- Post adjustment
- Review audits

### Backend Needed
- Wallet workspace contract

### Priority
Critical

### Status
Blocked

### Component
Ledger summary rows and transaction timeline

### Current State
- Static mock data
- No transaction drilldown, search, filters, or export

### Expected Behaviour
- Open ledger detail
- Filter by sub-ledger and status
- Navigate to transaction/audit/customer

### Backend Needed
- Wallet ledger and transaction contract

### Priority
Critical

### Status
Blocked

## Documents

### Component
Header actions

### Current State
- Visible
- Local prototype screen
- No runtime wiring

### Expected Behaviour
- Approve selected
- Request resubmission

### Backend Needed
- Document queue workspace contract

### Priority
Critical

### Status
Blocked

### Component
Section tabs

### Current State
- Decorative

### Expected Behaviour
- Switch pending, approved, rejected, expired, resubmission

### Backend Needed
- Document status-tab contract

### Priority
Critical

### Status
Blocked

### Component
Queue cards, preview actions, decision cards, audit timeline

### Current State
- Static mock data
- No queue selection, preview loading, mutation, or audit navigation

### Expected Behaviour
- Select document
- Load preview and metadata
- Approve/reject/request resubmission through commands
- Open audit trail

### Backend Needed
- Document list/detail/mutation contract

### Priority
Critical

### Status
Blocked

## CRM

### Component
Header actions

### Current State
- Visible
- Local prototype screen
- No runtime wiring

### Expected Behaviour
- Open escalations
- Assign campaign

### Backend Needed
- CRM workspace contract

### Priority
Critical

### Status
Blocked

### Component
Queue tiles and performance rows

### Current State
- Static mock data
- No navigation, filtering, or queue ownership actions

### Expected Behaviour
- Open queue detail
- Filter by branch/owner/status
- Dispatch assignment workflows

### Backend Needed
- CRM queue/performance contract

### Priority
Critical

### Status
Blocked

## Reports

### Component
Header actions

### Current State
- Visible
- Local prototype screen
- No runtime wiring

### Expected Behaviour
- Run report
- Save template

### Backend Needed
- Reports workspace contract

### Priority
Critical

### Status
Blocked

### Component
Builder steps and saved report queue tiles

### Current State
- Visual workflow only
- No dataset selection, filters, preview, export, or schedule action

### Expected Behaviour
- Choose dataset
- Configure filters/columns
- Preview
- Export
- Schedule
- Open saved report definitions

### Backend Needed
- Reports builder and history contract

### Priority
Critical

### Status
Blocked

## Settings

### Component
Header actions

### Current State
- Backend labels exist
- Shared empty callbacks

### Expected Behaviour
- Open reset/session/configuration workflows through runtime

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Not Implemented

### Component
Search, tabs, filters

### Current State
- Backend contract exists
- Shared controls are decorative

### Expected Behaviour
- Search setting codes/values
- Switch domain tabs
- Filter health/status

### Backend Needed
- Already exists

### Priority
Critical

### Status
Partial

### Component
Settings rows and detail panels

### Current State
- Backend content renders
- No row selection, refresh, edit, or audit navigation

### Expected Behaviour
- Select setting
- Open detail and audit
- Refresh values

### Backend Needed
- Row action metadata

### Priority
High

### Status
Blocked

## Platform

### Component
Header actions

### Current State
- Backend labels exist
- Shared empty callbacks

### Expected Behaviour
- Inspect report engine
- Review integrations

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Not Implemented

### Component
Search, tabs, filters

### Current State
- Backend contract exists
- Shared controls are decorative

### Expected Behaviour
- Search integrations, runtime services, transport state
- Switch runtime/report/print/realtime tabs
- Filter healthy/configured/unavailable

### Backend Needed
- Already exists

### Priority
Critical

### Status
Partial

### Component
Platform rows and health widgets

### Current State
- Backend content renders
- No detail navigation or drilldown

### Expected Behaviour
- Open integration/service detail
- Refresh status
- Navigate to owning workspace

### Backend Needed
- Row action metadata

### Priority
High

### Status
Blocked

## Audit

### Component
Header actions

### Current State
- Backend labels exist
- Shared empty callbacks

### Expected Behaviour
- Export current view
- Inspect auth events

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Not Implemented

### Component
Search, tabs, filters

### Current State
- Backend contract exists
- Shared controls are decorative

### Expected Behaviour
- Search actors/entities/actions
- Switch actions/auth/recent tabs
- Filter severity and category

### Backend Needed
- Already exists

### Priority
Critical

### Status
Partial

### Component
Audit table and rows

### Current State
- Backend content renders
- No sort, pagination, row detail, or export workflow

### Expected Behaviour
- Sort and paginate
- Open audit event detail
- Export current result set

### Backend Needed
- Row action metadata and paging/sort contract

### Priority
High

### Status
Blocked

## Notifications

### Component
Header actions

### Current State
- Backend labels exist
- Shared empty callbacks

### Expected Behaviour
- Send in-app alert
- Review delivery devices

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Not Implemented

### Component
Search, tabs, filters

### Current State
- Backend contract exists
- Shared controls are decorative

### Expected Behaviour
- Search title/message/status
- Switch inbox/devices/unavailable templates
- Filter unread/read/channel

### Backend Needed
- Already exists

### Priority
Critical

### Status
Partial

### Component
Notification rows and timeline/detail content

### Current State
- Backend content renders
- No row navigation, mark-read, resend, or device drilldown

### Expected Behaviour
- Open notification detail
- Open related device/audit
- Dispatch read/resend workflows

### Backend Needed
- Row action and mutation contract

### Priority
High

### Status
Blocked

## Branches / Organization

### Component
Branch, employee, and role controls

### Current State
- Additional admin organization screens exist in repo
- Same prototype pattern as unmigrated business modules
- No backend-owned interactive behavior confirmed

### Expected Behaviour
- Search, filters, detail workspace, assignment, audit, and branch drilldowns

### Backend Needed
- Organization workspace contracts

### Priority
High

### Status
Blocked

## Immediate Execution Queue

1. Fix shared runtime chrome for backend-driven modules:
   - header actions
   - search
   - tabs
   - filters
   - refresh
2. Add request-aware workspace reload path through controller, repository, remote data source, and backend query params.
3. Add backend action metadata for backend-driven modules so visible buttons stop using empty callbacks.
4. Add drilldown metadata for KPI/cards/tables/timeline in backend-driven modules.
5. Replace or remove remaining dead controls in prototype-only modules until their backend workspace contracts exist.
