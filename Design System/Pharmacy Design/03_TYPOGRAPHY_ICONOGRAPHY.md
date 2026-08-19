# Typography & Iconography

## 1. Typeface

The supplied image files do not contain font metadata. For implementation consistency, this design system standardizes Pharmacy on:

**Primary UI font: Inter**

Fallback:
```text
Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
```

Flutter:
- Prefer the project-wide Inter integration if already available.
- Do not add a second near-identical font merely for Pharmacy.
- Do not ship font files through this design package.

## 2. Type scale

| Style | Size | Weight | Line height | Usage |
|---|---:|---:|---:|---|
| Display | 32 | 700 | 40 | rare large desktop hero |
| H1 | 28 | 700 | 36 | page title |
| H2 | 22 | 700 | 30 | major section |
| H3 | 18 | 600 | 26 | card/panel heading |
| H4 | 16 | 600 | 24 | subsection |
| Body L | 16 | 400 | 24 | primary readable body |
| Body M | 14 | 400 | 20 | default UI |
| Body M Strong | 14 | 600 | 20 | labels / entity names |
| Body S | 12 | 400 | 18 | metadata |
| Label | 12 | 600 | 16 | chip/compact labels |
| Micro | 11 | 500 | 14 | dense table metadata only |

## 3. Hierarchy examples

Order row:
```text
Order ID          14/600
Customer          13–14/500
Amount            14/600
Status chip       11–12/600
Time/meta         12/400
```

KPI:
```text
Metric label      14/500
Metric value      26–30/700
Amount/change     12–14/600
```

## 4. Typography rules

- Use sentence case, not ALL CAPS for headings.
- Status chips can use title case.
- Avoid excessive bold.
- Numbers must align visually in operational tables.
- Currency: `₹ 1,250.00` or current product convention, consistently.
- Use tabular numerals where available for money/quantity columns.
- Truncate only after preserving critical identity.
- On mobile, allow important order/item names to wrap to two lines.

## 5. Icons

Preferred style:
- Simple line icons
- Rounded geometry
- 1.5–2px visual stroke
- Consistent optical size
- Avoid mixing filled, outlined, skeuomorphic icon styles

Semantic examples:
- Dashboard: grid
- Orders: bag/cart/package
- Payments: wallet/rupee
- Payment Details: card/document
- Order History: clock/history
- Profile: user
- Settings: gear
- Ready: bag/check
- Delivery: truck/scooter
- Warning: triangle
- Reject: x-circle
- Chronic: repeat/refresh/medical recurrence
- Substitute: swap arrows
- Invoice: document/file
- Notes: pencil/message
- Notifications: bell

## 6. Icon button accessibility

Every icon-only action requires:
- Tooltip on web/desktop
- Semantic label
- Minimum 44×44 touch target on mobile
- Visible focus state on keyboard navigation

## 7. Product imagery

Medication thumbnails can be displayed when real product images exist. Use a neutral placeholder otherwise. Never insert fake medicine photography into production runtime data.
