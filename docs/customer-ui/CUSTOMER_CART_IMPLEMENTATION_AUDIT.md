# Customer Cart Implementation Audit

Classification: `DEFERRED — BACKEND CONTRACT REQUIRED`

No `Cart` or `CartItem` model, customer-owned cart endpoint, backend total
calculation, stock reservation, product purchase-limit rule, or checkout
revalidation contract exists. The current Wellness catalogue is therefore
catalogue-only and no local/persistent cart has been introduced.

Required before implementation: backend-owned product orderability, inventory
authority, authenticated cart ownership, server-calculated totals, mutation
concurrency behaviour, and checkout revalidation.
