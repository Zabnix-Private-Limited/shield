# Customer 360 manual QA

1. Sign in as a SHIELD Agent with assigned customers and open `/portal/agent/customers`.
2. Select a customer; confirm the URL is `/portal/agent/customers/:customerId` and refresh it.
3. Verify all twelve tabs use records belonging to the selected customer.
4. Verify an assigned customer can be edited only through the existing update workflow and actions create their normal audit events.
5. Attempt a foreign customer ID, a customer session, and a provider session; all must be denied.
6. Inspect 768, 1024, 1280, 1366, 1440, and 1920 logical-pixel widths; confirm the responsive list/detail and summary layouts remain usable.

Automated static validation does not replace authenticated browser validation.
