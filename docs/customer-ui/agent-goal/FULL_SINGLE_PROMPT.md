# SHIELD CUSTOMER UI COMPLETION — FULL SINGLE PROMPT

# READ THIS FIRST — NON-NEGOTIABLE HANDOFF

You are continuing the existing SHIELD Customer App redesign inside an active production-oriented repository.

Do not start a new Flutter application. Do not create a parallel prototype. Do not replace the active customer portal with screenshots, static mockups or a disconnected demonstration shell.

## Paths

- Repository: `E:\K4NN4N\shield`
- Approved visual references: `E:\K4NN4N\shield\Design reference`
- Customer portal family: `/portal/customer/:section`

## Absolute source-of-truth order

1. The current repository, current schema and current API implementation are authoritative for exact technical names and persisted behavior.
2. `AGENTS.md`, `current_schema.md`, current product documentation and append-only `log.md` define product and engineering constraints.
3. The ten images in `E:\K4NN4N\shield\Design reference` are authoritative for visual language, layout character, spacing, typography, card styling, header behavior and mobile hierarchy.
4. This goal package defines the required completion surface and quality gates.
5. Old generated ZIPs, design boards, contact sheets and synthetic multi-screen posters are not design authorities.

## Visual-reference rule

The reference images define a design system, not the limit of the application. All existing and required customer pages must be retained and redesigned in the same language even when no exact reference image exists.

The single approved layout exception is the Operations-managed marketing/offer carousel. It is mandatory on Home immediately below the global customer header and before the membership card, even when the closest reference image does not show it.

## Functional rule

Never invent workflows that contradict the repository. Use current APIs, repositories, Riverpod providers, GoRouter routes, Firebase customer authentication, NestJS services, Prisma models and database-backed records.

When a documented customer capability lacks a verified backend contract:

1. Search the repository and documentation thoroughly.
2. Confirm the gap in a contract matrix.
3. Add the smallest compatible backend contract only when the business rule is clear and safe.
4. Otherwise implement a truthful unavailable/coming-after-approval state and document the blocker.
5. Never fake a successful financial, membership, card, order, referral, document or appointment mutation.

## Active-work rule

Do not spend work turns returning only statements such as “the goal remains active,” “no new changes were made,” or “I need another work turn.” Every active turn must inspect, modify, verify and report concrete repository work.


---

# CURRENT STATE HANDOFF

This section is a starting summary, not a substitute for inspecting Git history and the current working tree. Repository inspection overrides any stale statement below.

## Known architecture

- Flutter customer frontend
- Riverpod state management
- GoRouter navigation
- Dio/API repositories
- Hive/local caching where already used
- Firebase phone authentication for customers
- NestJS backend
- Prisma/PostgreSQL persistence
- Cloudflare R2 document storage
- Firebase Cloud Messaging notifications
- RBAC, scope enforcement and audit logging
- Active customer portal rendered through `/portal/customer/:section`

## Known shared customer foundation

The repository has or recently introduced equivalents of:

- `CustomerScaffold`
- `CustomerAppBar`
- `CustomerBottomNavigation`
- `CustomerDesignTokens`
- Shared loading, empty and error widgets
- Dashboard repository and cache
- Wallet repository
- Membership repository

Use the actual names in the repository. Extend existing components rather than creating duplicate shells.

## Known completed or partially completed work

The following work was reported as implemented and should be preserved unless a verified defect is found:

- Compact customer header
- Duplicate written SHIELD wordmark removed, leaving the compact SHIELD mark
- Header Cash Wallet amount and Reward Points count visible at supported mobile widths
- Notification badge
- Dashboard hierarchy corrected
- Operations carousel positioned first after the header
- Operations banner content database-backed through the existing commercial/settings mechanism
- Three non-production demo banners seeded without overwriting existing Operations configuration
- Duplicate lower Dashboard Wallet and Reward cards removed
- Visits, Documents and Updates/Activity summaries retained
- Dashboard empty states for no appointments and no recent ledger activity
- Dedicated Reward Points route using authenticated wallet data and the `REWARD_POINTS` ledger
- Wellness catalogue disclosure: `Demo products only — not live Sahakar inventory.`
- Profile and Settings routes exist, though their visual redesign and extraction may remain incomplete

Known recent commits reported in the previous work stream include:

- `80adc32 customer-header-wordmark-fix`
- `0314152 operations-banner-demo-seed`
- `a4d2c16 customer-dashboard-empty-states`
- `b7085ac label-wellness-demo-catalogue`
- `e48ce13 customer-dashboard-hierarchy-fix`
- `6e34eef record-operations-banner-seed`

Verify these commits locally. Do not assume every prior change is on the current branch.

## Known audit summary

Recent audit information indicated:

- Authentication screens exist but visual alignment and auth-state QA remain.
- Dashboard is API-backed and has the shared header, membership-first structure and Operations carousel; screenshot QA remains.
- Membership exists, but card lifecycle, QR, request/status/history and complete subscription-entitlement pages may be missing.
- Wallet exists, but add-funds, statement and transaction-detail routes may be incomplete.
- Reward Points live balance and activity exist; redemption and expiry need verified backend rules/contracts.
- Services, appointments, profile, notifications and settings have historically been embedded inside a large portal shell and require careful extraction without losing behavior.
- Documents and prescriptions are customer-scoped, but upload/view/share/pharmacy linkage and visual QA may remain incomplete.
- Wellness product APIs and purchase models exist, while customer cart/checkout/order route completeness must be verified.
- Referral, activity, full card lifecycle and family/dependent customer APIs may have gaps.

## Concurrent-work protection

Backend membership activation and product-data import work may occur separately. The UI agent must:

- Inspect `git status` before every phase.
- Preserve unrelated backend changes.
- Never reset, revert, stash or overwrite user-owned or concurrent-agent work without explicit authorization.
- Consume final API contracts instead of hardcoding temporary values.
- Never modify `E:\K4NN4N\shield\Design reference`.


---

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


---

