# Pharmacy Design Acceptance Criteria / Owner UAT

This is a design and behavior gate, not a substitute for business-logic testing.

## Global

- [ ] One coherent Pharmacy visual language across every page
- [ ] No random colors/radii/font sizes
- [ ] Sidebar routes are correct
- [ ] Mobile navigation reaches every Pharmacy page
- [ ] Every interactive card visibly behaves as interactive
- [ ] Hover/focus/press work
- [ ] 44px mobile touch targets
- [ ] No RenderFlex overflow
- [ ] No raw networking exceptions
- [ ] No broken assets
- [ ] No private-media CORS failures
- [ ] No wrong-role API calls
- [ ] Skeleton loading instead of full-page spinner

## Dashboard

- [ ] KPI cards clickable
- [ ] KPI drill-down filters correct
- [ ] View All Orders works
- [ ] View All Payments works
- [ ] recent rows open real details
- [ ] cards align and have consistent spacing
- [ ] responsive mobile/tablet layout

## Orders

- [ ] list searchable
- [ ] filter states visible
- [ ] selected order obvious
- [ ] full approve
- [ ] partial approve
- [ ] reject item
- [ ] substitute item
- [ ] low-stock UI
- [ ] out-of-stock UI
- [ ] chronic toggle
- [ ] notes/remarks
- [ ] rejection reason
- [ ] price/billing where allowed
- [ ] invoice upload
- [ ] send invoice
- [ ] partial dispatch where allowed
- [ ] customer confirmation state
- [ ] actions remain usable on mobile

## Payments

- [ ] pending list
- [ ] proof view
- [ ] approve
- [ ] reject + reason
- [ ] terminal status disables mutation
- [ ] mobile review screen usable

## Payment Details

- [ ] bank card
- [ ] UPI card
- [ ] QR visible
- [ ] edit
- [ ] active/primary
- [ ] QR works in web and APK

## History

- [ ] populated list
- [ ] status filters
- [ ] date filters
- [ ] search
- [ ] detail
- [ ] desktop/mobile parity

## Profile

- [ ] user details
- [ ] Pharmacy details
- [ ] edit UX
- [ ] branch context where supported
- [ ] security links
- [ ] mobile layout

## Settings

- [ ] real persisted settings only
- [ ] Save/Cancel/Reset behavior
- [ ] workflow preferences
- [ ] notification preferences
- [ ] delivery/payment preferences
- [ ] responsive layout

## Final visual gate

Compare implementation side-by-side with the `references/` folder.

Differences are acceptable when caused by:
- real data
- accessibility
- responsive adaptation
- business rule correctness

Differences are not acceptable when caused by:
- arbitrary styling
- inconsistent components
- developer convenience
- placeholder/basic UI left unfinished
