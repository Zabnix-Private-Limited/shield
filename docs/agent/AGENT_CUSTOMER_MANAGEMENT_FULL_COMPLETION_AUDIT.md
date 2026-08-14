# Agent Customer Management Full Completion Audit

Audited: 2026-08-14. This is a source-level audit; it is not authenticated production UAT.

## Agent / CRM route-level customer-management matrix

| Route / section | Contract and scope | UI/test evidence | Classification / blocker |
|---|---|---|---|
| `/portal/agent/dashboard` | Agent workspace contract | dashboard screen | PARTIAL / customer-operation summary tests pending |
| `/portal/agent/customers` | assigned customer list/search/360 | AgentScope customer assignment | VERIFIED_COMPLETE |
| `/portal/agent/registration` | customer creation/agent code | agent-owned registration | VERIFIED_COMPLETE |
| customer status/detail | customer APIs | AgentScope explicit customer | PARTIAL / business transition policy |
| membership application review | review API + `customers.approve` | application-customer AgentScope tests | VERIFIED_COMPLETE |
| membership conversion/card | conversion/card APIs | Agent/provider scope | PARTIAL / issuance/replacement source lifecycle |
| wallet visibility/mutation | wallet APIs | AgentScope profile/transaction/recharge/adjust/redeem tests | VERIFIED_COMPLETE |
| appointments | appointment APIs | assignment/provider scope | VERIFIED_COMPLETE |
| documents/prescriptions | document safe projection APIs | customer/provider/agent scope | VERIFIED_COMPLETE |
| orders/referrals | order/referral APIs | provider/branch and agent graph | PARTIAL / fulfilment and reversal lifecycle |
| `/portal/agent/followups` | CRM activities/tasks | explicit and unfiltered AgentScope | PARTIAL / internal notes/escalation/UI evidence |
| CRM customer timeline | activity events | customer scope | PARTIAL / dedicated Agent timeline route |
| support/complaint queue | complaint APIs | update/resolve scope | PARTIAL / assignment, replies, escalation, resolution notes UI |
| `/portal/agent/store-changes` | staff Store Change queue/review | AgentScope queue/review plus widgets | VERIFIED_COMPLETE / migration apply + UAT |
| notifications | notification read/send/device-token APIs | AgentScope provider/target scope tests | PARTIAL / Agent notification route workflow test |
| `/portal/agent/reports` | report registry/run contract | reports screen | PARTIAL / customer retention/support/complaint/follow-up/CRM performance report proof |
| settings/profile | Agent settings contracts | screen exists | VERIFIED_COMPLETE |

| Page / workflow | API / permission | Scope | Classification | Remaining issue |
|---|---|---|---|---|
| Agent login and portal shell | internal session and PortalResolver | role guarded | VERIFIED_COMPLETE | manual UAT |
| Customer list/search/detail | customer/Customer 360 contracts | AgentScopeService customer assignment | VERIFIED_COMPLETE | manual UAT |
| Customer registration | customer creation and agent code | agent-owned code and backend validation | VERIFIED_COMPLETE | manual duplicate/branch UAT |
| Customer status/CRM/timeline | customer and CRM contracts | permission plus agent scope | PARTIAL | status transition business policy needs manual confirmation |
| Membership application review | `customers.approve`, review route | permission plus application-customer AgentScope check | VERIFIED_COMPLETE | partial unique index release verification |
| Membership conversion | existing `POST /customers/:id/convert-to-membership` | provider/agent scope and `customers.create` | VERIFIED_COMPLETE | manual activation/card workflow UAT |
| Shield card management | card profile/request contracts | customer/agent scoped | PARTIAL | issuance/replacement lifecycle manual UAT |
| Wallet visibility/adjustment | wallet services/controllers | agent customer scope now enforced for recharge/adjust/redeem; ledger authority | VERIFIED_COMPLETE | manual permission mutation UAT |
| Appointment management | appointment controller/service | provider/agent customer scope | VERIFIED_COMPLETE | real scheduling/notification UAT |
| Documents/prescriptions | document safe projections | customer/provider/agent scope | VERIFIED_COMPLETE | signed-storage UAT |
| Orders/pharmacy context | purchase/order contracts | provider/branch scope | PARTIAL | fulfilment/refund deferred |
| Follow-ups/CRM activity | CRM task/activity APIs | AgentScope for explicit customer/task/activity paths and unfiltered agent lists, which receive assigned customer IDs only | PARTIAL | route-level Agent/CRM UI, internal notes, escalation and report contracts remain incomplete |
| Support/complaint queue | Complaint persistence and CRM complaint APIs | CRM complaint updates/resolution enforce AgentScope; customer-owned support requests are visible through the customer history contract | PARTIAL | assignment/escalation/replies/resolution notes and route-level CRM UI are incomplete |
| Store-change queue | protected `GET /store-change-requests` and `POST /store-change-requests/:id/review`; pending migration stores request history | unfiltered agent queue is reduced to assigned customer IDs; review resolves request customer and applies AgentScope; dedicated Agent queue renders load/empty/error/status and approve/reject actions; focused widgets cover empty and pending actions | VERIFIED_COMPLETE | manual UAT and approved migration application pending |
| Customer reports | agent reports surface exists | reports/customer-retention/support/follow-up completeness not proven | PARTIAL | customer-management report contracts need route-level evidence |

## Fix from this audit

Staff membership-application review previously enforced only `customers.approve`. It now resolves the application customer and invokes `AgentScopeService.assertAgentCanAccessCustomer` before review. This prevents a scoped SHIELD_AGENT from reviewing an application for an unassigned customer while preserving authorized non-agent staff behavior.

## Verification

- Focused CustomerService and CustomerMembershipController Jest suites: 18 passed; wallet/support scope suites: 7 passed.
- Backend `npx tsc --noEmit` and `npm run build` passed after correcting existing test fixture type declarations. Prisma generation occurred, but no schema application or database write was run.
