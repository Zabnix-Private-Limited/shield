# SHIELD Full Portal UI/UX Audit
Date: 2026-07-06
Repository: `E:\K4NN4N\shield`
Scope: frontend portal pages, shared shell, shared renderers, user-facing data presentation
Auditor stance: blunt, repo-grounded, no sugar coating
Target reader: engineering, product, design, platform leadership

## 1. Audit Intent
- This report audits the actual SHIELD frontend surfaces that exist in the repository.
- This report is not a design fantasy document.
- This report is not a generic dashboard best-practice memo.
- This report is based on the current portal structure, screen ownership, shared shell, shared runtime, and visible UI patterns in code.
- This report is intentionally direct.
- If a screen is weak, it is called weak.
- If a screen is architecturally dead, it is called dead.
- If a screen has good foundations, it is credited.
- If a screen still behaves like a demo, it is called a demo.

## 2. Files and Surfaces Inspected
- `frontend/lib/features/portal/presentation/screens/portal_shell.dart`
- `frontend/lib/features/portal/presentation/portal_role_data.dart`
- `frontend/lib/features/admin/presentation/screens/admin_portal_workspace.dart`
- `frontend/lib/features/admin/shared/presentation/widgets/admin_backend_workspace_module.dart`
- `frontend/lib/features/admin/shared/controllers/admin_workspace_controller.dart`
- `frontend/lib/features/admin/shared/components/admin_data_table.dart`
- `frontend/lib/features/admin/shared/components/admin_console_toolbar.dart`
- `frontend/lib/features/admin/shared/components/admin_workspace_header.dart`
- `frontend/lib/features/admin/shared/layout/admin_page.dart`
- `frontend/lib/features/provider/customers/presentation/screens/provider_customers_screen.dart`
- `frontend/lib/features/provider/shared/presentation/controllers/provider_portal_controller.dart`
- `frontend/lib/features/agent/shared/presentation/controllers/agent_portal_controller.dart`
- Admin screen files under `frontend/lib/features/admin/**/presentation/screens/`
- Agent screen files under `frontend/lib/features/agent/**/presentation/screens/`
- Provider screen files under `frontend/lib/features/provider/**/presentation/screens/`
- Customer screen files under `frontend/lib/features/customer/**/presentation/screens/`

## 3. Evidence Summary
- `portal_shell.dart` is still a massive multi-role branching surface at more than ten thousand lines.
- The admin portal is the cleanest architectural path because it routes through a shared runtime and backend-driven workspace contracts.
- The provider portal still carries heavy screen-specific ownership and a large monolithic customer screen.
- The agent portal is functionally broader than the customer portal but still heavily screen-specific.
- The customer portal is simpler and more coherent visually, but less operationally dense.
- Placeholder-style wording has decreased in admin, but empty-state dependency is still high across agent, provider, and customer.
- Debug logging still exists in multiple user-facing runtime paths.
- There are still many places where the frontend shows data structures instead of polished product language.

## 4. Rating Scale
- `GOOD`
- `OK`
- `WEAK`
- `BAD`
- `DEAD`

## 5. Meaning of Ratings
- `GOOD` means the screen is structurally healthy, user-comprehensible, and close to production expectations.
- `OK` means the screen works but needs meaningful UX and presentation refinement.
- `WEAK` means the screen has value but still feels fragile, incomplete, overly technical, or visually unrefined.
- `BAD` means the screen actively harms usability through density problems, unclear actions, poor ownership, or inconsistent interaction behavior.
- `DEAD` means the architecture or screen pattern should not be expanded further in its current form.

## 6. Executive Truth
- The admin platform is ahead of the rest of the product in architecture.
- The visual quality across the product is inconsistent.
- The portal shell is too large and too role-aware.
- The user experience is still split between platform thinking and screen-by-screen thinking.
- The data is often real.
- The product language is not always real.
- The interaction model is not yet consistently product-grade.
- The admin renderer is the strongest foundation.
- The provider customer experience is the weakest large operational surface.
- The customer portal is calmer than the internal portals but still under-polished in readability and data communication.

## 7. Top-Level Findings
- Good architecture does not automatically produce good UX.
- The repository now contains both modern platform patterns and legacy monolith patterns.
- A user-friendly system cannot keep exposing developer-oriented labels, raw timestamps, or fallback-style copy.
- Density is still uneven.
- The hierarchy is still inconsistent.
- The shells use too much space on navigation and not enough on decision surfaces.
- Empty states are numerous and sometimes reasonable, but too often they become the dominant interaction experience.
- Large screens should be split by behavior responsibility, not only by widget extraction.

## 8. Global Problems
- Oversized portal shell ownership
- Mixed architectural generations
- Uneven information density
- Weak copy standards
- Too many empty-state-driven flows
- Inconsistent action placement
- Inconsistent selection behavior
- Poor URL/query persistence discipline
- Limited keyboard ergonomics
- Too much developer-facing tone in internal portals

## 9. Global Solutions
- Shrink cross-role branching in `portal_shell.dart`
- Push more role-specific behavior into reusable portal runtimes
- Standardize display formatting helpers
- Standardize human-readable backend display contracts
- Reduce padding and nested container depth
- Promote table-first layouts for operational modules
- Move record details to drawers or subordinate tabs
- Persist query state
- Add debounced search everywhere
- Introduce stronger UX copy rules

## 10. Cross-Portal Verdict
- Shared runtime direction: `GOOD`
- Shared shell complexity: `BAD`
- Shared language consistency: `WEAK`
- Shared data readability: `WEAK`
- Shared responsiveness: `OK`
- Shared action ergonomics: `WEAK`
- Shared performance posture: `OK`
- Shared accessibility posture: `WEAK`

## 11. Cross-Portal Problems and Solutions
### Problem
- The product has multiple portal families that do not feel designed by one system.
### Solution
- Create one interaction grammar for search, filters, actions, empty states, details, and tables across all internal portals.

### Problem
- The portal shell still acts like a mega-router plus presentation owner.
### Solution
- Cut the shell down to navigation, framing, and role-to-runtime resolution only.

### Problem
- Too many screens are technically live but emotionally untrustworthy.
### Solution
- Remove copy that sounds like a fallback, a schema, or a dev note.

### Problem
- Internal surfaces overuse islands of cards.
### Solution
- Favor workspace slabs, split panes, drawers, and tabbed detail regions over decorative card stacks.

### Problem
- Data formatting is inconsistent.
### Solution
- Add shared formatters for money, phone, date, status, percentages, identifiers, and list summaries.

### Problem
- Tables are not yet fully premium operational grids.
### Solution
- Add denser cells, clearer selection mechanics, sticky headers, stronger row hover/focus states, and column sizing rules.

## 12. Portal Shell Audit
### Surface
- `frontend/lib/features/portal/presentation/screens/portal_shell.dart`
### Verdict
- `BAD`
### Truth
- This file is too large.
- This file still owns too much branching.
- This file is a sign that the platform is in transition, not finished.
### Good
- It centralizes high-level portal composition.
- It handles customer and internal roles in one place.
- It already supports collapsible internal sidebar behavior.
- It bridges live admin runtime and legacy role screens.
### OK
- It gracefully retries and shows loading/error states.
- It distinguishes customer shell behavior from internal shell behavior.
- It contains a clear role-content dispatch mechanism.
### Bad
- The file is structurally oversized.
- The file mixes navigation, data loading, view routing, page framing, portal content composition, and lots of legacy hand-built views.
- The file is difficult to reason about safely.
- The file is not a maintainable long-term owner for product-level UX.
### Dead
- Expanding this file as the main way to add portal behavior is dead architecture.
### Problems
- Massive conditional branching by role and section
- Hard-to-trace UI ownership
- Mixed generations of UI patterns
- Reduced testability
- High regression risk
- Harder performance profiling
- Harder copy normalization
- Harder consistency enforcement
### Solutions
- Split shell responsibilities
- Move role content maps into isolated owners
- Keep shell limited to frame plus route plus sidebar
- Extract provider and agent runtime paths
- Stop embedding large custom enterprise views here
- Reduce direct screen import sprawl
- Introduce explicit shell contracts
- Add shell-level navigation state persistence
### Priority
- Critical

## 13. Portal Navigation Audit
### Surface
- Internal sidebar and role navigation composition
### Verdict
- `WEAK`
### Good
- Collapsible internal sidebar exists
- Navigation structure is at least centralized
- Icon mapping is broad
### Bad
- Sidebar still takes too much attention relative to workspace
- Section summaries can be too verbose
- Navigation and content hierarchy are not always balanced
### Problems
- Width use
- Too much descriptive text
- Weak compression for expert users
- Limited quick-jump ergonomics
### Solutions
- Narrow default width
- Add compact mode by default
- Add search or command palette for sections
- Use summary text selectively, not everywhere
### Priority
- High

## 14. Cross-Portal Data Language Audit
### Verdict
- `WEAK`
### Truth
- SHIELD still sometimes talks like a codebase.
- It needs to talk like a product.
### Good
- Backend-driven admin contracts are moving in the right direction.
### Bad
- Raw identifiers
- Raw timestamps
- Literal fallback tone
- Technical empty-state phrasing
- Inconsistent capitalization
### Solutions
- One display-language spec
- One date/time spec
- One currency spec
- One action-label spec
- One empty-state spec

## 15. Cross-Portal Performance Audit
### Verdict
- `OK`
### Good
- Shared admin runtime has caching
- Query-driven admin reload path is clear
- Customer controllers are relatively modest
### Bad
- Large monolithic screens remain
- Many stateful screens use full reloads
- Search debounce is not universally enforced
- Heavy `notifyListeners` patterns remain in complex controllers
### Solutions
- Debounced search
- Partial panel refreshes
- Smaller screen owners
- Better memoization of derived display data
- Less shell-level rebuild pressure

## 16. Cross-Portal Accessibility Audit
### Verdict
- `WEAK`
### Good
- Flutter base controls help
- Tabs, buttons, and lists exist in accessible primitives in many places
### Bad
- Focus behavior is not clearly standardized
- Keyboard-first operational use is not a first-class design target yet
- Visual density improvements must preserve tap size and contrast
### Solutions
- Keyboard shortcut map
- Focus ring rules
- Semantic labels on row actions
- Row/checkbox behavior separation

## 17. Admin Portal Family Overview
### Verdict
- `GOOD` architecture
- `OK` UX foundation
- `WEAK` consistency in business depth
### Truth
- The admin platform is the best candidate for becoming the product-wide UI standard.
- It is not finished.
- It is the strongest base.

## 18. Admin Shared Runtime
### Surface
- `admin_workspace_controller.dart`
- `admin_backend_workspace_module.dart`
- `admin_data_table.dart`
- `admin_console_toolbar.dart`
- `admin_workspace_header.dart`
- `admin_page.dart`
### Verdict
- `GOOD`
### Good
- Real runtime model
- Query-driven state
- Shared action pipeline
- Shared repository flow
- Shared empty/error/offline states
- Shared table, toolbar, header, metrics, detail panel model
### OK
- Action menus are better than permanent noisy buttons
- Panels are structured
- Forms are runtime-driven
### Weak
- Search should be debounced
- Query state should persist in URL
- Copy still needs cleanup
- Detail pane presentation still needs stronger ergonomics
### Bad
- Too many fallback phrases still leak into user-facing text
- Table utility bar still feels basic rather than enterprise-grade
### Solutions
- Debounce search
- Persist query state
- Improve utility bar wording
- Add stronger grid ergonomics
- Add keyboard support

## 19. Admin Dashboard
### Path
- `frontend/lib/features/admin/dashboard/presentation/screens/admin_dashboard_module.dart`
### Verdict
- `OK`
### Good
- Lives inside the admin runtime direction
- Can benefit from shared renderer improvements
- Better than a static bespoke page
### OK
- Good surface for backend-owned metrics and operational posture
### Weak
- Still depends on the quality of emitted labels and layout density
- Risk of becoming a card farm again if not controlled
### Bad
- If widgets are not drillable and actionable, they become decorative waste
### Dead
- Decorative summary-card expansion is dead work
### Problems
- Potential KPI drift
- Potential action vagueness
- Potential over-cardification
- Potential whitespace waste
- Potential shallow widget semantics
### Solutions
- KPI drill-downs only
- Fewer cards
- More action routing
- Stronger alert prioritization
- Dense operations-first summary
### Priority
- High

## 20. Admin Customers
### Path
- `frontend/lib/features/admin/customers/presentation/screens/admin_customers_module.dart`
### Verdict
- `GOOD`
### Good
- Best current admin business surface
- Shared runtime ownership
- Search, sorting, pagination, selection, export, details, and command metadata direction are real
- Strongest proof that the new architecture can support actual work
### OK
- The module is already usable
- It is a credible flagship
### Weak
- Copy still needs normalization
- Table should remain the dominant surface
- Detail experience can become more efficient with drawer or tighter lower tabs
### Bad
- Any return to placeholder stats or decorative cards would be regression
### Dead
- Permanent three-column split with overlarge profile pane is dead
### Problems
- Selection semantics were recently fragile
- Table prominence still needs protection
- Detail density can be improved
- Bulk action discoverability can improve
- Badge/filter drill-down clarity can improve
### Solutions
- Keep no default selection
- Sharpen table/drawer detail interaction
- Improve row hover/focus affordance
- Add URL persistence
- Add better saved views
- Improve column alignment and data scanning
### Priority
- Critical

## 21. Admin Agents
### Path
- `frontend/lib/features/admin/agents/presentation/screens/admin_agents_module.dart`
### Verdict
- `OK`
### Good
- Registered in the admin runtime direction
- Can inherit shared improvements
### OK
- Good architectural slot
### Weak
- Business depth is likely behind customer management
- Risk of being structurally modern but operationally thin
### Bad
- If agent actions are not fully wired, the surface becomes misleading
### Dead
- “Agent details only” surfaces are dead end thinking
### Problems
- Insufficient management depth risk
- Possible shallow metrics
- Possible weak attendance/performance workflow UX
- Possible weak customer transfer ergonomics
### Solutions
- Make agent list operationally dense
- Add task-oriented actions
- Improve performance drill-downs
- Clarify branch assignment and customer transfer UX
### Priority
- High

## 22. Admin CRM
### Path
- `frontend/lib/features/admin/crm/presentation/screens/admin_crm_module.dart`
### Verdict
- `WEAK`
### Good
- Sits in the admin runtime ecosystem
### OK
- Can be upgraded through shared renderer patterns
### Weak
- CRM surfaces usually fail when they are list-only and not queue-driven
- If this module does not feel urgent and operational, it will fail users
### Bad
- A CRM surface without strong queue, owner, status, SLA, and next-action clarity is not enough
### Dead
- Generic “records” presentation for CRM is dead
### Problems
- Queue semantics
- Escalation semantics
- Time sensitivity
- Call history readability
- Follow-up action prominence
### Solutions
- Lead queue emphasis
- SLA badges
- Next follow-up countdowns
- Assignment controls
- Timeline-first CRM context
### Priority
- Critical

## 23. Admin Visits
### Path
- `frontend/lib/features/admin/visits/presentation/screens/admin_visits_module.dart`
### Verdict
- `OK`
### Good
- Fits well into shared runtime pattern
### OK
- Visit operations can naturally benefit from table-first layout
### Weak
- Scheduling and status workflows are UX-sensitive
- Needs strong time formatting, provider context, and customer context
### Bad
- Weak timeline or weak filters would make visit ops painful
### Dead
- Decorative visit cards without routing and filtering are dead
### Problems
- Calendar-to-list coherence
- Operational urgency
- Provider/customer linkage
- Visit status readability
### Solutions
- Dense schedule grid
- Strong date chips
- Better visit detail drawer
- Linked customer/provider drill-down
### Priority
- High

## 24. Admin Documents
### Path
- `frontend/lib/features/admin/documents/presentation/screens/admin_documents_module.dart`
### Verdict
- `OK`
### Good
- Shared runtime direction is suitable for review queues
### OK
- Good candidate for split-pane queue plus preview
### Weak
- Documents live or die on preview speed, status clarity, and approval ergonomics
### Bad
- If the page is too card-heavy, verification throughput will suffer
### Dead
- Static document rows without workflow actions are dead
### Problems
- Preview ergonomics
- Metadata readability
- Approval/reject clarity
- Timeline visibility
### Solutions
- Queue-first layout
- Larger preview area
- Strong status timeline
- Side-by-side metadata and actions
### Priority
- High

