# Customer Portal Performance UAT

## Purpose

Record comparable, privacy-safe evidence for the Customer portal performance
release. A successful build, static analysis, or a locally cached screen is not
evidence that a deployed customer experience meets these targets.

## Preconditions

- Test a signed release APK/AAB that contains the performance changes.
- Use an authenticated, provisioned customer with representative visits,
  documents, notifications, wallet entries, and membership state.
- Record device model, Android version, network type, backend revision, and
  frontend/app version. Do not record phone numbers, names, access tokens,
  OTPs, or API payloads.
- Run every applicable test once after clearing app data (cold) and once after
  returning to the app without clearing data (warm cache).

## Targets and recording sheet

| Flow | Cold target | Warm/perceived target | Record |
| --- | ---: | ---: | --- |
| App launch to branded shell | <= 0.5 s | <= 0.5 s | first frame timestamp |
| Launch to authenticated dashboard | <= 3 s | <= 1.5 s | shell, cache visible, fresh-data timestamps |
| Customer dashboard refresh | <= 3 s | n/a | HTTP request and render timestamps |
| Services directory | <= 2 s | <= 1 s on re-entry | category/page request timestamps |
| Provider detail | <= 2 s | <= 1 s on re-entry | request timestamp |
| Services -> booking -> back | <= 2 s | <= 1 s on return | whether directory state remains visible |
| Visits | <= 2 s | <= 1.5 s | first-page request timestamp |
| Wallet | <= 2 s | <= 1.5 s | first-page request timestamp |
| Documents | <= 2 s | <= 1.5 s | first-page request timestamp |
| Notifications | <= 2 s | <= 1.5 s | first-page request timestamp |
| Agent customer list | <= 2 s | <= 1.5 s | first-page request timestamp |
| Agent Customer 360 initial view | <= 2 s | <= 1.5 s | summary request timestamp |

## Dashboard-specific acceptance checks

1. The branded splash/shell appears before stored-session validation finishes.
2. Firebase Messaging permission, FCM token registration, and analytics do not
   block the first frame or dashboard route.
3. A warm dashboard shows only the cache belonging to the signed-in customer.
4. The dashboard refreshes in the background and replaces cache with fresh
   data without a whole-page blank spinner.
5. The header unread badge is supplied by the dashboard summary; opening the
   dashboard does not require a second notification-center request.
6. Dashboard payloads contain summary counts, not full document/notification
   lists for counters. Recent appointments and wallet activity stay bounded.

## Required timing evidence

For every slow flow, capture timings in this order:

1. Client request start and response received time.
2. HTTP status, endpoint path, and response size only; never log payloads.
3. Backend request timing, including `PERF customer.dashboard durationMs=...`
   for the dashboard endpoint.
4. Database query plan and duration only after a deployed timing points to a
   database bottleneck.
5. Flutter render/rebuild timing only after network and backend time are known.

Use this row format for each run:

```text
UTC/IST timestamp | app/backend revision | device/network | flow | cold/warm |
shell ms | cache-visible ms | response ms | fresh-render ms | endpoint/status |
backend PERF ms | result/pass-fail | non-sensitive notes
```

## Index-release verification

After the approved database release applies
`20260815_customer_performance_indexes`, verify that the authoritative schema
contains all five indexes below before treating them as active:

- `idx_appointments_customer_date`
- `idx_appointments_customer_status`
- `idx_documents_customer_created`
- `idx_notifications_customer_status`
- `idx_notifications_customer_sent`

For production-scale data, compare `EXPLAIN (ANALYZE, BUFFERS)` results for the
appointment, document, and notification customer filters against their actual
`WHERE` and `ORDER BY` patterns. Do not run write operations as part of this
verification.

## Release gate

- **Source/build gate:** passed only when Flutter analysis, backend compilation,
  and release builds succeed.
- **Database gate:** pending until the approved migration is applied and the
  schema snapshot is refreshed.
- **Device/deployment gate:** pending until all critical flows above have a
  recorded result and any missed target has a measured cause and owner.
