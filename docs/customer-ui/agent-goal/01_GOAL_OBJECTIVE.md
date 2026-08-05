# SHIELD CUSTOMER APP — COMPLETE UI/UX IMPLEMENTATION GOAL

## Mission

Complete the entire customer-facing SHIELD application inside the existing repository. Every supported customer route, workflow, state and secondary page must use one coherent UI/UX system derived from the approved reference images while remaining integrated with the current backend, database, authentication and architecture.

This is not finished when the Dashboard looks good. It is not finished when the ten reference screens are recreated. It is not finished when routes merely exist. It is finished only when the complete supported customer experience is visually coherent, functional, secure, database-backed, responsive, tested and screenshot-verified.

## Mandatory files to read before editing

Read all of the following completely:

1. Repository `AGENTS.md`
2. Repository `current_schema.md`
3. Repository `log.md`
4. Current customer UI audit and implementation-status documents
5. Current route configuration
6. Customer authentication implementation
7. Customer shell, header, drawer and bottom navigation
8. Customer repositories, Riverpod providers, DTOs and API clients
9. Backend controllers/services used by customer features
10. Prisma models and migrations relevant to customer features
11. Every image in `E:\K4NN4N\shield\Design reference`
12. Every file in this goal package

Do not begin broad implementation until the repository audit is updated.

## Mandatory first output in the repository

Create or update a customer UI audit that records, for every customer route and workflow:

- Current route and route name
- Current screen/widget
- Whether it is inline, extracted or missing
- Current API/controller
- Current repository/provider
- Current persisted models/tables
- Authentication and scope requirements
- Existing functionality that must be preserved
- Visual redesign status
- Missing related pages
- Loading/empty/error/offline-state status
- Responsive status
- Test status
- Screenshot-QA status
- Known blocker
- Next implementation action

Use `03_CUSTOMER_SCREEN_COMPLETION_MATRIX.csv` as the baseline and reconcile it against the actual repository. Do not blindly create every suggested route when an existing equivalent already exists.

## Product invariants

SHIELD is a healthcare membership and customer-retention platform with one customer identity across healthcare services, membership, wallet, benefits, referrals, medical records and commerce.

The customer experience must preserve:

- Firebase-verified customer identity
- Customer JWT/session handling
- Membership and digital card
- Cash Wallet
- Reward Points
- Hidden SHIELD Benefit ledger
- Service-specific benefit application
- Referral lifecycle
- Provider/service discovery
- Appointments and visits
- Documents and prescriptions
- Wellness products and orders
- Notifications and activity
- Profile, contacts and family where supported
- Operations-managed campaign content
- RBAC, authorization, audit and data isolation

## Three-ledger rule

The platform uses separate value domains:

1. `CASH` — customer-visible Cash Wallet, ledger-derived
2. `REWARD_POINTS` — customer-visible points ledger
3. `SHIELD_BENEFIT` — company-funded benefit ledger, not a withdrawable cash balance

Never merge these values.

The global Cash Wallet chip must display only the authenticated customer’s ledger-derived `CASH` balance.

The Reward Points chip and Reward screen must use only `REWARD_POINTS`.

Do not show the remaining hidden SHIELD Benefit as Cash Wallet or Reward Points. Where benefit application is allowed, show only the applied subsidy/coverage context that the backend authorizes for the relevant transaction or subscription view.

Never convert API failure into a displayed zero. A valid zero and unavailable data are different states.

## Authentication invariants

- Customers authenticate using the current Firebase phone-auth flow and SHIELD session exchange.
- The verified primary mobile is the authentication identity.
- An alternative contact number is not automatically a second login identity.
- Do not bypass OTP for visual convenience.
- Do not create local password authentication unless it already exists and is approved.
- Existing-customer lookup must remain duplicate-safe.
- Session expiry, revoked access, suspended customers and archived customers must have deliberate UI states.

## Operations carousel rule

The customer Home page must always reserve the first content position for the Operations-managed banner carousel:

1. Global customer header
2. Operations carousel
3. Membership/Privilege summary
4. Quick actions
5. Summary and recent/upcoming content
6. Bottom navigation

The carousel must remain database/API-driven. It must support publication window, placement, audience eligibility, priority, title, subtitle, media, alt text, CTA and status. Customer APIs must return only eligible published content. Do not create a static Flutter campaign list.

Visible terminology is `Operations Team`, not `Marketing Team`. Preserve historical/internal role codes when renaming them would break authorization.

