# SHIELD Authentication Hardening Checklist

Date: 2026-07-04
Status: Active release checklist

## Purpose

Freeze the now-working SHIELD authentication pipeline behind a repeatable regression checklist so future admin, agent, provider, and routing work does not silently reintroduce login or session failures.

## Scope

- internal Google sign-in
- customer auth session startup behavior
- portal routing and deep-link survival
- session persistence and logout behavior
- known non-blocking web warnings

## Release-Critical Scenarios

### Internal Google sign-in

- super-admin Google login succeeds from `/internal/login`
- provider Google login succeeds from `/internal/login`
- agent Google login succeeds from `/internal/login`
- internal login from a fresh incognito window succeeds
- first-time internal Google login links an existing employee row when `firebase_uid` is still null

### Session persistence

- refresh on `/portal/super-admin/dashboard` keeps the session
- refresh on a deep link such as `/portal/super-admin/customers` keeps the session
- opening a second tab preserves the same internal session
- closing and reopening the browser restores the session when refresh token is still valid
- logout clears session state and returns to the correct login route
- logout in one tab invalidates the active session cleanly in another tab after the next guarded request
- expired internal session redirects to `/session-expired` and then `/internal/login`

### Routing and guards

- direct URL access to every major admin section works when authenticated
- unauthenticated access to `/portal/super-admin/*` redirects to `/internal/login`
- customer sessions cannot open internal routes
- internal sessions cannot open customer portal routes
- invalid admin section keys fall back safely instead of crashing
- browser back/forward navigation does not create redirect loops

### Backend contract checks

- `/auth/internal/login` returns a session for an active provisioned employee
- internal login rejects suspended, inactive, or deleted users
- role resolution returns the expected portal route for `ADMIN`
- profile bootstrap succeeds immediately after backend session creation

## Known Non-Blocking Web Warnings

### Firebase popup COOP warning

Observed warning:

```text
Cross-Origin-Opener-Policy policy would block the window.close/window.closed call.
```

Interpretation:

- seen during Firebase popup cleanup on Chromium-based browsers
- not currently blocking SHIELD internal Google login
- no repo-side COOP header override was found in SHIELD frontend/Vercel config during the hardening pass

Action:

- leave documented unless future hosting/header changes provide a clean elimination path

### Firebase reCAPTCHA warmup warning

Observed warning before cleanup:

```text
recaptchaKey undefined
```

Interpretation:

- came from eager Firebase `initializeRecaptchaConfig()` warmup on web startup
- not required for internal Google popup auth

Action taken:

- removed eager startup warmup from app bootstrap
- if customer phone auth later needs explicit web reCAPTCHA setup, initialize it in the phone-auth-specific flow instead of global startup

## Observability Contract

Keep in production:

- login started
- backend session created
- internal profile loaded
- session saved
- session restored
- token refreshed
- session expired
- logout

Reduce or avoid in production:

- every `PortalResolver.current` access
- every router redirect check
- every successful route guard pass

## Sign-Off Rule

Do not treat authentication as stable for a release unless:

- all release-critical scenarios above pass
- no unexpected redirect loop appears
- no backend `401` or `403` appears for a valid internal login
- portal deep links survive refresh for at least admin and agent routes
