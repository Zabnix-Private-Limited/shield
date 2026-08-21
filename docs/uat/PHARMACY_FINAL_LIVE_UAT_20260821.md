# Pharmacy Portal Live UAT — 2026-08-21

## Scope

Authenticated Pharmacy workspace only: Dashboard, Orders, Payments, Payment Details, History, Profile, and Settings.

## Evidence-backed passes

- All seven routes rendered at 1440 x 900 and 390 x 844 with zero browser-console errors.
- UAT Orders verified full approval, rejection, partial fulfillment, substitution UI/data persistence, chronic tagging, internal notes, pickup-delivery prevention, terminal-status protection, invoice upload/view/replace/delete/send, and customer-confirmation API idempotency.
- UAT Payment Details verified UPI and bank CRUD/toggle operations and the UAT UPI QR upload, authenticated image read, removal, and re-upload lifecycle.
- Settings negative paths were verified for partial fulfillment, partial dispatch, home delivery, store pickup, invoice requirement, and customer confirmation.
- Source checks: affected Flutter analyzer checks passed with no issues. Backend TypeScript passed before the narrow final payment-settings extension; the subsequent check was accidentally invoked from the frontend directory and is not counted as proof.

## Fixed during UAT

- Mandatory manual verification now prevents counter auto-approval and ledger credit while enabled; the counter dialog submits for verification rather than presenting instant wallet credit.
- Provider payment scope is fail-closed, UTR proof is enforced by provider setting, confirmation state is correctly mapped, and invoice metadata is projected in order detail.

## Release gates — FAIL / unresolved

1. **Hosted frontend deployment propagation:** the hosted counter-payment dialog still displays the pre-fix instant-credit UI after hard reload. The source commits are pushed, but hosted re-test cannot pass until the current frontend bundle is live.
2. **Financial approval/rejection/ledger lifecycle:** both approved seed scripts were inspected. The two UAT PENDING intents resolve to live customers marked `Non-Member (Wellness Only)`. No eligible active SHIELD Privilege Card UAT fixture exists, so approval/rejection, exact-once ledger assertions, and benefit-visibility assertions were not lawfully executed.
3. **Substitution product ID:** one UAT substitution persists as a name/price with `substituteProductId: null`, because the live catalog projection supplies no product ID. This does not satisfy a product-ID-required substitution contract.
4. **Complete viewport matrix and owner mobile UAT:** the two representative desktop/narrow widths passed; the requested 360/430, tablet, 1366/1920 matrices and physical-device UAT remain outstanding.
5. **Provider-isolation proof:** server-side provider scope is fail-closed, but no second assigned/unassigned Pharmacy fixture identity was available for a live cross-scope proof.

## Safety record

Only clearly UAT-prefixed orders and payment methods were changed. No direct database writes, migrations, schema changes, or non-UAT payment destination changes were made.

## Artifacts

- `output/playwright/pharmacy-*-1440.png`
- `output/playwright/pharmacy-*-390.png`
- `output/playwright/pharmacy-counter-dialog-deployment-check.png`
- `output/playwright/pharmacy-confirmation-hard-reload.png`

