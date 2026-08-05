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
