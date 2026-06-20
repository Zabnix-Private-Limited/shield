# SHIELD Security Architecture

Version: 1.0

Project: SHIELD

This document contains detailed security architecture specifications for SHIELD.

---

# Authentication

## OTP-Based Authentication

- **OTP Length:** 6 digits
- **OTP Expiry:** 5 minutes
- **OTP Retry Limit:** 5 attempts
- **OTP Delivery Channels:** SMS (primary), Push Notification (fallback)

## JWT Tokens

### Access Token
- **Expiry:** 1 hour (3600 seconds)
- **Algorithm:** HS256
- **Claims:**
  - sub: user ID
  - role: user role code
  - business_id: business ID (if applicable)
  - department_id: department ID (if applicable)
  - iat: issued at timestamp
  - exp: expiry timestamp

### Refresh Token
- **Expiry:** 30 days (2592000 seconds)
- **Algorithm:** HS256
- **Claims:**
  - sub: user ID
  - jti: unique token ID (for revocation)
  - iat: issued at timestamp
  - exp: expiry timestamp

### Token Refresh Flow
1. Client sends refresh token to `/api/v1/auth/refresh`
2. Server validates refresh token (expiry, signature, not revoked)
3. Server issues new access token and new refresh token
4. Old refresh token is revoked

### Token Revocation
- Refresh tokens are stored in database with status (active/revoked)
- On logout, both access and refresh tokens are revoked
- On password change, all refresh tokens for user are revoked

---

# Authorization

## RBAC (Role-Based Access Control)

### Roles
1. **CUSTOMER**
   - View own profile
   - View own wallet
   - View own transactions
   - View own documents
   - View own appointments
   - View own notifications

2. **PHARMACY_STAFF**
   - Verify customers
   - Upload pharmacy bills
   - Upload prescriptions
   - View pharmacy history
   - View own customers

3. **CLINIC_STAFF**
   - Manage appointments
   - Upload consultation notes
   - Upload lab reports
   - View clinic records
   - View own customers

4. **DENTAL_STAFF**
   - Manage dental appointments
   - Upload dental records
   - View dental records
   - View own customers

5. **CRM_EXECUTIVE**
   - View customer profiles
   - Create CRM activities
   - Create tasks
   - Create follow-ups
   - Manage complaints

6. **SHIELD_EXECUTIVE**
   - Create customers
   - Approve customers
   - Manage memberships
   - Manage wallet adjustments
   - Approve reversals

7. **MANAGER**
   - View all reports
   - View analytics dashboard
   - Approve overrides
   - Approve credit requests

8. **SUPER_ADMIN**
   - Full system access
   - Manage users
   - Manage roles
   - Manage permissions
   - Manage businesses
   - Manage departments
   - Manage membership plans
   - View audit logs

## ABAC (Attribute-Based Access Control)

### Attributes Used
- **Business:** Which business the user belongs to
- **Department:** Which department the user belongs to
- **Record Type:** Type of record being accessed
- **Ownership:** Whether the user owns the record
- **Visibility:** Visibility level of the record

### Example ABAC Rules
- Clinic staff can only access records from their own clinic
- Pharmacy staff can only access records from their own pharmacy
- Dental staff can only access dental records
- Customers can only access their own records

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

# Password Security
- **Hashing Algorithm:** Argon2id
- **Salt Length:** 16 bytes
- **Iterations:** Configurable (default: 3)
- **Memory Cost:** Configurable (default: 65536 KB)
- **Parallelism:** Configurable (default: 4)

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
- **Storage:** Store files in MinIO with private buckets
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
