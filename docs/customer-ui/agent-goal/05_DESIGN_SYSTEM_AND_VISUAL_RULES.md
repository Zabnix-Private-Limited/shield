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
