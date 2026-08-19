# SHIELD Pharmacy Design System — Read First

**Status:** Canonical Pharmacy UI/UX design system  
**Scope:** SHIELD Pharmacy Staff portal, Pharmacy-facing shared components, and the Pharmacy experience on Web, Tablet, Android APK, and other Flutter targets.  
**Design reference date:** 2026-08-19

## 1. Purpose

This package is the implementation contract for the SHIELD Pharmacy interface. It converts the approved reference images in `references/` into a consistent, buildable design system.

The references are not one-off mockups. They represent **one design language** that must remain consistent across:

- Dashboard
- Orders
- Order detail / fulfillment
- Payments
- Payment review
- Payment Details / Bank / UPI / QR
- Order History
- Profile
- Settings
- Desktop Web
- Tablet
- Android APK / mobile
- Responsive Flutter Web

Do not redesign individual screens independently. New Pharmacy screens must look and behave as if they belong to the same product.

## 2. Source-of-truth hierarchy

When implementation decisions conflict, use this priority:

1. Correct Pharmacy business rules and security.
2. The design rules in this package.
3. The canonical reference images in `references/`.
4. Existing reusable SHIELD components that already match this system.
5. Existing legacy Pharmacy UI only where it does not conflict with the new system.

If a reference image depicts a capability that does not exist in the current backend, **do not fake it**. Implement the UI only when the real backend contract exists, or document the required backend/SQL work.

## 3. Canonical visual character

The Pharmacy product should feel:

- Professional and healthcare-oriented
- Clean, calm, low-noise
- Operational rather than decorative
- Fast to scan during pharmacy work
- Highly interactive without looking busy
- Consistent across desktop, tablet, and mobile
- White/light-first with restrained mint/teal accents
- Dark navy for hierarchy and high-confidence actions
- Semantic colors only when they communicate state
- Card-based, but not "everything inside a giant card"
- Dense enough for operational work on desktop
- Spacious enough to remain comfortable on mobile

## 4. Hard UI rules

- Every dashboard KPI card that represents a drill-down must be clickable.
- Every order/payment/history row that represents an entity must be clickable.
- `View All Orders` must navigate to Orders.
- `View All Payments` must navigate to Payments.
- Status cards should support direct filtered navigation where useful.
- Use obvious hover, focus, press, selected, disabled, loading, empty, and error states.
- No full-page spinner for normal page loading. Prefer skeleton/shimmer.
- No raw Dio/HTTP/stack errors in user-visible UI.
- No inaccessible icon-only controls without tooltip/semantic label.
- No desktop-only interaction that becomes impossible in APK/mobile.
- No mobile layout that is merely a shrunken desktop layout.

## 5. Business capabilities represented by this design system

The Orders experience is intended to support:

- Full approval
- Full rejection
- Per-item approval/rejection
- Partial item approval based on available stock
- Partial order fulfillment
- Partial dispatch
- Alternate brand / substitute item selection
- Customer confirmation where needed
- Chronic-order marking
- Notes / pharmacist remarks
- Rejection reason capture
- Editable price where business policy allows
- Bill / invoice upload
- Invoice sending
- Order status progression
- Delivery / pharmacy collection
- Push notifications for relevant user-facing state changes

The design system documents these workflows, but implementation must always use real backend state.

## 6. Cross-platform rule

The Pharmacy portal is one product across Web and APK, not two separate products.

Shared:
- Design tokens
- Status semantics
- Models
- Backend contracts
- Navigation intent
- Business actions
- Notification semantics

Adaptive:
- Navigation shell
- Information density
- Table vs card layout
- Sticky actions
- Dialog vs bottom sheet
- Sidebar vs bottom navigation
- Split-pane vs stacked detail screens

## 7. Repository placement

Recommended repo layout:

```text
Design System/
└── Pharmacy Design/
    ├── 00_READ_FIRST.md
    ├── ...
    ├── 18_AGENT_IMPLEMENTATION_INSTRUCTIONS.md
    └── references/
        ├── 01_pharmacy_orders_desktop_advanced.png
        ├── 02_responsive_web_tablet_mobile.png
        └── ...
```

Agents should read this directory before modifying any Pharmacy UI.

## 8. Change control

Do not casually change:
- Primary colors
- Typography
- Core spacing scale
- Navigation structure
- Card radii
- Status semantics
- Button hierarchy
- Mobile navigation model
- Core order workflow vocabulary

A deliberate redesign should update this package first so every Pharmacy screen stays coherent.
