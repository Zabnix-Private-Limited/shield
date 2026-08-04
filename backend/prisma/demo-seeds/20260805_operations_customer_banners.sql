-- DEMO ONLY. Run once against an approved non-production database.
-- This only creates the Operations banner setting if Operations has not
-- configured one already; it never overwrites a live Operations decision.

INSERT INTO commercial_settings (uuid, code, value_type, value_text, status)
VALUES (
  'f1515b83-e324-4d0e-b3f3-2ca4131584c5'::uuid,
  'OPERATIONS_CUSTOMER_BANNERS',
  'JSON',
  $$[
    {
      "id": "demo-wellness-catalogue",
      "title": "Explore demo wellness essentials",
      "subtitle": "Browse the clearly marked SHIELD demo wellness catalogue.",
      "imageUrl": "assets/images/operations/wellness-nutrition.jpg",
      "altText": "Fresh vegetables and ingredients arranged for a wellness meal.",
      "ctaLabel": "Open wellness shop",
      "ctaRoute": "/portal/customer/wellness-shop",
      "placement": "DASHBOARD",
      "audience": ["ALL_CUSTOMERS"],
      "priority": 30,
      "status": "PUBLISHED"
    },
    {
      "id": "demo-care-services",
      "title": "Plan your next care visit",
      "subtitle": "Find an active provider and request a visit through SHIELD.",
      "imageUrl": "assets/images/operations/care-visit.jpg",
      "altText": "Healthcare professional discussing care with a patient.",
      "ctaLabel": "View services",
      "ctaRoute": "/portal/customer/services",
      "placement": "DASHBOARD",
      "audience": ["ALL_CUSTOMERS"],
      "priority": 20,
      "status": "PUBLISHED"
    },
    {
      "id": "demo-healthy-routine",
      "title": "Build a balanced routine",
      "subtitle": "Keep your documents and membership details ready in one place.",
      "imageUrl": "assets/images/operations/healthy-food.jpg",
      "altText": "Fresh healthy food prepared for a balanced routine.",
      "ctaLabel": "View membership",
      "ctaRoute": "/portal/customer/membership",
      "placement": "DASHBOARD",
      "audience": ["ALL_CUSTOMERS"],
      "priority": 10,
      "status": "PUBLISHED"
    }
  ]$$,
  'ACTIVE'
)
ON CONFLICT (code) DO NOTHING;
