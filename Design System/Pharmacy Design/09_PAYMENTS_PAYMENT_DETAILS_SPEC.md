# Payments & Payment Details

## Payments

### Purpose
Review customer-submitted manual payment/recharge evidence and make a controlled approval/rejection decision.

### Payment list
Show:
- customer
- amount
- channel
- reference/UTR
- submitted timestamp
- status
- proof state

Entire row/card clickable.

### Payment review
Required:
- requested amount
- channel
- reference number
- payer/customer
- proof image/file
- destination snapshot
- submitted time
- review notes
- approve
- reject with reason

### Financial integrity UX
The UI must reflect backend truth:
- only APPROVED credits wallet
- duplicate approval cannot create another credit
- rejection does not credit
- approval/rejection disabled after terminal state
- show processing/locked state while mutation is running

Do not optimistically display wallet credit before server success.

## Payment Details

### Bank
Display:
- display label
- bank
- account holder if available
- masked account number
- primary
- active
- edit

### UPI
Display:
- display label
- UPI ID
- active
- primary
- QR
- replace/remove QR

### QR security
Private QR assets remain private.
Prefer authenticated same-origin backend delivery where direct R2 access causes browser CORS problems.

Do not:
- publish the bucket as a workaround
- expose raw storage paths
- allow another provider to read QR by ID manipulation

## Responsive

Desktop:
- table/card list + side/detail review

Mobile:
- payment list cards
- payment review full-screen route
- proof image zoom
- sticky Approve/Reject action bar

## Notifications

Relevant events:
- payment submitted -> Pharmacy staff alert
- payment approved -> customer
- payment rejected -> customer + reason
- payment details changed -> only notify where business workflow requires
