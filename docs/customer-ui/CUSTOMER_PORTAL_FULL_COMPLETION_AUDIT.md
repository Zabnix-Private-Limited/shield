# Customer Portal Full Completion Audit

Audited: 2026-08-14. Scope: source, contracts, schema, focused tests and static analysis only. Manual deployed UAT remains owner work.

## Route-level customer matrix

`Ownership` is authenticated customer principal unless noted. `UI states` means source loading/empty/error/retry evidence; manual responsive/device UAT is separate.

| Route | Screen / API | Persistence / state | UI states / tests | Phase-1 classification / blocker |
|---|---|---|---|---|
| `/customer/login`, `/customer/otp` | phone auth | Firebase + SHIELD session | guarded recovery | VERIFIED_COMPLETE / device OTP UAT |
| `/portal/customer/dashboard` | dashboard, `/customer/dashboard` | dashboard cache v2 | loading/error/retry; membership tests | VERIFIED_COMPLETE |
| `/portal/customer/membership` | application/card, membership APIs | MembershipApplication, Membership, ShieldCard | state resolver tests | VERIFIED_COMPLETE / migration apply + UAT |
| `/portal/customer/wallet` | wallet balance | ledger projections | loading/error | VERIFIED_COMPLETE |
| `/portal/customer/wallet-history` | transactions | cash/reward ledger | filter/empty/error | VERIFIED_COMPLETE |
| no recharge route yet | recharge intent APIs | WalletRechargeIntent pending migration | no customer UI | PARTIAL / provider checkout and UI |
| `/portal/customer/rewards` | reward balance/redemption | reward ledger | balance UI | PARTIAL / customer redemption contract |
| `/portal/customer/services` | discovery/detail | service providers | loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/book-appointment` | booking | appointments | loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/appointments` | visits | appointments | protected loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/documents` | documents/upload/detail | documents | protected loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/prescriptions` | prescription/request | prescriptions | protected loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/orders` | order/detail | purchases | loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/referrals` | referral graph | referrals/rewards | loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/activity` | timeline | activity events | loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/notifications` | inbox/detail/read | notifications/device tokens | pagination, retry, deep-link tests | PARTIAL / focused inbox widget test |
| `/portal/customer/account` | profile/preferred pharmacy | customer preferences | loading/empty/error | VERIFIED_COMPLETE |
| `/portal/customer/store-change` | request/history | StoreChangeRequest pending migration | focused customer widget test | VERIFIED_COMPLETE / migration apply + UAT |
| `/portal/customer/support` | submit/history/status | complaints | loading/empty/error | PARTIAL / CRM assignment/escalation/reply lifecycle |

