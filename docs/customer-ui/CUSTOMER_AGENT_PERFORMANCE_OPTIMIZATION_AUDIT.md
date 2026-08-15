# Customer + Agent/CRM Performance Optimization Audit

Audited: 2026-08-15 14:35:00 IST  
Scope: source-level only. This document intentionally contains no claimed browser, device, database-plan, or deployed timing. It is a performance inventory, not an authorization to change business workflows or apply database migrations.

## Evidence and constraints

- Current customer and Agent/CRM completion audits remain the functional source baseline. This audit does not reopen a completed workflow without a concrete performance finding.
- Customer startup now renders the Flutter shell before stored-session restoration and non-critical Firebase Messaging, analytics, and token registration complete. Firebase Core still precedes rendering for Phone Auth.
- Dashboard data is customer-keyed cached read data with authoritative refresh. Wallet balances and mutation outcomes remain server authoritative.
- Customer Services uses a two-minute in-memory cache and in-flight de-duplication for category, page, and provider-detail reads. The wellness catalogue is loaded only after the panel is expanded.
- The additive `20260815_customer_performance_indexes` migration is prepared but is not applied by this audit.

## Customer journey inventory

| Journey | Route/screen and initial request ownership | Cache / pagination / loading source | DB/query observation and optimization status |
|---|---|---|---|
| App bootstrap | `main.dart`, splash, route resolver; local auth stores restore after first frame | Immediate splash; no feature API waits before shell | Firebase Messaging/analytics/push are deferred. Deployed first-paint timing pending. |
| Login → OTP | Customer auth screens and Firebase Phone Auth | No customer data cache | Auth provider exchange is ordered security work; device/OTP timing pending. |
| OTP → session | customer auth session plus backend session validation | Shared stored session state; invalid session still clears state | Audit `/auth/me` callers before future auth changes; source does not authorize stale invalid sessions. |
| Authenticated startup | dashboard route and session stores | cached dashboard first, authoritative refresh after | Dashboard contract is a lightweight aggregate; cold-cache skeleton remains. |
| Dashboard | `GET /customer/dashboard` | customer-keyed cache v2 and repository in-flight de-duplication | Documents/unread notifications are counts; appointments and wallet entries are bounded projections. |
| Membership state | dashboard membership resolver and membership route | dashboard cache holds safe nullable snapshot only | Application/card fields must remain nullable; no fabricated cache fallback. |
| Wallet | wallet summary and history controller | local safe read followed by server refresh; history is paged | Server ledger remains authoritative; do not add authoritative financial cache. |
| Services | provider categories/list/detail | 2-minute in-memory request de-duplication; list pages retained | category/page/detail reads have separate cache keys; provider detail remains lazy. |
| Wellness catalogue | Services expansion panel | deferred load; search/category/page requests; no startup prefetch | browse-only list contract; no cart/checkout query or mutation exists. |
| Booking | booking route | form data loads when route opens | dependent provider selection remains ordered; no full provider graph is fetched by dashboard. |
| Visits | visits list/detail | page controller and stale-response protection | first page only is the intended list load; return navigation must not force a full reload. |
| Documents | documents list/upload/detail | list metadata only; preview/download on demand | binary/OCR payload must not be added to list projection. |
| Prescriptions | prescriptions list/upload | owned list and upload flows | prescription intelligence/detail is lazy; no binary request belongs in list bootstrap. |
| Orders | orders list/detail | paged list expected; detail opens on demand | do not load order history on dashboard. |
| Referrals | referral graph and reward views | feature-owned read state | no prefetch at startup; data remains identity scoped. |
| Notifications | inbox/detail/read | inbox pagination; dashboard uses unread count only | do not re-fetch whole inbox solely for badge updates. |
| Activity | customer timeline | bounded page window with Load more; loaded entries persist through refresh | first page limits appointments, documents, notifications, and visible wallet transactions before timeline composition. |
| Profile / pharmacy | account/preferences | feature route owned | mutable preference remains authoritative server read after change. |
| Support | support list/detail | summary list then detail/history on demand | lifecycle events stay lazy and ownership-filtered. |

## Agent / CRM journey inventory

| Journey | Route/screen and initial request ownership | Pagination/loading source | DB/query observation and optimization status |
|---|---|---|---|
| Portal bootstrap | internal session, portal resolver, shell | workspace, customer-page, and reference-data reads run concurrently; duplicate same-customer selection shares in-flight work | preserve role/permission checks; authenticated timing pending. |
| Agent dashboard | Agent dashboard workspace | page-owned metrics/loading | dashboard metrics need summary projections, not customer row graphs. |
| Customer list/search | Agent customers screen | server search/list pagination | preserve AgentScope; do not fetch every assigned customer locally. |
| Customer 360 | selected-customer workspace | identity shell then section-owned reads | wallet, documents, orders, appointments, support, and timeline should remain lazy tabs/sections. |
| Membership review | application review | application detail on demand | scope check is mandatory before review; no broader customer graph needed. |
| Wallet | customer wallet/action views | summary then page history | ledger query must remain scoped and bounded. |
| Appointments | Agent appointment workspace | server-side lists/filters | preserve assignment/provider constraints and first-page loading. |
| Documents/prescriptions | document queues/detail | metadata rows then selected detail | do not return storage binary/extraction payload in queues. |
| Follow-ups | CRM activity/task routes | server filtered list | scope is principal-derived; due/status filter should be database-side. |
| Complaints | CRM complaint queue/detail | paged queue, lifecycle on detail | do not load lifecycle events for all queue rows. |
| Store changes | Agent queue/review | status-scoped queue | requested customer is AgentScope checked before mutation. |
| Reports | platform report registry/run | query only after explicit run/export | report scope/permission stays principal-specific; no cross-principal report cache. |
| Notifications | Agent notification inbox | paged inbox | no complete-inbox reload for a badge only. |

## Proven source findings and actions

| Area | Finding | Action/status |
|---|---|---|
| Startup | Firebase non-critical work could delay useful UI | Deferred after first frame; source verified. |
| Session | Feature startup must not independently own session restoration | Shared session stores/route guard remain authoritative; repeat-call instrumentation remains a manual/deployed audit item. |
| Dashboard | Full document and notification rows were previously unnecessary for count badges | Replaced by count projections; wallet recent entries limited to four and independent reads are parallelized. |
| Services | Directory category/page/detail requests can recur during navigation | Two-minute in-memory cache and in-flight de-duplication added; pull-to-refresh bypasses cache. |
| Product catalogue | Catalogue must not increase ordinary Services first load | Deferred until the customer expands its panel. |
| Activity timeline | Customer timeline loaded every historical source row before rendering | Customer endpoint now requests only the source window needed for the selected page and returns `items` plus `hasMore`; staff/provider timeline behavior is unchanged. |
| Indexes | Customer list/count/order patterns lacked composite indexes in schema snapshot | Additive migration prepared only; applying it and collecting query plans are release-owned tasks. |

## Remaining evidence gates

1. Approved database release application and `current_schema.md` refresh for the prepared performance-index migration.
2. Deployed `PERF customer.dashboard durationMs=...` observations without identifiers or payload logging.
3. Owner-run physical-device cold/warm startup, cached dashboard, Services navigation, OTP, and agent/CRM UAT using `CUSTOMER_PORTAL_PERFORMANCE_UAT.md`.
4. Authenticated request trace confirming one authoritative session validation and no duplicate feature GETs per screen-open cycle.
5. Database query-plan evidence on production-like data for the added indexes; no latency target is achieved until this evidence exists.
