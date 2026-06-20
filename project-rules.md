# SHIELD Project Rules

## Core Project Principles
1. **Documentation First**: Always refer to the `docs/` directory as the single source of truth.
2. **Feature-First Architecture**: Follow Clean Architecture principles for both frontend (Flutter) and backend (NestJS).
3. **Security First**:
   - Use RBAC + ABAC for authorization
   - Implement audit logging for all critical operations
   - Never expose secrets in code
4. **Ledger-Based Wallet**: Never store wallet balance directly - always calculate from transactions.
5. **API First Design**: Define API schemas before implementing endpoints.

## Technology Stack Rules
### Frontend
- **Framework**: Flutter 3.24+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Networking**: Dio
- **Local Storage**: Hive + flutter_secure_storage

### Backend
- **Framework**: NestJS
- **Language**: TypeScript
- **ORM**: Prisma
- **Database**: PostgreSQL 16+
- **Auth**: JWT + OTP
- **API Documentation**: Swagger/OpenAPI

### Infrastructure
- **File Storage**: MinIO
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
