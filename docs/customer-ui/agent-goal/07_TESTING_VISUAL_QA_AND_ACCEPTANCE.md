# TESTING, VISUAL QA AND ACCEPTANCE CONTRACT

## Baseline before each phase

- Confirm branch and `git status`
- Preserve unrelated/concurrent work
- Run relevant existing tests
- Confirm non-production environment
- Confirm target customer test account
- Confirm backend and Flutter use the same database/API environment

## Required visual-QA loop

For every completed route or major state:

1. Open the closest approved reference image.
2. Run the real app through normal navigation.
3. Use deterministic database-backed non-production data.
4. Capture at a specified viewport.
5. Compare hierarchy, padding, spacing, typography, colors, cards, radii, borders, shadows, icons, controls, text wrapping and navigation.
6. Create overlay/difference output where practical.
7. Record mismatches.
8. Correct material mismatches.
9. Recapture.
10. Record final screenshot path and residual approved differences.

The Operations carousel’s presence/placement is an approved difference when absent from a reference.

## Required viewport matrix

- 350×appropriate height
- 375×appropriate height
- 390×appropriate height
- 412×appropriate height
- 448×appropriate height
- 480×appropriate height
- Tablet portrait
- Tablet landscape
- Desktop/web constrained frame

## Required test types

### Shared shell

- Header values loading/populated/zero/error
- No overflow at all mobile widths
- Drawer navigation
- Bottom navigation
- Session-expired handling
- Logout cache clearing
- Accessibility semantics

### Dashboard

- Carousel loading/populated/empty/error
- Carousel is before membership card
- Wallet and points not duplicated below
- Membership summary states
- Empty appointments/activity
- Quick-action navigation

### Membership/cards

- Active/pending/suspended/expired states
- Digital card and QR
- Entitlement values from backend
- SHIELD Benefit not included in cash
- Card-request supported/unsupported states
- Negative ownership checks

### Wallet/rewards

- Ledger filtering
- Transaction states
- Valid zero vs API failure
- Add-funds idempotency where supported
- Reward qualification/redemption rules
- No cross-customer data

### Services/booking/visits

- Search/filter results
- Provider detail
- Slot loading/no slots
- Pricing/coverage result
- Create/cancel/reschedule
- Double-submit protection
- Ownership scope

### Documents/prescriptions

- Upload validation/progress/failure
- Secure viewer
- Ownership denial
- Empty/error states
- No raw storage URL exposure

### Commerce

- Database product loading
- Search/filter/cart
- Server-authoritative totals
- Checkout/order creation
- Order state rendering
- Empty cart/catalogue
- Demo disclosure

### Referrals/notifications/profile

- Referral status lifecycle
- Privacy-safe tree
- Read/unread/mark-all-read
- Profile and contact updates
- Family ownership
- Settings persistence
- Support ticket states

## Commands

Use repository-standard commands. At minimum:

- `dart format`
- Targeted `flutter analyze`
- Full `flutter analyze` at phase completion
- Targeted `flutter test`
- Full relevant Flutter suite at release gate
- Backend `tsc --noEmit` or repository build when server contracts change
- Backend targeted tests
- Prisma validation when schema changes
- `git diff --check`

## Evidence document

Maintain `docs/customer-ui/CUSTOMER_UI_VISUAL_QA.md` with:

- Screen/route
- Reference image
- Viewport
- Test account/data fixture
- Before screenshot
- After screenshot
- Overlay/diff path
- Mismatches found
- Corrections made
- Remaining approved difference
- Tests run
- Reviewer status

Do not claim pixel-perfect output without evidence.
