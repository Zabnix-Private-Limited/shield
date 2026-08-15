# Customer Membership Cross-Portal Final Pre-UAT Audit — 2026-08-15

| Lifecycle state | Customer source | Agent source | Classification |
|---|---|---|---|
| No application | Apply action; no fabricated membership/card | scoped application queue is empty | VERIFIED_COMPLETE |
| Pending | application reference/status | assigned agent can read/review | VERIFIED_COMPLETE |
| Rejected/reapply | rejection state/reason and reapply | review reason/history retained | VERIFIED_COMPLETE |
| Approved | awaiting conversion; no fabricated membership/card | approval is review only | VERIFIED_COMPLETE |
| Converted | real membership number/status after refresh | staff conversion is sole membership creator | VERIFIED_COMPLETE |
| Card | only real qualifying card state is shown | current defined card state is retained | EXTERNAL_UAT_REQUIRED |

Customer identity is principal-derived. Agent review resolves the application customer and enforces AgentScope. The owner-verified open-application predicate blocks simultaneous PENDING/APPROVED rows. Deployment/device synchronization remains manual UAT.
