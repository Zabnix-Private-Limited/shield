# SHIELD Technical Design Architecture (TDA)

Version: 1.0

Project: SHIELD

Document Type: Technical Design Architecture

Platform:

* Android Application

* Web Application

* Progressive Web App (PWA)

* Future iOS Application

---

# 1. Architecture Overview

SHIELD follows a modern modular architecture.

Architecture Style:

Client Layer  
      ↓  
API Gateway Layer  
      ↓  
Application Layer  
      ↓  
Domain Layer  
      ↓  
Data Layer  
      ↓  
PostgreSQL \+ Object Storage

---

# 2. High-Level System Architecture

Flutter Application  
(Android/Web/PWA)

        ↓

REST API

        ↓

NestJS Backend

        ↓

Application Services

        ↓

Business Modules

        ↓

PostgreSQL Database

        ↓

Object Storage

---

# 3. Frontend Architecture

Technology:

Flutter

Targets:

* Android

* Web

* PWA

* iOS (Future)

Architecture:

Feature-First Clean Architecture

Presentation Layer  
      ↓  
Application Layer  
      ↓  
Domain Layer  
      ↓  
Data Layer

State Management:

Riverpod

Routing:

GoRouter

Networking:

Dio

Local Storage:

Hive

Secure Storage:

Flutter Secure Storage

---

# 4. Backend Architecture

Technology:

NestJS

Pattern:

Modular Monolith

Reason:

* Easier deployment

* Lower operational cost

* Fast development

* Easier maintenance

Future:

Can evolve into microservices.

---

# 5. Core Backend Modules

## Authentication Module

Responsibilities:

* Login

* OTP Verification

* Session Validation

---

## User Module

Responsibilities:

* User Management

* Role Management

* Permission Management

---

## Customer Module

Responsibilities:

* Registration

* Verification

* Profile Management

---

## Membership Module

Responsibilities:

* Membership Plans

* Card Generation

* Membership Lifecycle

---

## Wallet Module

Responsibilities:

* Ledger

* Balance Calculation

* Recharges

* Adjustments

---

## Credit Module

Responsibilities:

* Credit Accounts

* Credit Transactions

* Credit Limits

---

## Healthcare Module

Responsibilities:

* Prescriptions

* Reports

* Consultations

* Dental Records

---

## Appointment Module

Responsibilities:

* Scheduling

* Status Tracking

---

## CRM Module

Responsibilities:

* Tasks

* Follow-Ups

* Complaints

---

## Notification Module

Responsibilities:

* Push Notifications

* SMS

* Future WhatsApp

---

## Reporting Module

Responsibilities:

* Dashboards

* Exports

---

## Audit Module

Responsibilities:

* Activity Tracking

* Compliance

---

# 6. Security Architecture

Authentication:

OTP

Authorization:

RBAC

* ABAC

---

# RBAC

Role Controls:

* Customer

* Pharmacy Staff

* Clinic Staff

* Dental Staff

* CRM Executive

* Shield Executive

* Manager

* Super Admin

---

# ABAC

Rules Based On:

* Business

* Department

* Record Type

* Ownership

* Visibility

Example:

Clinic Staff

Can View:

Clinical Records

Cannot View:

Dental Records

---

# 7. Database Architecture

Database:

PostgreSQL

Approach:

Normalized Relational Database

Normal Form:

3NF

Primary Design Rules:

* UUID for public references

* BIGSERIAL internal IDs

* Soft delete support

* Audit logging

---

# 8. Financial Architecture

Wallet Type:

Ledger Based

Balance Formula:

Opening Balance  
\+ Credits  
\+ Recharges  
\- Purchases  
\- Adjustments  
\= Current Balance

No balance column stored.

---

# Credit Architecture

Separate Ledger

Credit Account  
        ↓  
Credit Transactions

Never mixed with wallet transactions.

---

# 9. Document Intelligence Architecture

Purpose:

Convert uploaded healthcare documents into structured data.

---

## Processing Pipeline

Upload  
↓  
Classification  
↓  
Extraction  
↓  
Validation  
↓  
Storage  
↓  
Indexing

---

## Stage 1

Document Upload

Formats:

* PDF

* JPG

* PNG

---

## Stage 2

Document Classification

Detect:

* Pharmacy Bill

* Prescription

* Lab Report

* Dental Report

* Invoice

---

## Stage 3

Text Extraction

Primary Method:

PDF Text Extraction

Used For:

* Selectable PDFs

---

## Stage 4

OCR Engine

Fallback Method

Used For:

* Scanned PDFs

* Images

---

## Stage 5

Human Validation

Required Before Save

---

## Stage 6

Structured Data Mapping

Extract:

* Date

* Provider

* Products

* Services

* Amounts

---

# 10. File Storage Architecture

Storage:

Object Storage

Options:

* Supabase Storage

* MinIO

Recommended:

MinIO

Reason:

Self-hosted Low Cost Full Control

---

# Storage Structure

documents/

customers/

prescriptions/

lab\_reports/

dental/

invoices/

audit/

---

# 11. Notification Architecture

Channels:

* Push

* SMS

* Future WhatsApp

---

## Notification Flow

Event  
↓  
Notification Queue  
↓  
Notification Service  
↓  
Delivery Channel

---

# 12. API Architecture

Style:

REST

Format:

JSON

Versioning:

/api/v1

Example:

/api/v1/customers

/api/v1/wallets

/api/v1/appointments

---

# 13. Reporting Architecture

Sources:

Operational Database

Reporting Views

Examples:

vw\_customer\_balance

vw\_wallet\_summary

vw\_membership\_summary

vw\_service\_usage

---

# 14. Audit Architecture

Every Critical Event:

User Login

Customer Update

Wallet Transaction

Document Approval

Membership Approval

Credit Adjustment

must create:

audit\_log

Entry.

Audit Logs:

Append Only

No Update

No Delete

---

# 15. PWA Architecture

Capabilities:

* Installable

* Offline Support

* Push Notifications

* Cached Assets

Components:

Flutter Web

Service Worker

Manifest

Cache Layer

---

# 16. Deployment Architecture

Production

Flutter Web  
      ↓

Nginx  
      ↓

NestJS  
      ↓

PostgreSQL  
      ↓

MinIO

---

# 17. Scalability Strategy

Phase 1

Single Server

---

Phase 2

Separate:

* App Server

* Database Server

---

Phase 3

Containerization

Docker

---

Phase 4

Kubernetes

If required.

---

# 18. Technology Stack

Frontend

* Flutter

* Riverpod

* GoRouter

* Dio

Backend

* NestJS

* TypeScript

Database

* PostgreSQL

Storage

* MinIO

Notifications

* Firebase Cloud Messaging

OCR

* Tesseract

* PDF Extraction Engine

Infrastructure

* Docker

* Nginx

---

# 19. Architecture Principles

* Modular

* Secure

* Auditable

* Scalable

* Offline Capable

* Mobile First

* API First

* Healthcare Compliant

End of Technical Design Architecture Document.