# ROUTE, DATA, API AND SECURITY GUIDE

## Route strategy

The customer interface currently uses `/portal/customer/:section`. Preserve existing route names and guards wherever possible.

Before adding any route:

1. Search all GoRouter declarations and portal metadata.
2. Check whether an inline view, nested route or route alias already exists.
3. Preserve inbound/deep links.
4. Preserve auth redirects and session restoration.
5. Add a route only when it creates a clear, testable customer task.
6. Document redirects from obsolete paths.

Suggested route patterns in the screen matrix are targets, not permission to duplicate existing routes.

## Data-binding worksheet required for every screen

Record:

- Screen
- Route
- User action
- Controller endpoint
- HTTP method
- Request DTO
- Response DTO
- Frontend model
- Repository method
- Riverpod provider/notifier
- Persisted models/tables
- Authorization rule
- Audit requirement
- Cache behavior
- Error/status mapping
- Empty-state meaning

## API use

- Reuse existing API clients.
- Use typed response models.
- Do not parse loosely typed maps throughout widgets.
- Preserve cancellation, timeout, retry and token-refresh behavior.
- Do not retry non-idempotent mutations automatically without an idempotency key or safe server handling.
- Map backend lifecycle enums to centralized UI labels.
- Do not create client-only authoritative financial calculations.

## Authentication and scope

Every customer endpoint and query must derive the current customer from the verified principal/session or validate requested IDs against that principal.

Reject cross-customer access even when a user guesses a UUID or route parameter.

Required negative tests include, where applicable:

- Customer A cannot fetch Customer B wallet
- Customer A cannot fetch Customer B membership/card
- Customer A cannot fetch Customer B documents/prescriptions
- Customer A cannot fetch Customer B appointments
- Customer A cannot fetch Customer B orders/addresses
- Customer A cannot fetch Customer B referral tree
- Customer A cannot mutate Customer B profile/family data

## Financial safety

- Use integer minor units for money where the backend does so.
- Use ledger-derived balances.
- Keep `CASH`, `REWARD_POINTS` and `SHIELD_BENEFIT` separate.
- Never allow negative balance through client calculation.
- Every financial mutation must be transactional, idempotent and audited.
- UI must display backend status for pending, succeeded, failed, reversed and refunded events.
- No bank withdrawal or wallet transfer unless explicitly approved and implemented.

## Membership/card safety

- Membership state must be backend-derived.
- UI does not activate customers by changing local state.
- Digital/physical card lifecycle maps to verified backend enums.
- QR payloads must be signed/opaque where supported; never encode sensitive customer details directly.
- Card request, block and replacement actions require audit events.

## Documents

- Use authorized/signed access.
- Do not expose R2/object-storage origin URLs.
- Validate MIME type, size and ownership.
- Show upload progress and recoverable failure.
- Preserve original file and metadata.
- Access and sharing events should be auditable where required.

## Commerce

- Product catalogue remains database/API-driven.
- Price, availability, inventory, discount, tax and totals come from backend-authoritative data.
- Cart/order mutations must be idempotent.
- Do not trust client totals.
- Preserve demo/live product classification.

## Cache behavior

Where caching already exists:

- Distinguish fresh, stale and unavailable data.
- Never show another customer’s cached data after account switch.
- Clear customer-scoped caches on logout/session change.
- Preserve a visible stale-data indicator when appropriate.


---

# DESIGN SYSTEM AND VISUAL RULES

## Approved source

Use only the images in `E:\K4NN4N\shield\Design reference` as visual references. They include the approved visual language for Dashboard, Wallet, Reward Points, Services, Booking, Documents, Privilege Card, Shop, Product/Cart and Profile.

Do not use previous AI contact sheets, posters, multi-phone boards or generated ZIP images as visual authority.

## Design character

- Modern healthcare membership application
- White or near-white page canvas
- Deep navy headings and primary text
- Cobalt/royal blue primary actions and selected navigation
- Teal Cash Wallet and positive financial/health states
- Amber/gold Reward Points
- Purple for documents, prescriptions and secondary domain emphasis
- Orange only for selected commerce/warning accents
- Red only for destructive/error/urgent states
- Large rounded cards
- Thin cool-gray borders
- Restrained shadows
- Generous mobile spacing
- Clear hierarchy and large touch targets
- Minimal clutter

Avoid:

- Glassmorphism
- Neon colors
- Unrelated gradients
- Dense admin-dashboard tables on mobile
- Tiny text
- Excessive elevation
- Financial-super-app advertisements
- Mixed icon families
- Full-screen screenshots as backgrounds

## Operations carousel placement exception

Even when the closest Dashboard reference lacks a banner, the Operations carousel is mandatory immediately below the global header and above the membership card. This is an approved product exception and must not be logged as a visual defect.

## Header

Main authenticated pages:

- Hamburger
- Compact SHIELD symbol
- Cash Wallet chip with label and amount
- Reward Points chip with label and count
- Notification bell with unread badge

Do not restore a duplicated written SHIELD wordmark that crowds the header.

Detail pages:

- Back action
- Concise title
- Contextual trailing action only when needed

## Bottom navigation

- Home
- Wallet
- Services
- Visits
- Profile

Use consistent icon size, selected treatment, label style, top border/elevation and SafeArea padding.

## Token system

Consolidate tokens in the existing theme/design-token layer.

### Color roles

- `customerNavy`
- `customerBlue`
- `customerBluePressed`
- `walletTeal`
- `successTeal`
- `rewardAmber`
- `documentPurple`
- `commerceOrange`
- `errorRed`
- `pageBackground`
- `cardBackground`
- `borderSubtle`
- `textPrimary`
- `textSecondary`
- `textDisabled`
- `skeletonBase`
- `skeletonHighlight`

Use actual repository naming conventions.

### Spacing

Use an 8-point-oriented rhythm with supported increments such as 4, 8, 12, 16, 20, 24, 32 and 40 logical pixels.

### Radius

Define small-control, standard-card, large-card, pill and circle radii. Do not scatter arbitrary radii per screen.

