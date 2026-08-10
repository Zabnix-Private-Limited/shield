# Customer 360 permission matrix

| Principal | Workspace route | Customer data |
|---|---|---|
| `SHIELD_AGENT` with `agent.customer.view` | Allowed | Only customers where `customers.agent_code` equals the authenticated employee code |
| `ADMIN` | RBAC permission may allow the endpoint, but the current Agent service intentionally requires an agent context | Denied unless a separate operations contract is added |
| `CRM_EXECUTIVE` | Denied | Use CRM-specific contracts; this endpoint is not a general staff bypass |
| Customer principal | Denied | Never a staff workspace |
| Provider principal | Denied | Provider workspace is separate |

Every customer identifier is parsed server-side and checked through `AgentScopeService.assertAgentCanAccessCustomer` before the aggregated workspace query runs.

## Current capability decision

| Capability | SHIELD_AGENT | Reason |
|---|---|---|
| Search/view profile, membership, wallet, rewards, documents, prescriptions, visits, orders, referrals, family, notifications, activity, audit | Allowed for assigned customers | `agent.customer.view` plus graph enforcement |
| Edit basic profile / alternative contact / address | Allowed only through existing scoped customer workflows | `agent.customer.update`; no identity, membership-number, wallet, or status editing in the form |
| Schedule follow-up / visit / upload document / request physical card | Allowed only through existing dedicated contracts | Individual operation permissions and ownership checks apply |
| Change membership/account status, approve, suspend, reactivate | Not exposed in the Agent Customer 360 UI | Agent RBAC does not grant `customers.approve`; server lifecycle endpoints require that permission and derive audit actor from the authenticated principal |
| Modify cash/rewards, entitlement, membership financial values | Not exposed | No verified Agent adjustment contract; ledger and entitlement remain read-only |
| Download documents / modify orders / send arbitrary notifications | Not exposed from Customer 360 | Existing contracts and permission boundaries are narrower than this workspace |
