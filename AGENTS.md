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
- Auth: OTP + JWT
- API Documentation: Swagger/OpenAPI
- Caching: Redis
- Logging: Winston

### Infrastructure
- File Storage: MinIO
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
- **NO STORED BALANCE IN WALLET TABLE**: Always calculate from transactions (ledger-based)
- Soft delete support (deleted_at column)
- Append-only audit logs
- Index frequently queried columns
- Use database constraints for data integrity

## Security Rules
1. RBAC + ABAC authorization
2. OTP + JWT authentication
3. Encrypt sensitive data at rest
4. HTTPS only (TLS 1.3)
5. Audit all critical actions
6. Rate limiting for APIs
7. Input validation and sanitization

## User Roles
1. **CUSTOMER**: View profile, wallet, transactions, documents, appointments
2. **PHARMACY_STAFF**: Verify customers, upload bills/prescriptions
3. **CLINIC_STAFF**: Manage appointments, consultations, reports
4. **DENTAL_STAFF**: Manage dental appointments, records
5. **CRM_EXECUTIVE**: View customers, create tasks/follow-ups/complaints
6. **SHIELD_EXECUTIVE**: Approve customers, manage memberships, wallet adjustments
7. **MANAGER**: View reports/analytics, approve overrides/credit requests
8. **SUPER_ADMIN**: Full system access

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
