# SHIELD Admin Portal Design Specification v1.0

Date: 2026-07-03
Status: Approved for implementation
Primary owner: SHIELD platform product and frontend implementation

## Purpose

This document is the single source of truth for the SHIELD Admin Portal V1. The Admin Portal is not another isolated portal. It is the control center for the SHIELD platform and the parent operational workspace for governance, operations, growth, verification, compliance, and platform controls.

This spec translates the current SHIELD repo direction into one coherent enterprise application contract so implementation can follow a stable product blueprint instead of page-by-page redesign.

## Grounding Sources

- `AGENTS.md`
- `current_schema.md`
- `docs/SHIELD Portal Navigation Map.md`
- `docs/SHIELD Module-to-Portal Visibility Matrix.md`
- `docs/SHIELD Master Data Ownership Matrix.md`
- `docs/SHIELD Backend Domain Boundaries.md`
- `frontend/lib/features/portal/presentation/portal_role_data.dart`
- `frontend/lib/features/portal/presentation/screens/portal_shell.dart`
- `backend/src/*` domain modules

## Product Positioning

The Admin Portal should feel like a mix of:

- Salesforce for customer and staff workspaces
- HubSpot for master-detail CRM flow
- Stripe Dashboard for ledger and transaction confidence
- Linear for operational clarity and density
- Notion and Monday.com for structured control surfaces and workflow orchestration

The result must still feel like SHIELD:

- healthcare operations
- membership-driven ecosystem
- wallet and rewards governance
- centralized document verification
- branch and provider network oversight

## Platform Direction

The Admin Portal is no longer a UI-first collection of screens. It is now a platform-first internal application framework.

The directional shift is:

- freeze infrastructure
- build the admin engine
- define contracts
- implement modules

The old direction of screen-first placeholders and later backend wiring should be treated as deprecated.

## Core Principles

1. The Admin Portal is one workspace, not a loose collection of pages.
2. Navigation is grouped and intentional; nothing becomes a dumping ground.
3. Backend domains remain the source of truth for business semantics.
4. Admin screens are command-center oriented, not task-list oriented like the Agent Portal.
5. Customer, provider, wallet, and pricing domains stay centralized and are never duplicated into ad hoc admin-only logic.
6. Timeline, activity, auditability, and status semantics should be visible everywhere.
7. Dense enterprise layouts are preferred over airy consumer spacing.
8. The portal is desktop-first and optimized for 1280px to 1440px operations use.
9. Shared engine infrastructure should own rendering, state, and action patterns; business rules stay in modules and backend services.
10. No production-facing admin module should depend on fake analytics, fake telemetry, or placeholder operational datasets.

## Admin Engine Architecture

The frontend foundation should be treated as an admin engine composed of six subsystems:

1. Layout Engine
2. Workspace Engine
3. Data Engine
4. Action Engine
5. Form Engine
6. Permission Engine

The detailed subsystem contract lives in:

- `docs/superpowers/specs/2026-07-04-shield-admin-engine-architecture.md`

## Registry and Plugin Model

The admin platform should be registry-driven.

- navigation should resolve workspaces through a registry
- new modules should behave like plugins instead of requiring direct sidebar rewrites
- workspace definitions should describe module structure, actions, forms, filters, and view modes
- the engine should render those definitions consistently

This keeps SHIELD extensible for future modules such as diagnostics, pharmacy, insurance, claims, and specialized provider operations.

## Primary User Roles

Admin Portal V1 is primarily for:

- `ADMIN` as the super-admin shell owner
- future central operations leads
- commercial and platform admins
- managers and specialized internal operators via later visibility constraints

V1 frontend shell taxonomy remains `super-admin`, but the page architecture must already anticipate delegated operators.

## Information Architecture

### Level 1 Navigation

