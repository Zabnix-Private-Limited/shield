# Customer UI visual QA

## Services discovery — automated visual-adjacent coverage — 2026-08-06

- Route: `/portal/customer/services`.
- Widget coverage verified loading completion, backend category/provider render, and the provider-detail unavailable boundary.
- Authenticated screenshot review is pending release QA; no screenshot was fabricated because the existing Chrome-control integration and Playwright CLI are not usable in this workspace.

## Services discovery route-state checkpoint — 2026-08-08

- Static widget and route-state coverage was updated for route-backed category, query, pagination, and provider-detail navigation.
- Authenticated browser and width screenshots remain **DEFERRED — TOOLING FAILURE** until the approved localhost customer session can be controlled; no visual evidence is claimed by static checks.
- A later bounded Playwright check confirmed the Flutter app redirects to customer login when unauthenticated. It did not reach an authenticated form/control snapshot, so it is not evidence of Services rendering or responsive completion.
- Deterministic widget coverage now mounts the Services screen at 350, 375, 390, 412, 448, 480, 768, and 1200 logical pixels with no Flutter layout exception. This is static responsive evidence only; authenticated screenshot QA remains deferred.

## Booking and Visits static responsive checkpoint — 2026-08-08

- Deterministic widget coverage mounts Booking and Visits at 350, 375, 390, 412, 448, 480, 768, and 1200 logical pixels, including a long provider name, with no Flutter layout exception.
- This is not authenticated screenshot evidence. Browser QA remains separately deferred until the approved local login controls are reachable.

## Membership/Card QA closure — 2026-08-06

Functional and responsive automated QA passed. Authenticated screenshot QA is **DEFERRED — TOOLING FAILURE** because the existing Chrome-control integration timed out and Playwright CLI crashed with a native Windows assertion. No screenshot evidence was fabricated. Manual authenticated screenshot review remains a release-QA follow-up.

## 2026-08-05 account-capabilities checkpoint

- Source route: `/portal/customer/account`.
- Static verification: targeted Flutter analysis and customer portal route test passed.
- Browser result: the existing localhost session redirected to customer login after route navigation. No OTP was submitted, no sign-out was requested, and no customer data was created, edited, or removed.
- Screenshot state: customer login page only; it is not evidence for authenticated account capability rendering.

## 2026-08-06 Firebase development verification

- The localhost runtime rejected the supplied development number while it displayed spacing. Current source already normalizes non-digits before ten-digit validation and Firebase submission, so this is stale-runtime evidence rather than a source-level regression. Entering the digits-only equivalent advanced to the OTP screen.
- The supplied development OTP populated the six input cells but Firebase verification returned the visible generic failure message. No authenticated session was established.
- No customer profile, membership, wallet, reward-point, address, dependent, contact, provider preference, or active-session record was changed. The OTP page remains open for Firebase development configuration review.

## Required follow-up

- Restore an authenticated local customer session and verify addresses, family, contacts, preferred pharmacy, and notification preferences against the development API.
- Capture populated and empty-state screenshots at the required responsive widths before marking visual QA complete.

## 2026-08-06 wellness catalogue checkpoint

- Source route: `/portal/customer/services`.
- The authenticated customer shell rendered its existing Services retry state after the backend restart; this is evidence of the existing membership-access dependency, not proof of catalogue rendering.
- Static wellness checks passed after the customer API contract and UI were updated. The browser run cannot yet record populated catalogue screenshots because the local Flutter process did not become reachable on port 53431 after its required restart command.
- Pending live evidence: landing catalogue, search, category filter, product details, empty search, retry, and responsive widths. No screenshots with customer credentials or tokens were saved.

## 2026-08-06 wellness live verification

- Route: `/portal/customer/services`; approved localhost customer session, with credentials intentionally omitted from this document.
- Backend connectivity correction: local Nest now binds IPv4 as well as the browser-facing loopback target. Health was `200` at `127.0.0.1:3000`; no session tokens were inspected or recorded.
- Browser-session captures (not persisted to disk): catalogue landing, `vitamin` search results, `Vitamins & supplements` filter results, product detail sheet, first-page pagination (`Page 1 of 23`) and second-page records, loading skeleton, and empty search recovery.
- Observed customer contract: 552 total records across 23 pages, 24 first-page records, imported rows show numeric prices and neutral product fallback icons, and the required disclosure remains visible.
- Responsive verification: 350, 375, 390, 412, 448, 480, 768, and 1200 px had no document-width overflow. At 350 px the prior raw import category label was too long; backend-owned concise labels were applied and visually verified.
- Detail verification: a product detail sheet opened from a card and retained the demo disclosure. Back/drop-dismiss returned to the catalogue without signing out. No cart records, orders, balances, memberships, or customer records were changed.
- Error/retry: verified live without stopping the backend. Chrome blocked only `/customer/wellness-products*` after Services access had loaded; the catalogue displayed its error card and Retry action. The block was removed, Retry restored the selected `Diagnostic devices` results, and no session or customer data changed.

## 2026-08-08 commerce QA checkpoint

- Deterministic Orders model/screen tests and targeted analysis passed.
- A bounded Playwright run reached the local Flutter page but returned an empty accessibility snapshot; the backend was not listening on port 3000. Authenticated order-history visual QA is `DEFERRED — TOOLING/RUNTIME FAILURE`; no OTP, order, payment, or ledger action was attempted.

## 2026-08-06 customer home completion

- Route: `/portal/customer/dashboard`; browser-session capture verified the Operations carousel, active membership card, Cash Wallet header value, and Reward Points header value in the authenticated session.
- A short local backend interruption was used only to confirm health recovery; the service was restored to `200` on the browser loopback target immediately. No customer data or session state was modified.
# Documents and prescriptions follow-up — 2026-08-08

- Static widget coverage verifies archive failure, category/search controller state, duplicate upload protection, prescription archive failure, and responsive surrounding customer shell coverage.
- Documents and Prescriptions responsive widget coverage passed at 350, 375, 390, 412, 448, 480, 768, and 1200 logical pixels with a long prescription filename.
- Authenticated screenshot QA remains `DEFERRED — TOOLING FAILURE` until a controlled local session exposes actionable rendered controls. No screenshot evidence is claimed.
- Final bounded attempt: localhost reached HTTP 200, but Playwright produced an empty accessibility snapshot, so approved local OTP could not be entered without bypassing stable controls. The matching local Flutter process was stopped after the attempt.
- Secure sharing, local-storage download streaming, OCR/clinical interpretation, fulfilment, payment, and delivery remain outside the current customer contract.
# Account/Profile QA note — 2026-08-08

Static responsive verification remains required across 350–1200px before claiming device QA. The profile, account workspace and session sheet use constrained cards, wrapping text and safe-area-aware scroll content. Authenticated browser evidence is not claimed in this document until an active local customer session is exercised.
