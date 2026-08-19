# States, Accessibility & Performance

## UI states every screen must define

- initial/loading
- populated
- empty
- error
- retrying
- refreshing
- partial/degraded
- disabled action
- mutation in progress
- success
- permission denied where applicable

## Loading

Use skeletons.
Do not replace the whole portal with a spinner.

## Error

User-facing:
- concise
- actionable
- retry when meaningful

Developer detail:
- logs/Sentry/debug console

Never render raw networking library exceptions.

## Empty

Good:
> No pending payments right now.

Bad:
> []

## Accessibility

Targets:
- WCAG 2.1 AA intent
- readable contrast
- keyboard access on web
- screen-reader semantics
- 44×44 minimum mobile target
- status not communicated by color alone
- focus ring visible
- meaningful labels for icons
- forms have labels, errors, hints

## Status chips

Include text + color.

## Tables

- header semantics
- keyboard reachable row actions
- horizontal adaptation
- never make font microscopic to fit

## Motion

Respect reduced-motion preference where available.
Keep transitions short.

## Performance budgets / intent

- first useful Pharmacy shell quickly visible
- skeleton within first render
- avoid duplicate role/API preloads
- no Agent API calls from Pharmacy
- cancel stale searches
- debounce search ~250–350ms
- paginate lists
- image thumbnails appropriately sized
- do not fetch full-resolution proof/QR until needed when avoidable

## Console quality gate

For a release candidate, Pharmacy runtime should have:
- 0 relevant asset 404s
- 0 RenderFlex overflow
- 0 uncaught Flutter errors
- 0 incorrect-role 403 API calls
- 0 private-media CORS errors