## 25. Admin Memberships
### Path
- `frontend/lib/features/admin/memberships/presentation/screens/admin_memberships_module.dart`
### Verdict
- `WEAK`
### Good
- Runtime slot exists
### OK
- Could become clean through shared engine patterns
### Weak
- Membership admin needs more than viewing plans
- Lifecycle actions must be first-class
### Bad
- Anything “view only” in memberships is not acceptable
### Dead
- Static plans and summary cards are dead
### Problems
- Renew
- Upgrade
- Downgrade
- Freeze
- Cancel
- Benefits visibility
- Usage clarity
- Transaction linkage
### Solutions
- Lifecycle toolbar
- Table plus detail tabs
- Benefit eligibility section
- Invoice and transaction drill-down
### Priority
- Critical

## 26. Admin Notifications
### Path
- `frontend/lib/features/admin/notifications/presentation/screens/admin_notifications_module.dart`
### Verdict
- `OK`
### Good
- Backend-driven workspace fit is solid
- Queue-style review can work well here
### OK
- Device state and message state can be rendered cleanly
### Weak
- Template/campaign absences need better operator guidance
### Bad
- Internal comms pages feel weak if they lack delivery confidence signals
### Dead
- Notification list without meaningful actionability is dead
### Problems
- Delivery trust
- Device registry clarity
- Read/unread semantics
- Action outcomes
### Solutions
- Channel breakdown
- Retry visibility
- Segment and audience context
- Better delivery-state color hierarchy
### Priority
- Medium

## 27. Admin Branches
### Path
- `frontend/lib/features/admin/organization/presentation/screens/admin_branches_module.dart`
### Verdict
- `WEAK`
### Good
- Administrative master-data domain fits runtime model
### OK
- Can share list-detail patterns
### Weak
- Branch operations need people, providers, performance, and revenue context
### Bad
- A branch page that is only profile-level is weak management software
### Dead
- Branch-as-static-record is dead
### Problems
- Manager visibility
- Staff counts
- Provider availability
- Revenue KPIs
- Linked business operations
### Solutions
- Multi-tab branch workspace
- Performance snapshots
- Linked provider and employee tables
- Better cross-module linking
### Priority
- High

## 28. Admin Employees
### Path
- `frontend/lib/features/admin/organization/presentation/screens/admin_employees_module.dart`
### Verdict
- `WEAK`
### Good
- Correct domain placement
### OK
- Good candidate for dense operational lists
### Weak
- Employee admin requires strong role, branch, shift, and permission clarity
### Bad
- Without lifecycle actions, it is not complete
### Dead
- Read-only employee registry is dead
### Problems
- Role visibility
- Branch assignment
- Status transitions
- Permission mapping
### Solutions
- Better action menus
- More compact people grid
- Shift and assignment summaries
- Permission visibility
### Priority
- High

## 29. Admin Roles
### Path
- `frontend/lib/features/admin/organization/presentation/screens/admin_roles_module.dart`
### Verdict
- `OK`
### Good
- Shared runtime can support this cleanly
### OK
- Good domain for backend-owned permissions
### Weak
- Permission language must be understandable
- Role composition must avoid raw technical jargon
### Bad
- Raw permission keys shown directly are poor UX
### Dead
- Role page as plain string matrix is dead
### Problems
- Permission readability
- Scope explanation
- Inheritance clarity
- Action risk communication
### Solutions
- Humanized permission labels
- Better grouping
- Impact previews
- Assignment drill-downs
### Priority
- Medium

## 30. Admin Providers
### Path
- `frontend/lib/features/admin/providers/presentation/screens/admin_providers_module.dart`
### Verdict
- `WEAK`
### Good
- Runtime direction exists
### OK
- Strong future fit if approvals and status workflows are real
### Weak
- Provider management is usually one of the hardest enterprise modules
### Bad
- If approval, licensing, branch assignment, and commission are shallow, the page is not useful
### Dead
- Provider profile listing without operational workflows is dead
### Problems
- Approval flow
- Service assignment
- Working hours
- License review
- Agreement review
- Commission transparency
### Solutions
- Approval queue
- Better provider detail drawer
- Credential timeline
- Availability tab
- Commission and payment visibility
### Priority
- Critical

## 31. Admin Referrals
### Path
- `frontend/lib/features/admin/referrals/presentation/screens/admin_referrals_module.dart`
### Verdict
- `OK`
### Good
- Domain fits runtime and table patterns
### OK
- Can be useful with status-driven progression
### Weak
- Referral state communication must be crystal clear
### Bad
- Ambiguous reward lifecycle labels will destroy trust
### Dead
- Referral summary without qualification timeline is dead
### Problems
- Qualification state clarity
- Reward timing clarity
- Owner visibility
- Customer linkage
### Solutions
- State timeline
- Better delayed-reward explanation
- Linked customer drill-down
- Reward audit linkage
### Priority
- Medium

## 32. Admin Rewards
### Path
- `frontend/lib/features/admin/rewards/presentation/screens/admin_rewards_module.dart`
### Verdict
- `WEAK`
### Good
- Runtime placement is logical
### OK
- Related naturally to wallet and referrals
### Weak
- Reward systems become confusing fast without clear ledgers and event provenance
### Bad
- A reward page with generic totals is not enough
### Dead
- Rewards as summary-only metrics are dead
### Problems
- Event provenance
- Customer visibility
- Approval path
- Redemption traceability
### Solutions
- Reward event ledger
- Linked customer and referral context
- Stronger approval states
- Better reward type grouping
### Priority
- High

## 33. Admin Services
### Path
- `frontend/lib/features/admin/services/presentation/screens/admin_services_module.dart`
### Verdict
- `WEAK`
### Good
- Central services catalog matters
### OK
- Runtime ownership can keep labels and metadata centralized
### Weak
- Service admin needs taxonomy, pricing, provider fit, and availability rules
### Bad
- A service page that only lists service names is weak
### Dead
- Static catalog pages are dead
### Problems
- Category clarity
- Price ownership
- Provider compatibility
- Business rule visibility
### Solutions
- Better service detail model
- Operational metadata in table
- Provider-eligibility relationships
- Business-rule links
### Priority
- High

## 34. Admin Reports
### Path
- `frontend/lib/features/admin/reports/presentation/screens/admin_reports_module.dart`
### Verdict
- `WEAK`
### Good
- Good domain for backend-owned workflows
### OK
- Could become one of the strongest modules if workflow-based
### Weak
- Report pages often fail by becoming card galleries
### Bad
- Report selection without filter, preview, export, and history flow is not production-grade
### Dead
- Card-grid report chooser is dead
### Problems
- Workflow clarity
- Filter builder
- Column selector
- Preview trust
- Export feedback
- History traceability
- Schedule visibility
### Solutions
- Wizard-like report workflow
- Strong preview step
- Export queue/status
- Saved configurations
- Email and scheduled export states
### Priority
- Critical

## 35. Admin Insights
### Path
- `frontend/lib/features/admin/analytics/presentation/screens/admin_insights_module.dart`
### Verdict
- `OK`
### Good
- Shared runtime supports it
### OK
- Good place for backend analytics composition
### Weak
- Charts without drill-downs are decoration
### Bad
- Insight pages often become beautiful but passive
### Dead
- Static analytics summaries are dead
### Problems
- Drill-down
- Filter persistence
- Dimensional clarity
- Timeframe readability
### Solutions
- Drillable cards
- Better chart legends
- Strong timeframe controls
- Links into operational data
### Priority
- Medium

## 36. Admin Wallet
### Path
- `frontend/lib/features/admin/wallet/presentation/screens/admin_wallet_module.dart`
### Verdict
- `WEAK`
### Good
- Ledger-driven backend rules make this a strong candidate for serious ops UX
### OK
- Shared runtime layout can handle list/detail well
### Weak
- Wallet operations are risky and need excellent clarity
### Bad
- If the wallet page is not ledger-first, it will fail
### Dead
- Balance-summary-first without event detail is dead
### Problems
- Ledger clarity
- Sub-ledger distinction
- Adjustment trust
- Refund flow clarity
- Approval visibility
- Audit visibility
### Solutions
- Ledger-first table
- Clear sub-ledger chips
- Approval queue linkage
- Before/after impact previews
- Better reason capture UX
### Priority
- Critical

## 37. Admin Availability
### Path
- `frontend/lib/features/admin/availability/presentation/screens/admin_availability_module.dart`
### Verdict
- `WEAK`
### Good
- Important operational domain
### OK
- Can benefit from list plus calendar hybrid
### Weak
- Availability UX needs a strong temporal model
### Bad
- Generic rows alone will not communicate resource availability well
### Dead
- Availability as plain list without schedule semantics is dead
### Problems
- Date range readability
- Resource assignment
- Exception handling
- Shift context
### Solutions
- Calendar/list hybrid
- Exception markers
- Better provider and branch filter design
- Dense temporal chips
### Priority
- High

## 38. Admin Settings
### Path
- `frontend/lib/features/admin/settings/presentation/screens/admin_settings_module.dart`
### Verdict
- `OK`
### Good
- Live backend settings are a real strength
- Better than fake settings shells
### OK
- Explicit unavailable domains are honest
### Weak
- Settings copy must stay operator-friendly
- Settings should not read like raw config rows
### Bad
- Too much config language can still scare non-technical admins
### Dead
- Generic key/value admin settings as the final UX is dead
### Problems
- Domain grouping
- Value readability
- Change confidence
- Scope visibility
### Solutions
- Better grouping
- Human-readable value summaries
- Safer editing affordances
- Better “who changed this” visibility
### Priority
- Medium

## 39. Admin Platform
### Path
- `frontend/lib/features/admin/settings/presentation/screens/admin_platform_module.dart`
### Verdict
- `OK`
### Good
- Honest backend health and capability posture is useful
### OK
- This is the right place for platform visibility
### Weak
- Platform pages can become too diagnostic and not enough operational
### Bad
- Overly technical wording will alienate non-engineer admins
### Dead
- Internal platform health as a wall of raw states is dead
### Problems
- Health readability
- Integration clarity
- Actionability
- Business impact linkage
### Solutions
- Better severity hierarchy
- Human-readable health summaries
- Operational next steps
- Distinguish info from incidents
### Priority
- Medium

## 40. Admin Audit
### Path
- `frontend/lib/features/admin/audit/presentation/screens/admin_audit_module.dart`
### Verdict
- `OK`
### Good
- Real audit tables matter
- Searchable audit evidence is strong
### OK
- Good backend fit
### Weak
- Audit pages need very clear actor, before/after, and reason semantics
### Bad
- If it feels like raw logs instead of forensic evidence, trust drops
### Dead
- Audit without mutation context is dead
### Problems
- Field-level readability
- Before/after comparison
- Actor trust
- Filtering ergonomics
### Solutions
- Better diff visualization
- Stronger entity filters
- Sticky context summary
- Better timestamp formatting
### Priority
- High

## 41. Admin Overall Truth
- The admin runtime is the platform to invest in.
- The admin UX is not done.
- Customers is the reference surface.
- Reports, wallet, CRM, memberships, and providers are the highest-value module upgrades.
- The shared renderer should be refined before building more surface-area variety.

## 42. Agent Portal Family Overview
### Verdict
- `WEAK`
### Truth
- The agent portal has more business texture than a demo.
- It is not as clean as the admin runtime path.
- It is more feature-rich than platform-disciplined.

## 43. Agent Architecture
### Surface
- `agent_portal_controller.dart`
- Screen-specific widgets
### Verdict
- `WEAK`
### Good
- Rich domain coverage
- Multiple operational modules exist
### Bad
- Too much screen-specific ownership
- Large screens remain
- Many `Future.microtask` initial loads
- Controller-driven updates are broad, not very surgical
### Solutions
- Pull repeated list/filter/action patterns into shared internal-portal primitives
- Reduce giant screens
- Add better interaction standards

## 44. Agent Dashboard
### Path
- `frontend/lib/features/agent/dashboard/presentation/screens/agent_dashboard_screen.dart`
### Verdict
- `OK`
### Good
- Central operational entry point exists
### OK
- Useful place for KPI and workload framing
### Weak
- Risk of dashboard-over-operations imbalance
### Bad
- If KPI cards are not actionable, they waste space
### Dead
- Dashboard as pretty status wallpaper is dead
### Problems
- Drill-down consistency
- Task prioritization
- Noise control
- Space usage
### Solutions
- Action-first dashboard
- Queue and follow-up prominence
- Better “today” framing
- Stronger metric routing
### Priority
- High

## 45. Agent Customers
### Path
- `frontend/lib/features/agent/customers/presentation/screens/agent_customers_screen.dart`
### Verdict
- `OK`
### Good
- Customer operations exist
- Print flow exists
### OK
- Useful business surface
### Weak
- Needs stronger list/detail interaction standards
- Could easily become crowded
### Bad
- If assignment, notes, and next actions are not clear, the list loses value
### Dead
- Customer screen without next-step affordances is dead
### Problems
- Follow-up action clarity
- Search/filter strength
- Print action placement
- Selection ergonomics
### Solutions
- Better action grouping
- Stronger detail drawer
- More explicit status and next-step chips
- Denser grid
### Priority
- High

## 46. Agent Appointments
### Path
- `frontend/lib/features/agent/appointments/presentation/screens/agent_appointments_screen.dart`
### Verdict
- `OK`
### Good
- Useful operational surface
### OK
- Booking and provider context are meaningful
### Weak
- Provider availability and booking ergonomics are fragile areas
### Bad
- Appointment tools fail fast when availability copy and slot clarity are weak
### Dead
- Appointment card stacks without schedule control are dead
### Problems
- Slot clarity
- Provider availability messaging
- Booking confidence
- Follow-up visibility
### Solutions
- Better date grouping
- Slot density
- Confirmation clarity
- Better exception states
### Priority
- High

## 47. Agent Documents
### Path
- `frontend/lib/features/agent/documents/presentation/screens/agent_documents_screen.dart`
### Verdict
- `WEAK`
### Good
- Documents are present
### OK
- Suitable for operational completion workflows
### Weak
- Empty states appear frequently
- Likely needs stronger queueing and preview
### Bad
- Document workflows feel weak when they are file lists instead of review tasks
### Dead
- Static upload list mentality is dead
### Problems
- Preview
- Classification
- Status
- Ownership
### Solutions
- Better queue structure
- Better metadata summary
- Better document action bar
- Better reason capture on rejection/issue cases
### Priority
- High

## 48. Agent Follow-ups
### Path
- `frontend/lib/features/agent/followups/presentation/screens/agent_followups_screen.dart`
### Verdict
- `WEAK`
### Good
- Correct business domain
### OK
- Can be useful if urgency is visualized well
### Weak
- Follow-up UX is all about time pressure and next action
### Bad
- If it looks like generic tasks, the module underdelivers
### Dead
- Follow-up list without urgency grammar is dead
### Problems
- Due-today clarity
- Missed follow-up state
- Outcome logging
- Call action prominence
### Solutions
- Strong urgency groups
- Better due-state badges
- Outcome capture shortcuts
- Customer context side pane
### Priority
- Critical

## 49. Agent Notifications
### Path
- `frontend/lib/features/agent/notifications/presentation/screens/agent_notifications_screen.dart`
### Verdict
- `WEAK`
### Good
- Needed operational surface
### OK
- Role-specific notifications add value
### Weak
- Notification pages easily become passive inboxes
### Bad
- Passive inboxes are not enough for agent workflows
### Dead
- Notification list without routing and action context is dead
### Problems
- Readability
- Priority
- Routing
- Snooze/resolve semantics
### Solutions
- Better priority chips
- Stronger CTA mapping
- Better grouping by workflow type
- Better read/unread balance
### Priority
- Medium

## 50. Agent Performance
### Path
- `frontend/lib/features/agent/performance/presentation/screens/agent_performance_screen.dart`
### Verdict
- `WEAK`
### Good
- Performance visibility matters
### OK
- Metrics exist
### Weak
- Performance pages often collapse into vanity charts
### Bad
- If numbers lack context or drill-down, the page becomes management theater
### Dead
- Static performance cards are dead
### Problems
- Target context
- Time window clarity
- Drill-down path
- Actionability
### Solutions
- Goal vs actual visual pattern
- Better time filters
- Click-through to customers/tasks
- Exception explanations
### Priority
- Medium

