# Customer 360 implementation audit

Implemented against the existing Agent platform instead of a parallel Operations portal:

- Added a stable routed selection at `/portal/agent/customers/:customerId`.
- Added an agent-scoped server-side customer list/search contract with pagination; the UI no longer treats the dashboard's 24-row preview as the complete customer graph.
- Retained the existing agent-scoped workspace aggregation and direct list workflow.
- Exposed existing prescription records explicitly in the workspace projection.
- Organised the UI into Overview, Membership, Wallet & Rewards, Documents, Visits, Prescriptions, Orders, Family, Referrals, Notifications, Activity, and Audit tabs.

Deferred: an administrator-wide Customer 360 surface. The current Agent endpoint deliberately requires `SHIELD_AGENT`; broadening it requires an explicit, separately audited operations permission and scope policy.

## Requirement evidence

| Requirement | Current evidence | Decision |
|---|---|---|
| Stable customer route | `/portal/agent/customers/:customerId` reconstructs selection through the guarded portal shell | Implemented |
| Search/list | Agent-scoped API supports debounced query, account/membership filters, stable newest-first order, pagination, and page-size cap | Implemented |
| Identity/contact/addresses/family | Existing selected-customer projection plus customer contacts and non-deleted addresses | Implemented read-only; profile edits retain the existing scoped workflow |
| Membership/card/entitlement | Existing membership bundle, subscription, card profile/request workflow | Implemented visibility; only real card request action is exposed |
| Wallet/rewards/benefit | Ledger-derived bundle and recent transactions | Implemented read-only; no direct balance action |
| Visits/documents/prescriptions/pharmacy requests/orders | Existing scoped aggregates and dedicated operational flows | Implemented visibility; no invented fulfilment/order mutation |
| Referrals/notifications/activity/audit | Existing summaries, records, timeline and customer-status history | Implemented read-only |
| Lifecycle actions | Existing lifecycle API was hardened, but current Agent RBAC does not grant approval permission | Not exposed to Agent UI |
| Preferred provider | Stored preference resolved to a safe provider label | Implemented read-only |
| Preferred pharmacy | No separate current-schema preference field | Unsupported; not invented |
| Browser/RBAC UAT | No authenticated browser session evidence | Pending manual QA |

The workspace is intentionally not an unrestricted staff directory. It is an assigned-customer Agent workspace, and all new list/detail reads retain the `AgentScopeService` graph check.
