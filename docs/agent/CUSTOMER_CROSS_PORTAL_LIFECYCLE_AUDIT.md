# Customer Cross-Portal Lifecycle Audit

Audited: 2026-08-14. Source-level contract trace.

| Customer event | Backend/persistence | Staff action | Customer-visible result | Status |
|---|---|---|---|---|
| Submit membership application | authenticated `POST /customer/membership/application`; MembershipApplication + activity event | authorized staff reads/reviews | dashboard refetch renders PENDING/reference | VERIFIED_COMPLETE |
| Reject application | reviewer/time/reason retained | `customers.approve`, AgentScope enforced | REJECTED reason and Apply again; new row preserves history | VERIFIED_COMPLETE |
| Approve application | application becomes APPROVED only | existing separate conversion workflow | approved-awaiting-activation; no fabricated card | VERIFIED_COMPLETE |
| Convert customer to membership | existing transactional conversion | staff conversion remains sole creator | actual membership number/plan/status appears only after API refetch | VERIFIED_COMPLETE |
| Issue/activate card | ShieldCard relation/status | card management path | View card only for actual ISSUED/ACTIVE card | PARTIAL — manual issuance UAT |
| Submit appointment | customer-owned appointment contract | staff/provider scheduling/status | Visits consumes authoritative status | VERIFIED_COMPLETE |
| Upload/process document | customer-owned document contract | staff/provider processing | customer safe document state | VERIFIED_COMPLETE |
| Wallet mutation | ledger transaction | authorized staff workflow | wallet read model updates; hidden SHIELD_BENEFIT not exposed | VERIFIED_COMPLETE |
| Wallet recharge safe intent | customer-owned recharge intent contract with idempotency; no customer ledger credit route | staff-only ledger recharge remains the only credit path; no client callback can credit funds | Wallet displays safe intent status/payment setup unavailable without pretending payment completed | VERIFIED_COMPLETE — migration apply and manual UAT pending; payment settlement remains BUSINESS_DECISION_REQUIRED |
| Preferred pharmacy/store change | preference plus pending `store_change_requests` migration; customer-owned submit/history plus protected staff queue/review contracts | agent queue and review are scoped to assigned customers; approval updates only the requested preference | customer and Agent routes render request/status/review result; focused widget tests cover populated customer history and Agent empty/pending states | VERIFIED_COMPLETE — manual UAT and approved migration application pending |
| Support complaint | customer-owned `GET/POST /customer/support` plus ownership-bound detail projection; lifecycle events preserve staff/customer communication | CRM list/detail/actions are AgentScoped; assignment, reply, escalation, resolution and audit history are persisted | customer detail exposes only customer-visible replies/resolution; CRM queue/detail renders scoped operational actions | VERIFIED_COMPLETE — TEST_VERIFICATION_PENDING focused Flutter support/CRM widgets; migration/UAT pending |

## Release dependencies

The repository membership migration includes the partial unique index `uq_membership_applications_one_open_per_customer` (`customer_id` where status is PENDING/APPROVED). Applying and verifying the approved migration in the deployed database remains an external release step.