## 51. Agent Referrals
### Path
- `frontend/lib/features/agent/referrals/presentation/screens/agent_referrals_screen.dart`
### Verdict
- `OK`
### Good
- Referral workflows belong here
### OK
- Role fit is strong
### Weak
- Needs very clear reward-stage explanation
### Bad
- Ambiguous referral state language damages trust
### Dead
- Referral counts without journey state are dead
### Problems
- Stage clarity
- Reward timing
- Customer drill-down
- Agent ownership
### Solutions
- Strong stage timeline
- Better stage labels
- Customer and reward linkage
- Better pending-state education
### Priority
- Medium

## 52. Agent Registration
### Path
- `frontend/lib/features/agent/registration/presentation/screens/agent_registration_screen.dart`
### Verdict
- `OK`
### Good
- High business value surface
### OK
- Core lifecycle importance is clear
### Weak
- Registration flows can become long and exhausting fast
### Bad
- If data capture is not chunked and validated well, drop-off rises
### Dead
- One giant form with weak progress guidance is dead
### Problems
- Step clarity
- Validation fatigue
- Document dependency clarity
- Completion confidence
### Solutions
- Better staged flow
- Progress cues
- Better field grouping
- Review step before submit
### Priority
- Critical

## 53. Agent Reports
### Path
- `frontend/lib/features/agent/reports/presentation/screens/agent_reports_screen.dart`
### Verdict
- `WEAK`
### Good
- Reports exist as a concept
### OK
- Useful if targeted to agent role
### Weak
- Empty state indicates report-template maturity is not strong
### Bad
- If reports are unavailable often, the surface becomes dead weight
### Dead
- Report shell with no meaningful templates is dead
### Problems
- Template availability
- Role-specific relevance
- Export trust
- History
### Solutions
- Smaller focused templates
- Better empty-state action
- Saved report presets
- Better export feedback
### Priority
- Medium

## 54. Agent Settings
### Path
- `frontend/lib/features/agent/settings/presentation/screens/agent_settings_screen.dart`
### Verdict
- `WEAK`
### Truth
- The screen is too large.
- A settings screen at more than one thousand lines is a maintainability warning.
### Good
- Broad scope
- Real operational fields
### OK
- Useful business depth
### Weak
- Likely too much in one place
- Risks overwhelming users
### Bad
- Oversized owner
- Potentially mixed concerns
- Hard to keep interaction consistency
### Dead
- Continuing to expand this one screen is dead
### Problems
- Cognitive load
- Too many subdomains
- Hard testing
- Hard consistency
### Solutions
- Break into sections or subroutes
- Better settings IA
- Reusable field groups
- Stronger save-state communication
### Priority
- High

## 55. Agent Overall Truth
- The agent portal contains useful business workflows.
- It does not yet feel like one clean operating system.
- It needs stronger shared patterns and smaller screen ownership.

## 56. Provider Portal Family Overview
### Verdict
- `BAD`
### Truth
- The provider portal has functional ambition.
- It is currently too monolithic and too custom in important places.
- It is the riskiest internal portal from a UX maintainability perspective.

## 57. Provider Architecture
### Surface
- `provider_portal_controller.dart`
- `provider_customers_screen.dart`
### Verdict
- `BAD`
### Good
- Deep provider workflows exist
- Search configuration exists
- Print support exists
### Weak
- Controller is very large
- Screen ownership is very large
- Empty-state fallback text is abundant
### Bad
- `provider_customers_screen.dart` is a giant screen
- Provider patient workspace is doing too much in one owner
- This is not the direction to expand
### Dead
- Growing the provider customer screen further in its current shape is dead architecture
### Solutions
- Split provider patient workspace
- Build shared provider runtime patterns
- Reuse admin-like query and detail primitives

## 58. Provider Dashboard
### Path
- `frontend/lib/features/provider/dashboard/presentation/screens/provider_dashboard_screen.dart`
### Verdict
- `OK`
### Good
- Important role landing surface
### OK
- Can orient providers by queue and today-work
### Weak
- Dashboard value depends on clear workload prioritization
### Bad
- Passive summaries are not enough
### Dead
- Dashboard without next action is dead
### Problems
- Queue emphasis
- Today focus
- Escalation visibility
- Document and prescription urgency
### Solutions
- Worklist-first dashboard
- Queue shortcuts
- Better “today” cluster
- Better pending action visibility
### Priority
- High

## 59. Provider Queue
### Path
- `frontend/lib/features/provider/queue/presentation/screens/provider_queue_screen.dart`
### Verdict
- `OK`
### Good
- Queue is the right provider center of gravity
### OK
- Operational structure is correct in principle
### Weak
- Queue empty states and stage messaging need to be sharp
### Bad
- If stage transitions are unclear, the queue becomes friction instead of guidance
### Dead
- Generic queue list without stage grammar is dead
### Problems
- Stage clarity
- Item urgency
- Hand-off clarity
- Queue-to-detail flow
### Solutions
- Better stage headers
- Better urgency badges
- Better queue filters
- Faster item drill-down
### Priority
- Critical

## 60. Provider Customers
### Path
- `frontend/lib/features/provider/customers/presentation/screens/provider_customers_screen.dart`
### Verdict
- `BAD`
### Truth
- This is one of the biggest warning files in the repo.
- It carries too much UI, too much workflow, and too much product surface in one place.
### Good
- Real feature ambition
- Deep patient workspace concept
- Search placeholder support
- Print capability
### OK
- There is enough business depth here to justify serious investment
### Weak
- Heavy empty-state dependence
- Too much local screen ownership
- Too much potential layout sprawl
### Bad
- Giant screen size
- High regression risk
- Hard reuse
- Hard consistency
- Hard performance tuning
### Dead
- Continuing to pile more provider workflow into this same screen is dead
### Problems
- Monolith ownership
- Too many tabs/sections in one file
- Inconsistent presentation density risk
- Hard-to-standardize details
- Hard-to-standardize action behavior
- Hard-to-standardize formatting
### Solutions
- Split into provider runtime modules
- Reuse backend-owned metadata where possible
- Extract patient header, timeline, documents, billing, notes, print, and record tabs into modular owners
- Add stronger list/detail shell
- Normalize copy and empty states
### Priority
- Critical

## 61. Provider Appointments
### Path
- `frontend/lib/features/provider/appointments/presentation/screens/provider_appointments_screen.dart`
### Verdict
- `OK`
### Good
- Correct domain fit
### OK
- Supports core provider workflow
### Weak
- Appointment tools need speed and clarity above all else
### Bad
- Overly verbose cards or weak time-slot layout would hurt throughput
### Dead
- Appointment experiences that do not optimize for fast scan are dead
### Problems
- Time grouping
- Patient context
- Status changes
- No-show handling
### Solutions
- More compact appointment rows
- Faster inline actions
- Better status colors
- Better timeline linkage
### Priority
- High

## 62. Provider Documents
### Path
- `frontend/lib/features/provider/documents/presentation/screens/provider_documents_screen.dart`
### Verdict
- `WEAK`
### Good
- Needed workflow exists
### OK
- Patient-linked records make sense here
### Weak
- Empty-state heavy language suggests incomplete record populations are common
### Bad
- File lists are not enough for provider productivity
### Dead
- Documents as passive attachments are dead
### Problems
- Record categorization
- Preview
- Upload confidence
- Missing-data guidance
### Solutions
- Better preview-first layout
- Better grouping by document type
- Better upload result feedback
- Better patient context strip
### Priority
- High

## 63. Provider Prescriptions
### Path
- `frontend/lib/features/provider/prescriptions/presentation/screens/provider_prescriptions_screen.dart`
### Verdict
- `OK`
### Good
- High-value clinical surface
### OK
- Clinical documents and generated outputs make sense here
### Weak
- Prescription UX must be extremely confidence-oriented
### Bad
- Ambiguous print/download/create/edit states will reduce trust
### Dead
- Prescription list without structured action flow is dead
### Problems
- Confidence
- Print clarity
- Upload/review/edit path
- Timeline linkage
### Solutions
- Strong action hierarchy
- Better clinical metadata display
- Better review state cues
- Better patient context
### Priority
- High

## 64. Provider Profile
### Path
- `frontend/lib/features/provider/profile/presentation/screens/provider_profile_screen.dart`
### Verdict
- `OK`
### Good
- Good place for account and operational identity
### OK
- Probably calmer and simpler than other provider screens
### Weak
- Profile pages should not absorb operational tasks
### Bad
- Overloading profile with workflow operations is poor IA
### Dead
- Profile as a junk drawer is dead
### Problems
- Identity vs operations separation
- Credential visibility
- Branch/service relationship visibility
- Settings overlap
### Solutions
- Keep profile focused
- Link to operations rather than absorb them
- Make credentials and service assignments clear
### Priority
- Medium

## 65. Provider Settings
### Path
- `frontend/lib/features/provider/settings/presentation/screens/provider_settings_screen.dart`
### Verdict
- `OK`
### Good
- Appropriate module exists
### OK
- Usually lower complexity than patient workspace
### Weak
- Settings must be simpler and more segmented than giant mixed forms
### Bad
- If settings feel too technical, providers will avoid them
### Dead
- Settings as one giant scrolling form are dead
### Problems
- Segmentation
- Save-state feedback
- Session/device trust
- Notification preferences clarity
### Solutions
- Sectioned settings
- Better save feedback
- Stronger preference summaries
- Better security/device history surface
### Priority
- Medium

## 66. Provider Auth
### Path
- `frontend/lib/features/provider/auth/presentation/screens/internal_login_screen.dart`
### Verdict
- `OK`
### Good
- Internal auth path exists
### OK
- Functional necessity is clear
### Weak
- Logging and debug tone should stay out of production experience
### Bad
- Internal auth should feel secure and clean, not instrumented
### Dead
- Debug-first login UX is dead
### Problems
- Tone
- Error feedback
- Session confidence
- Support path
### Solutions
- Cleaner auth copy
- Better failure explanations
- Better account/session guidance
- Remove unnecessary debug-oriented feel
### Priority
- Medium

## 67. Provider Overall Truth
- The provider portal has real domain potential.
- It also has the most dangerous large-screen concentration.
- It needs architectural slimming before more feature accretion.

## 68. Customer Portal Family Overview
### Verdict
- `OK`
### Truth
- The customer portal is calmer than the internal portals.
- It is more coherent visually.
- It is less operationally dense by nature.
- It still needs polish in language, formatting, and state communication.

## 69. Customer Architecture
### Verdict
- `OK`
### Good
- Simpler scope
- Dedicated shared widgets
- Clear route set
### Weak
- Still relies on conventional per-feature controllers
- Less platform-like than admin
### Bad
- If more complexity is added without shared patterns, drift will grow
### Solutions
- Better display formatters
- Better shared customer states
- Stronger route-state continuity where needed

## 70. Customer Splash
### Path
- `frontend/lib/features/customer/auth/presentation/screens/customer_splash_screen.dart`
### Verdict
- `OK`
### Good
- Correct auth bootstrap role
### OK
- Usually brief
### Weak
- Splash screens must not feel indefinite or ambiguous
### Bad
- Weak session-restore communication harms trust
### Dead
- Long idle splash is dead UX
### Problems
- Delay clarity
- Auth branch clarity
- Error handling
- Offline path
### Solutions
- Tight timing
- Clear fallback states
- Better session-restoration messaging
- Better retry behavior
### Priority
- Medium

## 71. Customer Login
### Path
- `frontend/lib/features/customer/auth/presentation/screens/customer_login_screen.dart`
### Verdict
- `OK`
### Good
- Core entry path exists
### OK
- OTP-first flow is straightforward
### Weak
- Login copy and visual trust need to feel extremely clean
### Bad
- Any friction or ambiguity at login is expensive
### Dead
- Verbose or technical login guidance is dead
### Problems
- Clarity
- Validation
- Country/phone formatting
- Error tone
### Solutions
- Cleaner field guidance
- Better validation
- Better failure messages
- Better visual confidence
### Priority
- High

## 72. Customer OTP
### Path
- `frontend/lib/features/customer/auth/presentation/screens/customer_otp_screen.dart`
### Verdict
- `OK`
### Good
- Necessary second step
### OK
- Usually focused
### Weak
- OTP flows need excellent timer and resend clarity
### Bad
- Confusing resend states destroy trust fast
### Dead
- OTP step with poor timer feedback is dead
### Problems
- Resend timing
- Autofill friendliness
- Failure messaging
- Step clarity
### Solutions
- Better timer
- Better resend state
- Better invalid-code messaging
- Better success transition
### Priority
- High

## 73. Customer Register
### Path
- `frontend/lib/features/customer/auth/presentation/screens/customer_register_screen.dart`
### Verdict
- `WEAK`
### Good
- Necessary path for first-time customers
### OK
- Structured capture exists
### Weak
- Registration can become long and intimidating
### Bad
- Weak guidance or too many fields will cause abandonment
### Dead
- Giant unchunked register form is dead
### Problems
- Pace
- Validation load
- Agent code clarity
- Completion confidence
### Solutions
- Better staged flow
- Better field grouping
- Better progress messaging
- Better completion summary
### Priority
- High

## 74. Customer Dashboard
### Path
- `frontend/lib/features/customer/dashboard/presentation/screens/dashboard_screen.dart`
### Verdict
- `OK`
### Good
- Clear home surface
- Can show membership, wallet, appointment, and notification value
### OK
- Calm format is appropriate
### Weak
- Must avoid becoming a generic summary wall
### Bad
- Non-actionable wallet/card/info panels reduce value
### Dead
- Dashboard as static brochure is dead
### Problems
- Action clarity
- Notification priority
- Membership state visibility
- Wallet summary readability
### Solutions
- Stronger quick actions
- Better top tasks
- Better personalized state communication
- Better formatting polish
### Priority
- High

## 75. Customer Documents
### Path
- `frontend/lib/features/customer/documents/presentation/screens/customer_documents_screen.dart`
### Verdict
- `OK`
### Good
- Useful self-service surface
### OK
- Appropriate as a document access view
### Weak
- Needs strong empty states and upload/approval clarity
### Bad
- A plain list without status guidance is weak
### Dead
- Passive docs shelf is dead
### Problems
- Document type clarity
- Approval status clarity
- Upload confidence
- Preview access
### Solutions
- Better grouping
- Better status chips
- Better upload feedback
- Better document actions
### Priority
- Medium

## 76. Customer Membership
### Path
- `frontend/lib/features/customer/membership/presentation/screens/membership_screen.dart`
### Verdict
- `OK`
### Good
- High-value self-service area
### OK
- Core membership visibility exists
### Weak
- Benefits and usage communication must be extremely clear
### Bad
- Raw plan details are not enough
### Dead
- Membership page as static plan sheet is dead
### Problems
- Renewal state
- Benefit eligibility
- Usage visibility
- Next renewal clarity
### Solutions
- Better lifecycle summary
- Better benefits presentation
- Better expiry warnings
- Better transaction linkage
### Priority
- High

## 77. Customer Prescriptions
### Path
- `frontend/lib/features/customer/prescriptions/presentation/screens/customer_prescriptions_screen.dart`
### Verdict
- `OK`
### Good
- Useful health record surface
### OK
- Clinical relevance is high
### Weak
- Prescription display must be simple and trustworthy
### Bad
- Overly technical layouts would confuse customers
### Dead
- Prescription list without date, doctor, and file clarity is dead
### Problems
- Readability
- Download/preview clarity
- Timeline context
- Provider linkage
### Solutions
- Better metadata rows
- Better date hierarchy
- Better preview actions
- Better explanatory tone
### Priority
- Medium

## 78. Customer Wallet
### Path
- `frontend/lib/features/customer/wallet/presentation/screens/wallet_screen.dart`
### Verdict
- `OK`
### Good
- Wallet is central to SHIELD value
### OK
- Dedicated screen and widgets exist
### Weak
- Wallet communication must be very careful because hidden benefit logic is tricky
### Bad
- If the page confuses cash, reward points, and benefits, trust will collapse
### Dead
- Any wallet UI that implies a hidden benefit balance is dead
### Problems
- Sub-ledger explanation
- Transaction readability
- Benefit visibility rules
- Reward clarity
### Solutions
- Clear cash vs reward separation
- Better ledger grouping
- Better transaction semantics
- Better explanatory copy
### Priority
- Critical

