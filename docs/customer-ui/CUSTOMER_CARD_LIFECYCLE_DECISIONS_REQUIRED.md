# Customer card lifecycle decisions required

## Renewal

- Release support, eligible renewal window, plan selection, and price authority.
- Payment methods, wallet eligibility, payment-failure/refund handling, new validity period, and carry-forward treatment.
- Required audit events, notifications, and referral side effects.

## Lost, damaged, and replacement cards

- Whether each workflow is in release scope; replacement fee and cancellation policy.
- Whether/when the prior card is deactivated; duplicate active-card policy.
- Delivery-address source, status lifecycle, operational owner, and customer notifications.

## QR verification

- Static versus dynamic token; signing key ownership and expiry.
- Provider verification endpoint, replay prevention, offline behavior, and PII review.

Until these decisions have approved backend contracts, the customer app must keep these workflows unavailable.
