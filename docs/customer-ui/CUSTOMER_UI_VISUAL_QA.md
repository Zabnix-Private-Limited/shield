# Customer UI visual QA

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