### Typography

Define styles for:

- Page title
- Section heading
- Card title
- Body
- Secondary body
- Caption
- Button
- Large amount
- Medium amount
- Status label
- Navigation label

### Elevation

Use:

- Flat bordered card
- Standard card
- Floating balance chip/header control
- Bottom navigation
- Dialog/bottom sheet

## Layout rules

- Consistent horizontal page padding
- Clear vertical grouping
- Avoid unexplained dead space
- Avoid fixed heights for variable text
- Use constrained widths on web
- Use single-column mobile layouts
- Use two columns on tablet only when comprehension improves
- Do not turn the customer web app into an admin dashboard

## Content rules

- Use concise, human labels
- Use “Cash Wallet,” not ambiguous “Balance”
- Use “Reward Points,” not coins/stars unless icon-only decoration
- Use “Operations Team,” not visible “Marketing Team”
- Use Indian currency formatting for display
- Do not show unsupported claims or invented statuses
- Use backend state labels through centralized mapping


---

# REUSABLE COMPONENT ARCHITECTURE

Reuse current components where compatible. Rename only when a deliberate refactor improves clarity without breaking imports.

## Shell and navigation

- `CustomerAppShell`
- `CustomerScaffold`
- `CustomerMainHeader`
- `CustomerSubpageHeader`
- `CustomerDrawer`
- `CustomerBottomNavigation`
- `ResponsiveCustomerFrame`
- `SafeAreaBody`
- `CustomerPageBody`

## Global header components

- `WalletBalanceChip`
- `RewardPointsChip`
- `NotificationBell`
- `HeaderValueSkeleton`
- `HeaderValueErrorState`

## Home and membership

- `OperationsCarousel`
- `OperationsBannerCard`
- `MembershipSummaryCard`
- `DigitalMembershipCard`
- `QrCardPanel`
- `EntitlementSummary`
- `BenefitUsageRow`
- `CardStatusTimeline`
- `PlanSummaryCard`

## Generic surfaces

- `ShieldCard`
- `InformationCard`
- `StatusCard`
- `SectionHeader`
- `StatusPill`
- `SummaryTile`
- `QuickActionTile`
- `KeyValueRow`
- `TimelineItem`
- `ProgressSummary`

## Inputs and filtering

- `ShieldTextField`
- `PhoneField`
- `OtpField`
- `SearchField`
- `FilterChip`
- `ChoiceChipGroup`
- `DatePickerField`
- `TimeSlotSelector`
- `AddressSelector`
- `ConsentCheckbox`
- `FileUploadField`
- `QuantitySelector`

## Actions

- `PrimaryButton`
- `SecondaryButton`
- `TertiaryTextAction`
- `DestructiveButton`
- `IconActionButton`
- `StickyBottomActionBar`
- `LoadingButton`

## Domain list rows/cards

- `WalletTransactionRow`
- `RewardTransactionRow`
- `ServiceCategoryCard`
- `ProviderCard`
- `DoctorCard`
- `AppointmentCard`
- `VisitCard`
- `DocumentRow`
- `PrescriptionRow`
- `ProductCard`
- `CartItemRow`
- `OrderCard`
- `OrderStatusTimeline`
- `ReferralCard`
- `NotificationRow`
- `ActivityTimelineItem`
- `ProfileMenuRow`
- `SettingsRow`
- `FamilyMemberCard`
- `AddressCard`
- `SupportTicketCard`

## Feedback and state

- `LoadingSkeleton`
- `EmptyState`
- `ErrorState`
- `OfflineState`
- `PermissionDeniedState`
- `SessionExpiredState`
- `FeatureUnavailableState`
- `InlineMessage`
- `Toast/Snackbar adapter`
- `ConfirmationDialog`
- `ConfirmationBottomSheet`

## Component rules

1. Components receive typed models and callbacks; they do not fetch directly.
2. Financial components never infer unavailable values as zero.
3. Every interactive component supports disabled and loading states.
4. Semantics labels and focus order are required.
5. Avoid component duplication across feature folders.
6. Avoid one giant component with unrelated flags.
7. Centralize formatting and state-label mappings.
8. Add focused widget tests for shared components.


---

# CUSTOMER SCREEN COMPLETION MATRIX

This is the minimum completion inventory. Reconcile it against the repository before implementation. Existing route names are authoritative; suggested route/surface values must not create duplicates. A row may be implemented as a page, nested route, dialog, bottom sheet or deliberate state when that best matches the current architecture.

Completion requires all of: route audited, functional, visual, states, responsive, tests and screenshot QA.

