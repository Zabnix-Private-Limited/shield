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
- Buttons now render only when a real callback is resolved
- Refresh and some tab/filter-targeted actions execute through `AdminWorkspaceController`
- Backend-authored action descriptors, form metadata, and bulk actions now execute for the customer workspace
- Affects all backend-rendered modules

### Expected Behaviour
- Dispatch real workspace action metadata
- Refresh, navigate, open drawer/dialog, or mutate through runtime
- Hide when action contract is absent

### Backend Needed
- Already exists for customers
- Still needed for the remaining workspaces

### Priority
Critical

### Status
Partial

### Component
Toolbar search

### Current State
- Visible
- Shared owner
- Real text input in `admin_search_bar.dart`
- Debounced workspace reload through controller
- Clear action supported

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
Completed

### Component
Toolbar tabs

### Current State
- Visible
- Shared owner
- Real tab selection
- Active tab state stored in workspace controller
- Repository reload executes through runtime

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
Completed

### Component
Filter chips

### Current State
- Visible
- Shared owner
- Real selection in `admin_filter_bar.dart`
- Filter state stored in workspace controller
- Repository reload executes through runtime

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
Completed

### Component
Entity cards, KPI cards, timeline rows, empty-state actions, data-table headers/rows

### Current State
- Visible across multiple modules
- Shared owner
- Table rows can now sort, paginate, bulk-select, export the current view, and select a live record in backend-driven workspaces
- Entity cards and KPI drilldowns still depend on backend action metadata
- Empty-state CTA remains refresh-oriented rather than workflow-specific

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
Partial

## Dashboard

### Component
Header actions

### Current State
- Backend data exists
- Buttons render from backend labels
- Refresh and inferred tab/filter actions execute
- No explicit backend action descriptor contract yet

### Expected Behaviour
- `Refresh workspace`
- `Open approvals` / `Open activity` through runtime action metadata

### Backend Needed
- Action descriptors for dashboard header

### Priority
Critical

### Status
Partial

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
Completed

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
- Backend labels and explicit action descriptors exist
- Refresh executes
- Customer edit, suspend, activate, delete, card generation, print profile, and bulk suspend/activate/export now execute through workspace commands
- Create, merge, assign, and communication workflows are still missing

### Expected Behaviour
- `Create customer`
- `Review approvals`
- `Export current view`

### Backend Needed
- Additional action descriptors and command metadata for create, assignment, merge, and outreach workflows

### Priority
Critical

### Status
Partial

### Component
Customer command platform

### Current State
- Backend-owned action descriptors are returned in the workspace payload
- Dynamic edit form metadata is returned from `/admin/workspaces/customers/forms/edit`
- Single-record and bulk mutation commands execute through `/admin/workspaces/customers/actions/*` and `/admin/workspaces/customers/bulk-actions/*`
- Shared Flutter renderer now opens confirmation dialogs, dynamic forms, and bulk action bars from backend metadata

### Expected Behaviour
- Render customer actions from backend metadata only
- Load forms dynamically
- Execute commands through the shared action pipeline
- Refresh workspace after successful mutations

### Backend Needed
- Already exists for the current customer action set
- Remaining customer workflows still need published command descriptors

### Priority
Critical

### Status
Completed

### Component
Search, tabs, filters

### Current State
- Backend contract exists
- Shared toolbar search, tab switching, and status filters all reload the workspace through the repository/runtime path

### Expected Behaviour
- Search customers by name, code, membership, wallet, CRM signals, and email
- Switch tabs such as `Profile`, `Wallet`, `Membership`, `Referrals`, `Family`, `Documents`, `Medical Records`, `Visits`, `Timeline`, `Activity Log`, `Notes`, `CRM`, `Services Used`, `Lab Reports`, `Prescriptions`
- Filter by `ACTIVE`, `INACTIVE`, `PENDING`, `SUSPENDED`, `REJECTED`

### Backend Needed
- Already exists

### Priority
Critical

### Status
Completed

### Component
Customer list table

