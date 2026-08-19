# Pharmacy Screen & Route Matrix

| Screen | Canonical route | Desktop | Tablet | Mobile/APK |
|---|---|---|---|---|
| Dashboard | `/portal/pharmacy-staff/dashboard` | KPI + 2-column recents | wrapped KPI | stacked |
| Orders | `/portal/pharmacy-staff/orders` | queue + detail | split/adaptive | list |
| Order Detail | route/state under Orders | split pane or detail | detail | full screen |
| Payments | `/portal/pharmacy-staff/payments` | list/review | adaptive | list |
| Payment Review | payment detail | panel/modal | detail | full screen |
| Payment Details | `/portal/pharmacy-staff/payment-details` | bank/UPI cards | stacked | stacked |
| Order History | `/portal/pharmacy-staff/history` | filters/list | filters/list | compact filters |
| Profile | `/portal/pharmacy-staff/profile` | multi-column | 2-col | stacked |
| Settings | `/portal/pharmacy-staff/settings` | multi-card grid | 2-col | sections |

## Dashboard drill-down matrix

| Surface | Destination |
|---|---|
| New Orders card | Orders/New |
| Preparing card | Orders/Preparing |
| Ready for Pickup | Orders/Ready |
| Out for Delivery | Orders/Delivery |
| Pending Payments | Payments/Pending |
| Approved Today | Payments/Approved + Today |
| Completed Today | History/Completed + Today |
| View All Orders | Orders |
| Recent Order row | Order detail |
| View All Payments | Payments |
| Recent Payment row | Payment review |

## Order action matrix

| Scenario | UI action |
|---|---|
| all stock available | Approve |
| lower stock than requested | Partial Approve |
| zero stock | Reject / Choose Alternative |
| alternate exists | Propose/Use Alternative |
| customer confirmation required | Request Customer Confirmation |
| home delivery partial items | Dispatch Partial Order if allowed |
| pickup partial items | mark ready for approved items according to policy |
| long-term/refill | Mark as Chronic |
| invoice ready | Upload / Send Invoice |

## Profile navigation

Quick links may point to:
- Payment Details
- Notification Settings
- Security/session management

Only show links that have real destinations.