## Authentication

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 001 | Splash / Bootstrap | `/splash` | Secure startup, config and session restoration | local config + auth/session |
| 002 | Onboarding — Connected Care | `/onboarding/connected-care` | Explain unified care ecosystem | public app content/config |
| 003 | Onboarding — Membership | `/onboarding/membership` | Explain membership and privilege card | public plan summary |
| 004 | Onboarding — Rewards | `/onboarding/rewards` | Explain rewards without unapproved conversion promises | public reward rules |
| 005 | Welcome / Entry Choice | `/welcome` | Choose login or registration | local navigation |
| 006 | Customer Phone Login | `/customer/login` | Start Firebase phone authentication | Firebase + customer auth repository |
| 007 | OTP Verification | `/customer/otp` | Verify OTP and establish session | Firebase + auth exchange |
| 008 | OTP Resend / Timeout | `same auth surface` | Handle resend countdown and retry | Firebase auth |
| 009 | OTP Error / Rate Limit | `same auth surface` | Explain invalid/expired/rate-limited OTP | Firebase/auth errors |
| 010 | Existing Customer Lookup | `/register/lookup` | Prevent duplicate customer registration | customer lookup API |
| 011 | Existing Customer Found | `/register/existing` | Review and convert/link legacy customer | customer conversion API |
| 012 | Registration — Personal Details | `/register/personal` | Capture customer profile | customer create/update |
| 013 | Registration — Contact and Address | `/register/contact` | Capture alternative contact and address | customer contacts + addresses |
| 014 | Registration — Consent | `/register/consent` | Capture versioned consent | consent/legal API |
| 015 | Registration — Review | `/register/review` | Review before submit | registration draft |
| 016 | Registration Complete | `/register/complete` | Confirm account/membership result | registration response |
| 017 | Membership Pending | `auth/portal gate` | Truthful pending state | membership status |
| 018 | Account Suspended / Archived | `auth/portal gate` | Blocked-account explanation and support action | customer status |
| 019 | Session Expired | `global auth state` | Reauthenticate safely | session/auth |
## Home

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 020 | Customer Dashboard | `/portal/customer/dashboard` | Primary customer home | dashboard aggregate |
| 021 | Operations Banner Details | `/portal/customer/banner/:id` | View eligible campaign/offer details | published banner detail |
| 022 | Offers and Benefits List | `/portal/customer/offers` | Browse eligible customer offers | Operations content API |
| 023 | Global Search Entry | `/portal/customer/search` | Search supported customer content | search APIs where supported |
## Membership & Card

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 024 | Membership Dashboard | `/portal/customer/membership` | Membership and plan overview | membership aggregate |
| 025 | Privilege Card | `/portal/customer/card` | Card and subscription summary | membership/card/subscription |
| 026 | Digital Card | `/portal/customer/card/digital` | Full digital card | membership card API |
| 027 | QR Card | `/portal/customer/card/qr` | Scannable signed identity token | card token API |
| 028 | Membership Benefits | `/portal/customer/membership/benefits` | Eligible benefits and limits | plan benefits API |
| 029 | Subscription Details | `/portal/customer/membership/subscription` | Plan contribution and validity | subscription API |
| 030 | Entitlement Details | `/portal/customer/membership/entitlement` | Total/monthly entitlement | entitlement API |
| 031 | Carry Forward Details | `/portal/customer/membership/carry-forward` | Carry-forward breakdown | entitlement ledger/config |
| 032 | Benefit Usage History | `/portal/customer/membership/usage` | Applied benefit events | benefit application API |
| 033 | Request Physical Card | `/portal/customer/card/request` | Submit supported card request | card request API |
| 034 | Card Request Review | `same request flow` | Review request/address | card request draft |
| 035 | Card Request Confirmation | `same request flow` | Confirm submission | card request response |
| 036 | Card Request Tracking | `/portal/customer/card/tracking` | Track lifecycle | card request/events |
| 037 | Card History | `/portal/customer/card/history` | Issue/activation/replacement events | card events API |
| 038 | Report Lost Card | `/portal/customer/card/lost` | Block/report lost card | card lifecycle API |
| 039 | Report Damaged Card | `/portal/customer/card/damaged` | Request damaged-card handling | card lifecycle API |
| 040 | Replacement Card | `/portal/customer/card/replacement` | Request replacement | card lifecycle API |
| 041 | Membership Renewal Overview | `/portal/customer/membership/renew` | Renewal eligibility and plan | renewal API/config |
| 042 | Membership Renewal Review | `same renewal flow` | Review renewal values | renewal quote |
| 043 | Membership Renewal Payment | `same renewal flow` | Complete approved payment | payment/renewal API |
| 044 | Membership Renewal Success | `same renewal flow` | Confirm renewal | renewal result |
| 045 | Membership Renewal Failure | `same renewal flow` | Recover from payment/renewal failure | renewal error |
| 046 | Expired Membership | `membership state` | Explain expiry and supported actions | membership status |
| 047 | Suspended Membership | `membership state` | Explain suspension and support | membership status |
## Cash Wallet

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 048 | Cash Wallet Dashboard | `/portal/customer/wallet` | Show CASH balance and actions | customer wallet API |
| 049 | Wallet Transaction History | `/portal/customer/wallet/transactions` | Ledger history | wallet ledger API |
| 050 | Wallet Transaction Filters | `same history surface` | Filter credits/debits/refunds/status | wallet ledger API |
| 051 | Wallet Transaction Detail | `/portal/customer/wallet/transactions/:id` | Explain one ledger entry | wallet transaction API |
| 052 | Add Funds — Amount | `/portal/customer/wallet/add-funds` | Enter supported amount | payment/top-up config |
| 053 | Add Funds — Payment Method | `same add-funds flow` | Choose approved method | payment methods API |
| 054 | Add Funds — Review | `same add-funds flow` | Review authoritative amount/fees | top-up quote |
| 055 | Add Funds — Processing | `same add-funds flow` | Prevent duplicate submit | payment transaction |
| 056 | Add Funds — Success | `same add-funds flow` | Confirm credit after backend success | payment/wallet result |
| 057 | Add Funds — Failure | `same add-funds flow` | Recover safely | payment error |
| 058 | Wallet Statement | `/portal/customer/wallet/statements` | Statement periods/download | statement API |
| 059 | Statement Filters | `same statement surface` | Select range/type | statement API |
| 060 | Statement Download/Share | `same statement surface` | Authorized export | report API |
| 061 | Refund Detail | `/portal/customer/wallet/refunds/:id` | Explain refund status | wallet transaction/refund |
| 062 | Reversal Detail | `/portal/customer/wallet/reversals/:id` | Explain reversal | wallet transaction |
| 063 | Pending/Locked Balance | `/portal/customer/wallet/locked` | Explain unavailable amount | wallet holds API |
| 064 | Wallet Rules | `/portal/customer/wallet/rules` | Explain supported usage | wallet config/content |
## Reward Points

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 065 | Reward Points Dashboard | `/portal/customer/rewards` | Available points and summary | REWARD_POINTS ledger |
| 066 | Reward History | `/portal/customer/rewards/history` | Reward ledger events | reward ledger API |
| 067 | Reward Transaction Detail | `/portal/customer/rewards/history/:id` | Explain one points event | reward transaction API |
| 068 | Pending Points | `/portal/customer/rewards/pending` | Pending qualification events | reward/referral API |
| 069 | Earned Points | `/portal/customer/rewards/earned` | Qualified credits | reward ledger API |
| 070 | Redeemed Points | `/portal/customer/rewards/redeemed` | Redemption history | reward ledger API |
| 071 | Expiring Points | `/portal/customer/rewards/expiring` | Expiry only when supported | reward rule API |
| 072 | How to Earn | `/portal/customer/rewards/earn` | Approved earning rules | reward rules |
| 073 | Reward Rules | `/portal/customer/rewards/rules` | Eligibility and limitations | reward rules |
| 074 | Redemption Catalogue | `/portal/customer/rewards/redeem` | Supported redemption choices | redemption config/API |
| 075 | Redemption Detail | `/portal/customer/rewards/redeem/:id` | Review selected redemption | redemption API |
| 076 | Redemption Review | `same redemption flow` | Confirm points/cost | redemption quote |
| 077 | Redemption Success | `same redemption flow` | Confirm persisted event | redemption result |
| 078 | Redemption Failure | `same redemption flow` | Recover safely | redemption error |
## Services & Providers

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 079 | Services Landing | `/portal/customer/services` | Browse service families | service catalogue API |
| 080 | Service Search | `/portal/customer/services/search` | Search services/providers | service/provider search |
| 081 | Service Search Results | `same search flow` | Display categorized results | search API |
| 082 | Service Categories | `/portal/customer/services/categories` | Browse categories | master data/API |
| 083 | Service Category Detail | `/portal/customer/services/categories/:id` | Category services/providers | service API |
| 084 | Service Filters and Sort | `same listing surface` | Filter location/type/availability | provider API |
| 085 | Provider Listing | `/portal/customer/providers` | List eligible providers | provider API |
| 086 | Provider Detail | `/portal/customer/providers/:id` | Provider branch/services/contact | provider profile API |
| 087 | Doctor Listing | `/portal/customer/doctors` | List doctors | provider/practitioner API |
| 088 | Doctor Profile | `/portal/customer/doctors/:id` | Doctor details and availability | practitioner API |
| 089 | Lab Listing | `/portal/customer/labs` | List labs | provider API |
| 090 | Lab Detail | `/portal/customer/labs/:id` | Lab services and availability | provider/service API |
| 091 | Pharmacy Listing | `/portal/customer/pharmacies` | List pharmacies | provider API |
| 092 | Pharmacy Detail | `/portal/customer/pharmacies/:id` | Pharmacy services and preferred action | provider API |
| 093 | Dental Providers | `/portal/customer/dental` | Dental discovery | provider API |
| 094 | Home Care | `/portal/customer/home-care` | Home-care services | service/provider API |
| 095 | Dietitian | `/portal/customer/dietitian` | Dietitian services | service/provider API |
| 096 | Cosmetic/Wellness Services | `/portal/customer/wellness-services` | Supported wellness services | service/provider API |
| 097 | Nearby Services | `/portal/customer/services/nearby` | Location-aware list where supported | provider/location API |
| 098 | Favourite Providers | `/portal/customer/providers/favourites` | Saved providers where supported | favourites API |
## Booking & Visits

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 099 | Book Visit Start | `/portal/customer/book` | Start booking | service/provider APIs |
| 100 | Select Service | `same booking flow` | Choose service | service API |
| 101 | Select Provider | `same booking flow` | Choose provider/branch | provider API |
| 102 | Select Practitioner | `same booking flow` | Choose doctor/practitioner | practitioner API |
| 103 | Select Patient | `same booking flow` | Choose self/family where supported | customer/family API |
| 104 | Select Visit Type | `same booking flow` | In-person/online/home where supported | service config |
| 105 | Select Date | `same booking flow` | Choose date | availability API |
| 106 | Select Time Slot | `same booking flow` | Choose live slot | slot API |
| 107 | Booking Notes | `same booking flow` | Capture allowed notes | appointment DTO |
| 108 | Pricing and Coverage | `same booking flow` | Display backend quote/benefit | pricing evaluate API |
| 109 | Booking Review | `same booking flow` | Review details | booking draft/quote |
| 110 | Booking Confirmation | `same booking flow` | Confirm mutation | appointment API |
| 111 | Booking Success | `same booking flow` | Show persisted appointment | appointment result |
| 112 | Booking Failure | `same booking flow` | Retry without duplicates | appointment error |
| 113 | My Visits | `/portal/customer/visits` | Upcoming/completed/cancelled | appointment API |
| 114 | Visit Filters | `same visits surface` | Filter status/type/date | appointment API |
| 115 | Visit Detail | `/portal/customer/visits/:id` | Full appointment information | appointment API |
| 116 | Reschedule Visit | `/portal/customer/visits/:id/reschedule` | Select new slot | appointment API |
| 117 | Cancel Visit | `/portal/customer/visits/:id/cancel` | Confirm cancellation | appointment API |
| 118 | Cancellation Result | `same cancel flow` | Show status/refund effect | appointment result |
| 119 | Online Consultation Detail | `/portal/customer/visits/:id/online` | Join/instructions where supported | consultation API |
| 120 | No Available Slots | `booking state` | Truthful no-slot recovery | availability API |
## Documents & Prescriptions

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 121 | Documents Landing | `/portal/customer/documents` | Document overview/categories | documents API |
| 122 | Document Categories | `/portal/customer/documents/categories` | Browse supported types | document metadata |
| 123 | Document List | `/portal/customer/documents/list` | List owned documents | documents API |
| 124 | Document Detail | `/portal/customer/documents/:id` | Metadata/actions | document API |
| 125 | Secure Document Viewer | `/portal/customer/documents/:id/view` | Authorized view | signed access API |
| 126 | Upload Document | `/portal/customer/documents/upload` | Upload with metadata | document upload API |
| 127 | Document Upload Progress | `same upload flow` | Progress/cancel/retry | upload API |
| 128 | Document Share | `/portal/customer/documents/:id/share` | Authorized sharing where supported | document access API |
| 129 | Document Download | `same document surface` | Authorized download | signed access API |
| 130 | Lab Reports | `/portal/customer/documents/lab-reports` | Lab report list | documents/lab API |
| 131 | Lab Result Detail | `/portal/customer/documents/lab-reports/:id` | View result safely | lab report API |
| 132 | Medical Records | `/portal/customer/documents/medical-records` | Medical record grouping | documents API |
| 133 | Vaccination Records | `/portal/customer/documents/vaccinations` | Vaccination records where supported | documents API |
| 134 | Prescriptions List | `/portal/customer/prescriptions` | Owned prescriptions | documents/prescription API |
| 135 | Upload Prescription | `/portal/customer/prescriptions/upload` | Upload prescription | document upload API |
| 136 | Prescription Detail | `/portal/customer/prescriptions/:id` | Metadata/status/actions | prescription API |
| 137 | Prescription Viewer | `/portal/customer/prescriptions/:id/view` | Secure view | signed access API |
| 138 | Prescription Processing | `prescription state` | Show processing without invented OCR | document status |
| 139 | Prescription Verified | `prescription state` | Show verified status | document status |
| 140 | Prescription Rejected | `prescription state` | Explain rejection/reupload | document status |
| 141 | Prescription to Pharmacy | `/portal/customer/prescriptions/:id/pharmacy` | Send/link where supported | pharmacy request API |
## Wellness Shop & Orders

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 142 | Wellness Shop Landing | `/portal/customer/shop` | Catalogue landing | wellness products API |
| 143 | Product Search | `/portal/customer/shop/search` | Search catalogue | product search API |
| 144 | Search Suggestions | `same search surface` | Suggestions/recent searches | search API/local history |
| 145 | Product Categories | `/portal/customer/shop/categories` | Browse categories | product categories API |
| 146 | Product Listing | `/portal/customer/shop/products` | List database products | products API |
| 147 | Product Filters | `same listing surface` | Category/brand/price/availability | products API |
| 148 | Product Sort | `same listing surface` | Sort supported fields | products API |
| 149 | Product Detail | `/portal/customer/shop/products/:id` | Product information/price/stock | product API |
| 150 | Product Image Gallery | `same detail surface` | View product images | product media API |
| 151 | Wishlist | `/portal/customer/shop/wishlist` | Saved products where supported | wishlist API |
| 152 | Cart | `/portal/customer/shop/cart` | Current customer cart | cart API |
| 153 | Cart Item Edit | `same cart surface` | Quantity/remove | cart API |
| 154 | Apply Coupon | `same cart/checkout flow` | Validate approved coupon | promotion API |
| 155 | Address Selection | `/portal/customer/shop/checkout/address` | Choose delivery address | address API |
| 156 | Add Delivery Address | `same checkout flow` | Create address | address API |
| 157 | Edit Delivery Address | `same checkout flow` | Update address | address API |
| 158 | Checkout | `/portal/customer/shop/checkout` | Checkout summary | checkout quote API |
| 159 | Payment Selection | `same checkout flow` | Select supported method | payment config |
| 160 | Wallet Payment Review | `same checkout flow` | Confirm wallet charge | checkout/payment API |
| 161 | Order Review | `same checkout flow` | Server-authoritative totals | checkout quote |
| 162 | Place Order Processing | `same checkout flow` | Idempotent creation | orders API |
| 163 | Order Success | `same checkout flow` | Show persisted order | orders API |
| 164 | Order Failure | `same checkout flow` | Recover safely | orders error |
| 165 | My Orders | `/portal/customer/orders` | List owned orders | orders API |
| 166 | Order Filters | `same orders surface` | Filter statuses/date | orders API |
| 167 | Order Detail | `/portal/customer/orders/:id` | Items/totals/status/address | order API |
| 168 | Order Tracking | `/portal/customer/orders/:id/tracking` | Status timeline | order events API |
| 169 | Cancel Order | `/portal/customer/orders/:id/cancel` | Cancel when eligible | orders API |
| 170 | Return Request | `/portal/customer/orders/:id/return` | Return where supported | return API |
| 171 | Refund Status | `/portal/customer/orders/:id/refund` | Refund lifecycle | refund/payment API |
| 172 | Reorder | `/portal/customer/orders/:id/reorder` | Create cart from prior order | cart/orders API |
## Referrals

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 173 | Referral Dashboard | `/portal/customer/referrals` | Summary and code | referral summary API |
| 174 | Referral Code | `same referral surface` | Display unique code | referral API |
| 175 | Referral QR | `/portal/customer/referrals/qr` | Shareable QR | referral API |
| 176 | Share Referral | `same referral surface` | Native/web share | referral link API |
| 177 | Referral History | `/portal/customer/referrals/history` | Owned referrals | referral API |
| 178 | Referral Detail | `/portal/customer/referrals/:id` | Privacy-safe status | referral API |
| 179 | Pending Referrals | `/portal/customer/referrals/pending` | Awaiting qualification | referral API |
| 180 | Qualified Referrals | `/portal/customer/referrals/qualified` | Qualified status | referral API |
| 181 | Rewarded Referrals | `/portal/customer/referrals/rewarded` | Rewarded status | referral/reward API |
| 182 | Rejected Referrals | `/portal/customer/referrals/rejected` | Rejected status/reason | referral API |
| 183 | Referral Rewards | `/portal/customer/referrals/rewards` | Reward events | reward ledger API |
| 184 | Referral Rules | `/portal/customer/referrals/rules` | Qualification rules | referral config/content |
## Activity & Notifications

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 185 | Activity Timeline | `/portal/customer/activity` | Customer event history | timeline API |
| 186 | Activity Detail | `/portal/customer/activity/:id` | Event detail | timeline API |
| 187 | Activity Filters | `same activity surface` | Filter event types/date | timeline API |
| 188 | Notifications Inbox | `/portal/customer/notifications` | Live inbox | notifications API |
| 189 | Notification Filters | `same notification surface` | Filter type/read state | notifications API |
| 190 | Notification Detail | `/portal/customer/notifications/:id` | Read detail/action | notifications API |
| 191 | Mark All Read | `same notification surface` | Persist read state | notifications API |
| 192 | Notification Preferences | `/portal/customer/settings/notifications` | Channel/type preferences | preference API |
| 193 | Service Notifications | `notification filter/state` | Service events | notifications API |
| 194 | Order Notifications | `notification filter/state` | Order events | notifications API |
| 195 | Reward Notifications | `notification filter/state` | Reward events | notifications API |
| 196 | Membership/Card Notifications | `notification filter/state` | Membership/card events | notifications API |
## Profile & Family

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 197 | Profile | `/portal/customer/profile` | Customer account overview | profile/session API |
| 198 | Edit Profile | `/portal/customer/profile/edit` | Update allowed fields | customer API |
| 199 | Personal Details | `/portal/customer/profile/personal` | View demographic fields | customer API |
| 200 | Alternative Contact | `/portal/customer/profile/contact` | Manage non-login contact | customer contacts API |
| 201 | Profile Photo | `/portal/customer/profile/photo` | Upload/remove photo where supported | profile media API |
| 202 | Address Book | `/portal/customer/profile/addresses` | Owned addresses | address API |
| 203 | Address Detail | `/portal/customer/profile/addresses/:id` | View address | address API |
| 204 | Add Address | `/portal/customer/profile/addresses/add` | Create address | address API |
| 205 | Edit Address | `/portal/customer/profile/addresses/:id/edit` | Update address | address API |
| 206 | Family Members | `/portal/customer/family` | Owned family/dependents | family API |
| 207 | Family Member Detail | `/portal/customer/family/:id` | View dependent | family API |
| 208 | Add Family Member | `/portal/customer/family/add` | Create dependent where supported | family API |
| 209 | Edit Family Member | `/portal/customer/family/:id/edit` | Update dependent | family API |
| 210 | Remove Family Member Confirmation | `same family flow` | Safe removal/unlink | family API |
| 211 | Emergency Contacts | `/portal/customer/profile/emergency-contacts` | Emergency contacts | contacts API |
| 212 | Add Emergency Contact | `same contact flow` | Create emergency contact | contacts API |
| 213 | Edit Emergency Contact | `same contact flow` | Update emergency contact | contacts API |
| 214 | Preferred Pharmacy | `/portal/customer/profile/preferred-pharmacy` | Current preferred provider | customer/provider API |
| 215 | Select Preferred Pharmacy | `same preferred pharmacy flow` | Choose eligible pharmacy | provider API |
| 216 | Linked Accounts | `/portal/customer/profile/linked-accounts` | Linked identities where supported | auth/account API |
| 217 | Account Information | `/portal/customer/profile/account` | Membership/customer identifiers | profile API |
## Settings, Privacy & Support

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 218 | Settings | `/portal/customer/settings` | Settings landing | preferences API/local settings |
| 219 | Appearance | `/portal/customer/settings/appearance` | Theme preference where supported | local preference |
| 220 | Language | `/portal/customer/settings/language` | Language preference where supported | preference/content |
| 221 | Notification Settings | `/portal/customer/settings/notifications` | Channel/type preferences | notifications API |
| 222 | Biometric Settings | `/portal/customer/settings/biometrics` | Local biometric unlock where supported | device secure storage |
| 223 | Security | `/portal/customer/settings/security` | Security overview | session/auth API |
| 224 | Change Primary Mobile | `/portal/customer/settings/security/mobile` | Verified mobile-change workflow | auth/customer API |
| 225 | Verify New Mobile | `same mobile flow` | Firebase verification | Firebase/auth API |
| 226 | Active Sessions | `/portal/customer/settings/security/sessions` | View/revoke sessions | session API |
| 227 | Privacy & Security | `/portal/customer/privacy` | Privacy/security hub | legal/config/session APIs |
| 228 | Privacy Policy | `/portal/customer/privacy/policy` | Versioned policy | legal content API |
| 229 | Terms and Conditions | `/portal/customer/privacy/terms` | Versioned terms | legal content API |
| 230 | Consent Management | `/portal/customer/privacy/consents` | View/manage consents | consent API |
| 231 | Data Usage | `/portal/customer/privacy/data-usage` | Explain data use | legal content |
| 232 | Download My Data | `/portal/customer/privacy/export` | Request export where supported | data export API |
| 233 | Delete Account | `/portal/customer/settings/delete-account` | Auditable deletion request | account deletion API |
| 234 | Delete Account Confirmation | `same delete flow` | Deliberate confirmation | account deletion API |
| 235 | Help & Support | `/portal/customer/support` | Support landing | support content/API |
| 236 | Help Search | `/portal/customer/support/search` | Search help content | support/FAQ API |
| 237 | FAQ | `/portal/customer/support/faq` | FAQ list | support content API |
| 238 | FAQ Detail | `/portal/customer/support/faq/:id` | FAQ article | support content API |
| 239 | Contact Support | `/portal/customer/support/contact` | Support channels | support config |
| 240 | Create Support Ticket | `/portal/customer/support/tickets/new` | Create ticket | support API |
| 241 | Support Ticket Detail | `/portal/customer/support/tickets/:id` | Ticket history/replies | support API |
| 242 | Support History | `/portal/customer/support/tickets` | Owned tickets | support API |
| 243 | Feedback | `/portal/customer/support/feedback` | Submit feedback | feedback API |
| 244 | Rate App | `/portal/customer/support/rate` | Platform rating action | platform deep link/config |
| 245 | About SHIELD | `/portal/customer/about` | Product information | app content/config |
| 246 | App Version | `same about/settings surface` | Display build/version | local package info |
| 247 | Logout Confirmation | `global account action` | Confirm logout and clear scope | auth/session |
## Global States

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 248 | Global Loading Skeleton | `shared state` | Reusable loading treatment | n/a |
| 249 | Global Empty State | `shared state` | Reusable legitimate-empty treatment | n/a |
| 250 | Global Recoverable Error | `shared state` | Retryable error | n/a |
| 251 | Offline / No Internet | `global state` | Explain cached/offline behavior | connectivity/cache |
| 252 | Maintenance | `global state` | Planned maintenance | platform config |
| 253 | Service Unavailable | `global state` | Backend unavailable | API errors |
| 254 | Feature Unavailable | `shared state` | Unsupported/disabled capability | capabilities/config |
| 255 | Permission Denied | `global state` | Authorization failure | API 403 |
| 256 | Session Expired | `global state` | Reauthenticate | API 401/session |
| 257 | Update Required | `global state` | Minimum-version enforcement where supported | app config |
| 258 | Not Found | `global state` | Unknown route/resource | router/API 404 |
| 259 | Account Suspended | `global state` | Restricted customer | customer status |

