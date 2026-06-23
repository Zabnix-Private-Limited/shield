# SHIELD Technical Requirements Document (TRD)

Version: 1.0

Project: SHIELD

Document Type: Technical Requirements Document

Technology Stack:

* Flutter

* NestJS

* PostgreSQL

* Cloudflare R2 (S3 API)

* Firebase Cloud Messaging

---

# 1. Purpose

This document defines the technical requirements, standards, infrastructure, security requirements, performance requirements, integration requirements, and deployment requirements for the SHIELD platform.

---

# 2. Supported Platforms

## Mobile

Mandatory

* Android 10+

Recommended

* Android 12+

Supported Form Factors

* Mobile Phones

* Tablets

---

## Web

Supported Browsers

* Chrome

* Edge

* Firefox

* Safari

Latest two major versions.

---

## PWA

Must Support

* Installation

* Offline Mode

* Push Notifications

* Background Sync

---

## Future

* iOS

* iPadOS

---

# 3. Frontend Requirements

Technology

Flutter Stable Channel

Minimum Version

Flutter 3.24+

Language

Dart 3+

Architecture

Feature First Clean Architecture

---

# Required Libraries

State Management

* Riverpod

Navigation

* GoRouter

Networking

* Dio

Serialization

* json\_serializable

Storage

* Hive

Secure Storage

* flutter\_secure\_storage

File Upload

* file\_picker

PDF

* syncfusion\_flutter\_pdfviewer

QR

* mobile\_scanner

Push Notifications

* firebase\_messaging

---

# 4. Backend Requirements

Technology

NestJS

Language

TypeScript

Version

NodeJS 22+

---

Required Packages

Authentication

* JWT

* Passport

Validation

* Class Validator

ORM

* Prisma

Documentation

* Swagger

Scheduling

* NestJS Scheduler

Logging

* Winston

Caching

* Redis

---

# 5. Database Requirements

Database

PostgreSQL 16+

Requirements

* ACID Transactions

* Foreign Keys

* Indexing

* Constraints

* Stored Procedures

* Views

---

Database Standards

Every Table Must Include

**id**  
uuid  
created\_at  
updated\_at

Soft Delete

deleted\_at

where applicable.

---

# 6. Storage Requirements

Storage Engine

Cloudflare R2 (S3 API)

Alternative

Supabase Storage

---

Supported Files

PDF

PNG

JPG

JPEG

---

Maximum Upload Size

20 MB

Configurable

---

Storage Categories

Customer Documents

Prescriptions

Lab Reports

Dental Records

Invoices

Audit Documents

---

# 7. OCR Requirements

Primary Method

PDF Text Extraction

---

Secondary Method

OCR

---

Supported OCR Inputs

Scanned PDFs

Images

Low Quality Documents

---

OCR Engine

Tesseract

---

Requirements

Minimum Accuracy

95% for digital PDFs

85% for scanned documents

---

# 8. Authentication Requirements

Primary Authentication

Mobile OTP

---

OTP Length

6 Digits

---

OTP Expiry

5 Minutes

---

OTP Retry Limit

5 Attempts

---

Session Duration

30 Days

Configurable

---

# 9. Authorization Requirements

Authorization Model

RBAC

ABAC

---

RBAC Requirements

Role Based Access

Customer

Pharmacy

Clinic

Dental

CRM

Shield

Manager

Admin

---

ABAC Requirements

Based On

Business

Department

Record Type

Ownership

Visibility

---

# 10. Wallet Requirements

Architecture

Ledger Based

---

Requirements

No Stored Balance

Balance Must Be Calculated

Every Transaction Immutable

No Direct Deletion

---

Supported Transactions

Opening Balance

Recharge

Purchase

Discount

Adjustment

Credit

Reversal

Promotional Credit

---

# 11. Credit Requirements

Separate Credit Ledger

---

Capabilities

Credit Limit

Credit Usage

Credit Settlement

Credit Approval

Credit Suspension

---

# 12. Document Intelligence Requirements

Supported Documents

Pharmacy Bills

Prescriptions

Lab Reports

Dental Reports

Invoices

---

Processing Stages

Upload

Classification

Extraction

Validation

Approval

Archive

---

Document Classification

Automatic

Manual Override Supported

---

# 13. Appointment Requirements

Appointment Types

Consultation

Lab Test

Dental

Home Visit

---

Statuses

Pending

Confirmed

Completed

Cancelled

No Show

---

Reminder Requirements

24 Hours Before

1 Hour Before

---

# 14. CRM Requirements

Capabilities

Call Logs

Follow-Ups

Tasks

Complaints

Notes

---

Task Assignment

Mandatory

---

Task Escalation

Supported

---

# 15. Notification Requirements

Channels

Push

SMS

Future WhatsApp

---

Events

OTP

Transaction Success

Appointment Reminder

Report Upload

Follow-Up Reminder

Membership Approval

---

Delivery Tracking

Required

---

# 16. Reporting Requirements

Export Formats

PDF

Excel

CSV

---

Required Reports

Customer Report

Membership Report

Wallet Report

Credit Report

Appointment Report

CRM Report

Revenue Report

Document Report

---

# 17. Security Requirements

Encryption

HTTPS

TLS 1.3

---

Passwords

Argon2

---

JWT

Required

---

Sensitive Data

Encrypted At Rest

---

Audit Logging

Mandatory

---

# 18. Audit Requirements

Track

Login

Logout

Customer Creation

Customer Update

Membership Approval

Wallet Activity

Credit Activity

Document Upload

Document Approval

Appointment Activity

CRM Activity

Admin Actions

---

Audit Rules

Append Only

No Modification

No Deletion

---

# 19. Performance Requirements

API Response

Average

\< 500ms

---

Search

\< 2 Seconds

---

Document Upload

\< 10 Seconds

---

Dashboard Load

\< 3 Seconds

---

Concurrent Users

Minimum

500

Target

5000+

---

# 20. Availability Requirements

Target Uptime

99.5%

---

Backup

Daily

---

Retention

90 Days

---

Disaster Recovery

Required

---

# 21. Infrastructure Requirements

Environment

Development

Testing

Staging

Production

---

Deployment

Docker

---

Web Server

Nginx

---

Monitoring

Prometheus

Grafana

---

Logging

Winston

Structured Logs

---

# 22. API Requirements

Protocol

HTTPS

---

Format

JSON

---

Versioning

/api/v1

---

Authentication

Bearer Token

---

Rate Limiting

Enabled

---

Swagger Documentation

Mandatory

---

# 23. PWA Requirements

Installable

Yes

---

Offline Mode

Yes

---

Service Worker

Required

---

Cache Strategy

Network First

API

Cache First

Assets

---

Push Notifications

Supported

---

# 24. Mobile Requirements

Android APK

Required

---

Android App Bundle

Required

---

Background Notifications

Required

---

QR Scanner

Required

---

Camera Upload

Required

---

PDF Upload

Required

---

# 25. Compliance Requirements

Audit Trails

Mandatory

---

Medical Record Security

Mandatory

---

Data Retention

Configurable

---

Customer Consent Tracking

Required

---

# 26. Non-Functional Requirements

Scalable

Maintainable

Testable

Secure

Auditable

Modular

Extensible

Offline Capable

API First

Mobile First

---

# 27. Acceptance Criteria

The system shall be accepted when:

* All FRD requirements are implemented

* All APIs are documented

* RBAC is enforced

* ABAC is enforced

* Ledger system functions correctly

* Document Intelligence Engine operates correctly

* Audit logging is functional

* PWA passes installation tests

* Android APK passes production testing

End of Technical Requirements Document.