## 79. Customer Portal Overall Truth
- The customer experience is less architecturally messy than provider.
- It is less advanced than admin.
- It is capable of becoming polished relatively quickly because scope is narrower.

## 80. Shared UI Language Audit
### Verdict
- `WEAK`
### Problems
- Mixed capitalization
- Mixed date styles
- Mixed button tone
- Mixed empty-state tone
- Mixed section density
### Solutions
- UI language handbook
- shared formatter layer
- shared empty-state and button label rules
- shared status taxonomy

## 81. Shared Table Audit
### Verdict
- `OK`
### Good
- Real sorting
- Real pagination
- Real selection support
- Shared usage
### Weak
- Not yet a premium enterprise data grid
### Bad
- Selection and row click semantics still need careful discipline
### Solutions
- Sticky header
- better row hover
- denser cell rhythm
- stronger checkbox semantics
- column width and alignment system

## 82. Shared Search Audit
### Verdict
- `WEAK`
### Problems
- Debounce not universally present
- Query persistence not universal
- Search confidence feedback limited
### Solutions
- Shared debounce
- shared search-state persistence
- recent search or saved-view support where useful

## 83. Shared Filter Audit
### Verdict
- `WEAK`
### Problems
- Filters are visible but not always sufficiently expressive
- Advanced filtering is still immature
### Solutions
- Relative dates
- grouped filters
- saved filters
- better chip grammar

## 84. Shared Action Audit
### Verdict
- `OK`
### Good
- Admin action descriptors are a strong direction
### Weak
- Other portals do not yet benefit from the same rigor
### Bad
- Action placement inconsistency across portals remains
### Solutions
- Propagate action metadata concepts beyond admin
- standardize primary/record/bulk/context action hierarchy

## 85. Shared Empty-State Audit
### Verdict
- `WEAK`
### Truth
- There are a lot of empty states in this repo.
- Some are honest.
- Some are overused.
### Problems
- Empty states become the product too often
- Copy sometimes sounds generic
- Recovery actions are not always strong enough
### Solutions
- Stronger “what now” copy
- better creation/import/retry CTAs
- fewer passive empty-state surfaces

## 86. Shared Copy Audit
### Verdict
- `BAD`
### Problems
- Developer-oriented terms
- Fallback-style phrases
- Technical labels
- occasional awkward wording
### Solutions
- dedicated content pass
- enforce product voice
- ban raw internal phrasing in operator UI

## 87. Shared Density Audit
### Verdict
- `WEAK`
### Problems
- Too much whitespace in some admin/internal surfaces
- Inconsistent compactness
- Over-carded compositions
### Solutions
- 8px spacing system
- denser headers
- fewer nested cards
- table-first layouts

## 88. Shared Detail-View Audit
### Verdict
- `WEAK`
### Problems
- Permanent detail panes can steal too much width
- Some portals still need clearer list-to-detail ergonomics
### Solutions
- shared drawer pattern
- subordinate tabs
- context summary bars

## 89. Shared Notification and Feedback Audit
### Verdict
- `OK`
### Good
- Snackbars and retry patterns exist
### Weak
- Need richer success and failure explanations
### Solutions
- action result summaries
- next-step hints
- clearer download/export confirmations

## 90. Shared Formatting Audit
### Verdict
- `WEAK`
### Problems
- Raw timestamps still existed until recently in admin
- Identifier presentation is inconsistent
- Money formatting can be improved
- Status capitalization and text spacing are uneven
### Solutions
- global display-format package for app layer
- strict per-type formatters

## 91. Shared Accessibility Audit
### Verdict
- `WEAK`
### Problems
- keyboard-first admin operation is not fully designed
- selection/focus/row semantics need explicit attention
### Solutions
- keyboard map
- semantic labels
- focus ring pass
- screen reader pass

## 92. Shared Performance Audit
### Verdict
- `OK`
### Problems
- giant screens
- broad state notifications
- mixed granularities of rebuild
### Solutions
- split owners
- debounce search
- partial updates
- expensive widget profiling

## 93. Dead Surfaces and Dead Patterns
- Expanding `portal_shell.dart` further as the main UX owner is dead
- Growing `provider_customers_screen.dart` further in place is dead
- Growing `agent_settings_screen.dart` further in place is dead
- Returning to decorative admin dashboard cards is dead
- Keeping wallet pages ambiguous on ledger semantics is dead
- Treating CRM as generic record management is dead
- Treating reports as card galleries is dead
- Treating branch/provider/employee modules as profile-only pages is dead

## 94. Good Surfaces and Good Patterns
- Admin shared runtime
- Admin workspace controller model
- Admin action descriptor direction
- Backend-owned workspace semantics
- Query-driven admin loading
- Customer portal’s calmer presentation baseline
- Provider queue as a concept
- Agent registration as a high-value workflow domain

## 95. OK Surfaces That Can Become Great
- Admin dashboard
- Admin visits
- Admin documents
- Admin settings
- Admin audit
- Agent customers
- Agent appointments
- Provider dashboard
- Provider queue
- Customer dashboard
- Customer membership
- Customer documents

## 96. Bad Surfaces Requiring Serious Rework
- Portal shell architecture
- Provider customers screen architecture
- Shared copy quality
- Shared empty-state overreliance
- Shared internal density balance

## 97. Module Priority Order For UX/UI Improvement
1. Admin shared renderer
2. Admin customers refinement
3. Provider customers decomposition
4. Agent shared interaction patterns
5. Wallet display-language hardening
6. CRM operational UX
7. Reports workflow UX
8. Membership lifecycle UX
9. Provider queue and documents
10. Customer auth and register polish

## 98. Design-System-Level Recommendations
- One spacing rhythm
- One title scale
- One meta text scale
- One status-color map
- One action hierarchy
- One empty-state pattern
- One table grammar
- One detail drawer pattern
- One query persistence pattern
- One formatting package

## 99. Product-Language Recommendations
- Never show raw enum-like values if backend can provide display text
- Never show raw timestamps in primary views
- Never use backend architecture words in operator-facing descriptions
- Never let empty states feel like a system apology
- Prefer task language over data language

## 100. Admin Page-by-Page Quick Scoreboard
- Dashboard: `OK`
- Customers: `GOOD`
- Agents: `OK`
- CRM: `WEAK`
- Visits: `OK`
- Documents: `OK`
- Memberships: `WEAK`
- Notifications: `OK`
- Branches: `WEAK`
- Employees: `WEAK`
- Roles: `OK`
- Providers: `WEAK`
- Referrals: `OK`
- Rewards: `WEAK`
- Services: `WEAK`
- Reports: `WEAK`
- Insights: `OK`
- Wallet: `WEAK`
- Availability: `WEAK`
- Settings: `OK`
- Platform: `OK`
- Audit: `OK`

## 101. Agent Page-by-Page Quick Scoreboard
- Dashboard: `OK`
- Customers: `OK`
- Appointments: `OK`
- Documents: `WEAK`
- Follow-ups: `WEAK`
- Notifications: `WEAK`
- Performance: `WEAK`
- Referrals: `OK`
- Registration: `OK`
- Reports: `WEAK`
- Settings: `WEAK`

## 102. Provider Page-by-Page Quick Scoreboard
- Dashboard: `OK`
- Queue: `OK`
- Customers: `BAD`
- Appointments: `OK`
- Documents: `WEAK`
- Prescriptions: `OK`
- Profile: `OK`
- Settings: `OK`
- Auth: `OK`

## 103. Customer Page-by-Page Quick Scoreboard
- Splash: `OK`
- Login: `OK`
- OTP: `OK`
- Register: `WEAK`
- Dashboard: `OK`
- Documents: `OK`
- Membership: `OK`
- Prescriptions: `OK`
- Wallet: `OK`

## 104. Brutal Summary
- Admin is the future path.
- Provider is the biggest maintenance risk.
- Agent is useful but not yet systematic.
- Customer is steady but under-polished.
- Copy quality is still below product-grade.
- Query persistence and keyboard ergonomics are behind where they should be.
- The product has enough real data now that presentation quality is the next major differentiator.

## 105. Immediate Fix List
- Add search debounce to shared admin controller
- Persist admin query state in URL
- Tighten admin spacing and density further
- Normalize all user-facing date and time output
- Normalize all money and ledger formatting
- Refactor provider customer workspace into smaller owners
- Break up agent settings
- Reduce role branching pressure in portal shell
- Remove debug logging from production-facing runtime paths
- Run a dedicated copy cleanup pass

## 106. 30-Day UX Engineering Plan
- Week 1: shared admin renderer polish
- Week 2: provider patient workspace decomposition
- Week 3: agent interaction normalization
- Week 4: customer auth and wallet language polish

## 107. 60-Day Platform UX Plan
- Move more internal portals toward runtime-driven models
- Introduce shared internal detail drawer
- Introduce saved views
- Introduce shared formatting layer
- Introduce keyboard navigation standard

## 108. 90-Day Product Maturity Goal
- One consistent internal operating experience
- One consistent display-language system
- One consistent query and selection grammar
- No giant multi-thousand-line workflow screens growing unchecked

## 109. Final Verdict
- SHIELD is no longer just a front-end demo.
- SHIELD is also not yet a consistently mature product UI.
- The architecture is ahead of the experience.
- The admin portal is the best place to set the standard.
- The next gains come from ruthless UX, language, density, and interaction cleanup, not from adding more decorative screens.

## 110. Appendix A: Screen Inventory By Portal
### Admin
- `admin_dashboard_module.dart`
- `admin_customers_module.dart`
- `admin_agents_module.dart`
- `admin_crm_module.dart`
- `admin_visits_module.dart`
- `admin_documents_module.dart`
- `admin_memberships_module.dart`
- `admin_notifications_module.dart`
- `admin_branches_module.dart`
- `admin_employees_module.dart`
- `admin_roles_module.dart`
- `admin_providers_module.dart`
- `admin_referrals_module.dart`
- `admin_rewards_module.dart`
- `admin_services_module.dart`
- `admin_reports_module.dart`
- `admin_insights_module.dart`
- `admin_wallet_module.dart`
- `admin_availability_module.dart`
- `admin_settings_module.dart`
- `admin_platform_module.dart`
- `admin_audit_module.dart`

### Agent
- `agent_dashboard_screen.dart`
- `agent_customers_screen.dart`
- `agent_appointments_screen.dart`
- `agent_documents_screen.dart`
- `agent_followups_screen.dart`
- `agent_notifications_screen.dart`
- `agent_performance_screen.dart`
- `agent_referrals_screen.dart`
- `agent_registration_screen.dart`
- `agent_reports_screen.dart`
- `agent_settings_screen.dart`

### Provider
- `provider_dashboard_screen.dart`
- `provider_queue_screen.dart`
- `provider_customers_screen.dart`
- `provider_appointments_screen.dart`
- `provider_documents_screen.dart`
- `provider_prescriptions_screen.dart`
- `provider_profile_screen.dart`
- `provider_settings_screen.dart`
- `internal_login_screen.dart`

### Customer
- `customer_splash_screen.dart`
- `customer_login_screen.dart`
- `customer_otp_screen.dart`
- `customer_register_screen.dart`
- `dashboard_screen.dart`
- `customer_documents_screen.dart`
- `membership_screen.dart`
- `customer_prescriptions_screen.dart`
- `wallet_screen.dart`

## 111. Appendix B: Architectural Risk Callouts
- `portal_shell.dart` is too large and too central.
- `provider_customers_screen.dart` is too large and too central.
- `agent_settings_screen.dart` is too large and too central.
- Admin runtime is the cleanest reusable path.
- Provider and agent should gradually absorb more runtime-like shared patterns.

## 112. Appendix C: Copy Problems To Eliminate Everywhere
- technical fallback wording
- ambiguous empty-state wording
- backend-contract wording
- schema-ish labels
- raw identifiers in primary contexts
- raw timestamp formatting
- generic “no data available” with no recovery path

## 113. Appendix D: Visual Problems To Eliminate Everywhere
- oversized sidebars
- excessive whitespace
- too many nested cards
- table not being the hero in operational pages
- equal visual weight for primary and secondary information
- weak title hierarchy
- timid status hierarchy

## 114. Appendix E: Interaction Problems To Eliminate Everywhere
- invisible state changes
- weak selection semantics
- actions too far from context
- filters that do not feel persistent
- no keyboard-first flow
- refresh without visible freshness feedback
- passive timelines
- passive reports

## 115. Appendix F: What Success Looks Like
- Every portal feels like one product
- Every operational module feels task-oriented
- Every key surface has readable data
- Every key action has confidence and feedback
- Every table is efficient to scan
- Every detail view earns its space
- Every empty state helps the user recover
- Every screen uses human language, not implementation language

## 116. Closing Statement
- The strongest thing in this repository right now is the direction of the admin runtime.
- The weakest thing in this repository right now is the coexistence of that runtime with oversized legacy screen ownership.
- The product can cross the line into genuinely user-friendly software.
- It will not happen by adding more modules first.
- It will happen by cleaning the shell, standardizing the interaction model, tightening density, fixing language, and decomposing the largest risky screens.

## 117. Detailed Page Matrix
- The sections below turn the audit into a page-by-page action document.
- Each block is intentionally repetitive.
- The repetition is useful because it makes comparison easier.
- The goal is not literary elegance.
- The goal is operational clarity.

## 118. Admin Dashboard Matrix
- Portal: Admin
- Page: Dashboard
- File: `admin_dashboard_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: shared runtime path
- Good: backend-owned surface direction
- Good: can inherit shared fixes
- OK: role-aware metric capability
- OK: operational summary potential
- Bad: at risk of decorative widgets
- Bad: easy to over-cardify
- Dead: static summary expansion
- Primary problem: KPI cards can overpower actions
- Secondary problem: dashboard can consume too much vertical space
- Tertiary problem: if widgets are not drillable they become wallpaper
- UX solution: force drill-down behavior on every KPI
- UI solution: compress header and metric band
- Data solution: use human labels and freshness hints
- Performance solution: avoid full dashboard reload for every minor interaction
- Accessibility solution: keyboard and focus support for metric cards
- Copy solution: remove generic “overview” language and use task language
- Do not do: add more decorative cards

## 119. Admin Customers Matrix
- Portal: Admin
- Page: Customers
- File: `admin_customers_module.dart`
- Overall status: `GOOD`
- Architecture status: `GOOD`
- UX status: `OK`
- Data trust status: `GOOD`
- Density status: `OK`
- Action clarity: `OK`
- Good: strongest admin business module
- Good: real search, sort, pagination, selection, export direction
- Good: command metadata foundation exists
- OK: details are now structurally usable
- OK: shared runtime keeps ownership sane
- Bad: still vulnerable to density drift
- Bad: still vulnerable to wording drift
- Dead: permanent oversized right profile pane
- Primary problem: detail area still competes with list too much in some states
- Secondary problem: action discoverability can improve
- Tertiary problem: saved views and advanced filtering are still missing
- UX solution: table-first workspace with better subordinate detail behavior
- UI solution: tighter rows, better column alignment, denser summary panel
- Data solution: strong customer-facing display values everywhere
- Performance solution: partial refresh for detail-only interactions
- Accessibility solution: clearer row vs checkbox semantics
- Copy solution: keep all labels operator-friendly
- Do not do: regress into local mock state or placeholder metrics

## 120. Admin Agents Matrix
- Portal: Admin
- Page: Agents
- File: `admin_agents_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: registered in runtime
- Good: can reuse shared renderer
- Good: right placement in admin ecosystem
- OK: appropriate candidate for list-detail model
- OK: can become strong with real action depth
- Bad: likely thinner than customer module today
- Bad: management semantics may still be too shallow
- Dead: view-only agent directory thinking
- Primary problem: insufficient operational depth is the main risk
- Secondary problem: performance and attendance need task framing
- Tertiary problem: assigned-customer workflows need clearer hierarchy
- UX solution: turn into management console, not detail browser
- UI solution: emphasize assignments, status, and targets in the grid
- Data solution: clear performance and attendance summaries
- Performance solution: list caching and targeted tab reloads
- Accessibility solution: better action grouping for keyboard users
- Copy solution: avoid generic “performance” wording without context
- Do not do: stop at profile-only rendering

