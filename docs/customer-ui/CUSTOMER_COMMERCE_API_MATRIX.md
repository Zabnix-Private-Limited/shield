# Customer Wellness Commerce API Matrix

Last audited: 2026-08-08

## Current product decision

The customer Wellness feature is a catalogue, not an online shop. Imported
`LEGACY_XLS_20260805` records are demo-visible catalogue data, and the current
schema/API has no customer cart, checkout, order-creation, payment, delivery
snapshot, cancellation, refund, or reorder contract. A product price, stock
quantity, `ACTIVE` status, or demo visibility must not be treated as ordering
eligibility.

The customer catalogue response now returns `purchasable: false` with a
customer-safe reason. Flutter displays this state and deliberately provides no
Add to Cart or Checkout affordance. This avoids creating an unsupported flow
or incorrectly debiting CASH, REWARD_POINTS, or SHIELD_BENEFIT.

## Capability matrix

| Capability | Customer route | Backend endpoint | Contract/model | Classification |
| --- | --- | --- | --- | --- |
| Browse catalogue | Wellness Shop | `GET /customer/wellness-products` | `Product`, `ProductCategory`; authenticated customer; paged/search/category filtered | Supported catalogue only |
| View product | Wellness Shop detail | `GET /customer/wellness-products/:id` | Customer-safe product projection; ownership is not relevant because catalogue is shared | Supported catalogue only |
| Availability disclosure | Wellness Shop | Included in catalogue response | `purchasable: false`, `purchasabilityReason`; backend is authoritative | Supported safety disclosure |
| Persistent cart | — | — | No Cart/CartItem Prisma model, service, controller, repository, or provider | Missing contract |
| Checkout / submit order | — | — | No customer checkout DTO, idempotency token, or transactional customer order mutation | Missing contract |
| Customer payment | — | — | No customer payment method/intent contract. Existing wallet and pricing services are provider/staff purchase infrastructure. | Missing contract |
| Delivery address snapshot | — | — | `CustomerAddress` exists, but `Purchase` has no address snapshot and no delivery contract | Missing contract |
| Order history | My Orders | `GET /pharmacy/purchases?customer_id=:id` | Existing `Purchase` / `PurchaseItem` read surface; customer identity is supplied from the authenticated session in Flutter | Existing recorded-purchase history |
| Order details / timeline | — | — | No customer order-detail DTO or historical status event model | Missing contract |
| Cancel, refund, reorder | — | — | No customer mutation/API/model contract | Missing contract |

## Financial and security rules

- CASH, REWARD_POINTS, and SHIELD_BENEFIT remain separate backend-ledger
  concerns. Flutter never calculates balances or deducts funds.
- `Purchase`/`PurchaseItem` are existing recorded purchase entities, not proof
  of a supported customer checkout flow.
- The existing `POST /pharmacy/purchases` is provider-scoped and must not be
  reused as a customer checkout endpoint: it accepts provider/invoice/item
  inputs and follows the provider pharmacy pricing/ledger path.
- A future customer commerce contract must revalidate product eligibility,
  price, stock, delivery data, and payment transactionally; it must also use
  backend idempotency protection before any wallet/payment mutation.

## Required product decision before checkout implementation

Define a backend-owned orderability contract (including inventory ownership),
cart strategy, fulfilment/delivery rules, payment methods, ledger eligibility,
order status transitions, address snapshot, cancellation/refund policy, and
idempotent submit semantics. Only then add additive schema/API work and the
corresponding Flutter cart/checkout UI.
