# Customer Referrals API Matrix

Classification: `COMPLETE — SUPPORTED FUNCTIONAL SCOPE`

| Capability | Route | API | Customer rule | Classification |
| --- | --- | --- | --- | --- |
| Referral summary/code | Referrals | `GET /referrals/me` | Customer is derived solely from the session | Supported |
| Referral history | Referrals | `GET /referrals/me` | Only the customer's own referrer events; no referred-customer identity | Supported |
| Reward lifecycle | Referrals | `GET /referrals/me` | Backend status and reward points only; no client calculation | Supported |
| Copy code | Referrals | Clipboard API | Public code only; no internal IDs | Supported |
| Share link/native share | — | — | No backend-issued public URL/token or existing share abstraction | Deferred |
| Commission tree/seven-level data | — | — | Internal business processing; not customer-visible | Not supported |

Database source: `customers.referral_code`, `referral_reward_events`, and
`reward_point_transactions` in `current_schema.md`. No SQL is required.
