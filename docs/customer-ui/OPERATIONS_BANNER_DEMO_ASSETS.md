# Operations banner demo assets

The dashboard carousel remains controlled by the `OPERATIONS_CUSTOMER_BANNERS` database setting. The optional non-production seed at `backend/prisma/demo-seeds/20260805_operations_customer_banners.sql` references these locally bundled demo photos:

- `frontend/assets/images/operations/wellness-nutrition.jpg` — Unsplash, healthy-food image search source.
- `frontend/assets/images/operations/care-visit.jpg` — Unsplash, doctor-consultation image search source.
- `frontend/assets/images/operations/healthy-food.jpg` — Unsplash, wellness-food image search source.

They are visual-only assets for the demo banner records; they do not describe a customer, product, provider, price, or medical outcome. Replace them through the Operations setting when approved campaign assets are available.
