# Customer 360 authenticated RBAC UAT

## Status

**PENDING — EXTERNAL QA GATE**

This checklist validates the deployed/authenticated staff experience. Do not
mark an item PASS from widget tests, API unit tests, or an unauthenticated
browser page.

## Environment prerequisites

- A QA/development deployment with the current Customer 360 commits.
- Reachable Nest API and Flutter web client using the same QA environment.
- Firebase/internal sign-in available; do not share credentials in this file.
- At least two assigned customers for the Agent account, including one customer
  outside that Agent's graph for denial checks.
- A customer with membership, wallet history, document/prescription data, and
  at least one status-history entry where available.

## Required accounts and roles

| Purpose | Required account/role | Credentials |
|---|---|---|
| Allowed workspace | `SHIELD_AGENT` with assigned customers | Obtain from QA owner |
| Staff denial | Internal role without `agent.customer.view` | Obtain from QA owner |
| Customer denial | Customer principal | Obtain from QA owner |
| Provider denial | Provider principal | Obtain from QA owner |
| Optional lifecycle check | Staff role granted `customers.approve` | Obtain from QA owner |

## Routes

- Customer list: `/portal/agent/customers`
- Direct selected workspace: `/portal/agent/customers/:customerId`
- Related workflows: `/portal/agent/followups`, `/portal/agent/appointments`,
  `/portal/agent/documents`, `/portal/agent/referrals`

## Checklist

| ID | Scenario and expected behaviour | PASS | FAIL | Evidence / screenshot | Defect ID |
|---|---|:---:|:---:|---|---|
| UAT-01 | Authorized Agent can sign in, search, paginate, and open only assigned customers. | [ ] | [ ] |  |  |
| UAT-02 | Direct Customer 360 URL reconstructs the selected customer after refresh and requires authentication. | [ ] | [ ] |  |  |
| UAT-03 | Agent sees only permitted read surfaces and existing actions; unsupported financial/lifecycle actions are absent. | [ ] | [ ] |  |  |
| UAT-04 | Unauthorised internal role receives forbidden/appropriate access denial. | [ ] | [ ] |  |  |
| UAT-05 | Customer principal cannot use Agent customer-list or Customer 360 endpoints. | [ ] | [ ] |  |  |
| UAT-06 | Provider principal cannot use Agent Customer 360 endpoints. | [ ] | [ ] |  |  |
| UAT-07 | Membership/card information is scoped to the selected customer; lifecycle actions obey RBAC. | [ ] | [ ] |  |  |
| UAT-08 | Cash, Reward Points, and SHIELD Benefit remain distinct; no direct balance edit is exposed. | [ ] | [ ] |  |  |
| UAT-09 | Documents, prescriptions, and pharmacy requests are visible only when the selected Agent scope permits them. | [ ] | [ ] |  |  |
| UAT-10 | Audit/status history is visible only to authorised staff and does not disclose another customer. | [ ] | [ ] |  |  |
| UAT-11 | Search/list → Customer 360 → tab → Back retains expected list/selection behaviour. | [ ] | [ ] |  |  |
| UAT-12 | Mutations available to the test role create the expected server-side audit/status records. | [ ] | [ ] |  |  |
| UAT-13 | Desktop layout is manually checked at representative 1024, 1366, and 1920 logical-pixel widths. | [ ] | [ ] |  |  |

## Security notes

- Test a guessed foreign `customerId` route while signed in as the Agent; it
  must not reveal customer data.
- Do not test by changing database rows directly or by bypassing sign-in.
- Capture only QA-safe screenshots; do not attach credentials, tokens, or
  sensitive clinical documents to tickets.