If no eligible banner exists, render a polished empty/neutral state without inventing a campaign. The banner’s mandatory placement is an approved exception to the closest visual reference when that reference has no banner.

## Dashboard rules

The Dashboard must use the approved hierarchy and avoid duplication.

Header:

- Hamburger menu
- Compact SHIELD symbol
- Cash Wallet label and amount
- Reward Points label and count
- Notification bell and unread badge

Do not restore a second written SHIELD wordmark if it creates crowding.

Dashboard content:

- Operations carousel first
- Membership/Privilege summary
- Customer name, member status and membership number
- Digital-card access
- Subscription/plan and validity
- Monthly entitlement and carry-forward when supported
- Physical-card request or tracking state when supported
- Quick actions: Book Service, Upload Prescription, Wellness Shop and Activity
- Useful summary items such as Visits, Documents, Active Orders and unread Updates
- Relevant upcoming visit, recent transaction/order/document or activity content

Do not repeat Cash Wallet and Reward Points in lower Dashboard cards once they are visible in the header. Use the space for customer-relevant information.

## Complete implementation requirement

Implement and finish every module and screen in `03_CUSTOMER_SCREEN_COMPLETION_MATRIX.md`. The matrix is a minimum completion inventory, not permission to remove currently existing pages. If the repository contains additional customer pages, add them to the matrix and complete them as well.

Not every entry must become a separate top-level route. A bottom sheet, dialog, nested route or inline state may be correct when that matches existing architecture and mobile UX. However, every customer task and state must be deliberately implemented, reachable and testable.

## Domain requirements

### Authentication and onboarding

Complete splash/bootstrap, onboarding, phone login, OTP verification, resend/error states, existing-customer lookup, customer conversion, registration, contact/address capture, consent, review, completion, pending/suspended/archived states and session recovery.

Onboarding content must not promise unapproved financial or reward conversion rules. Public content should come from configuration/API where supported.

### Membership, subscription and privilege card

Complete membership overview, digital card, QR card, plan details, contribution, SHIELD Benefit, total entitlement, monthly entitlement, carry-forward, usage, benefits, physical-card request, request tracking, history, block/lost/damaged/replacement flows and renewal where the backend supports them.

All monetary values and lifecycle statuses must come from backend configuration and persisted state. Do not hardcode plan values merely because examples show ₹10,000, ₹1,000 and ₹11,000. These may be used only when the active configured plan returns them.

A physical-card action must not display a fake success when no backend contract exists. Verify the contract first, implement the smallest safe contract when the rule is clear, or show an honest unavailable state and document the gap.

### Cash Wallet

Complete the wallet dashboard, transaction history, filters, transaction details, add-funds flow, payment method/review/processing/result, statements, downloads, refunds, reversals, pending/locked amounts, rules and all data states.

No bank withdrawal or customer-to-customer transfer may be added unless current approved business rules support it. No negative balance. Financial mutations must be auditable and idempotent.

### Reward Points

Complete live balance, ledger history, transaction detail, pending/earned/redeemed/expiring views, earning rules and redemption only when the backend contract and management rule are verified.

Do not invent a points-to-currency rate. Do not promise immediate referral rewards. Preserve delayed qualification, reversal and reward lifecycle.

### Services and providers

Extract and complete the customer Services experience without losing existing behavior. Cover service categories, search, provider listing, provider detail, doctors, labs, pharmacy, dental, home care, dietitian, cosmetics/wellness and future supported services.

Every list and detail view must use real provider/profile APIs. Do not create branded fake providers. Show truthful empty/error/unavailable states when no provider data exists.

### Booking and visits

Complete service/provider selection, patient selection, visit type, date/time slots, notes, backend pricing/coverage, review, confirmation, result, My Visits, filters, details, reschedule, cancellation and online-consultation information.

Do not calculate authoritative pricing or SHIELD coverage independently in Flutter. Use centralized backend pricing/eligibility. Prevent duplicate appointment creation from retries or double taps.

### Documents and prescriptions

Complete document categories, lists, details, secure viewer, uploads, share/download where authorized, lab reports, medical records, vaccination records, prescription list/upload/view/status and pharmacy linkage where supported.

Use the existing secure file pipeline. Never expose raw object-storage URLs. Enforce customer ownership and access logs. OCR/extraction is optional/deferred unless the repository currently supports it; do not make upload success depend on invented OCR.

### Wellness Shop and orders

Complete the database-backed catalogue, search, categories, filters, sort, product detail, image gallery, wishlist, cart, coupon, delivery addresses, checkout, payment method, review, order creation, result, order list/detail/tracking, cancellation, return/refund and reorder where supported.

