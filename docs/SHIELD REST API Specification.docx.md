# SHIELD REST API Specification

Version: 1.0

Project: SHIELD

API Style: REST

Data Format: JSON

Authentication: Firebase ID Token Verification \+ SHIELD JWT

Base URL:

* Local Development: `http://localhost:3000`
* Staging/Custom: `https://api.shield.sahakar.com/api/v1`
* Live Vercel Production: `https://shield-backend.vercel.app`

Primary Frontend Application:

* Live Vercel Production: `https://shield-zabnix.vercel.app`

API Versioning:

/api/v1

Content-Type:

application/json

---

# 1. Authentication Module

## Customer Login

### Endpoint

POST /auth/customer/login

### Request

{
  "firebase_id_token": "firebase-id-token-from-phone-auth"
}

### Response

{
  "success": **true**,
  "message": "Customer login successful.",
  "data": {
    "access_token": "jwt",
    "refresh_token": "jwt",
    "principal": {}
  }
}

---

## Internal User Login

### Endpoint

POST /auth/internal/login

### Request

{
  "firebase_id_token": "firebase-id-token-from-google-sign-in"
}

### Response

{
  "success": **true**,
  "message": "Internal user login successful.",
  "data": {
    "access_token": "jwt",
    "refresh_token": "jwt",
    "principal": {}
  }
}

---

## Refresh Session

### Endpoint

POST /auth/refresh

### Request

{
  "refresh_token": "jwt"
}

### Response

{
  "success": **true**,
  "message": "Session refreshed successfully.",
  "data": {
    "access_token": "jwt",
    "refresh_token": "jwt"
  }
}

---

## Logout

POST /auth/logout

---

## Authenticated Profile

GET /auth/me

---

# 2. Customer Module

## Create Customer

POST /customers

### Request

{  
  "first\_name": "Rahul",  
  "last\_name": "Muraleedharan",  
  "aadhaar\_number": "XXXX",  
  "mobile": "9876543210",  
  "address": "..."  
}

---

## Update Customer

PUT /customers/{id}

---

## Get Customer

GET /customers/{id}

---

## Search Customer

GET /customers/search

Query Parameters

?mobile=  
?membership=  
?aadhaar=  
?name=

---

## Approve Customer

POST /customers/{id}/approve

---

## Suspend Customer

POST /customers/{id}/suspend

---

# 3. Membership Module

## Create Membership

POST /memberships

---

## Get Membership

GET /memberships/{id}

---

## Generate Card

POST /memberships/{id}/generate-card

---

## Activate Membership

POST /memberships/{id}/activate

---

## Suspend Membership

POST /memberships/{id}/suspend

---

# 4. Shield Card Module

## Get Card

GET /cards/{id}

---

## Regenerate QR

POST /cards/{id}/regenerate-qr

---

# 5. Wallet Module

## Get Wallet

GET /wallets/{customerId}

### Response

{  
  "wallet_id": 1,
  "customer_id": 1,
  "status": "ACTIVE",
  "cash_wallet": {
    "available": 14550,
    "credited": 16000,
    "debited": 1450
  },
  "reward_points": {
    "available": 500,
    "earned": 700,
    "redeemed": 200
  },
  "shield_benefit_applied_total": 150,
  "credit_available": 5000
}

---

## Recharge Wallet

POST /wallets/recharge

### Request

{  
  "customer\_id": 1,  
  "amount": 5000,
  "ledger_type": "CASH"
}

---

## Wallet Transactions

GET /wallets/{id}/transactions

Filters

?from=  
?to=  
?type=

---

## Manual Adjustment

POST /wallets/adjustments

---

## Redeem Reward Points

POST /wallets/redeem-points

### Request

{
  "customer_id": 1,
  "points": 1000
}

---

# 6. Credit Module

## Create Credit Account

POST /credit/accounts

---

## Get Credit Account

GET /credit/accounts/{id}

---

## Approve Credit

POST /credit/accounts/{id}/approve

---

## Credit Transactions

GET /credit/accounts/{id}/transactions

---

# 7. Customer Verification Module

## Verify By OTP

POST /verification/otp

---

## Verify By QR

POST /verification/qr

---

## Verify Membership

POST /verification/membership

---

# 8. Document Module

## Upload Document

POST /documents/upload

Multipart Form Data

file  
customer\_id  
document\_type

---

## Get Document

GET /documents/{id}

---

## Download Document

GET /documents/{id}/download

---

## Delete Document

Restricted

DELETE /documents/{id}

Soft Delete Only

---

# 9. Document Intelligence Module

## Classify Document

POST /document-intelligence/classify

---

## Extract Document

POST /document-intelligence/extract

---

## Validate Extraction

POST /document-intelligence/validate

---

## Processing Logs

GET /document-intelligence/logs/{documentId}

---

# 10. Pharmacy Module

## Upload Bill

POST /pharmacy/bills

---

## Upload Prescription

POST /pharmacy/prescriptions

---

## Create Purchase

POST /pharmacy/purchases

