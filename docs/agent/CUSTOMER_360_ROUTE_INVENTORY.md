# Customer 360 route inventory

- Customer list: `/portal/agent/customers`
- Stable selected workspace: `/portal/agent/customers/:customerId`
- Existing follow-up workflow: `/portal/agent/followups`
- Existing appointments workflow: `/portal/agent/appointments`
- Existing documents workflow: `/portal/agent/documents`

The selected-workspace route remains inside `PortalShell`, runs the normal portal role guard, and initializes the existing Agent customer controller with the route identifier. It does not expose a new public route.
