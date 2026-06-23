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
- Auth: Customers use Mobile OTP login; Staff/Providers/Admins use Email/Password + JWT
- API Documentation: Swagger/OpenAPI
- Caching: Redis
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

## Database Rules
- Use UUIDs for public identifiers
- Use BIGSERIAL for internal primary keys
- **NO STORED BALANCE IN WALLET TABLE**: Always calculate dynamically from transactions.
- Wallet balances are segregated via `sub_ledger_type` ('CASH' vs 'POINTS') in `wallet_transactions` table.
- Enforce location constraint check using `issued_business_id` in `shield_cards`.
- Soft delete support (deleted_at column)
- Append-only audit logs
- Index frequently queried columns
- Use database constraints for data integrity

## Security Rules
1. RBAC + ABAC authorization
2. OTP verification (Customers) and Email Credentials verification (Staff / Service Providers)
3. Mandatory `agent_code` check for Customer registration (onboarding agent who initiated creation)
4. Enforce branch restriction rules on SHIELD card utilization (Hyperpharmacy store cards are locked to their issuing branch, general service providers are cross-compatible)
5. Encrypt sensitive data at rest
6. HTTPS only (TLS 1.3)
7. Audit all critical actions
8. Rate limiting for APIs
9. Input validation and sanitization

## User Roles
1. **CUSTOMER**: Access Profile (Name, Address, Pin Code, Phone, DOB/Age, Blood Group), Wallet (Cash, Points, Transactions), Services (Pharmacy, Lab, Homecare, Dental, Doctor, Cosmetic, Dietitian), and Appointments.
2. **SERVICE_PROVIDER (PHARMACY_STAFF, CLINIC_STAFF, DENTAL_STAFF, etc.)**: Verify customer digital privilege cards, enforce hyperpharmacy local store rules, upload prescriptions/bills, and log card utilization.
3. **CRM_EXECUTIVE**: View customers, create tasks/follow-ups/complaints
4. **SHIELD_EXECUTIVE**: Approve customers (validating agent_code), manage memberships, wallet adjustments
5. **MANAGER**: View reports/analytics, approve overrides/credit requests
6. **SUPER_ADMIN / ADMINISTRATOR**: View Branch-wise IDs list, IDs service utilization, reports, configure roles/users/permissions.

## Document Intelligence Pipeline
1. Upload
2. Classification
3. Extraction (PDF text first, OCR fallback)
4. Validation
5. Approval
6. Storage

## Log.md Rules
1. Initialize/Locate: Check root for log.md first
2. Dev Attribution: First line = Dev Name
3. Structure: Numbered features (## 1., ## 2., etc.), high-level description, bullet points
4. File Categorization: Split into Frontend Files and Backend Files
5. Append Only: Add at bottom, never delete
6. Timestamps: IST format (YYYY-MM-DD HH:mm:ss IST)
7. Engineer-to-Engineer: Explain *why* choices were made
8. Method: Use append-log.js or PowerShell append, NEVER full rewrite or Edit tool

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
- PRD: docs/SHIELD Product Requirements Document.docx.md
- FRD: docs/SHIELD Functional Requirements Document.docx.md
- ERD: docs/SHIELD Entity Relationship Design.docx.md
- Database Schema: docs/SHIELD Database Schema.docx.md
- API Spec: docs/SHIELD REST API Specification.docx.md
- Flutter Architecture: docs/SHIELD Flutter Project Architecture.docx.md
- UI/UX: docs/SHIELD UI-UX Design Specification.docx.md
- Security: docs/SHIELD Security Architecture.docx.md
- Test Plan: docs/SHIELD Test Plan.docx.md
