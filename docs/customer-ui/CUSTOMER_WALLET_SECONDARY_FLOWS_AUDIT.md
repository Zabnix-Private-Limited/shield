# Cash Wallet secondary flows audit

The customer wallet reads `GET /customer/wallet`. Its bundle is customer-self scoped and returns ledger-derived CASH and `REWARD_POINTS` balances plus wallet-wide history; `SHIELD_BENEFIT` is never a Cash Wallet balance. The Cash Wallet screen now renders CASH entries only, with client-side All/Credits/Debits/Reversals filters over the returned history. Tapping a row shows only the returned date, type, status (where present), reference, and remarks.

| Flow | Contract finding | Classification |
|---|---|---|
| CASH history | Bundle returns complete customer-owned history from the CASH and reward ledgers. Customer screen filters to CASH. | COMPLETE — SUPPORTED SCOPE |
| Credit, debit, refund, reversal | Raw transaction types are returned and shown. There is no separate cash status field; reward entries may return status. | COMPLETE — AVAILABLE DATA ONLY |
| Transaction detail | No customer transaction-by-ID endpoint; the existing detail sheet only renders fields included in the history row. | COMPLETE — SUPPORTED SCOPE |
| Date/type query | `GET /wallets/:walletId/transactions` accepts `from`, `to`, and exact raw `type`, with customer wallet-ownership enforcement. Full history now sends the supported All time/30 day/90 day date query; supported credit/debit/reversal filters remain local over the returned CASH entries. | COMPLETE — SUPPORTED SCOPE |
| Statement/export | No customer statement, download, export, or share contract. | NOT SUPPORTED IN CURRENT CONTRACT |
| Locked/unavailable balance | Wallet has a status, but no customer hold/locked-amount detail contract. | NOT SUPPORTED IN CURRENT CONTRACT |
| Wallet rules | No customer-readable rules/configuration contract. | NOT SUPPORTED IN CURRENT CONTRACT |
| Add Funds | Only staff `POST /wallets/recharge` exists; no customer payment/top-up, idempotency key, gateway callback, or customer mutation contract. | NOT SUPPORTED IN CURRENT CONTRACT |
| Offline/zero/error | Cached wallet data remains available while refresh fails; an initial API failure is retryable and is never rendered as ₹0. | COMPLETE — SUPPORTED SCOPE |

No withdrawal, transfer, payment, statement, top-up, or wallet mutation workflow is exposed without a verified backend-authoritative, transactional, idempotent, audited customer contract.