**Total inventory rows: 259**

The agent must add any customer-facing route discovered in the repository that is not listed here.

---

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


---

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


---

# OPEN OR CONFIGURATION-DEPENDENT BUSINESS RULES

The agent must verify current configuration/documentation before implementing these. Do not hardcode a speculative answer.

## Membership pricing and entitlement

Examples have used ₹10,000 customer contribution, ₹1,000 SHIELD Benefit and ₹11,000 total entitlement. Treat them as configured plan examples, not permanent source-code constants.

Verify:

- Active plan values
- Allocation basis
- Monthly rounding
- Final-month reconciliation
- Carry-forward policy
- Eligible services/products
- Expiry and renewal behavior

## Reward conversion and expiry

Do not invent:

- Points-to-rupee conversion
- Minimum redemption
- Expiry period
- Catalogue values
- Immediate referral credit

Use configured rules and existing reward/referral services.

## Physical-card lifecycle

Verify supported statuses, fees, address rules, replacement policy and operational actions before enabling mutations.

## Payment gateway

Do not fake successful add-funds, subscription or order payments. Use the current approved gateway/sandbox contract or show an unavailable state.

## Family/dependents

Family linking may be a phased capability. Verify models and customer APIs before creating persistent flows. Do not create independent login identities silently.

## Insurance and future services

