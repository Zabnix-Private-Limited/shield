# READ THIS FIRST — NON-NEGOTIABLE HANDOFF

You are continuing the existing SHIELD Customer App redesign inside an active production-oriented repository.

Do not start a new Flutter application. Do not create a parallel prototype. Do not replace the active customer portal with screenshots, static mockups or a disconnected demonstration shell.

## Paths

- Repository: `E:\K4NN4N\shield`
- Approved visual references: `E:\K4NN4N\shield\Design reference`
- Customer portal family: `/portal/customer/:section`

## Absolute source-of-truth order

1. The current repository, current schema and current API implementation are authoritative for exact technical names and persisted behavior.
2. `AGENTS.md`, `current_schema.md`, current product documentation and append-only `log.md` define product and engineering constraints.
3. The ten images in `E:\K4NN4N\shield\Design reference` are authoritative for visual language, layout character, spacing, typography, card styling, header behavior and mobile hierarchy.
4. This goal package defines the required completion surface and quality gates.
5. Old generated ZIPs, design boards, contact sheets and synthetic multi-screen posters are not design authorities.

## Visual-reference rule

The reference images define a design system, not the limit of the application. All existing and required customer pages must be retained and redesigned in the same language even when no exact reference image exists.

The single approved layout exception is the Operations-managed marketing/offer carousel. It is mandatory on Home immediately below the global customer header and before the membership card, even when the closest reference image does not show it.

## Functional rule

Never invent workflows that contradict the repository. Use current APIs, repositories, Riverpod providers, GoRouter routes, Firebase customer authentication, NestJS services, Prisma models and database-backed records.

When a documented customer capability lacks a verified backend contract:

1. Search the repository and documentation thoroughly.
2. Confirm the gap in a contract matrix.
3. Add the smallest compatible backend contract only when the business rule is clear and safe.
4. Otherwise implement a truthful unavailable/coming-after-approval state and document the blocker.
5. Never fake a successful financial, membership, card, order, referral, document or appointment mutation.

## Active-work rule

Do not spend work turns returning only statements such as “the goal remains active,” “no new changes were made,” or “I need another work turn.” Every active turn must inspect, modify, verify and report concrete repository work.
