# Customer App Manual QA Checklist

Use the approved customer account. Do not change primary phone, membership/financial data, or revoke the current session.

- [ ] Login — phone OTP reaches Dashboard and restores the intended protected route.
- [ ] Home/header/navigation — wallet/reward values, unread badge, drawer and five-item bottom navigation remain visible and routes work.
- [ ] Membership/card — overview, subscription/benefits, digital card and supported physical-card status render; unavailable actions state why.
- [ ] Wallet/rewards — CASH and points are distinct; filters/history/details work; an API error is not shown as a false zero.
- [ ] Services/booking — search, category, provider detail and booking request work; no false availability/price/distance claims.
- [ ] Visits — status filters, details, permitted cancel/reschedule and failures are clear.
- [ ] Documents/prescriptions — list/category/detail/upload/view flows respect the customer; pharmacy review requires explicit action.
- [ ] Wellness/orders — catalogue search/pagination/detail and recorded order detail work; no cart/checkout/tracking claims.
- [ ] Referrals/notifications/activity — self-only history renders; read/mark-all updates unread state without leaking another customer.
- [ ] Profile/family/providers — profile saves supported fields only; login phone stays read-only; addresses, contacts, dependents and preference actions refresh truthfully.
- [ ] Sessions/logout — only own devices appear; revoke-other excludes this device; sign-out ends the current session.
- [ ] Responsive/error behavior — repeat representative Home, Services and Profile paths at 350px and desktop; check retry/empty/error state instead of blank/zero state.
