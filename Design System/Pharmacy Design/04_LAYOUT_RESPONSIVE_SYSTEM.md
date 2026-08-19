# Layout & Responsive System

## 1. Breakpoints

Canonical behavior:

```text
compact/mobile   0–599
tablet           600–1023
desktop          1024–1439
wide desktop     1440+
```

Breakpoints describe behavior, not device brand.

## 2. Desktop shell

- Sidebar: 248px fixed/collapsible
- Top bar: ~72px
- Main canvas: `#F7F9FC` or white-dominant
- Content padding: 24–32px
- Max content width: 1440px where appropriate
- Dense operational table/split-pane allowed
- Persistent left navigation

## 3. Tablet

Preferred Orders layout:
- Navigation rail or collapsible sidebar
- Two-pane order list + detail where width permits
- Reduce metadata columns
- Keep key actions sticky
- Replace wide tables with adaptive item cards or condensed table
- Do not shrink desktop table until unreadable

## 4. Mobile / APK

- Mobile top bar: ~56px
- Bottom navigation for highest-frequency destinations
- Suggested bottom destinations:
  - Dashboard
  - Orders
  - Payments
  - More
- "More" contains Payment Details, History, Profile, Settings if needed
- Detail screens become stacked routes
- Sticky bottom action bar for high-frequency fulfillment actions
- Dialogs become full-screen dialog/bottom sheet when necessary
- Filter controls use sheets
- Avoid horizontal scrolling for primary workflows

## 5. Desktop grids

Dashboard:
- Order KPI: 4 columns
- Financial KPI: 3 columns
- Recent Orders + Recent Payments: 2 columns
- Collapse intelligently below desktop width

Settings:
- Up to 3-column card grid on wide desktop
- 2 columns tablet/normal desktop
- 1 column mobile

Profile:
- 3 functional columns on wide desktop only
- 2 columns desktop/tablet
- 1 column mobile

## 6. Orders workspace

Wide desktop:
```text
[ queue 320–380px ] [ order detail flex ]
```

Tablet:
```text
[ queue ~300 ] [ detail flex ]
```
or route-to-detail depending on width.

Mobile:
```text
Orders list route
   -> Order detail route
      -> substitution / invoice / confirmation sheets
```

## 7. Vertical constraints

Critical Flutter rule:

A Pharmacy page embedded in `PortalShell` / `CustomScrollView` / `SliverToBoxAdapter` must not create an incompatible nested full-height layout.

Avoid unsafe combinations:
- nested Scaffold when not needed
- Expanded under unbounded vertical constraints
- Flexible inside intrinsic/sliver contexts
- arbitrary fixed screen-height assumptions

Prefer:
```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: ...
)
```

Use scroll ownership intentionally.

## 8. Density

Desktop:
- Information-dense but readable
- 56–72px order rows/cards
- Tables acceptable

Mobile:
- 72–100px cards
- Fewer simultaneous data points
- Prioritize status, customer, amount, fulfillment, next action

## 9. Click/touch behavior

Desktop:
- entire row/card clickable
- pointer cursor
- hover background/border
- keyboard focus

Mobile:
- entire card tap target
- 44px minimum controls
- avoid tiny chevrons as the only tap target

## 10. APK/web parity

A workflow is not complete until it has a valid interaction model at both compact and desktop widths. Pixel identity is not required; behavioral parity is.