## 121. Admin CRM Matrix
- Portal: Admin
- Page: CRM
- File: `admin_crm_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `BAD`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: shared runtime gives a path to fix it
- Good: queue concepts fit backend ownership well
- Good: can become one of the most valuable modules
- OK: correct domain placement
- OK: suitable for filters and bulk actions
- Bad: current risk is generic list behavior
- Bad: CRM needs urgency grammar and next-action clarity
- Dead: record-grid CRM without queue semantics
- Primary problem: no queue-first mental model means weak operator flow
- Secondary problem: follow-up and escalation states can become visually flat
- Tertiary problem: conversion context may feel abstract
- UX solution: redesign as lead queue plus action lane
- UI solution: SLA chips, due states, next action prominence
- Data solution: customer history and outcome history beside current task
- Performance solution: incremental queue refresh instead of full resets
- Accessibility solution: keyboard triage support
- Copy solution: use task labels, not module labels
- Do not do: treat CRM as a generic admin table

## 122. Admin Visits Matrix
- Portal: Admin
- Page: Visits
- File: `admin_visits_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: runtime-friendly domain
- Good: naturally supports filters and date pivots
- Good: strong candidate for split-pane details
- OK: visit lifecycle can be rendered clearly
- OK: scheduling and provider context belong here
- Bad: weak date handling would make it tiring fast
- Bad: visit urgency could get buried
- Dead: visit records as generic static rows
- Primary problem: time and status must dominate the UI
- Secondary problem: provider and customer linkage must be effortless
- Tertiary problem: missed and overdue states need stronger hierarchy
- UX solution: date-grouped list and strong visit state color usage
- UI solution: denser visit rows with richer status chips
- Data solution: consistent location, provider, customer, and status display
- Performance solution: efficient paging and range filtering
- Accessibility solution: clear keyboard traversal by row and date group
- Copy solution: use simple visit-state words
- Do not do: collapse visit operations into summary cards

## 123. Admin Documents Matrix
- Portal: Admin
- Page: Documents
- File: `admin_documents_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `OK`
- Good: queue-style governance is appropriate
- Good: can leverage shared table and detail patterns
- Good: approval flows belong in admin
- OK: document metadata can be made useful
- OK: verification queue is the right mental model
- Bad: preview and review speed are likely not yet optimized enough
- Bad: too much card nesting would harm throughput
- Dead: passive file table without workflow actions
- Primary problem: document review must optimize for speed and confidence
- Secondary problem: metadata and preview need better balance
- Tertiary problem: rejection reasons and history need stronger context
- UX solution: queue left, preview center, metadata/actions right
- UI solution: larger preview and stronger status/timeline rail
- Data solution: concise metadata summaries
- Performance solution: lazy preview loading and targeted fetches
- Accessibility solution: document actions reachable without pointer dependence
- Copy solution: approval and rejection language must be plain
- Do not do: keep it as an attachment shelf

## 124. Admin Memberships Matrix
- Portal: Admin
- Page: Memberships
- File: `admin_memberships_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `BAD`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: lives in shared runtime direction
- Good: can reuse action metadata and forms
- Good: domain value is high
- OK: plans and records can fit list-detail pattern
- OK: backend-first lifecycle actions are achievable
- Bad: if lifecycle actions are missing the screen is not complete
- Bad: “view only” thinking is unacceptable here
- Dead: plans page without renew, upgrade, freeze, cancel actions
- Primary problem: lifecycle management is the product, not a sidebar detail
- Secondary problem: benefits and eligibility are often hard to read
- Tertiary problem: invoices and transactions need better integration
- UX solution: lifecycle actions above the table and record details below
- UI solution: better status timeline and benefit blocks
- Data solution: explicit start, expiry, next billing, benefits, and usage
- Performance solution: refresh only affected tabs after actions
- Accessibility solution: clear action affordances and confirmations
- Copy solution: avoid technical membership jargon where possible
- Do not do: leave this page as a read-only catalog

## 125. Admin Notifications Matrix
- Portal: Admin
- Page: Notifications
- File: `admin_notifications_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: backend workspace model suits notification operations
- Good: device registry and inbox concepts belong together
- Good: delivery status can be made meaningful
- OK: filters and tabs fit well here
- OK: list/detail can work
- Bad: template and campaign gaps need better explanation
- Bad: passive inboxes are low-value
- Dead: notification page without actionability or outcome confidence
- Primary problem: delivery trust is the main UX requirement
- Secondary problem: message list alone is not enough
- Tertiary problem: device state needs clearer operational value
- UX solution: focus on delivery state, audience, and action result
- UI solution: stronger unread and failed emphasis
- Data solution: human-friendly channel, audience, and status labels
- Performance solution: lightweight refresh for delivery counts
- Accessibility solution: better item grouping and focus order
- Copy solution: reduce diagnostic tone
- Do not do: treat it like a simple message inbox

## 126. Admin Branches Matrix
- Portal: Admin
- Page: Branches
- File: `admin_branches_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: branches belong in a backend-owned registry model
- Good: branch list and detail structure are straightforward
- Good: can link to employees, providers, customers, and revenue
- OK: business value is obvious
- OK: branch as a workspace is sound
- Bad: branch pages often become static profiles
- Bad: without linked ops, they underperform
- Dead: branch profile without linked workforce and performance
- Primary problem: branch needs to feel like an operating unit
- Secondary problem: people and provider relationships need surfacing
- Tertiary problem: revenue and visit metrics need better presentation
- UX solution: multi-tab branch workspace with linked tables
- UI solution: branch summary as compact top strip, not giant card
- Data solution: headcounts, provider counts, customer counts, revenue, status
- Performance solution: load related tables lazily by tab
- Accessibility solution: consistent navigation between branch tabs
- Copy solution: use business language, not master-data language
- Do not do: stop at branch profile text

## 127. Admin Employees Matrix
- Portal: Admin
- Page: Employees
- File: `admin_employees_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: employee management belongs here
- Good: shared runtime can standardize it
- Good: table-first layout is appropriate
- OK: strong candidate for bulk actions
- OK: branch and role links can be useful
- Bad: if role, branch, shift, and status are not obvious, the page fails
- Bad: profile-only people pages are not enough
- Dead: employee registry without lifecycle management
- Primary problem: people operations must be fast and explicit
- Secondary problem: permission context needs to be understandable
- Tertiary problem: status and assignment changes need confidence
- UX solution: clear list with branch, role, status, last seen, and actions
- UI solution: denser rows and compact detail drawer
- Data solution: human-readable role and permission summaries
- Performance solution: targeted refresh on assignment/status changes
- Accessibility solution: bulk action flows must stay keyboard reachable
- Copy solution: avoid internal-only terminology
- Do not do: hide permissions inside unreadable detail panels

## 128. Admin Roles Matrix
- Portal: Admin
- Page: Roles
- File: `admin_roles_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: central role ownership is correct
- Good: backend permissions can feed this cleanly
- Good: can become one of the clearest governance modules
- OK: role listing and detail views fit the runtime
- OK: grouping can work well here
- Bad: raw permission codes are hostile UX
- Bad: too much technical exposure reduces trust
- Dead: permission matrix without translation layer
- Primary problem: role pages become unreadable if permission labels are raw
- Secondary problem: assignment impact is often hidden
- Tertiary problem: inheritance or scope semantics can be confusing
- UX solution: humanized permission groups and summary descriptions
- UI solution: grouped permission blocks with strong hierarchy
- Data solution: display labels, scope labels, assignment counts
- Performance solution: collapse and lazy-load large permission groups
- Accessibility solution: grouped focus traversal and section labels
- Copy solution: translate every technical permission into business English
- Do not do: expose raw permission names directly

## 129. Admin Providers Matrix
- Portal: Admin
- Page: Providers
- File: `admin_providers_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `BAD`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: runtime path exists
- Good: approvals and provider metadata can fit backend contracts
- Good: branch/service assignment belongs here
- OK: provider detail tabs can be rich and useful
- OK: workflow state is appropriate for admin
- Bad: if approval, licensing, and commission are thin, the page feels fake
- Bad: provider onboarding and governance are high-risk operations
- Dead: provider profiles without approval workflow and documents
- Primary problem: provider lifecycle is inherently workflow-heavy
- Secondary problem: compliance visibility is critical
- Tertiary problem: branch and service assignment need to be frictionless
- UX solution: queue-first onboarding plus detail tabs
- UI solution: approval panel, document stack, service assignment matrix
- Data solution: license, agreement, status, branch, services, commission, payouts
- Performance solution: load heavy detail tabs on demand
- Accessibility solution: approve/reject flows with strong confirmation semantics
- Copy solution: use clear onboarding and compliance wording
- Do not do: present provider management as a static profile page

## 130. Admin Referrals Matrix
- Portal: Admin
- Page: Referrals
- File: `admin_referrals_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: referral state machine fits backend ownership
- Good: can connect customers, rewards, and timeline well
- Good: queueing by status is natural
- OK: list and detail can be effective
- OK: delayed reward model can be explained here
- Bad: ambiguous stage wording will confuse operators
- Bad: reward timing can be misunderstood easily
- Dead: referral count views without state lineage
- Primary problem: stage language must be unmistakable
- Secondary problem: qualification logic needs a visible explanation
- Tertiary problem: operator auditability matters
- UX solution: referral status timeline and reason panels
- UI solution: strong stage chips and linked entities
- Data solution: who referred whom, when, status, reward state, reason
- Performance solution: preserve filters while drilling down
- Accessibility solution: maintain context on deep linking
- Copy solution: explain pending vs verified vs qualified simply
- Do not do: flatten referral state into generic status chips

## 131. Admin Rewards Matrix
- Portal: Admin
- Page: Rewards
- File: `admin_rewards_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: reward governance is centrally important
- Good: works well with ledgers and referrals
- Good: backend-driven tables are appropriate
- OK: list/detail is feasible
- OK: audit-friendly domain
- Bad: rewards are hard to trust when provenance is unclear
- Bad: summary cards are not enough
- Dead: reward management without event-level ledger context
- Primary problem: operators need event-level confidence
- Secondary problem: reward type and source must be explicit
- Tertiary problem: approvals and reversals need visible workflow
- UX solution: reward ledger plus record detail timeline
- UI solution: stronger source/type tagging
- Data solution: event date, source, customer, points/value, approval state
- Performance solution: filter and sort heavy ledgers efficiently
- Accessibility solution: clear reading order for dense event tables
- Copy solution: explain source and reversal states cleanly
- Do not do: show only reward totals

## 132. Admin Services Matrix
- Portal: Admin
- Page: Services
- File: `admin_services_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: central catalog ownership is correct
- Good: backend metadata can own labels and types
- Good: service operations can be made clean
- OK: list and detail model fits
- OK: category and provider eligibility can live here
- Bad: service catalogs easily become static and hard to use
- Bad: pricing and rule linkage may be too hidden
- Dead: service registry without operational relationships
- Primary problem: services need context, not just names
- Secondary problem: eligibility and provider compatibility matter
- Tertiary problem: rule ownership must be visible
- UX solution: catalog plus linked providers, pricing, and policy tabs
- UI solution: stronger category chips and compact service summaries
- Data solution: category, price, provider types, availability, notes, rule links
- Performance solution: lazy load related lists
- Accessibility solution: filter and row controls must remain simple
- Copy solution: keep service descriptions concise and useful
- Do not do: ship a flat service-name list

## 133. Admin Reports Matrix
- Portal: Admin
- Page: Reports
- File: `admin_reports_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `BAD`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: backend-owned report workflows are the right direction
- Good: runtime model can drive steps
- Good: export metadata can be centralized
- OK: report generation is a strong admin use case
- OK: history and schedules belong here
- Bad: report pages often fail by being chooser galleries
- Bad: preview and schedule flows can become buried
- Dead: card-grid reports without workflow depth
- Primary problem: reporting must feel like a workflow, not a brochure
- Secondary problem: preview trust is essential
- Tertiary problem: export feedback must be explicit
- UX solution: choose report, filter, choose columns, preview, export, history
- UI solution: stepwise layout and split preview
- Data solution: expose export status, last run, schedules, recipients
- Performance solution: async export status and preview loading
- Accessibility solution: wizard steps must be screen-reader and keyboard clear
- Copy solution: use workflow language, not platform language
- Do not do: stop at a report card grid

## 134. Admin Insights Matrix
- Portal: Admin
- Page: Insights
- File: `admin_insights_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: analytics belongs in admin
- Good: backend composition is a fit
- Good: runtime can render it consistently
- OK: chart surfaces can be valuable
- OK: insight narratives can be useful
- Bad: charts without actions are decoration
- Bad: too much whitespace would weaken scan speed
- Dead: static analytics dashboard thinking
- Primary problem: insights must lead to action
- Secondary problem: dimensional filters need to be clear
- Tertiary problem: chart language must be very readable
- UX solution: drill from charts into operational modules
- UI solution: compress chart cards and legend weight
- Data solution: timeframe, dimension, comparison, and unit clarity
- Performance solution: cache chart data by timeframe
- Accessibility solution: textual equivalents for chart states
- Copy solution: phrase insights as findings, not raw metrics
- Do not do: create chart-only pages

## 135. Admin Wallet Matrix
- Portal: Admin
- Page: Wallet
- File: `admin_wallet_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `BAD`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: ledger-based backend rules are strong
- Good: admin runtime can render complex table/detail flows
- Good: audit and approvals naturally belong here
- OK: wallet ops are a high-value admin surface
- OK: sub-ledger distinctions can be communicated clearly
- Bad: the UX risk is very high because money semantics must be exact
- Bad: hidden benefits must never be misrepresented
- Dead: wallet summary surfaces without ledger truth
- Primary problem: financial trust requires perfect wording and structure
- Secondary problem: approval and reason flows must be explicit
- Tertiary problem: customer-visible and internal-only balances must not blur
- UX solution: ledger-first, action-second, metrics-third
- UI solution: sub-ledger pills and before/after transaction details
- Data solution: cash, reward, hidden benefit, reason, actor, approval, reference
- Performance solution: paged ledger and targeted action refresh
- Accessibility solution: dense rows still need clear focus and labels
- Copy solution: prohibit misleading balance language
- Do not do: display hidden benefit as customer wallet balance

## 136. Admin Availability Matrix
- Portal: Admin
- Page: Availability
- File: `admin_availability_module.dart`
- Overall status: `WEAK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: scheduling domain is valid and important
- Good: branch and provider filters can make this useful
- Good: backend metadata can own slot semantics
- OK: list and calendar hybrid is possible
- OK: shift ownership can live here
- Bad: schedule UX is hard and generic tables are insufficient
- Bad: if time ranges are not visually strong, scanning suffers
- Dead: availability as generic data rows
- Primary problem: time is the main content type and needs special treatment
- Secondary problem: exceptions and overrides need visibility
- Tertiary problem: cross-resource filtering must stay fast
- UX solution: calendar-aware grid plus exception list
- UI solution: strong date and slot visualization
- Data solution: date, time, provider, branch, service, exception, source
- Performance solution: range-based data loading
- Accessibility solution: keyboard navigation across time structures
- Copy solution: use plain time and availability language
- Do not do: flatten schedules into simple text lists

## 137. Admin Settings Matrix
- Portal: Admin
- Page: Settings
- File: `admin_settings_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `OK`
- Data trust status: `GOOD`
- Density status: `OK`
- Action clarity: `OK`
- Good: backed by real settings rows
- Good: explicit unavailable states are honest
- Good: governance-friendly module
- OK: table and detail pattern is sensible
- OK: search and status filters belong here
- Bad: config language can still feel technical
- Bad: some values may need better summaries
- Dead: exposing raw settings rows as the final UX
- Primary problem: operators need confidence, not schema detail
- Secondary problem: grouping by domain is important
- Tertiary problem: change impact needs visibility
- UX solution: domain grouping and safer edit flows
- UI solution: cleaner value summaries and stronger badges
- Data solution: humanized setting value display and last-change context
- Performance solution: avoid reloading unrelated groups on one edit
- Accessibility solution: edit dialogs must be simple and readable
- Copy solution: remove implementation-flavored wording
- Do not do: treat settings as developer config sheet

## 138. Admin Platform Matrix
- Portal: Admin
- Page: Platform
- File: `admin_platform_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `WEAK`
- Data trust status: `GOOD`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: real platform health surface
- Good: integration visibility is useful
- Good: backend-driven health data is honest
- OK: capability and readiness views have value
- OK: this page should exist
- Bad: non-engineers may find the tone too technical
- Bad: health without action recommendations is limited
- Dead: technical state board with no operator meaning
- Primary problem: platform health must tie to business impact
- Secondary problem: diagnostics need clear severity hierarchy
- Tertiary problem: config absence needs plain-language guidance
- UX solution: distinguish healthy, warning, and operator-action-needed clearly
- UI solution: stronger severity layout and less equal card weight
- Data solution: add business meaning beside technical state
- Performance solution: light refresh and cached health polling
- Accessibility solution: severity color plus text redundancy
- Copy solution: convert diagnostics into operator-readable summaries
- Do not do: leave this page engineer-only in tone

