# Flutter Frontend Implementation Guide

## 1. Architecture objective

Implement the design as a reusable Pharmacy component layer rather than screen-specific styling.

Suggested structure:

```text
frontend/lib/features/provider/pharmacy/
├── design/
│   ├── pharmacy_colors.dart
│   ├── pharmacy_spacing.dart
│   ├── pharmacy_typography.dart
│   ├── pharmacy_radius.dart
│   ├── pharmacy_breakpoints.dart
│   └── pharmacy_theme_extensions.dart
├── presentation/
│   ├── components/
│   ├── screens/
│   └── responsive/
├── domain/
└── data/
```

Adapt to the current repo rather than forcing this exact tree if an equivalent design-system location already exists.

## 2. Reuse first

Before adding a component:
1. inspect existing shared component
2. determine if it matches the Pharmacy system
3. extend safely if shared behavior is correct
4. create Pharmacy-specific wrapper if altering global shared styling would regress other portals

## 3. Recommended primitives

- PharmacyPage
- PharmacyPageHeader
- PharmacySectionHeader
- PharmacyCard
- PharmacyMetricCard
- PharmacyStatusChip
- PharmacyEntityRow
- PharmacyPrimaryButton
- PharmacySecondaryButton
- PharmacyDangerButton
- PharmacyTextField
- PharmacyDropdown
- PharmacyToggleRow
- PharmacyEmptyState
- PharmacyErrorState
- PharmacySkeleton
- PharmacyStickyActionBar
- PharmacyResponsiveBuilder

## 4. Responsive approach

Avoid device-name branching.

Prefer width/layout constraints:
```dart
if (width < 600) compact
else if (width < 1024) tablet
else desktop
```

Use:
- LayoutBuilder
- MediaQuery
- responsive widget composition

## 5. Navigation

Canonical Pharmacy role:
`SHIELDRole.pharmacyStaff`

Canonical route family:
`/portal/pharmacy-staff/...`

Do not infer Pharmacy from section names.

## 6. Interactive cards

Implement semantic tap/click wrappers:
- InkWell / appropriate Material interaction
- mouse cursor on web
- focus node
- keyboard activation
- tooltip for icon-only action

The chevron is an affordance, not the only click target.

## 7. Loading

Controllers expose:
- loading
- refreshing
- data
- error

Avoid nested Scaffolds inside PortalShell unless architecturally required.

## 8. Forms

- local editing state
- server field errors
- unsaved-change guard where needed
- no silent destructive changes

## 9. File/image handling

Web:
- authenticated URL/proxy
- no direct private R2 CORS dependency unless configured intentionally

Mobile:
- picker/camera where allowed
- upload progress
- same backend storage contract

## 10. APK requirement

Before Pharmacy is release-ready, every Pharmacy page must be usable on Android:
- no overflow
- correct keyboard behavior
- safe areas
- system back
- file picker
- push routing
- no web-only assumptions

## 11. Testing ownership

This design package defines acceptance behavior. Automated tests may be used when the owner requests them. If the owner is manually testing, agents should implement and stop for owner UAT rather than fabricate runtime proof.
