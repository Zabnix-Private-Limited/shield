# Agent Customer Management Full Completion Audit

Audited: 2026-08-14. This is a source-level audit; it is not authenticated production UAT.

## Agent / CRM route-level customer-management matrix

| Route / section | Contract and scope | UI/test evidence | Classification / blocker |
|---|---|---|---|
| `/portal/agent/dashboard` | Agent workspace contract | dashboard customer-operation metrics have focused widget coverage in the portal scroll shell | VERIFIED_COMPLETE / authenticated owner UAT pending |
| `/portal/agent/customers` | assigned customer list/search/360 | AgentScope customer assignment | VERIFIED_COMPLETE |
| `/portal/agent/registration` | customer creation/agent code | agent-owned registration | VERIFIED_COMPLETE |
| customer status/detail | customer APIs | AgentScope explicit customer | PARTIAL / business transition policy |
| membership application review | review API + `customers.approve` | application-customer AgentScope tests | VERIFIED_COMPLETE |
| membership conversion/card | conversion/card APIs | Agent/provider scope | PARTIAL / issuance/replacement source lifecycle |
| wallet visibility/mutation | wallet APIs | AgentScope profile/transaction/recharge/adjust/redeem tests | VERIFIED_COMPLETE |
| appointments | appointment APIs | assignment/provider scope | VERIFIED_COMPLETE |
| documents/prescriptions | document safe projection APIs | customer/provider/agent scope | VERIFIED_COMPLETE |
| orders/referrals | order/referral APIs | provider/branch and agent graph | PARTIAL / fulfilment and reversal lifecycle |
| `/portal/agent/followups` | CRM activities/tasks | explicit and unfiltered AgentScope | VERIFIED_COMPLETE / TEST_VERIFICATION_PENDING populated widget local-runner timeout; escalation belongs to Complaint lifecycle |
| CRM customer timeline | Customer 360 selected-customer activity timeline | customer scope via selected-customer workspace | VERIFIED_COMPLETE / canonical Customer 360 timeline controller test; no duplicate route required |
| support/complaint queue | Complaint plus append-only lifecycle event APIs; deployed schema verified by owner | read/mutation AgentScope; staff actor audit | VERIFIED_COMPLETE / TEST_VERIFICATION_PENDING CRM widget; owner UAT pending |
| `/portal/agent/store-changes` | staff Store Change queue/review; deployed schema verified by owner | AgentScope queue/review plus widgets | VERIFIED_COMPLETE / owner UAT |
| notifications | notification read/send/device-token APIs | AgentScope provider/target scope tests | VERIFIED_COMPLETE / TEST_VERIFICATION_PENDING Agent route widget; device UAT pending |
| `/portal/agent/reports` | backend-owned report registry/run contract; `reports.view` for metadata and `reports.export` for generation; AgentScope overwrites agent code; every export is audited | report chooser/filter/export screen; focused registry-selection and permission-safe empty-state Flutter test; backend permission/scope/report-contract tests | VERIFIED_COMPLETE / authenticated export UAT pending |
| settings/profile | Agent settings contracts | screen exists | VERIFIED_COMPLETE |

| Page / workflow | API / permission | Scope | Classification | Remaining issue |
|---|---|---|---|---|
| Agent login and portal shell | internal session and PortalResolver | role guarded | VERIFIED_COMPLETE | manual UAT |
| Customer list/search/detail | customer/Customer 360 contracts | AgentScopeService customer assignment | VERIFIED_COMPLETE | manual UAT |
| Customer registration | customer creation and agent code | agent-owned code and backend validation | VERIFIED_COMPLETE | manual duplicate/branch UAT |
| Customer status/CRM/timeline | customer and CRM contracts | permission plus agent scope | PARTIAL | status transition business policy needs manual confirmation |
| Membership application review | `customers.approve`, review route | permission plus application-customer AgentScope check | VERIFIED_COMPLETE | owner verified deployed partial unique index; manual UAT |
| Membership conversion | existing `POST /customers/:id/convert-to-membership` | provider/agent scope and `customers.create` | VERIFIED_COMPLETE | manual activation/card workflow UAT |
| Shield card management | card profile/request contracts | customer/agent scoped | PARTIAL | issuance/replacement lifecycle manual UAT |
| Wallet visibility/adjustment | wallet services/controllers | agent customer scope now enforced for recharge/adjust/redeem; ledger authority | VERIFIED_COMPLETE | manual permission mutation UAT |
| Appointment management | appointment controller/service | provider/agent customer scope | VERIFIED_COMPLETE | real scheduling/notification UAT |
| Documents/prescriptions | document safe projections | customer/provider/agent scope | VERIFIED_COMPLETE | signed-storage UAT |
| Orders/pharmacy context | purchase/order contracts | provider/branch scope | PARTIAL | fulfilment/refund deferred |
| Follow-ups/CRM activity | CRM task/activity APIs | AgentScope for explicit customer/task/activity paths and unfiltered agent lists, which receive assigned customer IDs only | VERIFIED_COMPLETE | TEST_VERIFICATION_PENDING populated widget local-runner timeout; escalation is covered by Complaint lifecycle, not duplicated here |
| Support/complaint queue | Complaint persistence plus append-only lifecycle events and CRM complaint APIs; deployed schema verified by owner | every list/detail/mutation is AgentScope-gated; assignment/reassignment, notes, replies, escalation, resolution and audit history are source-covered; customer API filters internal events | VERIFIED_COMPLETE | TEST_VERIFICATION_PENDING focused CRM widget; owner UAT pending |
| Store-change queue | protected `GET /store-change-requests` and `POST /store-change-requests/:id/review`; deployed schema verified by owner | unfiltered agent queue is reduced to assigned customer IDs; review resolves request customer and applies AgentScope; dedicated Agent queue renders load/empty/error/status and approve/reject actions; focused widgets cover empty and pending actions | VERIFIED_COMPLETE | manual UAT pending |
| Customer reports | ten agent-scoped registry reports: registrations, membership, follow-up, support/complaints, appointments, documents, referrals, performance, retention proxy and CRM performance | report generation is permission-gated, agent scope is principal-derived, and exports write an audit log; registry and permission-safe empty state have focused widget coverage | VERIFIED_COMPLETE | authenticated export UAT pending |

## Fix from this audit

Staff membership-application review previously enforced only `customers.approve`. It now resolves the application customer and invokes `AgentScopeService.assertAgentCanAccessCustomer` before review. This prevents a scoped SHIELD_AGENT from reviewing an application for an unassigned customer while preserving authorized non-agent staff behavior.

The platform report endpoints previously had no report-specific permission metadata. The registry now requires `reports.view` and execution requires `reports.export`; an Agent principal still has its submitted scope replaced with the authenticated agent code before any report query runs. The existing registry now also supplies membership, support/complaint, retention-proxy, and CRM-performance customer-management reports from existing persisted data, and every export creates an audit record. The retention report explicitly labels its current-ACTIVE ratio as a proxy rather than inventing cohort/churn semantics.

## Verification

- Focused CustomerService and CustomerMembershipController Jest suites: 18 passed; wallet/support scope suites: 7 passed.
- Focused PlatformCapabilitiesController/PlatformReportService reports suites: 4 passed (permission metadata, authenticated-agent scope override, report registry and scoped support/complaint export).
- Backend `npx tsc --noEmit` and `npm run build` passed after correcting existing test fixture type declarations. Prisma generation occurred, but no schema application or database write was run.