```text
Dashboard

Operations
  Customers
  Agents
  CRM
  Visits
  Documents

Business
  Memberships
  Wallet
  Rewards
  Referral Network

Providers
  Providers
  Services
  Availability

Organization
  Branches
  Employees
  Roles

Analytics
  Reports
  Insights
  Audit Logs

System
  Notifications
  Settings
  Platform
```

### Navigation Rules

- Sidebar groups are always visible in expanded mode.
- Collapsed mode keeps icons and tooltips only.
- Each top-level module contributes its internal structure through workspace definitions and registry metadata.
- Cross-linking between modules should preserve context where possible, especially customer, provider, and agent references.

## Screen Inventory

### Dashboard

- Executive Dashboard
- Operational Dashboard
- Activity Feed
- Alerts Center

### Customers

- Customer List
- Customer Workspace
- Customer Timeline
- Wallet Surface
- Membership Surface
- Documents Surface
- Visits Surface
- Medical Records Surface
- Referral Tree Surface
- Notes Surface
- Activity Log Surface

### Agents

- Agent List
- Agent Workspace
- Customers Surface
- Performance Surface
- Follow-Ups Surface
- Visits Surface
- Attendance Surface
- Documents Surface
- Timeline Surface

### CRM

- Call Queue
- Today Work
- Escalations
- Performance

### Visits

- Master Calendar
- Agenda
- Provider Schedule
- Customer Visit View

### Documents

- Verification Queue
- Preview Workspace
- Approval Surface
- Rejection Surface
- Audit History

### Memberships

- Plan Library
- Pricing Rules View
- Benefits View
- Renewals View
- Usage View
- Expiry View

### Wallet

- Ledger Overview
- Transactions
- Recharge Requests
- Adjustments
- Rewards Credit View

### Rewards

- Reward Rules
- Campaigns
- Redemption Rules
- Points Performance

### Referral Network

- Referral Tree
- Reward Progress
- Campaign Analytics
- Conversion View

### Providers

- Provider List
- Provider Workspace
- Services View
- Availability View
- Bookings View
- Reviews View
- Documents View
- Timeline View

### Services

- Service Catalog
- Eligibility and Benefit Controls
- Provider Mapping
- Commercial Rule Visibility

### Availability

- Provider Calendar
- Branch Capacity
- Slot Health
- Escalation Queue

### Branches

- Branch List
- Branch Performance
- Employees
- Providers
- Customers

### Employees

- User Directory
- Session Visibility
- Device Visibility
- Access Status

### Roles

- Role Catalog
- Permission Matrix
- Scope View
- Assignment Health

### Reports

- Report Builder
- Saved Reports
- Export History
- Scheduled Reports

### Insights

- KPI Trends
- Branch Comparison
- Growth and Retention
- Funnel and Compliance

### Audit Logs

- Activity Log
- Security Log
- Login History
- Configuration Change History

### Notifications

- Internal Inbox
- Broadcast Drafts
- Scheduled Messages
- Delivery Health

### Settings

- Company
- Branding
- Notifications
- Security
- API
- Storage
- Feature Flags

### Platform

- Runtime Health
- Integration Status
- Storage Usage
- Background Job and Queue Status

## Design System

### Layout Patterns

- persistent grouped left sidebar
- compact page headers instead of large hero banners
- sticky filter and command bars for data-heavy modules
- master-detail split workspaces
- right-side detail and approval panels
- timeline-first history areas
- command strips for high-frequency actions
- data tables only where tabular comparison matters
- right-side drawers for detail, editing, and workflow follow-up where possible

### Density

- tighter than Agent Portal
- reduced vertical whitespace
- smaller section gaps
- denser cards and tables
- 1280px laptop optimized by default

### Typography

- strong dark page titles
- compact supporting descriptions
- smaller helper text
- much clearer contrast between title, summary, meta, and caption layers

### Semantic Colors

- Blue: primary navigation, platform actions, neutral priority
- Green: active, healthy, completed
- Yellow: pending, caution
- Orange: waiting, needs action
- Red: overdue, rejected, critical
- Purple: rewards, referral value
- Teal: visits, care activity, schedules

