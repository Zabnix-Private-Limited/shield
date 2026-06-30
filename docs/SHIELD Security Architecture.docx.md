# SHIELD Security Architecture

Version: 1.0

Project: SHIELD

This document contains detailed security architecture specifications for SHIELD.

---

# Authentication

## Customer Authentication

- Customers authenticate using **Firebase Phone Authentication**
- The client sends a Firebase ID token to `POST /auth/customer/login`
- NestJS verifies the Firebase token, confirms that the customer was pre-provisioned in SHIELD, and then issues a SHIELD access token and refresh token
- No customer password, email login, or self-signup flow exists in V1

## Internal User Authentication

- Internal users authenticate using **Firebase Google Sign-In**
- The client sends a Firebase ID token to `POST /auth/internal/login`
- NestJS verifies the Firebase token, confirms that the internal account was pre-provisioned by an admin, and then issues a SHIELD access token and refresh token
- Only organization-approved Google identities should be provisioned for internal use

## SHIELD JWT Tokens

### Access Token
- **Expiry:** short-lived, controlled by env (`JWT_ACCESS_TTL`)
- **Algorithm:** HS256
- **Claims:**
  - `sub`: SHIELD principal ID
  - `role_code`: RBAC role code
  - `user_type`: `CUSTOMER | EMPLOYEE | SERVICE_PROVIDER | SYSTEM`
  - `access_scope`: `GLOBAL | ORGANIZATION | CLUSTER | BRANCH | SELF`
  - `customer_id`: customer public identifier when principal is a customer
  - `branch_business_id`: branch scope when applicable
  - `permissions`: resolved `resource.action` permissions
  - `firebase_uid`: verified Firebase subject
  - `iat` and `exp`

### Refresh Token
- **Expiry:** effectively persistent, controlled by env (`JWT_REFRESH_TTL`), with SHIELD defaulting to a very long-lived refresh session so customers and internal users remain signed in unless they intentionally sign out or security operations revoke access
- **Algorithm:** HS256
- **Claims:**
  - `sub`: SHIELD principal ID
  - `session_id`: unique session identifier
  - `jti`: token identifier for revocation
  - `iat` and `exp`

### Token Refresh Flow
1. Client sends refresh token to `/api/v1/auth/refresh`
2. Server validates signature and expiry
3. Server checks session state in PostgreSQL auth-session storage
4. Server issues a new access token and rotated refresh token
5. Prior refresh token session entry is revoked

### Token Revocation
- Refresh sessions are stored in PostgreSQL auth-session records
- On logout, the refresh session is revoked
- On admin-enforced access reset, all known sessions for the principal should be revoked
- Normal access-token expiry should silently refresh and keep the user signed in when the refresh session remains valid
- Customer and internal login activity must still be audit logged in PostgreSQL

---

# Authorization

## RBAC + Scoped Access

SHIELD uses role-based permissions with scope and relationship enforcement. Pure role checks are not sufficient for medical and financial data.

### Human Roles
1. **ADMIN**
2. **SHIELD_AGENT**
3. **CRM_EXECUTIVE**
4. **PHARMACY_PROVIDER**
5. **LAB_PROVIDER**
6. **DOCTOR**
7. **HOMECARE_PROVIDER**
8. **DENTAL_PROVIDER**
9. **COSMETIC_PROVIDER**
10. **DIETITIAN**
11. **CUSTOMER**

### System Roles
- `SYSTEM`
- `BACKGROUND_WORKER`
- `NOTIFICATION_SERVICE`
- `WEBHOOK_SERVICE`

### Permission Model
- Permissions use `resource.action`
- Resources include:
  - `customers`
  - `wallet`
  - `membership`
  - `appointments`
  - `medical_records`
  - `documents`
  - `reports`
  - `crm`
  - `agents`
  - `providers`
  - `referrals`
  - `analytics`
  - `settings`
  - `notifications`

### Access Scopes
- `GLOBAL`
- `ORGANIZATION`
- `CLUSTER`
- `BRANCH`
- `SELF`

### Relationship and Ownership Rules
- Customers may only access their own records
- Service providers may only access customers when there is a valid operational relationship such as assignment, appointment, treatment, or referral context
- Branch-scoped users must not access records outside their assigned branch scope
- Access to medical records and document downloads should always be auditable

## Policy Constraints

### Example Constraints
- Pharmacy providers can view and update only assigned or validly-related pharmacy customers
- CRM executives can work only on assigned customer follow-up records
- Customers can only view their own referral subtree, not the full referral network
- Hidden SHIELD promotional benefit ledger entries must never be exposed to customer-facing wallet views

---

# Rate Limiting

## Global Rate Limits
- **Unauthenticated Endpoints:** 10 requests per minute per IP
- **Authenticated Endpoints:** 100 requests per minute per user

## Specific Rate Limits
- **/api/v1/auth/request-otp:** 5 requests per 10 minutes per mobile number
- **/api/v1/auth/verify-otp:** 10 requests per 5 minutes per mobile number

---

# Data Encryption

## At Rest
- **Database Columns:** Sensitive columns (aadhaar_number, mobile, email) are encrypted
- **Encryption Algorithm:** AES-256-GCM
- **Key Management:** Use a secure key management system (KMS)

## In Transit
- **Protocol:** HTTPS only (TLS 1.3)
- **Certificate:** Use valid SSL/TLS certificates
- **HSTS:** Enabled with max-age=31536000

---

# Audit Logging

## What to Log
All critical operations must be logged:
- User login/logout
- Customer creation/update
- Customer status changes
- Membership approval
- Wallet transactions
- Credit transactions
- Document upload/approval
- Appointment actions
- CRM activities
- Admin actions

## Audit Log Schema
```json
{
  "id": "number",
  "user_id": "number",
  "action": "string",
  "entity_type": "string",
  "entity_id": "number",
  "old_data": "JSONB",
  "new_data": "JSONB",
  "ip_address": "string",
  "device_info": "string",
  "created_at": "timestamp"
}
```

## Audit Log Rules
- Append-only: No updates or deletions allowed
- Retention: 7 years
- Access: Only SUPER_ADMIN can view audit logs

---

# Wallet, Benefit, and Referral Security
- Cash wallet, reward points, and hidden SHIELD benefit must be stored as separate ledgers and never collapsed into one exposed customer balance
- SHIELD benefit is an internal promotional ledger; customers may see only the amount applied to a transaction, never the remaining hidden balance
- Reward points are not cash, cannot be transferred, cannot be purchased, and may only convert through configured redemption rules
- Referral rewards must be delayed until qualification rules pass; registration alone must not trigger a reward
- Pricing, benefit application, reward redemption, and wallet debits must be executed by a centralized service/rule engine rather than ad-hoc UI calculations

---

# Input Validation
- All inputs must be validated
- Use schema validation (e.g., Joi, Zod)
- Sanitize inputs to prevent XSS
- Validate file uploads (type, size)

---

# File Upload Security
- **Allowed File Types:** PDF, PNG, JPG, JPEG
- **Maximum File Size:** 20 MB
- **Virus Scanning:** Scan all uploaded files for viruses
- **Storage:** Store files in Cloudflare R2 with private buckets
- **Access:** Use signed URLs for file access

---

# Security Headers
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- Content-Security-Policy: default-src 'self'
- Referrer-Policy: strict-origin-when-cross-origin

---

# End of Security Architecture Document
