# Customer Account Security API Matrix

| Capability | UI route | API | DB / Prisma | Ownership / safe projection | Classification |
|---|---|---|---|---|---|
| Active sessions | Settings security sheet | `GET /auth/sessions` | `auth_sessions`, `auth_devices` / `AuthSession`, `AuthDevice` | Owner type/ID derive from JWT; returns device label/platform/browser and timestamps only | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Revoke one other session | same | `POST /auth/sessions/:sessionId/revoke` | `auth_sessions.revoked_at` | Service verifies owner before revocation; current session indicator is returned | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Revoke all other sessions | same | `POST /auth/sessions/revoke-others` | same | Excludes the JWT session ID and revokes only the authenticated owner’s sessions | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Current session sign-out | Settings | `POST /auth/logout` | same | Intentionally ends the session; not used in automated QA | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Password/change phone/delete/export | none | none | No verified customer-safe contract | Do not fabricate security or retention operations | DEFERRED — BACKEND CONTRACT REQUIRED |

Raw refresh tokens, JWTs, Firebase tokens, token hashes, IP/user-agent values and internal session identifiers are not exposed to customer Flutter UI.