Never hardcode product rows in Flutter. Product data must come from the existing product API and database imports/seeds. Preserve the non-production disclosure until management classifies the catalogue as live inventory.

Do not claim unsupported medical benefits for wellness products.

### Referrals

Complete referral code/QR/share, history, details, statuses, qualification explanation, rewards and rules using privacy-safe customer APIs.

Customers may see only their own direct/referral subtree information allowed by the backend. Do not expose internal national/regional/state/district/assembly/LSGD/ward commission structures to ordinary customers.

### Notifications and activity

Extract and complete Notifications and Activity Timeline with live authenticated data, read/unread state, filters, details, mark-all-read, preferences and empty/error states.

Do not create shared static notifications for real customer accounts.

### Profile, family and contacts

Complete Profile, Edit Profile, personal details, alternative contact, addresses, profile photo, family/dependent records, emergency contacts, preferred pharmacy and linked-account/account information where supported.

Alternative contact remains separate from login identity. Family members must not silently become independent customer accounts unless the backend workflow explicitly creates them.

### Settings, privacy, security and support

Complete Settings, notification preferences, language/appearance where supported, biometric preferences, security, verified primary-mobile change, active sessions, privacy, legal documents, consent, data use, download/delete requests, Help, FAQ, support tickets, feedback, About, app version and logout confirmation.

Legal content must be versioned/configured where current architecture supports it. Account deletion must explain retention obligations and create an auditable request rather than immediately erasing regulated records from the client.

## Navigation contract

Mobile bottom navigation remains:

1. Home
2. Wallet
3. Services
4. Visits
5. Profile

The authenticated drawer must expose secondary destinations grouped consistently:

MAIN
- Home
- Membership & Privilege Card
- Cash Wallet
- Reward Points

HEALTHCARE
- Services
- My Visits
- Medical Documents
- Prescriptions

COMMERCE
- Wellness Shop
- My Orders

ENGAGEMENT
- Referral & Rewards
- Activity Timeline
- Notifications

ACCOUNT
- Profile & Family
- Preferred Pharmacy
- Help & Support
- Privacy & Security
- Settings
- Logout

Every item must navigate to a valid route, highlight correctly and preserve the current session. Do not leave dead links or blank placeholders.

## State-completeness contract

Every data-bearing page must deliberately implement applicable states:

- Initial loading
- Skeleton loading
- Refreshing
- Populated
- Valid zero
- Empty
- Partial data
- Cached/stale data where supported
- Recoverable API error
- Retry
- Offline/no internet
- Permission denied
- Session expired
- Feature unavailable
- Maintenance/service unavailable
- Form validation
- Mutation in progress
- Mutation success
- Mutation failure
- Upload progress/failure
- Payment pending/success/failure
- No search results

Do not hide errors by showing empty collections or zero balances.

## Responsive contract

Test at minimum:

- 350 px
- 375 px
- 390 px
- 412 px
- 448 px
- 480 px
- Tablet portrait and landscape
- Desktop/web

Mobile uses the approved compact application shape and five-item bottom navigation. Tablet may use an adaptive rail/drawer. Web must remain a centered, width-constrained customer app rather than stretching into a dense desktop admin dashboard.

Requirements:

- SafeArea correctness
- No `RenderFlex` overflow
- No clipped balances
- No tiny illegible text
- Minimum touch targets approximately 44–48 logical pixels
- Text scaling support
- Keyboard-safe forms
- Sticky actions that do not cover content
- Correct focus order and semantics
- Sufficient color contrast
- Icons accompanied by labels where meaning is not obvious

## Architecture contract

- Preserve Clean Architecture and current feature boundaries.
- Widgets receive typed models and callbacks; they do not fetch directly.
- Use existing Riverpod providers and repositories.
- Extend shared API models rather than parsing arbitrary maps in screens.
- Preserve GoRouter guards and route names where possible.
- Add missing routes deliberately and document them.
- Centralize currency, points, date/time, lifecycle-label and error formatting.
- Do not create a second customer shell.
- Extract large inline portal views incrementally, preserving behavior and tests.
- Avoid one mega-widget with unrelated flags.
- Avoid duplicate components with slightly different styling.

## Backend-contract rule

Before implementing a mutation or authoritative value, verify:

- Controller route and HTTP method
- DTO and validation
- Authentication guard
- Customer-scope enforcement
- Service behavior
- Transaction and idempotency behavior
- Persisted models
- Audit event
- Notification side effect
- Error/status mapping
- Existing tests

