# Customer 360 security audit

- The workspace is not available to customer principals or provider principals.
- `SHIELD_AGENT` is constrained to records assigned by `customer.agent_code`; a guessed ID is rejected before aggregation.
- The response projects operational summaries rather than raw audit payloads, authentication secrets, refresh tokens, or wallet stored balances.
- Wallet information continues to use the existing ledger-derived bundle. `SHIELD_BENEFIT` is described as non-customer balance information.
- Existing mutations reuse their individual server-side ownership and permission checks. The route itself is read-only.