Do not add an insurance purchase workflow merely because a label appears in an old design board. Implement only supported customer-facing service information and APIs.

## OCR and document intelligence

Original document storage and metadata are primary. OCR/extraction is optional/deferred unless current backend support is verified.

## Legal, retention and deletion

Do not promise immediate permanent deletion when healthcare, audit, financial or legal retention obligations apply. Use an auditable request workflow.

## Product inventory classification

Wellness product imports may be demo, staging or live. Preserve backend classification and the demo disclosure until management explicitly approves live inventory.

## Customer activation

A separate backend process may activate eligible waiting customer memberships. The UI must render actual backend membership states and must not mass-activate users locally.


---

# FINAL DEFINITION OF DONE

The SHIELD Customer App redesign is complete only when all applicable gates below pass.

## Inventory

- Every current customer route is present in the matrix.
- Every required customer task in the matrix is implemented or has an explicitly approved, documented exclusion.
- Additional customer routes discovered in the repository were added to the matrix.
- No old inline/legacy view remains accidentally reachable with inconsistent UI unless explicitly documented during migration.

## Visual consistency

- Every page uses the approved design system.
- Home has the Operations carousel immediately below the header.
- Header shows Cash Wallet amount, Reward Points and notification state without overflow.
- Duplicate lower Dashboard wallet/reward cards remain removed.
- Profile and Settings are fully redesigned, not merely linked.
- No old generated poster/contact-sheet style leaked into the app.
- No screenshots are used as full-page backgrounds.
- Screenshot-QA evidence exists for every major route.

