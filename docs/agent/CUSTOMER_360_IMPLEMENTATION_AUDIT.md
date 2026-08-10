# Customer 360 implementation audit

Implemented against the existing Agent platform instead of a parallel Operations portal:

- Added a stable routed selection at `/portal/agent/customers/:customerId`.
- Retained the existing agent-scoped workspace aggregation and direct list workflow.
- Exposed existing prescription records explicitly in the workspace projection.
- Organised the UI into Overview, Membership, Wallet & Rewards, Documents, Visits, Prescriptions, Orders, Family, Referrals, Notifications, Activity, and Audit tabs.

Deferred: an administrator-wide Customer 360 surface. The current Agent endpoint deliberately requires `SHIELD_AGENT`; broadening it requires an explicit, separately audited operations permission and scope policy.
