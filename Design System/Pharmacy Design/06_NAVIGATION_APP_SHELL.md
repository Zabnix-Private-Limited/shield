# Navigation & App Shell

## Canonical Pharmacy route family

```text
/portal/pharmacy-staff/dashboard
/portal/pharmacy-staff/orders
/portal/pharmacy-staff/payments
/portal/pharmacy-staff/payment-details
/portal/pharmacy-staff/history
/portal/pharmacy-staff/profile
/portal/pharmacy-staff/settings
```

Legacy Pharmacy links may redirect into this family, but real non-Pharmacy provider routes must remain untouched.

## Desktop navigation order

1. Dashboard
2. Orders
3. Payments
4. Payment Details
5. Order History
6. divider
7. Profile
8. Settings

Support can live at the bottom of the sidebar.

## Mobile navigation

Suggested bottom nav:
- Dashboard
- Orders
- Payments
- More

`More`:
- Payment Details
- Order History
- Profile
- Settings
- Support
- Logout

If the product already has a shared mobile shell, adapt these destinations without creating duplicate routing systems.

## Deep links

Each business page must:
- open directly
- survive browser refresh
- preserve role guard
- work after app restart where deep-linking is supported
- resolve Pharmacy identity before showing content

## Dashboard drill-downs

Every navigable KPI or View All control must have a deterministic destination:

```text
New Orders           -> /orders?status=NEW
Preparing            -> /orders?status=PREPARING
Ready for Pickup     -> /orders?status=READY_FOR_PICKUP
Out for Delivery     -> /orders?status=OUT_FOR_DELIVERY

Pending Payments     -> /payments?status=PENDING
Approved Today       -> /payments?status=APPROVED&date=today
Completed Today      -> /history?status=COMPLETED&date=today

View All Orders      -> /orders
View All Payments    -> /payments
```

Use the actual current query/filter contract.

## App-shell behavior

- Pharmacy session must not preload Agent workspace/customer APIs.
- Pharmacy shell must not render generic Enterprise workspace content for Pharmacy business pages.
- Role identity and provider scope drive navigation; section-name heuristics must not identify Pharmacy.