### Surface Rules

- cards reserved for summaries, key entities, and compact modules
- heavy workflows prefer panels and split workspaces over stacked cards
- avoid nested rounded rectangles unless hierarchy truly requires it
- use whitespace, subtle dividers, and horizontal structure before adding more borders
- avoid marketing-style hero cards and decorative placeholder dashboards in governance and system modules

### Design Tokens

The admin engine should consume shared tokens for:

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

## Reusable Component Library

- Admin Console Page
- Admin Sidebar
- Global Command Toolbar
- Global Search Trigger
- Command Bar
- Stat Card
- Alert Card
- Activity Feed
- Timeline
- Master Table
- Entity List
- Entity Summary Card
- Status Badge
- Filter Bar
- Segment Tabs
- Split Workspace
- Approval Panel
- File Preview Panel
- Comment Thread
- Calendar Surface
- Agenda List
- Permission Matrix
- Report Builder Stepper
- Metric Chart Panel
- Audit Event Row
- Drawer
- Modal
- Confirmation Prompt
- Bulk Action Bar
- Empty State
- Error State
- Loading Skeleton
- Detail Drawer
- Filter Drawer
- Form Renderer
- Workspace Registry
- Workspace State Container

## State Patterns

### Loading States

- section-level skeletons
- table skeleton rows
- side-panel skeletons
- split-workspace loading without layout jumps

### Empty States

- every module needs a designed empty state
- empty states must explain what the operator can do next
- empty states should include one primary CTA and optional secondary action

### Error States

- retry-focused
- show what failed: fetch, permission, dependency, upload, save, approval
- preserve surrounding context where possible instead of blanking the whole page

### Shared Workspace State

Every admin workspace should inherit one shared state model:

- loading
- refreshing
- empty
- error
- permission denied
- offline
- ready

### CRUD Patterns

- create flows use drawers or modal wizards for focused entities
- edit flows preserve the current workspace context
- destructive actions require confirmation with concise impact copy
- detail workspaces should show activity history and author attribution when relevant
- CRUD forms should be definition-driven where possible rather than screen-local handwritten implementations

### Search Patterns

- universal global search in the shell header
- module-level search in tables and entity lists
- customer, provider, agent, visit, branch, membership, and report references should be searchable

### Filter Patterns

- sticky module filter bars
- quick chips for the common states
- advanced filters expand inline or in a side panel

### Timeline Patterns

- timeline-first for customer, agent, provider, and audit-centered flows
- newest-first by default
- each event shows timestamp, event type, actor, and outcome

### Approval Workflow Patterns

- queue list
- selected item preview
- decision panel
- approval notes
- audit trail
- next-item progression

### Action Lifecycle Patterns

High-trust actions should follow one shared lifecycle:

`Action -> Permission -> Validation -> Confirmation -> Event -> API -> Audit -> Refresh -> Toast`

This keeps destructive and compliance-sensitive workflows consistent.

## RBAC Visibility Matrix

V1 frontend scope centers on `super-admin`, but structure should prepare delegated access.

| Module | Primary V1 Visibility | Future Delegation Direction |
| --- | --- | --- |
| Dashboard | Super Admin | Manager, executive |
| Customers | Super Admin | CRM, manager |
| Agents | Super Admin | manager |
| CRM | Super Admin | CRM lead |
| Visits | Super Admin | manager, central ops |
| Documents | Super Admin | document verification ops |
| Memberships | Super Admin | central ops |
| Wallet | Super Admin | finance or commercial ops |
| Rewards | Super Admin | commercial ops |
| Referral Network | Super Admin | growth ops |
| Providers | Super Admin | provider ops |
| Services | Super Admin | commercial ops |
| Availability | Super Admin | provider ops |
| Branches | Super Admin | org admins |
| Employees | Super Admin | org admins |
| Roles | Super Admin | platform security admins |
| Reports | Super Admin | manager, executive |
| Insights | Super Admin | manager, executive |
| Audit | Super Admin | security and compliance admins |
| Notifications | Super Admin | central ops |
| Settings | Super Admin | platform admins |
| Platform | Super Admin | platform admins |

