# Profile & Settings Specification

## 1. Profile

The Profile page is not a generic account placeholder. It represents both the signed-in user and the Pharmacy business context.

### Pharmacist / User Profile
- avatar
- full name
- role
- mobile
- email
- branch/outlet
- password/security entry points

### Pharmacy / Business Details
- Pharmacy name
- business code
- address
- city/state/PIN
- contact number
- business email
- GST number if applicable
- drug license/registration
- business type
- established date
- operating hours

### Branches / Outlets
If multi-branch exists:
- branch name
- address
- primary branch
- active state
- current branch context

Do not invent multi-branch management if the backend does not support it.

### Delivery & Service Area
- delivery active
- service area
- delivery radius
- pickup availability

### Emergency / Support Contact
Only if actually required by product policy.

### Account & Security
- password change
- sessions
- optional 2FA where supported
- account state

## 2. Settings

Settings should control real persisted behavior.

### Order Workflow
- auto-accept new orders
- default state after accept
- allow partial fulfillment
- partial dispatch policy
- alternative/substitute suggestions
- customer confirmation requirement
- chronic order tagging
- invoice-before-dispatch policy

### Low Stock
- low-stock alerts
- threshold if backend inventory contract supports it
- notification channel

### Notifications
- new order alerts
- payment alerts
- order updates
- dispatch updates
- chronic reminders

### Delivery / Pickup
- home delivery enabled
- delivery time window
- minimum delivery order
- store pickup
- pickup lead time

### Payment Preferences
- manual verification
- proof requirement
- payment verification window

Do not expose "auto-approve" if that contradicts the current manual-payment-only architecture.

### Display / App Behavior
Safe user preferences:
- language
- date format
- time format
- items per page
- theme if supported
- default landing page

## 3. Save model

Settings:
- dirty state
- Save Changes
- Cancel
- Reset to Defaults where meaningful
- success confirmation
- server validation
- conflict handling

Do not silently save each toggle unless that is the explicit app convention.

## 4. Mobile

Use section cards and progressive disclosure.
Avoid a giant desktop form squeezed into one narrow page.
