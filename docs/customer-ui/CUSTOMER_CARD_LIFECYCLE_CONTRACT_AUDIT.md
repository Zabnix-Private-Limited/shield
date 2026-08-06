# Customer card lifecycle contract audit

Audited: 2026-08-06. `current_schema.md`, Prisma, and implemented customer routes are authoritative.

| Capability | Existing contract | Current-release classification |
|---|---|---|
| Physical-card request/status/history | `card_requests`; customer-self `POST /customer/membership/card/request`, `GET /customer/membership/card`, and `GET /customer/membership/card/requests`; creation is audited and duplicate active requests are reused. | COMPLETE — SUPPORTED SCOPE |
| Digital card | `shield_cards` card number/status/issued date; customer UI renders the issued card. | COMPLETE — SUPPORTED SCOPE |
| QR verification | Stored `qr_code` is static; no signer, expiry, provider verifier, replay protection, or PII review contract exists. | NOT SUPPORTED IN CURRENT CONTRACT |
| Renewal | Membership dates exist, but no renewal quote, payment, validity, carry-forward, audit, or notification workflow exists. | DEFERRED — PRODUCT DECISION REQUIRED |
| Lost/damaged/replacement | `shield_cards` permits a status but there is no reason/event model, fee, delivery, duplicate-card policy, safe deactivation workflow, or customer API. | DEFERRED — PRODUCT DECISION REQUIRED |

No renewal, replacement, card deactivation, payment, or QR security behavior is simulated in the customer UI.