## Functionality

- Every visible button, tab, chip, row and navigation entry works or is truthfully disabled with an explanation.
- Authentication uses the real Firebase/customer session flow.
- Membership/card values are database-backed.
- Wallet and Reward Points use separate ledgers.
- SHIELD Benefit is not rendered as Cash Wallet.
- Services/providers are API-backed.
- Booking/visit mutations work without duplicates.
- Documents/prescriptions use secure authorized storage access.
- Products are database/API-backed.
- Cart/order totals are server-authoritative.
- Referral lifecycle is preserved.
- Notifications and activity use authenticated data.
- Profile/family/settings/support changes persist where supported.

## States

- Loading, populated, valid-zero, empty, error, retry, offline and session-expired behavior are implemented for every applicable page.
- Mutations have progress, success and failure states.
- No API failure is silently displayed as zero/empty.

## Security

- Negative cross-customer tests pass for all sensitive domains.
- No raw storage URLs or secrets are exposed.
- Customer-scoped caches clear on logout/account switch.
- Backend authorization remains authoritative.
- Financial/document/card/order/consent mutations are auditable.

## Responsive and accessibility

- Supported mobile widths have no overflow.
- Tablet and web are usable and visually consistent.
- Text scaling does not break critical layouts.
- Touch targets, focus order, semantics and contrast are acceptable.
- Keyboard and sticky actions do not hide form content.

## Engineering quality

- No parallel customer shell.
- No duplicated near-identical component systems.
- No business logic inside presentation widgets.
- No static customer financial/order/document data.
- No uncontrolled Prisma db push or destructive migration.
- Flutter formatting and analysis pass.
- Relevant Flutter tests pass.
- Backend compile/tests pass for changed contracts.
- Prisma validation passes for schema changes.
- `git diff --check` passes.

## Documentation and delivery

- Audit, route inventory, API bindings, component guide, state matrix, visual QA, accessibility checklist, backend gaps and implementation status are current.
- `log.md` has an append-only final entry.
- Final report lists files, routes, APIs, schema changes, tests, screenshots and approved remaining business decisions.
- The full customer walkthrough succeeds from authentication through Home, membership/card, wallet/rewards, services/booking, documents, shop/order, referrals, notifications, profile and settings.

Do not claim complete until every applicable gate is evidenced.
