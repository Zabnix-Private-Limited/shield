# Component Library

## 1. PharmacyPageHeader

Includes:
- Page title
- Optional subtitle
- Role context
- Notification bell
- User avatar/menu
- Optional primary action

Responsive:
- Collapse subtitle/actions on compact
- Keep page identity visible

## 2. NavigationItem

States:
- default
- hover
- active
- focus
- disabled

Active:
- primary-soft background
- primary icon/text
- subtle radius

## 3. KPI / MetricCard

Required:
- icon block
- label
- main value
- optional amount/delta
- drill-down affordance

If a metric is navigable, the **entire card must be interactive**.

Example mappings:
- New Orders -> Orders filtered New
- Preparing -> Orders filtered Preparing
- Ready for Pickup -> Orders filtered Ready
- Out for Delivery -> Orders filtered Delivery
- Pending Payments -> Payments filtered Pending
- Approved Today -> Payments filtered Approved + Today
- Completed Today -> History filtered Completed + Today

## 4. EntityRow / EntityCard

Used for:
- Recent Orders
- Orders queue
- Payment requests
- History

Required states:
- default
- hover
- focused
- selected
- loading
- disabled if applicable

The row should expose:
- primary identity
- secondary identity
- status
- amount
- timestamp
- navigational affordance

## 5. StatusChip

Do not invent unique colors per arbitrary status.

Recommended mapping:

```text
NEW / PLACED            info
ACCEPTED                success-soft or info-soft
REVIEWING               warning/info
PREPARING               warning
READY_FOR_PICKUP        success
OUT_FOR_DELIVERY        purple/info
COMPLETED               success
PENDING payment         warning
APPROVED payment        success
REJECTED                danger
CANCELLED               danger-soft
LOW_STOCK               warning
OUT_OF_STOCK            danger
PARTIAL                  warning
SUBSTITUTED              primary/success
CHRONIC                  purple or primary-soft
```

## 6. Button hierarchy

### Primary
Use for one main action per region:
- Approve Order
- Save Changes
- Approve Payment

### Secondary outline
- Save Draft
- Send Invoice
- Request Confirmation

### Positive secondary
- Use Alternative
- Approve Selected

### Warning
- Partial Approve
- Partial Dispatch

### Destructive
- Reject Item
- Reject Payment
- Cancel Order

Do not show five visually equal primary buttons.

## 7. Form controls

Height:
- 40 desktop
- 44 mobile touch

States:
- default
- hover
- focus
- filled
- error
- disabled
- read-only

Every validation error appears near the field and is screen-reader accessible.

## 8. QuantityStepper

For per-item fulfill qty:
- minus
- current value
- plus
- max = available stock and requested qty under business rules

Must clearly show:
- requested quantity
- available quantity
- fulfill quantity
- partial-state explanation

## 9. OrderItemFulfillmentCard / Row

Required fields:
- item
- requested qty
- available qty
- approve/fulfill qty
- stock status
- unit price
- line amount
- action state
- alternate/substitute if relevant

Possible item states:
- approved
- partial
- rejected
- substituted
- awaiting customer confirmation

## 10. SubstituteSuggestion

Must contain:
- original item
- suggested replacement
- brand/product identity
- equivalent pack/strength details where available
- price
- availability
- customer confirmation requirement
- Use Alternative action

Never silently replace an item.

## 11. FileUploadCard

For bill/invoice/payment proof:
- drag/drop web
- file picker mobile
- file type/size guidance
- progress
- success
- error
- remove/retry
- file name

## 12. Notes / Remarks

Support:
- pharmacist internal note
- customer-visible note only when explicitly marked
- timestamps/user attribution where persisted
- rejection reason structured separately

## 13. AlertBanner

Types:
- information
- action required
- warning
- error

Must have:
- concise title
- short explanation
- optional CTA
- optional dismiss

## 14. Skeletons

Use shape-matched skeletons:
- KPI skeleton
- list row skeleton
- order item skeleton
- profile card skeleton

No full-page centered circular spinner for ordinary page load.

## 15. Toast / Snackbar

Use for transient confirmation:
- saved
- approved
- rejected
- invoice sent

Never use toast as the only place to communicate a blocking error.