| Route / feature | Contract and ownership | Static state evidence | Classification | Remaining issue |
|---|---|---|---|---|
| Auth, OTP, session, logout | Firebase phone auth plus SHIELD session; customer principal/session owned | diagnostics redact secrets; route guards and recovery route present | VERIFIED_COMPLETE | Firebase/device/runtime UAT external |
| Dashboard | `GET /customer/dashboard`, dashboard cache v2 | loading/error/retry; nullable membership application/card/member resolver | VERIFIED_COMPLETE | manual render/UAT |
| Membership application/card | `GET/POST /customer/membership/application`, card profile/request | no fabricated membership/cache; pending/approved/rejected/active/inactive states tested; source migration includes the exact partial unique index | VERIFIED_COMPLETE | manual UAT and approved deployed-DB migration verification |
| Wallet balance | `GET /customer/wallet`, ledger projections | loading/empty/error widgets; CASH/REWARD separation | VERIFIED_COMPLETE | manual UAT |
| Wallet transactions | customer wallet bundle/history projections | filter, cached read/error fallback | VERIFIED_COMPLETE | manual UAT |
| Wallet recharge intent | `GET/POST /customer/wallet/recharge-intents`; pending `wallet_recharge_intents` migration | customer ownership, positive amount and idempotency key are enforced; an intent cannot create a ledger credit | PARTIAL | customer UI, approved checkout initiation, signed webhook verification, verified settlement credit, failure/retry and reversal/refund handling remain incomplete |
| Recharge payment initiation | no payment-provider adapter/configuration found | safe intent boundary exists but returns no checkout action | BUSINESS_DECISION_REQUIRED | approved payment provider, merchant configuration and checkout contract |
| Payment callback / duplicate callback | no provider webhook/verifier found | no client success endpoint exists; no credit occurs from an intent | BUSINESS_DECISION_REQUIRED | provider signature and event contract; verified idempotent settlement implementation |
| Failed payment / refund-reversal | intent schema reserves failure state; no transition service exists | no customer-facing status/retry/reversal flow | PARTIAL | approved provider semantics and finance/reversal policy |
| Reward balance | reward ledger projection | separate reward route/read surface | VERIFIED_COMPLETE | manual UAT |
| Reward redemption | staff `POST /wallets/redeem-points`; no customer redemption workflow | no customer action/confirmation/history transition | PARTIAL | customer redemption rule and customer-safe contract absent |
| Services/provider discovery | customer-safe provider discovery | category/search/loading/error; no rating/distance fabrication | VERIFIED_COMPLETE | live availability/pricing deferred |
| Booking and visits | provider validation plus appointment request APIs | request terminology, stale response protection, empty/error paths | VERIFIED_COMPLETE | slot confirmation is not a supported claim |
| Documents/prescriptions | customer-owned document/prescription routes | safe upload/list/detail error states | VERIFIED_COMPLETE | clinical OCR/sharing deferred |
| Orders/referrals/activity | customer-safe history/referral/timeline APIs | read-only data surfaces and empty/error states | VERIFIED_COMPLETE | checkout/refunds/share deferred |
| Notifications | self inbox/read routes and post-auth push registration | unread/retry states; push route allowlist, cold-start navigation queue, and invalid/missing-target recovery to notification center are source-tested | PARTIAL | notification pagination contract and UI remain incomplete; device delivery/tap UAT is external |
| Profile/account/security | customer-self profile/account/session APIs | route guard, loading/error and session controls | VERIFIED_COMPLETE | phone migration/deletion/export require separate policy |
| Preferred Hyper Pharmacy | `GET /customer/pharmacies`, `GET/PUT/DELETE /customer/preferred-provider` | Account Pharmacy tab loads eligible active pharmacies, renders empty/error, and updates only authenticated customer preference | VERIFIED_COMPLETE | manual UAT |
| Store change request | `GET/POST /customer/store-change-requests`; pending migration persists current/requested pharmacy, reason, status, reviewer and history | dedicated customer route loads request history, eligible pharmacies and authoritative review result; authenticated customer identity is derived server-side; focused widget regression covers populated history | VERIFIED_COMPLETE | manual UAT and approved migration application pending |
| Support/complaints | authenticated `GET/POST /customer/support` plus public web contact/feedback | customer submission and history are principal-owned; dedicated Support route renders authoritative request status and refreshes after submit | PARTIAL | CRM assignment/escalation/reply/resolution-note lifecycle remains incomplete |

## Security and cache findings

- Customer application ownership is derived from the authenticated principal, not request customer IDs.
- Dashboard cache key version `customer_dashboard_v2_` prevents fabricated legacy membership cache reuse; null membership remains null after cache restore.
- Customer-facing contracts must remain null-safe; no parser may manufacture membership/card/financial entities.
- The Phase-1 product specification is newer/authoritative for wallet recharge, preferred Hyper Pharmacy, store change and support. They are not marked deferred here. The existing `CUSTOMER_APP_DEFERRED_SCOPE.md` documents missing contracts but does not explicitly approve moving those Phase-1 requirements out of release.

## Provider-specific journey matrix

| Provider journey | Discovery / request | Operational flow / status | Customer tracking / result | Classification |
|---|---|---|---|---|
| Hyper Pharmacy | service discovery, preferred pharmacy, orders | provider/branch purchase context | order history; no end-to-end fulfilment/refund proof | PARTIAL |
| Smart Lab | generic discovery/booking | lab provider appointment/report source is present | report lifecycle proof incomplete | PARTIAL |
| Clinic | generic discovery/booking | appointment/provider workflow | visit tracking | PARTIAL — clinic-specific mapping test absent |
| Doctor | generic discovery/booking | consultation/appointment source | visit and prescription surfaces | PARTIAL — provider-specific transition proof absent |
| Home Care | generic discovery/booking | home-care provider workflow source | visit tracking | PARTIAL — visit-note/result proof absent |
| Dietitian | generic discovery/booking | provider type accepted by generic engine | no plan/result lifecycle proof | PARTIAL |
| Dental | generic discovery/booking | dental provider/record source | visit tracking | PARTIAL — treatment-result proof absent |
| Skin Care | generic discovery/booking | cosmetic provider type source | no specialty result lifecycle proof | PARTIAL |

The generic engine is not accepted as complete evidence for a provider type until discovery, selection, request, provider status transition, customer tracking, notification, and relevant result/report behavior have focused source proof.

## Source verification

- Flutter membership/dashboard tests: 6 passed; targeted support/portal analyzer passed.
- The repository migration `20260814_membership_applications` contains `uq_membership_applications_one_open_per_customer` over `customer_id` where status is `PENDING`/`APPROVED`; no database execution was performed in this audit.
- Browser/device/deployed authenticated UAT: pending owner verification.
