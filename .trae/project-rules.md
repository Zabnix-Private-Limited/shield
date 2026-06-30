# SHIELD Project Rules

## Core Project Principles
1. **Documentation First**: Always refer to the `docs/` directory as the single source of truth.
2. **Feature-First Architecture**: Follow Clean Architecture principles for both frontend (Flutter) and backend (NestJS).
3. **Security First**:
   - Use RBAC + ABAC for authorization
   - Implement audit logging for all critical operations
   - Never expose secrets in code
4. **Ledger-Based Wallet**: Never store wallet balance directly - always calculate from transactions.
   - Segregate balance into Cash sub-ledger (recharged/preloaded funds) and Points sub-ledger (referral loop rewards).
5. **Segregated Authentication**:
   - Customers authenticate using Mobile number OTP.
   - Staff, service providers, and admins sign in using Email and Password credentials.
6. **Agent-Mediated Customer Onboarding**: Customers can only be registered by Sahakar Group agents. Customer creation requires a valid `agent_code`.
7. **Hyperpharmacy Card Restrictions**: Store-purchased cards cannot be utilized at other locations in the case of hyperpharmacies (to retain customers locally), but are cross-compatible across all general service providers regardless of location.
8. **API First Design**: Define API schemas before implementing endpoints.
9. **Database Truth Source**:
   - The repository-root file `current_schema.md` is the source of truth for the current database situation.
   - When schema/docs/code/runtime assumptions disagree, reconcile against `current_schema.md` first.
10. **Real Data Safety**:
   - Do not auto-apply Prisma schema changes during normal build or deploy flows.
   - Treat real database schema changes as explicit infrastructure operations.
   - Do not introduce dummy data in authenticated or production-facing SHIELD flows unless explicitly requested.
11. **Deployment Path**:
   - Production Vercel deployments for this repository happen through Git push.
   - Do not use production Vercel CLI deploy commands from this machine/account unless explicitly directed.
12. **Execution Bias**:
   - Choose the best project-safe fix by default.
   - Ask for confirmation only when the decision is destructive, unclear, or changes real infrastructure/data.
13. **Session Persistence**:
   - Customer and internal-user login should stay signed in by default across app restarts.
   - Prefer short-lived access tokens plus effectively long-lived refresh sessions over forcing frequent sign-ins.
   - End sessions only on intentional sign-out, explicit revocation, or security-driven reset.

## Technology Stack Rules
### Frontend
- **Framework**: Flutter 3.24+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Networking**: Dio
- **Local Storage**: Hive + flutter_secure_storage
- **Responsiveness**: Only customer-facing views are responsive/mobile-first. Staff/Admin portal screens are locked to a fixed 1300px width with horizontal scrolling.

### Backend
- **Framework**: NestJS
- **Language**: TypeScript
- **ORM**: Prisma
- **Database**: PostgreSQL 16+
- **Auth**: JWT + OTP
- **API Documentation**: Swagger/OpenAPI

### Infrastructure
- **File Storage**: Cloudflare R2 (S3 API)
- **Push Notifications**: Firebase Cloud Messaging
- **Caching**: Redis

## File Organization Rules
### Backend Structure
```
shield-backend/
├── src/
│   ├── modules/       # Feature modules (auth, customers, wallet, etc.)
│   ├── common/        # Shared utilities, guards, interceptors
│   ├── database/      # Prisma schema, migrations
│   ├── config/        # Configuration files
│   └── infrastructure/# External service integrations
```

### Frontend Structure
```
shield-app/
├── lib/
│   ├── app/           # App configuration, routing, theme
│   ├── core/          # Core utilities, services, widgets
│   ├── features/      # Feature-first modules
│   └── shared/        # Shared components, models, utilities
```

## Git & Version Control Rules
- Commit messages should follow Conventional Commits format
- Never commit secrets or sensitive data
- Keep commits focused and atomic

## Testing Rules
- Aim for minimum 80% test coverage
- Write unit tests for core logic
- Write integration tests for API endpoints
- Write widget tests for Flutter UI
