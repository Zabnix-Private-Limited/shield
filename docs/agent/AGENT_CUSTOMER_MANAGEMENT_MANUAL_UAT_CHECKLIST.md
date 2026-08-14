# Agent Customer Management Manual UAT Checklist

All outcome fields are intentionally blank pending owner testing.

| ID | Area | Precondition and action | Expected result | Actual | PASS/FAIL | Evidence / notes |
|---|---|---|---|---|---|---|
| AG-001–006 | Agent login, customer list/search/detail | login as scoped Agent and open assigned/unassigned customers | only assigned records accessible | | | |
| AG-007–009 | Registration/duplicate/status | register, duplicate, status actions | validation, audit and scope enforced | | | |
| AG-010–013 | Membership applications | list/review approve/reject and permission-denied identity | Agent sees assigned application only; customer cannot review | | | |
| AG-014–015 | Conversion/card | convert approved application and issue/view card | no duplicate membership/card; lifecycle reflected to customer | | | |
| AG-016–018 | Wallet/visits | inspect and update supported workflows | ledger and appointment scope enforced | | | |
| AG-016A | Wallet recharge | recharge assigned customer and retry request | customer scope, ledger audit and duplicate safety enforced | | | |
| AG-019–024 | Documents/prescriptions/orders/referrals/timeline/support | exercise supported modules | safe customer isolation and no CRM leakage | | | |
| AG-024A | Support/complaint/store change | queue, detail, assignment, resolution and customer update | only assigned customer actions allowed; history/audit and customer refresh verified | | | |
| AG-022A | CRM follow-up and reports | create/follow-up, filter customer reports | assignment scope, audit and no cross-customer data leak | | | |
| AG-025–029 | Entity/branch/security/responsive/audit | test out-of-scope customer and widths | denied access, responsive workspace, auditable actions | | | |