### Current State
- Visible
- Backend-owned rows
- Server-backed selection, sorting, and pagination are live
- Bulk selection is live for the current view
- Current-view export is live

### Expected Behaviour
- Search and filter through runtime query state
- Sort columns through backend query contract
- Paginate through backend query contract
- Select one or many rows
- Export current filtered view

### Backend Needed
- Already exists for current query state
- Bulk mutation command metadata still needed for multi-record actions

### Priority
Critical

### Status
Completed

### Component
Customer detail tabs

### Current State
- Visible
- Selected customer drives tab-specific backend detail content
- Profile, wallet, membership, referrals, family, documents, medical records, visits, timeline, activity log, notes, CRM, services used, lab reports, and prescriptions now render from live backend data

### Expected Behaviour
- Selecting a customer updates the detail workspace
- Switching tabs reloads tab-specific customer data
- Tabs should remain command-capable as customer mutations are added

### Backend Needed
- Already exists for read surfaces
- Customer command/action descriptors still needed for edit/suspend/activate/delete and related workflows

### Priority
Critical

### Status
Completed

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
- Backend workspace contract exists
- Shared runtime renderer is active
- Refresh and inferred tab/filter actions execute
- Explicit create/renewal command metadata is still missing

### Expected Behaviour
- Create plan
- Review renewals

### Backend Needed
- Action descriptors and mutation commands

### Priority
Critical

### Status
Partial

### Component
Plan cards and health rows

### Current State
- Backend data renders through shared runtime
- Search, filters, refresh, and tab switching are live
- No plan/detail row navigation or mutation contract yet

### Expected Behaviour
- Open plan detail
- Filter renewals
- Open expiry/audit queues

### Backend Needed
- Row action metadata and mutation commands

### Priority
Critical

### Status
Partial

## Agents

### Component
Header actions

### Current State
- Backend workspace contract exists
- Shared runtime renderer is active
- Refresh and inferred tab/filter actions execute
- Explicit add/assign command metadata is still missing

### Expected Behaviour
- Add agent
- Assign branch

### Backend Needed
- Action descriptors and mutation commands

### Priority
Critical

### Status
Partial

### Component
Section tabs

### Current State
- Backend-driven shared tabs
- Selection reloads repository through runtime

### Expected Behaviour
- Switch overview, customers, performance, follow-ups, visits, attendance, documents, timeline

### Backend Needed
- Already exists

### Priority
Critical

### Status
Completed

### Component
Agent cards, KPI strip, detail rows, timeline

### Current State
- Backend data renders through shared runtime
- No selection, drilldown, or navigation metadata yet

### Expected Behaviour
- Open agent workspace
- Drill into assigned customers, visits, follow-ups, attendance, and documents

### Backend Needed
- Agent list/detail/timeline contract

### Priority
Critical

### Status
Partial

## Providers

### Component
Header actions

### Current State
- Backend workspace contract exists
- Shared runtime renderer is active
- Refresh and inferred tab/filter actions execute

### Expected Behaviour
- Add provider
- Map branch

### Backend Needed
- Action descriptors and mutation commands

### Priority
Critical

### Status
Partial

### Component
Section tabs

### Current State
- Backend-driven shared tabs
- Selection reloads repository through runtime

### Expected Behaviour
- Switch profile, availability, services, bookings, reviews, documents, timeline, payments

### Backend Needed
- Already exists

### Priority
Critical

### Status
Completed

### Component
Provider cards, KPI strip, timeline

### Current State
- Backend data renders through shared runtime
- No detail or navigation metadata yet

### Expected Behaviour
- Open provider workspace
- Drill into bookings, availability, compliance, documents, reviews

### Backend Needed
- Provider list/detail/timeline contract

### Priority
Critical

### Status
Partial

## Wallet

### Component
Header actions

### Current State
- Backend workspace contract exists
- Shared runtime renderer is active
- Refresh and inferred tab/filter actions execute

### Expected Behaviour
- Post adjustment
- Review audits

### Backend Needed
- Action descriptors and mutation commands

### Priority
Critical

### Status
Partial

### Component
Ledger summary rows and transaction timeline

