# Agent Membership Management Manual UAT Checklist

All Actual, PASS/FAIL and Evidence fields are intentionally blank.

| ID | Action | Expected result | Actual | PASS/FAIL | Evidence |
|---|---|---|---|---|---|
| AM-01 | Agent login and membership queue | scoped queue loads with loading/empty/error states | | | |
| AM-02 | Open assigned application | factual customer, reference, submitted date and status shown | | | |
| AM-03 | Open unassigned application | denied by backend AgentScope | | | |
| AM-04 | Reject with reason | reason/history retained; Customer refresh shows rejection | | | |
| AM-05 | Customer reapply | rejected history remains; one new pending row | | | |
| AM-06 | Approve application | application APPROVED only; no fabricated membership/card | | | |
| AM-07 | Convert membership | exactly one real membership/status after refresh | | | |
| AM-08 | Retry conversion/review | no duplicate membership, application or card | | | |
| AM-09 | Card state | Customer sees only actual permitted card state | | | |
| AM-10 | Responsive/loading/error | usable membership UI; duplicate clicks safely handled | | | |
| AM-11 | Card request processing | assigned Agent can review only an assigned customer's card request and issue the real digital card once the server workflow is released | | | |