---

## Purchase History

GET /pharmacy/purchases

Filters

?customer=  
?date=

---

# 11. Product Module

## Create Product

POST /products

---

## Get Product

GET /products/{id}

---

## Product Search

GET /products/search

---

# 12. Appointment Module

## Create Appointment

POST /appointments

### Request

{  
  "customer\_id": 1,  
  "provider\_id": 2,  
  "appointment\_type": "CONSULTATION",  
  "appointment\_date": "2026-07-01"  
}

---

## Get Appointment

GET /appointments/{id}

---

## Update Appointment

PUT /appointments/{id}

---

## Cancel Appointment

POST /appointments/{id}/cancel

---

## Confirm Appointment

POST /appointments/{id}/confirm

---

# 13. Consultation Module

## Create Consultation

POST /consultations

---

## Get Consultation

GET /consultations/{id}

---

# 14. Lab Reports Module

## Upload Lab Report

POST /lab-reports

---

## Get Lab Report

GET /lab-reports/{id}

---

# 15. Dental Module

## Create Dental Record

POST /dental-records

---

## Get Dental Record

GET /dental-records/{id}

---

# 16. Home Visit Module

## Create Home Visit

POST /home-visits

---

## Complete Home Visit

POST /home-visits/{id}/complete

---

# 17. CRM Module

## Create CRM Activity

POST /crm/activities

---

## Create Task

POST /crm/tasks

---

## Update Task

PUT /crm/tasks/{id}

---

## Create Follow-Up

POST /crm/followups

---

## Follow-Up History

GET /crm/followups

---

# 18. Complaint Module

## Create Complaint

POST /complaints

---

## Update Complaint

PUT /complaints/{id}

---

## Resolve Complaint

POST /complaints/{id}/resolve

---

# 19. Notification Module

## Get Notifications

GET /notifications

---

## Mark As Read

POST /notifications/{id}/read

---

## Send Notification

POST /notifications/send

Admin Only

---

# 20. Referral Module

## Referral Tree

GET /referrals/tree/{customerId}

---

## Referral Summary

GET /referrals/summary/{customerId}

---

## Qualify Referral Reward

POST /referrals/qualify

### Request

{
  "customer_id": 1,
  "service_type": "LAB",
  "reference_type": "PURCHASE",
  "reference_id": 101
}

---

# 21. Pricing Module

## Evaluate Pricing

POST /pricing/evaluate

### Request

{
  "customer_id": 1,
  "service_type": "LAB",
  "original_amount": 900,
  "requested_reward_points": 1000
}

### Response

{
  "success": **true**,
  "message": "Pricing evaluation completed successfully.",
  "data": {
    "original_amount": 900,
    "shield_benefit_applied": 300,
    "membership_discount_applied": 0,
    "reward_points_applied": 0,
    "cash_wallet_applied": 0,
    "final_payable_amount": 600
  }
}

---

# 22. Dashboard Module

## Customer Dashboard

GET /dashboard/customer

---

## Staff Dashboard

GET /dashboard/staff

---

## CRM Dashboard

GET /dashboard/crm

---

## Management Dashboard

GET /dashboard/management

---

# 23. Reports Module

## Membership Report

GET /reports/memberships

---

## Wallet Report

GET /reports/wallet

---

## Revenue Report

GET /reports/revenue

---

## CRM Report

GET /reports/crm

---

## Service Usage Report

GET /reports/services

---

Export Formats

?format=pdf  
?format=xlsx  
?format=csv

---

# 24. User Management Module

## Create User

POST /users

---

## Update User

PUT /users/{id}

---

## Get User

GET /users/{id}

---

## Disable User

POST /users/{id}/disable

---

# 25. Role Management Module

## Create Role

POST /roles

---

## Assign Permissions

POST /roles/{id}/permissions

---

## Get Role Permissions

GET /roles/{id}/permissions

---

# 26. Business Management Module

## Create Business

POST /businesses

---

## Create Department

POST /departments

---

## Get Business

GET /businesses/{id}

---

# 27. Audit Module

## Audit Logs

GET /audit/logs

Filters

?entity=  
?action=  
?user=  
?date=

---

# 28. API Standards

Success Response

{  
  "success": **true**,  
  "message": "Operation Successful",  
  "data": {}  
}

---

Validation Error

{  
  "success": **false**,  
  "message": "Validation Error",  
  "errors": \[\]  
}

---

Server Error

{  
  "success": **false**,  
  "message": "Internal Server Error"  
}

---

# 29. Security Requirements

Every protected API Requires:

* JWT

* RBAC Validation

* ABAC Validation

* Audit Logging

Public Endpoints:

/auth/customer/login

/auth/internal/login

/auth/refresh

/support/contact

/support/feedback

/health

---

# 30. API Documentation

Documentation Tool

Swagger OpenAPI

URL

/api/docs

---

Total Estimated Endpoints

Core MVP:

\~120–150 APIs

Future Expansion:

200+ APIs

End of REST API Specification.
