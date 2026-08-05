# Customer UI visual QA

## 2026-08-05 account-capabilities checkpoint

- Source route: `/portal/customer/account`.
- Static verification: targeted Flutter analysis and customer portal route test passed.
- Browser result: the existing localhost session redirected to customer login after route navigation. No OTP was submitted, no sign-out was requested, and no customer data was created, edited, or removed.
- Screenshot state: customer login page only; it is not evidence for authenticated account capability rendering.

## Required follow-up

- Restore an authenticated local customer session and verify addresses, family, contacts, preferred pharmacy, and notification preferences against the development API.
- Capture populated and empty-state screenshots at the required responsive widths before marking visual QA complete.
