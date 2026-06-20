# SHIELD API Schemas

Version: 1.0

Project: SHIELD

This document contains detailed request/response schemas for all SHIELD API endpoints.

---

# Authentication Module

## Request OTP

**Endpoint:** POST /api/v1/auth/request-otp

**Request Body:**
```json
{
  "mobile": "string (required, format: phone number, e.g., 9876543210)"
}
```

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "otp_reference": "string (unique reference for OTP verification)"
  }
}
```

**Response (Error - 400 Bad Request):**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    {
      "field": "mobile",
      "message": "Mobile number is required"
    }
  ]
}
```

---

## Verify OTP

**Endpoint:** POST /api/v1/auth/verify-otp

**Request Body:**
```json
{
  "mobile": "string (required)",
  "otp": "string (required, 6 digits)",
  "otp_reference": "string (required, from request-otp response)"
}
```

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "access_token": "string (JWT access token)",
    "refresh_token": "string (JWT refresh token)",
    "user": {
      "id": "number",
      "uuid": "string",
      "first_name": "string",
      "last_name": "string",
      "mobile": "string",
      "email": "string",
      "role": {
        "id": "number",
        "code": "string",
        "name": "string"
      },
      "department": {
        "id": "number",
        "name": "string",
        "business": {
          "id": "number",
          "name": "string"
        }
      }
    }
  }
}
```

---

## Refresh Token

**Endpoint:** POST /api/v1/auth/refresh

**Request Body:**
```json
{
  "refresh_token": "string (required)"
}
```

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "access_token": "string (new JWT access token)",
    "refresh_token": "string (new JWT refresh token)"
  }
}
```

---

## Logout

**Endpoint:** POST /api/v1/auth/logout

**Headers:**
- Authorization: Bearer <access_token>

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

# Customer Module

## Create Customer

**Endpoint:** POST /api/v1/customers

**Headers:**
- Authorization: Bearer <access_token>

**Request Body:**
```json
{
  "first_name": "string (required)",
  "last_name": "string",
  "aadhaar_number": "string (required, 12 digits, unique)",
  "mobile": "string (required, unique)",
  "email": "string (email format)",
  "address_line1": "string",
  "address_line2": "string",
  "city": "string",
  "district": "string",
  "state": "string",
  "pincode": "string"
}
```

**Response (Success - 201 Created):**
```json
{
  "success": true,
  "message": "Customer created successfully",
  "data": {
    "id": "number",
    "uuid": "string",
    "customer_code": "string",
    "first_name": "string",
    "last_name": "string",
    "aadhaar_number": "string",
    "mobile": "string",
    "email": "string",
    "status": "draft",
    "created_by": "number",
    "created_at": "string (ISO 8601 date-time)"
  }
}
```

---

## Get Customer

**Endpoint:** GET /api/v1/customers/:id

**Headers:**
- Authorization: Bearer <access_token>

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Customer retrieved successfully",
  "data": {
    "id": "number",
    "uuid": "string",
    "customer_code": "string",
    "first_name": "string",
    "last_name": "string",
    "aadhaar_number": "string",
    "mobile": "string",
    "email": "string",
    "address_line1": "string",
    "address_line2": "string",
    "city": "string",
    "district": "string",
    "state": "string",
    "pincode": "string",
    "status": "string (draft|pending_approval|active|suspended|closed)",
    "membership": {
      "id": "number",
      "membership_number": "string",
      "type": {
        "id": "number",
        "code": "string",
        "name": "string"
      },
      "activation_date": "string (ISO 8601 date)",
      "expiry_date": "string (ISO 8601 date)",
      "status": "string"
    },
    "wallet": {
      "id": "number",
      "balance": "number (calculated from transactions)"
    },
    "created_by": "number",
    "approved_by": "number",
    "created_at": "string (ISO 8601 date-time)",
    "updated_at": "string (ISO 8601 date-time)"
  }
}
```

---

## Search Customers

**Endpoint:** GET /api/v1/customers/search

**Headers:**
- Authorization: Bearer <access_token>

**Query Parameters:**
- q: string (search term for name, mobile, membership number)
- status: string (filter by status)
- page: number (default: 1)
- limit: number (default: 20)

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Customers retrieved successfully",
  "data": {
    "customers": [
      {
        "id": "number",
        "uuid": "string",
        "customer_code": "string",
        "first_name": "string",
        "last_name": "string",
        "mobile": "string",
        "status": "string"
      }
    ],
    "pagination": {
      "page": "number",
      "limit": "number",
      "total": "number",
      "total_pages": "number"
    }
  }
}
```

---

## Approve Customer

**Endpoint:** POST /api/v1/customers/:id/approve

**Headers:**
- Authorization: Bearer <access_token>

**Request Body:**
```json
{
  "remarks": "string (optional)"
}
```

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Customer approved successfully",
  "data": {
    "customer": {
      "id": "number",
      "status": "active"
    },
    "membership": {
      "id": "number",
      "membership_number": "string"
    },
    "wallet": {
      "id": "number"
    }
  }
}
```

---

## Suspend Customer

**Endpoint:** POST /api/v1/customers/:id/suspend

**Headers:**
- Authorization: Bearer <access_token>

**Request Body:**
```json
{
  "reason": "string (required)"
}
```

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Customer suspended successfully"
}
```

---

## Update Customer

**Endpoint:** PUT /api/v1/customers/:id

**Headers:**
- Authorization: Bearer <access_token>

**Request Body:** (same as create, all fields optional)

---

# Wallet Module

## Get Wallet

**Endpoint:** GET /api/v1/wallets/:customer_id

**Headers:**
- Authorization: Bearer <access_token>

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Wallet retrieved successfully",
  "data": {
    "id": "number",
    "customer_id": "number",
    "balance": "number (calculated from transactions)",
    "credit_available": "number",
    "transactions": [
      {
        "id": "number",
        "transaction_type": "string (opening_balance|recharge|purchase|discount|adjustment|credit|reversal|promotional_credit)",
        "amount": "number",
        "reference_type": "string",
        "reference_id": "number",
        "remarks": "string",
        "created_by": "number",
        "created_at": "string (ISO 8601 date-time)"
      }
    ]
  }
}
```

---

## Recharge Wallet

**Endpoint:** POST /api/v1/wallets/recharge

**Headers:**
- Authorization: Bearer <access_token>

**Request Body:**
```json
{
  "customer_id": "number (required)",
  "amount": "number (required, positive)",
  "remarks": "string (optional)"
}
```

**Response (Success - 201 Created):**
```json
{
  "success": true,
  "message": "Wallet recharged successfully",
  "data": {
    "transaction_id": "number",
    "new_balance": "number"
  }
}
```

---

## Wallet Transactions

**Endpoint:** GET /api/v1/wallets/:id/transactions

**Headers:**
- Authorization: Bearer <access_token>

**Query Parameters:**
- from: string (ISO 8601 date)
- to: string (ISO 8601 date)
- type: string (filter by transaction type)
- page: number
- limit: number

---

## Manual Adjustment

**Endpoint:** POST /api/v1/wallets/adjustments

**Headers:**
- Authorization: Bearer <access_token>

**Request Body:**
```json
{
  "customer_id": "number (required)",
  "amount": "number (required, can be positive or negative)",
  "remarks": "string (required)"
}
```

---

## Reversal Request

**Endpoint:** POST /api/v1/wallets/reversal-request

**Headers:**
- Authorization: Bearer <access_token>

**Request Body:**
```json
{
  "transaction_id": "number (required)",
  "reason": "string (required)"
}
```

---

# End of API Schemas Document