## Backend Domain Mapping

| Admin Module | Backend Domain |
| --- | --- |
| Customers | `customer` |
| Agents | `agent` |
| CRM | `crm` |
| Visits | `appointment` |
| Documents | `document` + `storage` |
| Memberships | customer and membership-backed tables |
| Wallet | `wallet` |
| Rewards | `pricing` + `referral` + `wallet` |
| Referral Network | `referral` |
| Providers | `service-provider` |
| Services | `pricing` + service master data |
| Availability | provider metadata plus appointment domain |
| Branches | `master-data` + business entities |
| Employees | `auth` |
| Roles | `auth` |
| Reports | `dashboard` plus analytics layer later |
| Insights | `dashboard` plus analytics layer later |
| Audit | `auth`, audit tables, timeline surfaces |
| Notifications | `notification` |
| Settings | `platform-metadata`, `pricing`, `master-data`, notification config |
| Platform | `platform-metadata`, `platform-capabilities`, infra status surfaces |

## Backend Contract Standards

Admin endpoints should align on one shared response envelope:

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

- use consistent pagination metadata
- expose filter metadata in predictable structure
- expose permission metadata where a workspace needs action or field gating
- avoid controller-specific response drift across admin modules

## Database Entity Mapping

### Core operational entities

- `customers`
- `memberships`
- `shield_cards`
- `wallets`
- `auth_sessions`
- `users`
- `roles`
- `permissions`
- `businesses`
- `departments`
- `service_providers`
- `provider_profiles`
- `appointments`
- `documents`
- `notifications`
- `crm_tasks`
- `crm_activities`
- `complaints`
- `pricing_rule_audits`
- `reward_point_rules`
- `reward_redemption_rules`
- `service_benefit_rules`
- `referral_reward_events`

### Derived or read-only admin surfaces

- branch performance comparisons
- follow-up completion snapshots
- growth, retention, and conversion analytics
- ledger health summaries
- document verification queues

## Responsive Behavior

- desktop-first baseline at 1440px
- strong support for 1280px laptops
- grouped sidebar collapses to icon rail
- split workspaces stack at narrow desktop widths
- large tables support horizontal scrolling rather than truncating critical data
- command bars wrap gracefully without breaking hierarchy
- no mobile-first assumptions for admin workspaces

## Accessibility Rules

- all statuses require text plus color
- primary actions need consistent button hierarchy
- large target sizes remain valid even with denser layouts
- keyboard focus order follows workspace priority
- filter bars, tabs, and tables must remain understandable to screen readers

## Implementation Order

1. Freeze authentication, routing, session, and portal resolution
2. Build the Admin Engine foundation and design token system
3. Define workspace, table, form, filter, and action contracts
4. Standardize backend DTOs, pagination, filtering, permissions, and audit events
5. Deliver production modules in this order:
   - Settings
   - Platform
   - Audit
   - Notifications
6. Expand into core operational modules:
   - Customers
   - Agents
   - CRM
   - Wallet
   - Providers
   - Documents
7. Move into performance, observability, caching, testing, and production hardening

## V1 Delivery Boundary

V1 must deliver:

- the complete grouped Admin Portal IA in the app
- every top-level module represented as a coherent workspace
- reusable admin design language
- state-ready surfaces for loading, empty, and error treatment
- frontend structure that can absorb live backend wiring without redesign

V1 does not require:

- final production analytics engines
- full live CRUD wiring for every admin control outside the first production module wave
- final delegated non-admin access setup

## Definition of Done

The Admin Portal V1 is done when:

- the full shell navigation is live
- all top-level modules exist in the portal
- screens follow one shared admin design language
- the blueprint, plan, and app structure align
- no existing agent, provider, or customer experiences are regressed
