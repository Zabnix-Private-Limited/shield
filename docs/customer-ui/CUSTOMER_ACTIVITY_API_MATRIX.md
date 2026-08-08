# Customer Activity API Matrix

Classification: `COMPLETE — SUPPORTED FUNCTIONAL SCOPE`

| Capability | Route | API | Customer rule | Classification |
| --- | --- | --- | --- | --- |
| Activity feed | Activity | `GET /timeline/me` | Session-derived customer | Supported |
| Event sources | Activity | Timeline aggregation | Existing membership/card, appointment, document, wallet, notification records only | Supported |
| Category filter | Activity | Local filter over API records | No invented events | Supported |
| Safe entity hint | Activity | `GET /timeline/me` | Allowlisted target/id only; no actor/patient/raw metadata | Supported |
| Persistent activity ledger | — | — | `activity_events` exists but is not used as a customer UI substitute | Deferred |
| Pagination/deep navigation | — | — | Current customer timeline contract is unpaged and no safe route mapper exists | Deferred |

Database source: `activity_events` plus verified domain records in
`current_schema.md`. No SQL is required.