## 139. Admin Audit Matrix
- Portal: Admin
- Page: Audit
- File: `admin_audit_module.dart`
- Overall status: `OK`
- Architecture status: `GOOD`
- UX status: `OK`
- Data trust status: `GOOD`
- Density status: `OK`
- Action clarity: `OK`
- Good: live audit evidence matters
- Good: search and filters are appropriate
- Good: timestamps and actors are meaningful once formatted well
- OK: audit tables suit runtime model
- OK: login history adjacency is useful
- Bad: audit can feel too raw if before/after is not visualized
- Bad: entity filters need to stay understandable
- Dead: forensic page without mutation context
- Primary problem: audit must feel investigative, not dump-like
- Secondary problem: before/after readability matters
- Tertiary problem: reason and actor attribution must stand out
- UX solution: better diff view and event detail drawer
- UI solution: stronger action/entity/actor column emphasis
- Data solution: who, when, what changed, before, after, reason, device, IP
- Performance solution: page large logs efficiently
- Accessibility solution: clear table headers and deep-link states
- Copy solution: forensic but plain language
- Do not do: reduce audit to raw rows only

## 140. Agent Dashboard Matrix
- Portal: Agent
- Page: Dashboard
- File: `agent_dashboard_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: natural entry point for agent work
- Good: can center daily priorities
- Good: role fit is obvious
- OK: metrics and tasks can coexist here
- OK: useful place for quick actions
- Bad: KPI-heavy layout would weaken operational value
- Bad: if next work is buried, the dashboard fails
- Dead: dashboard as a static summary mural
- Primary problem: today’s work must dominate
- Secondary problem: conversions and retention need context
- Tertiary problem: dashboard actions need closer ties to queues
- UX solution: task-first dashboard
- UI solution: denser queue cards and fewer summary blocks
- Data solution: due today, missed, new customers, pending docs, pending follow-ups
- Performance solution: staged loading for cards and queues
- Accessibility solution: shortcut-friendly CTA placement
- Copy solution: action language over abstract labels
- Do not do: optimize this page for screenshots over operations

## 141. Agent Customers Matrix
- Portal: Agent
- Page: Customers
- File: `agent_customers_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `OK`
- Good: customer operations matter here
- Good: print support exists
- Good: likely contains meaningful list context
- OK: can become a high-frequency work surface
- OK: domain importance is clear
- Bad: screen-specific ownership makes consistency harder
- Bad: density may still be lighter than ideal for operators
- Dead: customer surface without next action and follow-up cues
- Primary problem: list and next-step context need stronger integration
- Secondary problem: selected-customer actions need clarity
- Tertiary problem: print and export must not crowd primary actions
- UX solution: better master-detail rhythm
- UI solution: denser rows and clearer customer state chips
- Data solution: last contact, assignment, status, next step, docs pending
- Performance solution: fast search and filter debounce
- Accessibility solution: shortcut for open customer and print
- Copy solution: prefer customer task language
- Do not do: overload with decorative summaries

## 142. Agent Appointments Matrix
- Portal: Agent
- Page: Appointments
- File: `agent_appointments_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: a direct operational workflow surface
- Good: supports booking-related context
- Good: role relevance is obvious
- OK: providers and slots can be integrated well
- OK: appointment statuses can be visually effective
- Bad: complexity increases fast if UI is too verbose
- Bad: provider availability failures need clearer trust messaging
- Dead: appointment surface without strong slot clarity
- Primary problem: scheduling interfaces need instant scanability
- Secondary problem: provider availability and fallback messaging matter
- Tertiary problem: no-show and reschedule states need clarity
- UX solution: date-grouped schedule and action-first row controls
- UI solution: stronger slot cards or dense schedule rows
- Data solution: date, time, provider, customer, type, status, notes
- Performance solution: cache date-range responses
- Accessibility solution: navigable day and slot grouping
- Copy solution: reduce passive wording around availability
- Do not do: bury booking outcomes inside generic feedback

## 143. Agent Documents Matrix
- Portal: Agent
- Page: Documents
- File: `agent_documents_screen.dart`
- Overall status: `WEAK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: documents are part of agent operations
- Good: customer-linked document work is valid
- Good: upload and view concepts are necessary
- OK: document queue patterns could work
- OK: approval hand-off potential exists
- Bad: too many empty states suggest low confidence or incomplete interaction design
- Bad: review speed and categorization may be underdeveloped
- Dead: document screen as file bucket
- Primary problem: documents need task framing and status clarity
- Secondary problem: preview and metadata balance matter
- Tertiary problem: missing-doc guidance needs to be sharper
- UX solution: document tasks, missing items, and upload state grouped clearly
- UI solution: better queue layout and preview action row
- Data solution: document type, required status, uploaded by, date, verification state
- Performance solution: lazy thumbnails and preview fetches
- Accessibility solution: upload and review flows must stay simple
- Copy solution: better missing-document and verification wording
- Do not do: let the screen be dominated by empty-state cards

## 144. Agent Follow-ups Matrix
- Portal: Agent
- Page: Follow-ups
- File: `agent_followups_screen.dart`
- Overall status: `WEAK`
- Architecture status: `WEAK`
- UX status: `BAD`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: follow-ups are core to this role
- Good: correct business placement
- Good: urgency-based prioritization can make this powerful
- OK: list-centric design fits the domain
- OK: can be upgraded quickly with the right grammar
- Bad: if urgency is not dominant, the module loses its value
- Bad: missed follow-ups need stronger visual treatment
- Dead: generic task list follow-up page
- Primary problem: the page must make time pressure obvious
- Secondary problem: action outcomes need easy capture
- Tertiary problem: customer context must stay visible while acting
- UX solution: due today, overdue, upcoming clusters
- UI solution: large urgency chips and compact action controls
- Data solution: due time, owner, customer, last note, next step, status
- Performance solution: efficient refresh of changed tasks only
- Accessibility solution: keyboard triage and quick-complete support
- Copy solution: task verbs over abstract statuses
- Do not do: flatten urgency into neutral rows

## 145. Agent Notifications Matrix
- Portal: Agent
- Page: Notifications
- File: `agent_notifications_screen.dart`
- Overall status: `WEAK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: role-specific alerts matter
- Good: module existence is justified
- Good: can support operational awareness
- OK: can be grouped by type
- OK: can complement dashboard
- Bad: inboxes are weak if they do not route to action
- Bad: low-priority noise can crowd useful items
- Dead: notification list without workflow links
- Primary problem: notification value is measured by action routing
- Secondary problem: priority levels need stronger expression
- Tertiary problem: read/unread is less important than relevance
- UX solution: action-oriented grouped notifications
- UI solution: stronger priority and age indicators
- Data solution: source, action target, due relevance, status
- Performance solution: lightweight polling or real-time updates if available
- Accessibility solution: clear list semantics and action buttons
- Copy solution: concise message summaries
- Do not do: treat notifications as passive log stream

## 146. Agent Performance Matrix
- Portal: Agent
- Page: Performance
- File: `agent_performance_screen.dart`
- Overall status: `WEAK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: performance visibility can motivate and coach
- Good: management and self-review use cases exist
- Good: metric surfaces can be meaningful
- OK: role fit is clear
- OK: a benchmark and progress model can work
- Bad: charts alone are not enough
- Bad: metrics without drill-down feel abstract
- Dead: vanity-performance dashboard
- Primary problem: performance must lead to behavior, not just observation
- Secondary problem: retention and conversion need context
- Tertiary problem: historical comparison needs clarity
- UX solution: target vs actual plus linked underlying work
- UI solution: fewer charts, more actionable breakdowns
- Data solution: timeframe, target, actual, trend, underlying customers/tasks
- Performance solution: cache chart series and reduce rebuild churn
- Accessibility solution: non-chart summary of every chart
- Copy solution: clearer metric explanations
- Do not do: rely only on percentages

## 147. Agent Referrals Matrix
- Portal: Agent
- Page: Referrals
- File: `agent_referrals_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: role fit is strong
- Good: referral network matters to agents
- Good: status-driven rewards can be useful here
- OK: list and detail pattern is natural
- OK: can drive engagement
- Bad: poor stage explanation will confuse field users
- Bad: reward timing ambiguity hurts trust
- Dead: referral count page without timeline
- Primary problem: users need to understand the reward journey clearly
- Secondary problem: pending reasons need visibility
- Tertiary problem: customer ownership and tree context need better expression
- UX solution: clear stage bands and record timelines
- UI solution: stronger status badges and reward-state summaries
- Data solution: who referred, who joined, stage, reason, expected next state
- Performance solution: keep filters sticky through navigation
- Accessibility solution: readable hierarchy for referral trees
- Copy solution: remove vague reward language
- Do not do: compress nuanced states into one badge

## 148. Agent Registration Matrix
- Portal: Agent
- Page: Registration
- File: `agent_registration_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `OK`
- Good: high-value workflow
- Good: core business relevance is undeniable
- Good: registration is exactly the kind of workflow that benefits from polish
- OK: forms and status can be organized well
- OK: documents and validations fit this flow
- Bad: long forms can exhaust users quickly
- Bad: unclear progress or blocking states increase abandonment
- Dead: one endless registration page
- Primary problem: registration needs guided flow discipline
- Secondary problem: validation and document requirements need stage clarity
- Tertiary problem: completion confidence must be strong
- UX solution: multi-step flow with progress and review
- UI solution: chunk fields, shrink cognitive load, show completion state
- Data solution: clear required vs optional distinction and backend validation feedback
- Performance solution: save draft and recover state cleanly
- Accessibility solution: step navigation and validation messaging must be clear
- Copy solution: helpful instruction text, not verbose bureaucracy
- Do not do: leave it as one giant mixed form

## 149. Agent Reports Matrix
- Portal: Agent
- Page: Reports
- File: `agent_reports_screen.dart`
- Overall status: `WEAK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `WEAK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: reporting matters if it helps field execution
- Good: smaller role-specific templates make sense
- Good: export can add value
- OK: right place for productivity summaries
- OK: focused templates could work
- Bad: empty-state evidence suggests the module is not yet mature enough
- Bad: broad report expectations can lead to weak generic shells
- Dead: report page without useful live templates
- Primary problem: reports need relevance, not just presence
- Secondary problem: template availability and confidence must improve
- Tertiary problem: results need to feel actionable
- UX solution: offer a few high-value agent reports only
- UI solution: workflow-based generation with clear outputs
- Data solution: report purpose, inputs, last run, export result
- Performance solution: async generation and result caching
- Accessibility solution: clear generation feedback
- Copy solution: make outputs understandable
- Do not do: keep an empty or mostly empty reports shell

## 150. Agent Settings Matrix
- Portal: Agent
- Page: Settings
- File: `agent_settings_screen.dart`
- Overall status: `WEAK`
- Architecture status: `BAD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `BAD`
- Action clarity: `OK`
- Good: broad coverage exists
- Good: operational and profile settings are relevant
- Good: real fields matter
- OK: there is enough substance to justify investment
- OK: identity and branch context belong somewhere
- Bad: screen size alone is a warning sign
- Bad: too many responsibilities likely coexist here
- Dead: growing this screen indefinitely
- Primary problem: screen scope is too large for long-term usability
- Secondary problem: cognitive load is high
- Tertiary problem: maintenance and testing cost will keep rising
- UX solution: split settings into smaller sections or routes
- UI solution: clearer grouping and lighter subsection headers
- Data solution: show current state summaries before edit-heavy forms
- Performance solution: isolate subsections and their rebuilds
- Accessibility solution: smaller, clearer focus scopes
- Copy solution: shorten explanatory text and improve section labels
- Do not do: keep adding new settings blocks to the same file

## 151. Provider Dashboard Matrix
- Portal: Provider
- Page: Dashboard
- File: `provider_dashboard_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: natural home for queue and work summary
- Good: can orient provider quickly
- Good: route relevance is high
- OK: supports daily workload framing
- OK: can link into queue and appointments
- Bad: dashboard must not compete with actual worklist
- Bad: decorative summaries reduce urgency
- Dead: dashboard as passive role overview
- Primary problem: work queue should matter more than summary cards
- Secondary problem: today's action items need stronger visibility
- Tertiary problem: documents and prescriptions need priority cues
- UX solution: worklist-first provider dashboard
- UI solution: compress summary, enlarge queue strip
- Data solution: pending actions, appointments, reports due, unread items
- Performance solution: staged card loading and queue refresh
- Accessibility solution: quick open actions need keyboard path
- Copy solution: task-first wording
- Do not do: make this a pretty landing page only

## 152. Provider Queue Matrix
- Portal: Provider
- Page: Queue
- File: `provider_queue_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: queue is the right operational center
- Good: provider stage logic can shine here
- Good: matches actual provider work habits
- OK: empty-state owner exists
- OK: can become very strong
- Bad: generic stage language would blunt its value
- Bad: queue must feel fast, not ornamental
- Dead: queue list without clear item progression
- Primary problem: stage transitions and urgency need stronger grammar
- Secondary problem: row details and next actions need speed
- Tertiary problem: item routing must preserve context
- UX solution: column or segmented queue with strong stage counts
- UI solution: denser queue rows and stronger urgency indicators
- Data solution: stage, patient, due time, document state, next action
- Performance solution: stage-specific refresh and cache
- Accessibility solution: keyboard triage and action shortcuts
- Copy solution: use simple, urgent verbs
- Do not do: flatten all queue items into one neutral list

## 153. Provider Customers Matrix
- Portal: Provider
- Page: Customers
- File: `provider_customers_screen.dart`
- Overall status: `BAD`
- Architecture status: `BAD`
- UX status: `BAD`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: this is where serious clinical/provider work can happen
- Good: patient workspace ambition is real
- Good: print, search, and tab concepts exist
- OK: enough value exists to justify deep refactor
- OK: core workflows belong together conceptually
- Bad: screen size and responsibility load are too high
- Bad: empty-state and placeholder-style field naming still show up
- Dead: continuing in this ownership model
- Primary problem: one screen is owning too much product
- Secondary problem: maintainability and UX consistency are both at risk
- Tertiary problem: density and navigation can get chaotic
- UX solution: separate list shell, patient header, tab content, documents, notes, billing, history
- UI solution: stronger patient summary strip and tab ergonomics
- Data solution: consistent formatting, clearer section summaries, fewer generic empty states
- Performance solution: split data loading by tab and submodule
- Accessibility solution: break giant page into navigable regions
- Copy solution: remove placeholder-style wording and generic “No info” language
- Do not do: add more workflow panels into the same monolith

## 154. Provider Appointments Matrix
- Portal: Provider
- Page: Appointments
- File: `provider_appointments_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: strong provider role fit
- Good: appointments are operationally central
- Good: can stay focused if designed well
- OK: naturally supports date and status groupings
- OK: can tie into documents and prescriptions
- Bad: cluttered layout would make it slower than necessary
- Bad: slot and visit status need sharper visual differentiation
- Dead: appointment page without quick action flow
- Primary problem: providers need speed more than decorative context
- Secondary problem: linking from appointment to patient and documentation must stay easy
- Tertiary problem: reschedule/cancel states need clarity
- UX solution: compact schedule with strong actions
- UI solution: denser slot rendering and better status chips
- Data solution: time, patient, service, status, provider note, follow-up
- Performance solution: date-range caching
- Accessibility solution: appointment actions accessible without hover dependency
- Copy solution: use concise visit and schedule labels
- Do not do: bury next actions below large summary blocks

