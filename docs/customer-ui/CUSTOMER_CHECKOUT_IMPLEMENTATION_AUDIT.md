# Customer Checkout Implementation Audit

Classification: `DEFERRED — PAYMENT CONTRACT REQUIRED`

There is no customer checkout/order-submit endpoint, payment intent, cash
wallet payment authorization, reward redemption rule for Wellness products,
SHIELD Benefit eligibility for Wellness products, external gateway, COD rule,
delivery contract, address snapshot, or submit idempotency mechanism.

Existing provider pharmacy purchases and ledgers must not be used as a customer
checkout substitute. CASH, REWARD_POINTS, and SHIELD_BENEFIT remain separate
backend-ledger concerns and Flutter does not calculate or deduct any of them.