When a required, clearly documented feature lacks a contract, add the smallest compatible backend implementation with tests and non-destructive migration only when needed. Do not use `prisma db push`. Do not perform destructive migrations or production data changes.

## Customer-data security

Never expose another customer’s:

- Profile or contacts
- Membership/card/subscription
- Wallet or transactions
- Reward Points or referral records
- Visits or appointments
- Documents or prescriptions
- Orders or addresses
- Notifications/activity
- Family/dependent records

UI visibility is not authorization. Backend checks must remain authoritative. Add negative scope tests for data-bearing endpoints and repositories.

Do not log OTPs, tokens, medical content, raw file URLs, payment secrets or unnecessary PII.

## Demo-data rules

Allowed:

- Isolated, idempotent non-production seeds
- Explicitly marked demo products and Operations banners
- Deterministic test accounts
- Synthetic local image assets with documented license/provenance

Not allowed:

- Shared hardcoded customer data in Flutter
- Static wallet/reward balances
- Fake appointments/documents/orders shown as persisted records
- Mock repositories replacing working APIs
- Production-looking demo data without disclosure
- Silent fallback to local fake records after authenticated API failure

## Visual implementation loop

For every page or major state:

1. Open the closest approved image from `E:\K4NN4N\shield\Design reference`.
2. Identify the reference’s page padding, header height, typography, card geometry, colors, icon treatment, shadows, button size and bottom-navigation pattern.
3. Reconcile the real route and functional requirements.
4. Implement with reusable Flutter widgets.
5. Run through the real application route using deterministic non-production data.
6. Capture a screenshot at a matching mobile viewport.
7. Compare side by side.
8. Produce an overlay or pixel-difference image when tooling permits.
9. Record mismatches.
10. Correct them.
11. Repeat until materially equivalent.
12. Record route, screenshot paths, tests and residual differences in visual-QA documentation.

For pages with no exact image, derive them from the same approved tokens/components. Do not invent a new visual theme.

## Testing contract

Run and maintain:

- `dart format`
- Targeted `flutter analyze`
- Full `flutter analyze` at phase gates
- Widget tests
- Navigation tests
- Responsive-width tests
- Provider/repository tests
- Accessibility/semantics tests where practical
- Backend TypeScript compile when contracts change
- Backend unit/integration tests when server code changes
- Prisma validation when schema/migrations change
- `git diff --check`

Tests must cover positive, empty, loading, error and negative-authorization behavior appropriate to each domain.

Compilation alone is not completion.

## Documentation contract

Maintain or create:

- `docs/customer-ui/CUSTOMER_UI_AUDIT.md`
- `docs/CUSTOMER_UI_IMPLEMENTATION_STATUS.md`
- `docs/customer-ui/CUSTOMER_UI_ROUTE_INVENTORY.md`
- `docs/customer-ui/CUSTOMER_UI_API_BINDINGS.md`
- `docs/customer-ui/CUSTOMER_UI_COMPONENT_GUIDE.md`
- `docs/customer-ui/CUSTOMER_UI_STATE_MATRIX.md`
- `docs/customer-ui/CUSTOMER_UI_VISUAL_QA.md`
- `docs/customer-ui/CUSTOMER_UI_ACCESSIBILITY_CHECKLIST.md`
- `docs/customer-ui/CUSTOMER_UI_OPEN_BACKEND_GAPS.md`
- Append-only `log.md`

Track separately for every screen:

- Route exists
- Functional behavior complete
- API/database binding complete
- Visual redesign complete
- Loading/empty/error complete
- Responsive complete
- Tests complete
- Screenshot QA complete

Do not mark a route complete because it merely renders.

## Work sequencing

Use the phases in `08_EXECUTION_PHASES_AND_REPORTING.md`. Finish coherent vertical slices. Do not make an uncontrolled application-wide rewrite.

At the start of each phase:

- Inspect Git status and concurrent changes.
- Confirm the current branch.
- Re-run relevant baseline tests.
- Update the matrix.

At the end of each phase:

- Format, analyze and test.
- Capture screenshots.
- Update documentation and `log.md`.
- Create a coherent checkpoint commit when repository policy permits.
- Report concrete results and the exact next screen/file.

## Completion behavior

Do not repeatedly return status-only messages. If a work turn is active, make concrete changes. If blocked, investigate repository code, schema, tests and documentation, implement truthful unavailable states when appropriate, and report the precise blocker.

Continue until every completion gate in `10_FINAL_DEFINITION_OF_DONE.md` is satisfied.
