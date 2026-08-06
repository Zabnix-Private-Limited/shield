# Customer card lifecycle contract audit

Audited: 2026-08-06. `current_schema.md`, Prisma, and implemented customer routes are authoritative.

| Capability | Existing contract | Current-release classification |
|---|---|---|
| Physical-card request/status/history | `card_requests`; customer-self `POST /customer/membership/card/request`, `GET /customer/membership/card`, and `GET /customer/membership/card/requests`; creation is audited and duplicate active requests are reused. | COMPLETE — SUPPORTED SCOPE |
| Digital card | `shield_cards` card number/status/issued date; customer UI renders the issued card. | COMPLETE — SUPPORTED SCOPE |
| Secure QR verification | Stored `qr_code` is static; no signer, expiry, provider verifier, replay protection, or PII review contract exists. | DEFERRED — SECURITY CONTRACT REQUIRED |
| Membership renewal | Membership dates exist, but no renewal quote, payment, validity, carry-forward, audit, or notification workflow exists. | DEFERRED — PRODUCT DECISION AND BACKEND CONTRACT REQUIRED |
| Lost card | `shield_cards` permits a status but there is no customer-safe lost-card reason/event or safe deactivation contract. | NOT SUPPORTED IN CURRENT CONTRACT |
| Damaged card | There is no customer-safe damaged-card reason/event, assessment, fee, or delivery contract. | NOT SUPPORTED IN CURRENT CONTRACT |
| Replacement card | There is no replacement policy, duplicate-card rule, safe deactivation workflow, fee, delivery, or customer API. | DEFERRED — PRODUCT DECISION AND BACKEND CONTRACT REQUIRED |

No renewal, replacement, card deactivation, payment, or QR security behavior is simulated in the customer UI.
