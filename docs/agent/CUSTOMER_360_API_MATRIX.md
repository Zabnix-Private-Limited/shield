# Customer 360 API matrix

| Surface | Contract | Scope | Status |
|---|---|---|---|
| Workspace list | `GET /agents/workspace` | SHIELD_AGENT graph | Supported |
| Customer 360 | `GET /agents/customers/:customerId/workspace` | Assigned customer only | Supported |
| Customer update | `PUT /customers/:id` | Existing staff permission and agent graph check | Supported |
| Follow-up | CRM task/activity APIs | Assigned customer | Supported |
| Visits | Internal appointment APIs | Assigned customer | Supported |
| Documents | Scoped document APIs | Assigned customer | Supported |
| Card | Customer card profile/request APIs | Existing staff contract | Supported |

The workspace response uses live customer, membership, ledger-derived wallet, documents, appointments, purchases, referrals, notifications, prescription, activity, and status-history records. It does not create a new database contract.
