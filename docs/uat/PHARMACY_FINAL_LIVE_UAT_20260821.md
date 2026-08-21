# Pharmacy Portal Live UAT — 2026-08-21

## Scope

Authenticated Pharmacy workspace only: Dashboard, Orders, Payments, Payment Details, History, Profile, and Settings.

## Evidence-backed passes

- All seven routes rendered at 1440 x 900 and 390 x 844 with zero browser-console errors.
- UAT Orders verified full approval, rejection, partial fulfillment, substitution UI/data persistence, chronic tagging, internal notes, pickup-delivery prevention, terminal-status protection, invoice upload/view/replace/delete/send, and customer-confirmation API idempotency.
- UAT Payment Details verified UPI and bank CRUD/toggle operations and the UAT UPI QR upload, authenticated image read, removal, and re-upload lifecycle.
- Settings negative paths were verified for partial fulfillment, partial dispatch, home delivery, store pickup, invoice requirement, and customer confirmation.
- Hosted Orders now visibly replaces the confirmation action with `Customer confirmation request is pending.` for `INV-UAT-PLACED-5`; the state also survived a reload and order re-selection.
- `enableChronicTagging=false` and `suggestSubstitutes=false` were each proven by a live HTTP 400 against `INV-UAT-PLACED-5`, then immediately restored.
- History rendered terminal UAT records after settlement, and its Completed filter issued `GET /pharmacy/orders/history?page=1&pageSize=20&status=COMPLETED` with HTTP 200.
- A non-mutating `providerId=999999` queue-parameter tampering attempt returned the same first eight order IDs and total as the ordinary assigned-provider queue; the parameter cannot override assigned scope.
- All seven routes were captured at 360x800, 390x844, 430x932, 844x390, 768x1024, 1024x768, 1366x768, 1440x900, and 1920x1080. No clipping was found in the inspected mobile, landscape, tablet, or desktop captures.
- Source checks: affected Flutter analyzer checks passed with no issues. Backend TypeScript passed before the narrow final payment-settings extension; the subsequent check was accidentally invoked from the frontend directory and is not counted as proof.

## Fixed during UAT

- Mandatory manual verification now prevents counter auto-approval and ledger credit while enabled; the deployed counter dialog submits for verification. Its pre-approval panel now distinguishes the wallet cash credit after approval from the visible company promotional benefit.
- Provider payment scope is fail-closed, UTR proof is enforced by provider setting, confirmation state is correctly mapped, and invoice metadata is projected in order detail.

## Release gates — FAIL / unresolved

1. **Financial approval/rejection/ledger lifecycle:** both approved seed scripts were inspected. The two UAT PENDING intents resolve to live customers marked `Non-Member (Wellness Only)`. No eligible active SHIELD Privilege Card UAT fixture exists, so approval/rejection, exact-once ledger assertions, and benefit-visibility assertions were not lawfully executed.
2. **Substitution product ID:** one UAT substitution persists as a name/price with `substituteProductId: null`, because the live catalog projection supplies no product ID. This does not satisfy a product-ID-required substitution contract.
3. **Offline feedback:** a simulated Payments API 503 preserved loaded content and exposed no raw UI transport string, but visible retry/status feedback was not conclusively captured for all seven routes.
4. **Provider-isolation proof:** server-side provider scope is fail-closed, but no second assigned/unassigned Pharmacy fixture identity was available for a live cross-scope proof.
5. **Owner device acceptance:** browser viewport coverage is complete, but physical-device UAT remains owner acceptance work.

## Owner fixture handoff — 2026-08-21

The live Pharmacy customer search confirms `UAT-PHARMACY-FINAL-CUSTOMER` does not yet exist. To unblock only the final payment and identity-security cases, the owner must run the idempotent fixture script and then the read-only verifier:

- `backend/prisma/demo-seeds/20260821_pharmacy_final_uat_fixtures.sql`
- `backend/prisma/demo-seeds/20260821_pharmacy_final_uat_fixtures_verify.sql`

The fixture establishes a synthetic active UAT member with an issued card, active wallet, three `PENDING` UPI recharge intents (₹10,000/₹20,000/₹30,000), and primary/secondary/unassigned Pharmacy staff database identities. It does not provide Firebase test authentication credentials; the owner must bind/use the appropriate authorized test identities before the live isolation checks.

## Safety record

Only clearly UAT-prefixed orders and payment methods were changed. No direct database writes, migrations, schema changes, or non-UAT payment destination changes were made.

## Artifacts

- `output/playwright/pharmacy-*-1440.png`
- `output/playwright/pharmacy-*-390.png`
- `output/playwright/pharmacy-counter-dialog-deployment-check.png`
- `output/playwright/pharmacy-confirmation-hard-reload.png`
- `output/playwright/pharmacy-order-confirmation-persisted-after-reload.png`
- `output/playwright/pharmacy-*-360.png`, `pharmacy-*-430.png`, `pharmacy-*-844x390.png`, `pharmacy-*-768x1024.png`, `pharmacy-*-1024x768.png`, `pharmacy-*-1366x768.png`, and `pharmacy-*-1920x1080.png`
