# SHIELD Agent Reference

## Project Overview
- **Project Name**: SHIELD
- **Full Name**: Sahakar Healthcare Initiative to Exempt Lifestyle Disease
- **Type**: Unified healthcare ecosystem platform
- **Platforms**: Android, Web, PWA, Future iOS
- **Key Features**: Membership management, digital privilege card, wallet (ledger-based), credit facility, appointment management, CRM, healthcare records, document intelligence, notifications, reporting/analytics

## Technology Stack
### Frontend
- Framework: Flutter
- State Management: Riverpod
- Navigation: GoRouter
- Networking: Dio
- Local Storage: Hive + flutter_secure_storage
- PDF Viewer: syncfusion_flutter_pdfviewer
- QR Scanner: mobile_scanner
- Push Notifications: firebase_messaging

### Backend
- Framework: NestJS
- Language: TypeScript
- ORM: Prisma
- Database: PostgreSQL 16+
- Auth: Customers use Firebase Phone OTP -> Nest verification -> SHIELD JWT; Staff/Providers/Admins use Firebase Google Sign-In -> Nest verification -> SHIELD JWT
- API Documentation: Swagger/OpenAPI
- Caching: Redis / Valkey
- Logging: Winston

### Infrastructure
- File Storage: Cloudflare R2 (S3 API)
- Push Notifications: Firebase Cloud Messaging
- Web Server: Nginx
- Containerization: Docker

## Architecture Principles
1. Feature-First Architecture
2. Clean Architecture
3. Modular Architecture
4. Repository Pattern
5. Dependency Injection
6. SOLID Principles
7. Domain-Driven Design
8. API-First Design
9. Backend-Owned Workspace Semantics
   - Navigation, module registries, workflow stages, action definitions, display labels, button captions, empty states, permissions, and operational metadata must come from backend contracts rather than being hardcoded in Flutter.
   - Flutter should act as a renderer for backend-owned workspace metadata and should limit local decisions to layout, responsive behavior, accessibility, animations, and presentation-only formatting such as date, currency, and percentage display.
   - Do not expose raw database or backend enum codes in the UI when a human-readable backend display contract can be returned instead.
10. Provider Platform Module Architecture
   - SHIELD should have one Provider Platform with backend-driven modules, not separate duplicated provider portals for doctor, pharmacy, dental, laboratory, dietitian, or home-care roles.
   - Provider type should change the loaded module registry, module renderer identifiers, workflow stages, forms, actions, and permissions through backend metadata, while the Flutter shell remains a reusable renderer.
   - Avoid frontend branching on provider type for business semantics; if a provider workflow needs to differ, add or adjust the backend module contract instead of creating provider-type-specific pages.

## Database Rules
- `current_schema.md` at the repository root is the source of truth for the current database situation and schema state.
- Use UUIDs for public identifiers
- Use BIGSERIAL for internal primary keys
- **NO STORED BALANCE IN WALLET TABLE**: Always calculate dynamically from transactions.
- Wallet balances are ledger-based via `sub_ledger_type` in `wallet_transactions` and must remain separated across `CASH`, `REWARD_POINTS`, and hidden `SHIELD_BENEFIT` entries.
- `SHIELD_BENEFIT` is company-funded promotional credit and must never be exposed to customers as a remaining wallet balance; only applied-discount lines are customer-visible.
- Referral rewards must stay delayed and status-driven (`PENDING -> VERIFIED -> QUALIFIED -> REWARDED/REJECTED`) rather than being credited at registration or approval time.
- Pricing, benefit application, membership discounts, referral qualification, reward redemption, and final payable calculations should be centralized through a rule engine/service layer, not scattered across individual feature modules.
- Enforce location constraint check using `issued_business_id` in `shield_cards`.
- Soft delete support (deleted_at column)
- Append-only audit logs
- Index frequently queried columns
- Use database constraints for data integrity
- Do not run Prisma schema pushes automatically during normal builds or deployments. Treat production and real shared databases as explicit infrastructure changes, and only run schema-apply commands when the user specifically asks for that step.
- Do not introduce dummy or placeholder data in real authenticated or production-facing flows unless the user explicitly asks for mock/demo data for that exact task.
- When database-related code, docs, env assumptions, or runtime observations conflict, reconcile them against `current_schema.md` first before proposing or applying a fix.