## 155. Provider Documents Matrix
- Portal: Provider
- Page: Documents
- File: `provider_documents_screen.dart`
- Overall status: `WEAK`
- Architecture status: `WEAK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: patient-linked document access is necessary
- Good: a place for invoices and records is valid
- Good: the module supports a real workflow need
- OK: can integrate with patients and queue
- OK: document categories can be valuable
- Bad: too many “not available yet” style states reduce confidence
- Bad: preview and triage may not be strong enough
- Dead: document shelves with weak context
- Primary problem: users need task-oriented record handling
- Secondary problem: invoice and medical record grouping must be obvious
- Tertiary problem: upload confidence and preview quality matter
- UX solution: clearer category grouping and patient context strip
- UI solution: preview-focused layout with concise metadata
- Data solution: document type, source, date, status, linked patient, action
- Performance solution: preview lazy-loading and smaller subtrees
- Accessibility solution: simpler list semantics and file actions
- Copy solution: replace passive absence text with clearer guidance
- Do not do: let the page become a miscellaneous attachments bucket

## 156. Provider Prescriptions Matrix
- Portal: Provider
- Page: Prescriptions
- File: `provider_prescriptions_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: clinically meaningful surface
- Good: print and export value exists
- Good: can tie into visits and patient details naturally
- OK: list/detail approach is suitable
- OK: confidence and revision workflow can be built
- Bad: prescription UX gets risky if review and generation states are muddy
- Bad: clinical artifact presentation must stay highly readable
- Dead: prescription module without strong create/review/print flow
- Primary problem: trust and readability dominate this module
- Secondary problem: status and authorship context need to be obvious
- Tertiary problem: document linkage should be tight
- UX solution: create-review-print sequence with version context
- UI solution: concise card/row summaries and better metadata grouping
- Data solution: patient, author, date, meds, status, version, print state
- Performance solution: avoid reloading whole patient context on small actions
- Accessibility solution: printable and readable interaction path
- Copy solution: keep clinical language clear but not cluttered
- Do not do: hide important prescription states in dense text blobs

## 157. Provider Profile Matrix
- Portal: Provider
- Page: Profile
- File: `provider_profile_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: needed personal and operational identity surface
- Good: simpler than patient operations
- Good: appropriate place for provider metadata
- OK: can remain straightforward
- OK: useful anchor for account context
- Bad: should not become an overflow destination for unrelated workflows
- Bad: overloading profile reduces clarity
- Dead: profile as a mixed settings plus operations junk drawer
- Primary problem: keep identity and operations separated
- Secondary problem: credentials and affiliations need better summaries
- Tertiary problem: profile should link out, not absorb too much
- UX solution: focus profile on identity, services, branches, credentials
- UI solution: summary blocks and concise grouped metadata
- Data solution: provider type, status, branches, services, credentials, agreement
- Performance solution: lightweight fetch and small rebuild scope
- Accessibility solution: clear sections and headings
- Copy solution: plain identity and credential language
- Do not do: merge workflow-heavy modules into profile

## 158. Provider Settings Matrix
- Portal: Provider
- Page: Settings
- File: `provider_settings_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: settings surface is necessary
- Good: can be calmer than clinical modules
- Good: fits provider support needs
- OK: manageable scope if kept segmented
- OK: can improve trust around device, account, preferences
- Bad: too much technical language would weaken adoption
- Bad: if settings become long and mixed, usability drops
- Dead: giant mixed settings page
- Primary problem: segmentation and clarity
- Secondary problem: save-state and error-state feedback
- Tertiary problem: preference summaries
- UX solution: split into account, notifications, security, workspace prefs
- UI solution: better grouped forms and concise headers
- Data solution: current-state summaries before edit interactions
- Performance solution: smaller subtrees and independent save flows
- Accessibility solution: preserve simple tab order
- Copy solution: reduce jargon
- Do not do: let settings feel like a config dump

## 159. Provider Auth Matrix
- Portal: Provider
- Page: Internal Login
- File: `internal_login_screen.dart`
- Overall status: `OK`
- Architecture status: `WEAK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: internal auth route exists
- Good: clear separation from customer auth
- Good: operational necessity is clear
- OK: straightforward surface
- OK: login flow can be polished quickly
- Bad: debug-oriented residue should stay out of production feel
- Bad: failure guidance and support path need polish
- Dead: developer-feeling login UX
- Primary problem: trust and clarity at entry
- Secondary problem: secure but friendly failure messaging
- Tertiary problem: session persistence confidence
- UX solution: cleaner auth flow with clear support path
- UI solution: calmer layout and stronger feedback hierarchy
- Data solution: clear session/device information when useful
- Performance solution: fast auth initialization and error recovery
- Accessibility solution: clear field focus, validation, and error descriptions
- Copy solution: remove any debug-adjacent tone
- Do not do: leave auth messaging rough

## 160. Customer Splash Matrix
- Portal: Customer
- Page: Splash
- File: `customer_splash_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `N/A`
- Good: appropriate auth bootstrap entry
- Good: likely simple and limited in duration
- Good: separates restore logic from main flow
- OK: good starting point
- OK: small surface, easy to polish
- Bad: slow or silent transitions would hurt trust
- Bad: ambiguous auth recovery states are risky
- Dead: long idle splash
- Primary problem: users need confidence that progress is happening
- Secondary problem: offline and retry states matter
- Tertiary problem: branding vs wait-time balance
- UX solution: brief restore with clear fallback
- UI solution: simple status feedback and consistent branding
- Data solution: none heavy, mostly auth state clarity
- Performance solution: keep boot path lean
- Accessibility solution: readable loading text and retries
- Copy solution: reassuring and concise
- Do not do: keep users waiting without explanation

## 161. Customer Login Matrix
- Portal: Customer
- Page: Login
- File: `customer_login_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: direct OTP path is simple
- Good: role and purpose are clear
- Good: important entry surface exists
- OK: reasonable foundation
- OK: easy page to make feel premium
- Bad: validation and country/number formatting must be excellent
- Bad: error tone can easily feel blunt
- Dead: verbose or cluttered login layout
- Primary problem: trust and clarity in first input
- Secondary problem: invalid number handling
- Tertiary problem: support and help routing
- UX solution: one clear CTA and strong validation
- UI solution: calm layout and strong contrast
- Data solution: phone formatting and hint quality
- Performance solution: keep submit and resend fast
- Accessibility solution: numeric keyboard, good labels, readable errors
- Copy solution: concise and human
- Do not do: overcomplicate login with too much explanation

## 162. Customer OTP Matrix
- Portal: Customer
- Page: OTP
- File: `customer_otp_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: critical second-step screen exists
- Good: likely focused and linear
- Good: can be polished well
- OK: OTP flow is structurally simple
- OK: strong candidate for quick UX wins
- Bad: resend and timer state need to be perfect
- Bad: invalid-code messaging must be calm and clear
- Dead: OTP screen with weak resend logic communication
- Primary problem: timer and resend clarity
- Secondary problem: code entry friction
- Tertiary problem: transition confidence after success
- UX solution: clear countdown, resend state, and code-field behavior
- UI solution: high-clarity step header and input boxes
- Data solution: phone number echo and time status
- Performance solution: low-latency submission feedback
- Accessibility solution: autofill and readable error labels
- Copy solution: short and reassuring
- Do not do: make users guess when they can resend

## 163. Customer Register Matrix
- Portal: Customer
- Page: Register
- File: `customer_register_screen.dart`
- Overall status: `WEAK`
- Architecture status: `OK`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `OK`
- Good: registration path exists
- Good: customer onboarding is supported
- Good: business requirement fit is clear
- OK: can become much better with step discipline
- OK: not too late to structure well
- Bad: onboarding forms are naturally high-friction if not staged
- Bad: agent-code and identity requirements need graceful explanation
- Dead: one giant, intimidating registration sheet
- Primary problem: onboarding cognitive load
- Secondary problem: requirement clarity
- Tertiary problem: completion confidence
- UX solution: progressive steps with confirmation review
- UI solution: chunk fields and show only what matters now
- Data solution: required vs optional, validation, and next-step clarity
- Performance solution: save progress and restore draft
- Accessibility solution: predictable focus and validation ordering
- Copy solution: supportive instructions instead of bureaucratic wording
- Do not do: overload first-time users with all fields at once

## 164. Customer Dashboard Matrix
- Portal: Customer
- Page: Dashboard
- File: `dashboard_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: central customer home exists
- Good: can combine membership, wallet, services, and notifications
- Good: calm layout direction is appropriate
- OK: likely visually more approachable than internal portals
- OK: supports self-service journey
- Bad: non-actionable summaries can weaken daily value
- Bad: hierarchy may still need tightening
- Dead: customer dashboard as static info sheet
- Primary problem: home screen should guide action, not just show status
- Secondary problem: wallet and membership summaries need strong readability
- Tertiary problem: next recommended action should be visible
- UX solution: clearer quick actions and status highlights
- UI solution: cleaner hierarchy and tighter cards
- Data solution: human-readable wallet and membership summaries
- Performance solution: staged loading for summary modules
- Accessibility solution: easy access to key destinations
- Copy solution: friendly but concise
- Do not do: over-internalize the customer home copy

## 165. Customer Documents Matrix
- Portal: Customer
- Page: Documents
- File: `customer_documents_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: useful self-service record access
- Good: customers need this
- Good: likely easy to polish
- OK: clear module purpose
- OK: can stay focused
- Bad: status and availability messaging needs to be clear
- Bad: empty states must help, not shrug
- Dead: documents page as a passive archive only
- Primary problem: customers need to know what each file is and what to do next
- Secondary problem: approval and pending states need plain wording
- Tertiary problem: download and preview actions must be effortless
- UX solution: group files by type and status
- UI solution: cleaner metadata rows and action placement
- Data solution: file type, date, status, issuer, preview/download
- Performance solution: avoid heavy previews until requested
- Accessibility solution: readable file action rows
- Copy solution: simple document labels and helpful absence states
- Do not do: use internal approval terms without explanation

## 166. Customer Membership Matrix
- Portal: Customer
- Page: Membership
- File: `membership_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: one of the core customer value modules
- Good: domain is central to SHIELD
- Good: can be very clear with the right copy
- OK: likely calmer than internal pages
- OK: benefits and validity can be communicated well
- Bad: membership pages often become too abstract
- Bad: benefits and expiry can be underexplained
- Dead: plan page without lifecycle meaning
- Primary problem: explain current plan and next step clearly
- Secondary problem: benefits and usage must be readable
- Tertiary problem: renewal and expiry warnings must be confident
- UX solution: current plan summary, benefits, eligibility, renewal panel
- UI solution: clearer plan strip and benefit blocks
- Data solution: plan name, status, expiry, benefits, usage, transactions
- Performance solution: lightweight refresh after renewals
- Accessibility solution: straightforward section reading order
- Copy solution: plain member language
- Do not do: bury the important membership state below generic text

## 167. Customer Prescriptions Matrix
- Portal: Customer
- Page: Prescriptions
- File: `customer_prescriptions_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `OK`
- Data trust status: `OK`
- Density status: `OK`
- Action clarity: `OK`
- Good: valuable self-service clinical history surface
- Good: customers need trusted access to prescriptions
- Good: can remain compact and readable
- OK: focused use case
- OK: easy to improve with formatting
- Bad: clinical readability matters; weak metadata will hurt trust
- Bad: date, doctor, and file availability need strong clarity
- Dead: prescription list without context
- Primary problem: make medical information readable and calm
- Secondary problem: preview and download should be obvious
- Tertiary problem: history ordering matters
- UX solution: timeline-aware list with clear metadata
- UI solution: cleaner item cards or rows
- Data solution: date, issuer, type, status, preview/download
- Performance solution: fetch detail on demand
- Accessibility solution: large, readable touch targets
- Copy solution: avoid technical clutter in summaries
- Do not do: show raw record fields

## 168. Customer Wallet Matrix
- Portal: Customer
- Page: Wallet
- File: `wallet_screen.dart`
- Overall status: `OK`
- Architecture status: `OK`
- UX status: `WEAK`
- Data trust status: `CRITICAL`
- Density status: `OK`
- Action clarity: `WEAK`
- Good: wallet is a central customer promise
- Good: dedicated module and widgets exist
- Good: can become one of the strongest customer pages
- OK: ledger-driven backend rules create a truthful base
- OK: transaction histories fit self-service well
- Bad: ledger semantics are easy to miscommunicate
- Bad: benefit handling must stay extremely precise
- Dead: any wallet UX that implies hidden internal benefit is visible balance
- Primary problem: customers must understand what money or points they can really use
- Secondary problem: transaction histories need strong labels
- Tertiary problem: rewards and cash must stay visually distinct
- UX solution: cash, rewards, and benefit use explanations separated clearly
- UI solution: cleaner balance cards and better transaction grouping
- Data solution: strong transaction types, references, and impact summaries
- Performance solution: paginate long histories and cache summary
- Accessibility solution: readable financial rows and totals
- Copy solution: precision over marketing language
- Do not do: blur cash and non-cash value sources

## 169. Shared Admin Runtime Matrix
- Surface: Admin shared runtime
- Files: `admin_workspace_controller.dart`, `admin_backend_workspace_module.dart`
- Overall status: `GOOD`
- Architecture status: `GOOD`
- UX status: `OK`
- Data trust status: `GOOD`
- Density status: `WEAK`
- Action clarity: `OK`
- Good: strongest reusable foundation in the repo
- Good: query-driven, backend-owned, renderer-based
- Good: real strategic asset
- OK: already useful
- OK: can absorb many improvements once
- Bad: copy and density are still behind architecture quality
- Bad: keyboard and URL persistence are incomplete
- Dead: bypassing this runtime for new admin work
- Primary problem: presentation quality must catch up to architecture
- Secondary problem: grid ergonomics need maturity
- Tertiary problem: query persistence is still behind enterprise expectation
- UX solution: saved views, drawers, stronger table semantics
- UI solution: denser layout and cleaner action language
- Data solution: formatting helpers and display contracts
- Performance solution: targeted panel refresh and better cache invalidation
- Accessibility solution: keyboard-first behavior for runtime components
- Copy solution: remove fallback/dev phrasing
- Do not do: create parallel admin architectures

## 170. Shared Portal Shell Matrix
- Surface: Portal shell
- File: `portal_shell.dart`
- Overall status: `BAD`
- Architecture status: `BAD`
- UX status: `WEAK`
- Data trust status: `OK`
- Density status: `WEAK`
- Action clarity: `WEAK`
- Good: one shell coordinates all role families
- Good: can still serve as transition layer
- Good: central navigation logic exists
- OK: supports role-dependent framing
- OK: already in production path
- Bad: file size is a red flag
- Bad: too many responsibilities live here
- Dead: future expansion through more shell branching
- Primary problem: the shell is too central
- Secondary problem: change risk is high
- Tertiary problem: consistency is hard to enforce through one mega-file
- UX solution: push role-specific behavior downward into runtimes
- UI solution: standardize shell spacing and sidebar behavior
- Data solution: reduce local data transformation burden
- Performance solution: reduce rebuild breadth and branch complexity
- Accessibility solution: standardize shell-level navigation focus and shortcuts
- Copy solution: keep shell surfaces minimal and neutral
- Do not do: continue adding major workflow UI directly in the shell

## 171. Product-Wide UI Rules
- Tables are primary in operational modules.
- Detail panes are secondary.
- Cards are not the default answer.
- Empty states must always tell users what to do next.
- Search must feel persistent.
- Filters must feel reversible.
- Selection must never be ambiguous.
- Date formatting must always be human-readable.
- Money formatting must always be explicit.
- Technical wording must stay out of user-facing surfaces.
- Sidebars must not consume premium workspace by default.
- Typography hierarchy must always reveal what matters first.
- Status colors must always mean something consistent.
- Metrics without actions are decoration.
- Timelines without navigation are decoration.
- Notifications without next-step routing are noise.
- Reports without workflow are noise.
- CRM without queue urgency is noise.
- Wallet without ledger clarity is dangerous.
- Provider and agent monolith screens must be reduced, not expanded.

## 172. Product-Wide UX Rules
- Every primary page needs a single obvious purpose.
- Every action needs a visible outcome.
- Every mutation needs a confirmation or a confidence pattern where appropriate.
- Every list needs a scan path.
- Every detail view must justify its screen space.
- Every filter should be discoverable, reversible, and persistent.
- Every search should support clear, type, wait, result.
- Every empty state should explain why and what next.
- Every permission-denied state should explain what is missing without exposing internals.
- Every export flow should confirm that a file is ready and what it contains.
- Every approval flow should show current state, required step, and actor responsibility.
- Every queue should separate urgent from merely pending.
- Every dashboard should link into real work.
- Every customer-facing financial surface should optimize for trust over cleverness.

