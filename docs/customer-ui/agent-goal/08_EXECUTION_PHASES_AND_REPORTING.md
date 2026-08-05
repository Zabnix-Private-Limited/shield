# EXECUTION PHASES AND REPORTING

## Work-turn behavior

Every active work turn must make concrete progress. Do not return only status-preservation messages.

At the beginning of a turn:

1. Read the current matrix and implementation-status docs.
2. Inspect `git status` and recent commits.
3. Identify one coherent vertical slice.
4. State the exact files/routes being worked on.
5. Implement, test and document them.

At the end of a turn, report concrete results using the template below.

## Phase 0 — Audit and stabilization

- Reconcile screen matrix with real routes
- Inventory inline portal views
- Inventory shared components
- Inventory APIs/providers/models
- Establish baseline tests
- Verify recent Dashboard/header/banner/reward work
- Fix regressions before expanding

## Phase 1 — Shared visual foundation

- Tokens/theme
- Responsive frame
- Main/detail headers
- Wallet/Reward header chips
- Notification bell
- Drawer
- Bottom navigation
- Buttons/cards/inputs
- Loading/empty/error/offline components

## Phase 2 — Home, Profile and Settings first

- Dashboard visual completion
- Operations carousel QA
- Banner details
- Profile extraction/redesign
- Settings extraction/redesign
- Navigation consistency

These pages are highly visible and must not remain in the old visual system while other modules are polished.

## Phase 3 — Membership and card

- Membership dashboard
- Privilege/digital/QR card
- Subscription and entitlements
- Benefits
- Physical-card request/tracking/history
- Supported lost/damaged/replacement/renewal states

## Phase 4 — Wallet and Reward Points

- Wallet secondary pages
- Transactions/details
- Add funds/statements/refunds/reversals
- Reward history/details/rules
- Supported reward lifecycle

## Phase 5 — Services and booking

- Extract Services
- Search/categories/providers/details
- Booking flow
- Visits list/details/cancel/reschedule
- Pricing and coverage integration

## Phase 6 — Documents and prescriptions

- Document navigation/list/detail/view/upload
- Prescription list/upload/view/status
- Lab and medical-record views
- Security and ownership QA

## Phase 7 — Wellness commerce

- Catalogue/search/filter/detail
- Wishlist/cart/address
- Checkout/payment/order
- Order list/detail/tracking/cancel/return/refund where supported

## Phase 8 — Referrals, activity and notifications

- Referral dashboard/history/status/rules
- Activity timeline/details
- Notification inbox/details/preferences

## Phase 9 — Family, contacts, privacy and support

- Family/dependents
- Addresses/emergency contacts/preferred pharmacy
- Privacy/security/session/legal
- Help/FAQ/tickets/feedback/about/logout

## Phase 10 — State, responsive and accessibility completion

- All global states
- All breakpoints
- Text scaling
- Keyboard/focus/semantics
- Contrast and touch targets
- Offline/session-expired handling

## Phase 11 — Final verification and release readiness

- Matrix at 100% or approved explicit exclusions
- Full route walkthrough
- Screenshot QA
- Tests/builds
- Documentation
- Final implementation log
- No dead routes or static mocks

## Commit/checkpoint rules

- Use coherent feature commits.
- Do not include secrets, build outputs, signing files, temporary screenshots outside documented QA folders or the Design reference directory.
- Do not revert unrelated work.
- Do not rewrite shared history without authorization.
- Record the commit hash in the end-of-turn report.

## End-of-turn report template

### Phase

### Screens/routes completed

### Existing functionality preserved

### Components created/refactored

### Files changed

### APIs/controllers/repositories/providers used

### Backend/schema changes

### Data/security checks

### Tests run and exact results

### Screenshots and visual-QA evidence

### Mismatches found and corrected

### Supported workflows completed

### Unsupported/backend gaps documented

### Documentation updated

### Commit/checkpoint

### Exact next screen and file

Do not report “the goal remains active” without this concrete information.