### Current State
- Backend data renders through shared runtime
- Search, filters, refresh, and tab switching are live
- No transaction drilldown or export action metadata yet

### Expected Behaviour
- Open ledger detail
- Filter by sub-ledger and status
- Navigate to transaction/audit/customer

### Backend Needed
- Wallet ledger and transaction contract

### Priority
Critical

### Status
Partial

## Documents

### Component
Header actions

### Current State
- Backend workspace contract exists
- Shared runtime renderer is active
- Refresh and inferred tab/filter actions execute

### Expected Behaviour
- Approve selected
- Request resubmission

### Backend Needed
- Action descriptors and mutation commands

### Priority
Critical

### Status
Partial

### Component
Section tabs

### Current State
- Backend-driven shared tabs
- Selection reloads repository through runtime

### Expected Behaviour
- Switch pending, approved, rejected, expired, resubmission

### Backend Needed
- Already exists

### Priority
Critical

### Status
Completed

### Component
Queue cards, preview actions, decision cards, audit timeline

### Current State
- Backend queue, extraction, and processing data render through shared runtime
- No preview selection, mutation, or audit navigation metadata yet

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
Partial

## CRM

### Component
Header actions

### Current State
- Backend workspace contract exists
- Shared runtime renderer is active
- Refresh and inferred tab/filter actions execute

### Expected Behaviour
- Open escalations
- Assign campaign

### Backend Needed
- Action descriptors and mutation commands

### Priority
Critical

### Status
Partial

### Component
Queue tiles and performance rows

### Current State
- Backend queue and activity data render through shared runtime
- Filtering is live
- Queue navigation and ownership actions are still missing

### Expected Behaviour
- Open queue detail
- Filter by branch/owner/status
- Dispatch assignment workflows

### Backend Needed
- CRM queue/performance contract

### Priority
Critical

### Status
Partial

## Reports

### Component
Header actions

### Current State
- Backend workspace contract exists
- Shared runtime renderer is active
- Refresh and inferred tab/filter actions execute

### Expected Behaviour
- Run report
- Save template

### Backend Needed
- Action descriptors and export/schedule commands

### Priority
Critical

### Status
Partial

### Component
Builder steps and saved report queue tiles

### Current State
- Backend report catalog and history render through shared runtime
- Search and refresh are live
- Builder, preview, export, and schedule workflows are still missing

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
Partial

## Settings

### Component
Header actions

### Current State
- Backend labels exist
- Refresh and inferred tab/filter actions execute
- Explicit reset/session/configuration command metadata is still missing

### Expected Behaviour
- Open reset/session/configuration workflows through runtime

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Partial

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
Completed

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
- Refresh and inferred tab/filter actions execute
- Explicit integration/runtime command metadata is still missing

### Expected Behaviour
- Inspect report engine
- Review integrations

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Partial

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
Completed

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
- Refresh and inferred tab/filter actions execute
- Explicit export/auth-inspection action metadata is still missing

### Expected Behaviour
- Export current view
- Inspect auth events

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Partial

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
Completed

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
- Refresh and inferred tab/filter actions execute
- Explicit send/review action metadata is still missing

### Expected Behaviour
- Send in-app alert
- Review delivery devices

### Backend Needed
- Action descriptors

### Priority
Critical

### Status
Partial

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
Completed

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
- Branches, employees, and roles now load through backend workspace contracts
- Shared runtime search, filters, tabs, and refresh are live
- Row drilldown and mutation metadata are still missing

### Expected Behaviour
- Search, filters, detail workspace, assignment, audit, and branch drilldowns

### Backend Needed
- Row action metadata and mutation commands

### Priority
High

### Status
Partial

## Immediate Execution Queue

1. Add explicit backend action metadata for header buttons, row actions, KPI drilldowns, and timeline navigation.
2. Extend the shared workspace contract with row targets, bulk actions, pagination metadata, and mutation descriptors.
3. Replace inference-based header actions with backend-authored commands.
4. Add reports builder/export/schedule workflow contracts to move reports from catalog-only to operational workflow.
