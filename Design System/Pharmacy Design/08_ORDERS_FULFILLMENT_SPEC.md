# Orders & Fulfillment Specification

## 1. Purpose

Orders is the operational center of the Pharmacy portal.

The experience must support realistic stock outcomes without forcing an all-or-nothing order decision.

## 2. Queue filters

Recommended filters:
- All
- New
- Accepted
- Partial Review
- Preparing
- Ready for Pickup
- Out for Delivery
- Chronic Orders

Terminal records belong primarily in History.

## 3. Order detail header

Display:
- order ID
- placed timestamp
- source
- customer
- customer contact
- fulfillment preference
- delivery/pickup information
- payment state
- order state
- chronic-order toggle

## 4. Per-item fulfillment

Each item requires:

```text
Requested Qty
Available Qty
Fulfill/Approve Qty
Unit Price
Line Total
Action State
```

Actions:
- Approve full
- Approve partial
- Reject
- Suggest/use substitute
- Await customer confirmation if required

## 5. Low-stock behavior

If:
```text
available > 0 && available < requested
```

UI:
- show LOW STOCK
- maximum fulfill qty = available
- default behavior should not silently alter quantity
- allow partial approval if policy permits
- offer substitute for remaining quantity where valid
- show clear customer-impact summary

## 6. Out-of-stock behavior

If:
```text
available == 0
```

UI:
- OUT OF STOCK
- fulfill qty = 0
- reject action available
- alternative suggestion available
- reason captured

Do not pretend the item will be fulfilled.

## 7. Substitution / alternate brand

Use case:
same therapeutic/medicine requirement cannot be fulfilled with ordered brand, and a valid alternate exists.

Required flow:
1. Pharmacy selects alternate.
2. UI shows original and replacement.
3. Price difference is visible.
4. Customer confirmation is requested when business policy requires it.
5. Final approved item records the substitution.
6. Notification is sent.
7. Audit/timeline records the decision.

Do not silently replace brands.

## 8. Partial approval

Order-level derived state should indicate partial review/partial approval when at least one item is not fulfilled exactly as requested.

Example:
- item A 2/2 approved
- item B 1/3 approved
- item C rejected
- item D substituted

Billing uses only accepted/fulfilled quantities according to business rules.

## 9. Partial dispatch

Allowed only when:
- policy permits
- at least one item is dispatchable
- fulfillment is HOME_DELIVERY
- invoice/payment requirements are satisfied
- customer confirmation rules are satisfied

`COLLECT_FROM_PHARMACY` must not accidentally enter delivery dispatch states.

## 10. Chronic order

"Mark as Chronic Order" means the order/customer medication pattern requires future refill planning.

Store at least:
- flag
- optional frequency/refill interval
- note
- tagged timestamp
- tagged by
- associated customer/order

Use future reminders/notifications where supported.

Do not auto-diagnose or infer chronic treatment from medicine name alone.

## 11. Notes and remarks

Support:
- internal pharmacist remarks
- customer-visible note if explicitly chosen
- per-order rejection reason
- substitution reason
- low-stock explanation

## 12. Pricing

Where policy allows pharmacy pricing:
- unit price editable
- changed price clearly marked
- subtotal recalculated
- discount policy explicit
- final payable visible
- audit price changes

Do not allow UI price editing if backend/business policy forbids it.

## 13. Invoice / bill

Required UI:
- upload bill/invoice
- view uploaded file
- replace/remove according to state
- Send Invoice action
- invoice status
- invoice sent timestamp

Files:
- private storage
- authenticated retrieval
- web-safe CORS/streaming architecture
- mobile picker support

## 14. Notifications

Trigger candidate events:
- order accepted
- item partially approved
- item rejected
- substitute proposed
- customer confirmation requested
- order ready
- invoice available
- dispatched
- completed
- cancelled

Use backend event truth. UI toggle must not fake delivery.

## 15. Mobile UX

Use item cards rather than a wide table.

Sticky bottom actions can include:
- Approve Selected
- Partial Approve
- Reject Items
- Dispatch

The currently relevant action should have strongest emphasis.

## 16. Desktop UX

Use queue + detail split pane.
Avoid forcing navigation back and forth for high-volume work.
