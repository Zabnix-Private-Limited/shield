# SHIELD REST API Specification

Version: 1.0

Project: SHIELD

API Style: REST

Data Format: JSON

Authentication: JWT \+ OTP

Base URL:

https://api.shield.sahakar.com/api/v1

API Versioning:

/api/v1

Content-Type:

application/json

---

# 1. Authentication Module

## Request OTP

### Endpoint

POST /auth/request-otp

### Request

{  
  "mobile": "9876543210"  
}

### Response

{  
  "success": **true**,  
  "message": "OTP Sent"  
}

---

## Verify OTP

### Endpoint

POST /auth/verify-otp

### Request

{  
  "mobile": "9876543210",  
  "otp": "123456"  
}

### Response

{  
  "access\_token": "jwt",  
  "refresh\_token": "jwt",  
  "user": {}  
}

---

## Logout

POST /auth/logout

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
  "balance": 14550,  
  "credit\_available": 5000  
}

---

## Recharge Wallet

POST /wallets/recharge

### Request

{  
  "customer\_id": 1,  
  "amount": 5000  
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

## Reversal Request

POST /wallets/reversal-request

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

# 20. Dashboard Module

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

# 21. Reports Module

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

# 22. User Management Module

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

# 23. Role Management Module

## Create Role

POST /roles

---

## Assign Permissions

POST /roles/{id}/permissions

---

## Get Role Permissions

GET /roles/{id}/permissions

---

# 24. Business Management Module

## Create Business

POST /businesses

---

## Create Department

POST /departments

---

## Get Business

GET /businesses/{id}

---

# 25. Audit Module

## Audit Logs

GET /audit/logs

Filters

?entity=  
?action=  
?user=  
?date=

---

# 26. API Standards

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

# 27. Security Requirements

Every API Requires:

* JWT

* RBAC Validation

* ABAC Validation

* Audit Logging

Except:

/auth/request-otp

/auth/verify-otp

---

# 28. API Documentation

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