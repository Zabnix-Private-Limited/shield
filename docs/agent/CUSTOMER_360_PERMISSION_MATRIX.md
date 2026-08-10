# Customer 360 permission matrix

| Principal | Workspace route | Customer data |
|---|---|---|
| `SHIELD_AGENT` with `agent.customer.view` | Allowed | Only customers where `customers.agent_code` equals the authenticated employee code |
| `ADMIN` | RBAC permission may allow the endpoint, but the current Agent service intentionally requires an agent context | Denied unless a separate operations contract is added |
| `CRM_EXECUTIVE` | Denied | Use CRM-specific contracts; this endpoint is not a general staff bypass |
| Customer principal | Denied | Never a staff workspace |
| Provider principal | Denied | Provider workspace is separate |

Every customer identifier is parsed server-side and checked through `AgentScopeService.assertAgentCanAccessCustomer` before the aggregated workspace query runs.
