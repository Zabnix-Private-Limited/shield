# Web, Tablet & APK/Mobile Specification

## One product, adaptive presentation

Do not maintain separate business logic for Web and APK.

Share:
- repositories
- controllers/state management
- models
- validation
- permission logic
- route intent
- business statuses

Adapt only presentation and navigation.

## Desktop Web

Optimized for:
- keyboard/mouse
- high-volume queue processing
- split-pane Orders
- tables
- hover/focus
- deep links
- browser refresh

Required:
- pointer hover
- keyboard focus
- responsive down to tablet widths
- no CORS failures for private media
- no asset 404s

## Tablet

Optimized for:
- touch
- landscape workflows
- order queue + detail
- reduced column density
- sticky actions

Tablet should not simply render the mobile app enlarged.

## Android APK / Mobile

Optimized for:
- 360–430 logical px common widths
- touch
- bottom navigation
- stacked screens
- bottom sheets
- sticky actions
- system back behavior
- file picker/camera integration where applicable
- push notifications
- deep links where supported

## Navigation parity

Every canonical Pharmacy page must have a mobile path/state:
- Dashboard
- Orders
- Payments
- Payment Details
- History
- Profile
- Settings

If not all fit bottom navigation, use More.

## Orders parity

Desktop table/split pane becomes:
- order list
- order detail
- item cards
- substitute sheet
- invoice picker
- confirmation sheet
- sticky action bar

No business capability may be desktop-only without explicit product approval.

## Interaction parity matrix

| Capability | Web | Tablet | APK |
|---|---|---|---|
| KPI drill-down | click | tap | tap |
| order detail | split/route | split/route | route |
| partial approve | row controls | adaptive | item card |
| substitute | panel/dialog | sheet/dialog | bottom sheet |
| invoice upload | drag/drop + picker | picker | picker/camera |
| payment proof zoom | dialog | dialog | full-screen |
| Profile edit | forms | forms | stacked forms |
| Settings | grid/cards | cards | stacked sections |

## Performance

- Avoid sequential page-load waterfalls.
- Load independent dashboard sections in parallel.
- Cache appropriate reference data.
- Show skeletons immediately.
- Avoid rebuilding the entire page when one card changes.
- Keep lists virtual/lazy where dataset can grow.

## Offline / degraded network

Do not fake successful mutations offline.
Provide:
- retry
- last-known read cache where safe
- clear "could not update" state
