# SHIELD Repository Context — 2026-08-11

## Executive assessment

SHIELD is a viable modular healthcare-platform foundation, currently suitable for controlled internal QA of supported slices but not yet production-complete. The architecture is converging on the right model: backend-owned workspace semantics, shared portal renderers, persistent dual-track auth, and ledger-based financial domains. The major remaining work is hardening and proof rather than feature expansion.

## Repository map

- **Flutter client:** `frontend/` — Android, web, and PWA; 307 Dart files under `lib/` and 43 widget/unit test files.
- **NestJS backend:** `backend/` — 128 TypeScript source files and 22 spec files, structured as a modular monolith.
- **Database contract:** `current_schema.md` is authoritative. It contains 65 tables: 64 domain tables represented by 64 Prisma models, plus Prisma's `_prisma_migrations` metadata table.
- **Prescription intelligence:** `backend/prescription_ai_service/` is a separate Python service for OCR/prescription workflows.
- **Documentation:** `docs/` holds product, architecture, route, feature-audit, QA, and release handoff material. `log.md` is append-only delivery history.

## Runtime and identity model

- Flutter starts in `frontend/lib/main.dart`; `app_router.dart` owns session-aware route gating.
- Customer and internal users keep separate persisted sessions. Customer auth is Firebase phone OTP; internal auth is Firebase Google sign-in, followed by SHIELD access/refresh tokens.
- `PortalResolver` and GoRouter prevent customer/internal route-family crossover. The shared `PortalShell` renders customer, agent, provider, and most internal sections.
- The Nest app starts from `backend/src/main.ts`; `AppModule` composes 24 domain/platform modules, including auth, customer, wallet, pricing, referrals, documents, provider platform, operations queue, and admin governance.

## Architecture strengths

- The relational model covers membership, cards, sessions/devices, ledger activity, pricing/benefits, referrals, care records, documents, commerce history, notifications, and audit data.
- Wallet rules are correctly ledger-oriented: balances are derived; CASH, REWARD_POINTS, and hidden SHIELD_BENEFIT must remain distinct.
- Admin workspaces and provider platform metadata are moving business semantics to backend contracts, the preferred direction for all portal families.
- Recent customer work consistently uses principal-scoped, safe projections rather than allowing the UI to choose customer identity.
- Agent Customer 360 has a well-documented read-only scoped implementation with backend `AgentScopeService` enforcement and deterministic responsive/test evidence.

## Current implementation and verification status

### Customer portal

The supported customer surfaces (membership, card, wallet/rewards, services, booking/visits, documents/prescriptions, catalogue, orders, referrals/activity, notifications, profile, and session management) are documented as ready for internal QA. Their supported APIs use customer-owned or self-scoped projections. Commerce remains catalogue/history only: no cart, checkout, payment, fulfilment, refund, or tracking contract exists.

### Agent Customer 360

`/portal/agent/customers/:customerId` is implemented as an assigned-customer workspace with overview, membership, wallet/rewards, documents, visits, prescriptions/pharmacy requests, orders, family, referrals, notifications, activity, and audit/status tabs. Focused backend scope suites (11 checks) and responsive widgets (8 desktop/narrow widths) passed. Authenticated browser/RBAC UAT remains a required external gate; see `docs/agent/CUSTOMER_360_AUTHENTICATED_UAT.md`.

### Production evidence

Do not treat successful targeted tests or static analysis as production evidence. Historical full Flutter analysis/test and browser runs were blocked by local Windows runner/browser instability. Current evidence is slice-specific; authenticated browser RBAC, stable full suites, runtime/API environment checks, and release verification remain separate gates.

## Highest-priority risks and recommended order

1. **Security middleware:** `backend/src/main.ts` currently enables CORS and shutdown hooks but no visible global `ValidationPipe`, rate limiting, or security-header middleware. Add and verify these before broadening unauthenticated or high-value mutation exposure.
2. **Test depth and CI:** Execute stable full Nest and Flutter suites in CI. Add deep negative RBAC/ABAC tests, ledger/pricing/referral invariant tests, document upload/approval security tests, and appointment lifecycle tests.
3. **Workflow standardization:** Every critical mutation should consistently validate, authorize scope, mutate, audit before/after/reason, notify affected actors, and refresh the affected workspace.
4. **Large owners:** Decompose `frontend/lib/features/portal/presentation/screens/portal_shell.dart` (~391 KB), `backend/src/admin-governance/admin-governance.service.ts` (~196 KB), and other large service/screen owners into narrower composition/command units. Preserve existing contracts during extraction.
5. **Portal normalization:** Continue moving provider and agent semantics into backend-owned module metadata, following the admin runtime rather than creating provider-type-specific frontend forks.
6. **Operational hardening:** Establish schema-drift checks, monitoring/alerts, log redaction review, rate-limit verification, and production incident/runbook evidence. Improve PWA offline mutation/recovery behavior only after core trust boundaries are proven.

## Documentation conflicts to resolve

- `backend/README.md` and `frontend/README.md` still recommend manual `vercel deploy --prod`. This conflicts with `AGENTS.md`: SHIELD production deployment must use the Git-push workflow unless explicitly overridden.
- `project-rules.md` says internal users authenticate with email/password; `AGENTS.md` identifies Firebase Google sign-in as the current internal authentication path. Treat `AGENTS.md` and live auth code as governing until this document is corrected.
- The archived July audits provide useful structural risk analysis but predate the August customer and Agent Customer 360 work. Prefer feature-specific release/audit handoffs and `log.md` for current implementation status.

## Safe read order for future work

1. `AGENTS.md`, then `current_schema.md`.
2. Relevant PRD/FRD/API/route documentation and `DESIGN.md`.
3. Existing feature audit/release documents and the tail of `log.md`.
4. Backend module/controller/service and matching Flutter feature/repository/controller.
5. Additive migration plans only when a schema change is approved; never make schema application part of ordinary build/deploy work.

## Guardrails

- Do not apply Prisma schema commands, seed, reset, or direct database writes without explicit authorization.
- Do not fabricate availability, distance, ratings, preferred pharmacy, wallet balances, financial outcomes, or customer data where the schema/contract does not support them.
- Keep SHIELD_BENEFIT out of customer-visible remaining balances.
- Use the Git-push deployment workflow for SHIELD production releases; do not use production Vercel CLI deployment from this machine without explicit direction.