## Security Rules
1. RBAC + ABAC authorization
2. Firebase Phone OTP verification (Customers) and Firebase Google Sign-In verification (Staff / Service Providers / Admins)
3. Mandatory `agent_code` check for Customer registration (onboarding agent who initiated creation)
4. Enforce branch restriction rules on SHIELD card utilization (Hyperpharmacy store cards are locked to their issuing branch, general service providers are cross-compatible)
5. Encrypt sensitive data at rest
6. HTTPS only (TLS 1.3)
7. Audit all critical actions
8. Rate limiting for APIs
9. Input validation and sanitization
10. Keep authenticated customer and internal-user sessions persistent by default through long-lived refresh-session policy, and only end sessions on intentional sign-out, explicit revocation, or security-driven invalidation.

## User Roles
1. **ADMIN**: Full-platform access; dashboard layout may vary by assignment, but permissions remain unrestricted.
2. **SHIELD_AGENT**: Enroll customers, collect KYC, create memberships, assign referrals, recharge wallet manually, and track their own customer/referral graph.
3. **CRM_EXECUTIVE**: Handle assigned-customer follow-ups, call history, retention, upcoming renewals, and customer-status operations.
4. **PHARMACY_PROVIDER**: Search customers, upload bills/prescriptions/documents, view wallet usage, and redeem wallet benefits.
5. **LAB_PROVIDER**: Manage assigned lab requests, report uploads, and related customer documents.
6. **DOCTOR**: View assigned patients, appointments, consultation-linked records, and prescriptions.
7. **HOMECARE_PROVIDER**: Manage assigned visits, visit notes, and document updates.
8. **DENTAL_PROVIDER**: Manage assigned dental visits, documents, and treatment records.
9. **COSMETIC_PROVIDER**: Manage assigned cosmetic-service visits, records, and uploads.
10. **DIETITIAN**: Manage assigned customer plans, service notes, and related records.
11. **CUSTOMER**: Phone OTP only; access wallet, records, services, appointments, referral graph, profile, and notifications.

## Document Intelligence Pipeline
1. Upload
2. Storage of original file
3. Metadata capture and access control
4. Optional classification / extraction workflow
5. Validation
6. Approval

## Log.md Rules
1. Initialize/Locate: Check root for log.md first
2. Dev Attribution: First line = Dev Name
3. Structure: Numbered features (## 1., ## 2., etc.), high-level description, bullet points
4. File Categorization: Split into Frontend Files and Backend Files
5. Append Only: Add at bottom, never delete
6. Timestamps: IST format (YYYY-MM-DD HH:mm:ss IST)
7. Engineer-to-Engineer: Explain *why* choices were made
8. Method: Use append-log.js or PowerShell append, NEVER full rewrite or Edit tool

## Agent Workflow Rules
1. Prefer the best project-safe fix without repeatedly asking for confirmation on every small issue.
2. Escalate only when a choice is destructive, ambiguous, or affects real infrastructure/data.
3. Deploy SHIELD to Vercel through the Git push workflow for this repository.
4. Do not run `vercel --prod` or other production Vercel CLI deploy commands from this machine/account for SHIELD unless the user explicitly overrides that rule.
5. Do not make Prisma schema application part of the default Vercel build path.
6. When building or expanding any portal (Customer, Provider, CRM, Manager, Executive, or Super Admin), prefer backend-driven workspace contracts over frontend-owned business semantics, and treat the Provider Portal architecture as the template to generalize from.
7. When expanding the Provider Portal, prefer adding backend-owned modules/plugins inside the shared Provider Platform shell over creating separate provider-type portals or duplicate workflow pages.

## Project File Structure
```
shield/
├── .trae/              # Agent rules
│   ├── project-rules.md
│   └── coding-style.md
├── docs/               # Project documentation
├── append-log.js       # Log append utility
└── log.md              # Project log
```

## Key Documentation Files
- Current DB Truth Source: current_schema.md
- PRD: docs/SHIELD Product Requirements Document.docx.md
- FRD: docs/SHIELD Functional Requirements Document.docx.md
- ERD: docs/SHIELD Entity Relationship Design.docx.md
- Database Schema: docs/SHIELD Database Schema.docx.md
- API Spec: docs/SHIELD REST API Specification.docx.md
- Flutter Architecture: docs/SHIELD Flutter Project Architecture.docx.md
- UI/UX: docs/SHIELD UI-UX Design Specification.docx.md
- Security: docs/SHIELD Security Architecture.docx.md
- Test Plan: docs/SHIELD Test Plan.docx.md
