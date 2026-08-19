# Dashboard Specification

## Goal

Provide a high-speed operational snapshot with immediate drill-down into work.

## Required structure

### Header
- Pharmacy Operations Dashboard
- Optional concise subtitle
- Pharmacy Staff identity
- notifications
- user menu

### Action-required banner
Only show when there is a real actionable issue, such as missing payment details.

### Order Operations Overview
Cards:
- New Orders
- Preparing
- Ready for Pickup
- Out for Delivery

### Financial & Verification Summary
Cards:
- Pending Payments
- Approved Today
- Completed Today

### Recent Orders
- up to 5 recent relevant orders
- entire row clickable
- View All Orders works
- consistent status chips
- customer, amount, time

### Recent Manual Payment Requests
- up to 5 relevant requests
- entire row clickable
- View All Payments works
- customer, amount, channel, time, status

## Interactions

- Clicking KPI filters the target page.
- Clicking recent order opens order detail.
- Clicking recent payment opens payment review.
- Keyboard Enter/Space triggers focused interactive cards.

## Data truth

- No hard-coded KPI values.
- "Today" uses the Pharmacy business timezone.
- Completed Today is based on status transition timestamp, not purchase creation time.
- Approved Today uses approval timestamp.
- Recent entities must respect provider scope.

## Empty states

If no orders:
- "No active orders right now."
- CTA only if meaningful.

If no payment requests:
- "No manual payment requests."

Do not leave large blank white containers.

## Loading

Render layout-matching skeleton cards immediately.

## Responsive

Desktop:
- 4 order metrics
- 3 finance metrics
- two-column recent sections

Tablet:
- 2x2 order metrics
- finance wrap
- recent sections stacked if needed

Mobile:
- horizontally scrollable metric group or 2-column cards
- recent lists stacked
- cards fully tappable