## 173. Product-Wide Data Display Rules
- Customer names should never compete with raw identifiers.
- Identifiers should support recognition, not dominate.
- Phone numbers should be readable.
- Dates should be localized and human-first.
- Currency should include symbol and clear precision.
- Counts should be concise and grouped logically.
- Rewards and cash should not visually blend.
- Internal-only values should stay internal-only.
- Status strings should be normalized.
- Timestamps should indicate exact or relative meaning intentionally.
- Membership statuses should feel product-like, not database-like.
- Queue states should feel task-like, not abstract.
- Audit evidence should feel forensic, not dump-like.
- Provider credentials should feel compliance-oriented, not profile-oriented.

## 174. Product-Wide Copy Rules
- Avoid “backend-driven”.
- Avoid “workspace contract”.
- Avoid “current filters” if a more natural phrase exists.
- Avoid “no data available” without a reason.
- Avoid “unavailable” as a lazy catch-all when a better explanation exists.
- Avoid internal implementation nouns in operator pages.
- Prefer “Showing 25 customers” to “25 rows returned”.
- Prefer “Needs review” to “pending verification state” unless precision requires otherwise.
- Prefer “Last updated” to raw timestamp headings where context allows.
- Prefer “Wallet activity” to “transaction ledger” in customer surfaces unless the ledger concept is central.
- Prefer “Customer actions” to “record actions”.
- Prefer “Bulk actions” only when a real selection exists.

## 175. Product-Wide Performance Rules
- Debounce search.
- Preserve query state.
- Reload only what changed when feasible.
- Avoid giant screens owning too many tabs and behaviors.
- Split dense workflows into smaller owners.
- Cache list data by query shape.
- Delay expensive previews until requested.
- Avoid rebuilding entire shells for local changes.
- Make refresh visible but not disruptive.
- Use lazy detail loading for deep tabs.

## 176. Product-Wide Accessibility Rules
- Support keyboard-first internal operations.
- Maintain visible focus states.
- Keep checkbox behavior separate from row-open behavior.
- Provide text alongside color for status.
- Maintain adequate touch targets.
- Avoid tiny action menus in dense rows without keyboard alternative.
- Make dialogs simple, narrow, and readable.
- Keep error messages near the affected control.
- Ensure section headers form a readable hierarchy.
- Use semantic labels for critical actions and status chips.

## 177. Product-Wide Density Rules
- Reduce header padding.
- Reduce stacked-card padding.
- Reduce sidebar width.
- Increase table share of workspace width.
- Use detail drawers or lower tabs instead of permanent wide right panes.
- Keep summary strips compact.
- Let the primary content own the center.
- Use whitespace to group, not to drift.
- Avoid giving equal visual weight to low-value metadata.
- Maintain one spacing rhythm across portal families.

## 178. Admin Must-Fix Checklist
- Add search debounce to shared admin controller.
- Persist admin query state in URL.
- Improve admin table density.
- Improve admin action menu labels.
- Improve admin detail drawer or subordinate detail behavior.
- Remove remaining awkward fallback copy.
- Strengthen audit diff readability.
- Upgrade reports into workflow.
- Upgrade CRM into queue-first experience.
- Upgrade wallet into ledger-first experience.
- Upgrade memberships into lifecycle-first experience.
- Upgrade providers into approval-first experience.
- Protect customers as the reference module.

## 179. Agent Must-Fix Checklist
- Reduce screen-specific pattern drift.
- Break up oversized settings surface.
- Improve follow-up urgency grammar.
- Improve dashboard next-action focus.
- Improve document task framing.
- Improve performance drill-down clarity.
- Improve report usefulness or remove weak shells.
- Standardize list/detail behavior across screens.
- Improve print and export action placement.
- Improve empty-state guidance across agent modules.

## 180. Provider Must-Fix Checklist
- Decompose provider customers screen.
- Strengthen queue as primary operational home.
- Improve document preview and review flows.
- Improve prescription confidence and print flows.
- Keep profile lean.
- Keep settings segmented.
- Improve provider auth tone and polish.
- Normalize customer/patient sub-surface wording.
- Replace placeholder-style field language.
- Reduce giant controller and giant screen risk.

## 181. Customer Must-Fix Checklist
- Improve auth copy and confidence.
- Improve OTP resend clarity.
- Break registration into stronger steps if not already.
- Improve wallet explanation quality.
- Improve membership lifecycle clarity.
- Improve dashboard quick-action usefulness.
- Improve document status explanation.
- Improve prescription readability.
- Improve empty states across self-service pages.
- Keep customer tone simple and calm.

## 182. Admin Page Remediation Tracker
- Dashboard: make every KPI drillable
- Dashboard: compress metric strip
- Dashboard: remove decorative widget thinking
- Customers: preserve no-default-selection behavior
- Customers: strengthen detail interaction
- Customers: add saved views and stronger filters later
- Agents: strengthen lifecycle actions
- Agents: sharpen attendance and performance semantics
- CRM: redesign as queue, not record list
- CRM: make next action dominant
- Visits: emphasize time and due state
- Visits: improve provider/customer linkage
- Documents: optimize for preview and review speed
- Documents: make rejection and approval history stronger
- Memberships: add full lifecycle control
- Memberships: clarify benefits and usage
- Notifications: strengthen delivery-state meaning
- Notifications: make items actionable
- Branches: link to people, providers, revenue, customers
- Branches: stop at profile-only thinking
- Employees: expose role and branch context clearly
- Employees: improve permission visibility
- Roles: translate permission codes into business language
- Roles: group permissions better
- Providers: prioritize approval and compliance flow
- Providers: show service and branch assignment clearly
- Referrals: clarify state machine
- Referrals: link rewards and customers tightly
- Rewards: show event ledger, not only totals
- Rewards: show provenance and reversals
- Services: surface rule and provider compatibility context
- Services: avoid flat service list UX
- Reports: build workflow with preview and history
- Reports: stop at chooser-grid thinking
- Insights: make every chart lead somewhere
- Insights: reduce decorative analytics
- Wallet: enforce ledger-first trust model
- Wallet: separate sub-ledgers clearly
- Availability: make time visible, not buried
- Availability: add exception handling UX
- Settings: humanize config editing
- Settings: keep unavailable domains honest but helpful
- Platform: add business-impact framing
- Platform: reduce engineer-only tone
- Audit: improve before/after visualization
- Audit: keep actor and reason prominent

## 183. Agent Page Remediation Tracker
- Dashboard: show today’s work first
- Dashboard: reduce passive metric space
- Customers: emphasize next step and follow-up context
- Customers: improve action grouping
- Appointments: sharpen slot and provider clarity
- Appointments: improve no-show and reschedule states
- Documents: turn into task-oriented record handling
- Documents: reduce empty-state dependence
- Follow-ups: make urgency dominant
- Follow-ups: add faster outcome logging
- Notifications: route items to real work
- Notifications: improve priority grouping
- Performance: connect metrics to underlying work
- Performance: reduce vanity-chart feel
- Referrals: improve stage explanation
- Referrals: show next expected state
- Registration: split form burden
- Registration: add better progress and review
- Reports: either add real reports or keep scope smaller
- Reports: improve export confidence
- Settings: split into smaller sections
- Settings: reduce cognitive overload

## 184. Provider Page Remediation Tracker
- Dashboard: lead with queue, not summary
- Dashboard: emphasize pending actions
- Queue: show urgent versus pending more clearly
- Queue: keep item actions close and fast
- Customers: split monolith into smaller owned regions
- Customers: improve patient header and tab clarity
- Customers: reduce generic empty-state text
- Customers: stop growing this screen further in place
- Appointments: denser schedule display
- Appointments: better appointment action feedback
- Documents: better grouping and preview
- Documents: better missing-record guidance
- Prescriptions: stronger create-review-print path
- Prescriptions: stronger metadata readability
- Profile: keep it identity-focused
- Profile: do not absorb workflow junk
- Settings: segment clearly
- Settings: simplify save and error feedback
- Auth: remove any debug-adjacent feel
- Auth: improve trust and recovery messaging

## 185. Customer Page Remediation Tracker
- Splash: keep restore flow short and clear
- Login: polish validation and help text
- OTP: clarify timer and resend state
- Register: reduce onboarding fatigue
- Dashboard: increase task usefulness
- Dashboard: improve wallet and membership summaries
- Documents: better document-state language
- Documents: clearer download and preview actions
- Membership: show current plan and next step plainly
- Membership: improve benefit readability
- Prescriptions: clearer date and issuer context
- Prescriptions: stronger preview path
- Wallet: separate cash and rewards visually and verbally
- Wallet: never imply hidden benefit is visible balance

## 186. Remove List
- Remove technical labels from user-facing admin text
- Remove passive KPI cards that do not navigate
- Remove oversized permanent detail panes where they hurt grid work
- Remove placeholder-style wording in provider and other internal screens
- Remove debug print residue from production-facing experience paths
- Remove decorative dashboard growth
- Remove vague empty states with no action
- Remove profile-only module ambition in business-critical areas

## 187. Keep List
- Keep admin runtime architecture
- Keep backend-owned workspace semantics
- Keep ledger truth in wallet
- Keep explicit unavailable states when a domain truly is missing
- Keep customer portal calmness
- Keep provider queue centrality
- Keep agent registration importance
- Keep action metadata direction
- Keep repository and runtime layering discipline

## 188. Expand Carefully List
- Expand admin shared renderer polish
- Expand action descriptors to more portal families
- Expand shared formatting helpers
- Expand saved views after core interactions stabilize
- Expand detail drawers where they improve width usage
- Expand timeline navigation where events are truly actionable
- Expand workflow-driven reports, not report cards
- Expand queue-first CRM, not generic CRM tables

## 189. Do Not Expand List
- Do not expand `portal_shell.dart` as the main UI owner
- Do not expand `provider_customers_screen.dart` in place
- Do not expand `agent_settings_screen.dart` in place
- Do not expand decorative dashboard widgets
- Do not expand profile-only provider/admin modules in place of real workflows
- Do not expand technical copy in operator pages
- Do not expand passive report galleries
- Do not expand ambiguous wallet language

## 190. Final Operational Conclusion
- The repo is far enough along that honest UX auditing matters more than optimistic roadmapping.
- The best investment is to tighten the shared interaction model and reduce the largest monolith screens.
- The admin runtime should become the standard.
- The provider customer monolith should become the warning sign everyone respects.
- The customer wallet page should be treated as a trust-critical surface.
- The report above should be used as an execution checklist, not as an archive.

## 191. Non-Negotiables By Admin Page
### Dashboard
- Every KPI must drill down.
- Every widget must justify its existence.
- The grid must stay the hero if a list exists.

### Customers
- No default selection.
- No fake status text.
- No decorative detail pane waste.

### Agents
- No profile-only management.
- No shallow performance summary pretending to be management.
- No hidden assignment logic.

### CRM
- No generic record list masquerading as CRM.
- No missing urgency grammar.
- No next-action ambiguity.

### Visits
- No flat neutral treatment of overdue and missed visits.
- No weak date formatting.
- No buried provider/customer context.

### Documents
- No file bucket UX.
- No weak preview flow.
- No approval flow without reason history.

### Memberships
- No “view only”.
- No plan-summary-only surface.
- No missing lifecycle actions.

### Notifications
- No passive inbox-only posture.
- No failed delivery hidden in flat rows.
- No meaningless unread counts without routing.

### Branches
- No static profile-only branch pages.
- No branch without linked workforce context.
- No branch without operational metrics.

### Employees
- No people list without role and branch clarity.
- No unreadable permission mapping.
- No hidden lifecycle actions.

### Roles
- No raw permission-key UX.
- No undifferentiated permission matrix walls.
- No technical wording left untranslated.

### Providers
- No provider governance without approval and compliance.
- No profile-only illusion.
- No unclear branch or service assignment.

### Referrals
- No flattened status model.
- No hidden reward timing ambiguity.
- No referral ledger without customer context.

### Rewards
- No totals without provenance.
- No reward actions without audit.
- No vague reward-source language.

### Services
- No flat catalog-only UX.
- No missing provider compatibility context.
- No hidden business-rule ownership.

### Reports
- No card-gallery-only report module.
- No export without preview or feedback.
- No schedule/history invisibility.

### Insights
- No chart without drill-down.
- No decorative analytics.
- No unclear timeframe semantics.

### Wallet
- No misleading balance language.
- No hidden benefit shown like customer cash.
- No wallet summary without ledger truth.

### Availability
- No generic rows pretending to be scheduling UX.
- No hidden exceptions.
- No weak time hierarchy.

### Settings
- No developer-config-sheet feel.
- No unexplained unavailable domain wording.
- No unsafe editing without context.

### Platform
- No engineer-only diagnostic tone.
- No health status without operator meaning.
- No equal visual weight for info and incidents.

### Audit
- No raw-log feeling.
- No invisible before/after context.
- No weak actor or reason visibility.

## 192. Non-Negotiables By Agent Page
### Dashboard
- No passive KPI wallpaper.
- No hidden today-work.
- No summary-first bias over task flow.

### Customers
- No weak next-step context.
- No action clutter.
- No customer list without follow-up cues.

### Appointments
- No vague slot state.
- No weak provider-availability messaging.
- No buried reschedule/no-show handling.

### Documents
- No file-shelf mentality.
- No generic missing-document messages.
- No preview-light workflow.

### Follow-ups
- No neutral treatment of overdue work.
- No weak outcome logging.
- No task list without urgency.

### Notifications
- No passive inbox UX.
- No irrelevant noise dominating critical alerts.
- No unread/read bias over priority.

### Performance
- No vanity metrics.
- No charts without behavior linkage.
- No percentages without underlying work context.

### Referrals
- No ambiguous reward-stage wording.
- No weak tree context.
- No hidden next-state explanation.

### Registration
- No one-shot giant form.
- No weak progress guidance.
- No unclear completion state.

### Reports
- No shell with no useful outputs.
- No weak template relevance.
- No export ambiguity.

### Settings
- No further screen bloat.
- No mixed-domain overload.
- No low-signal long-form sprawl.

## 193. Non-Negotiables By Provider Page
### Dashboard
- No summary-first over queue-first design.
- No passive workload framing.
- No weak action routing.

### Queue
- No flat stage semantics.
- No hidden urgency.
- No slow path from queue to action.

### Customers
- No more monolith growth.
- No placeholder-style wording.
- No one-screen-owns-everything design.

### Appointments
- No cluttered schedule scan path.
- No weak action feedback.
- No hidden patient context.

### Documents
- No attachment-bucket UX.
- No unclear record categories.
- No weak missing-record guidance.

### Prescriptions
- No unclear create-review-print flow.
- No weak medical readability.
- No hidden authorship or version context.

### Profile
- No junk-drawer creep.
- No workflow spillover.
- No weak credential summary.

### Settings
- No mixed mega-form growth.
- No low-trust save behavior.
- No technical tone dominance.

### Auth
- No debug-feeling UI.
- No vague failure explanations.
- No weak support path.

## 194. Non-Negotiables By Customer Page
### Splash
- No unexplained wait.
- No unclear retry path.
- No noisy boot messaging.

### Login
- No sloppy validation.
- No cluttered entry form.
- No uncertain primary CTA.

### OTP
- No ambiguous resend timing.
- No weak error messaging.
- No step confusion.

### Register
- No giant intimidating form.
- No unclear agent-code guidance.
- No weak completion confidence.

### Dashboard
- No static brochure dashboard.
- No non-actionable card clutter.
- No weak wallet and membership summaries.

### Documents
- No passive file dump.
- No confusing status labels.
- No weak preview/download cues.

### Membership
- No abstract plan sheet feel.
- No unclear benefit explanation.
- No buried expiry or renewal state.

### Prescriptions
- No raw record field dumps.
- No weak issuer/date clarity.
- No confusing document actions.

### Wallet
- No blending of cash and rewards.
- No misleading hidden-benefit implication.
- No weak transaction semantics.

## 195. Final Truth Table
- Admin runtime: keep and improve
- Portal shell: constrain and reduce
- Provider customer monolith: decompose
- Agent settings monolith: decompose
- Customer wallet wording: harden
- Shared copy quality: raise
- Shared density quality: raise
- Shared grid ergonomics: raise
- Shared keyboard/accessibility discipline: raise
- Shared query persistence discipline: raise
