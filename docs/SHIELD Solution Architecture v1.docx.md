# SHIELD Solution Architecture v1

## Architecture Principle

SHIELD will be a unified platform consisting of:

* Single Database

* Single Backend

* Single Flutter Application

* Single Web Admin Application

Access control will be implemented using:

* RBAC (Role-Based Access Control)

* ABAC (Attribute-Based Access Control)

Users access the same platform but are presented only with features and data permitted by their roles and attributes.

---

# RBAC Matrix

## Roles

### CUSTOMER

Can:

* View profile

* View SHIELD card

* View balance

* View transactions

* View prescriptions

* View reports

* View appointments

Cannot:

* Edit healthcare records

* Adjust balances

* Access other customers

---

### PHARMACY\_STAFF

Can:

* Verify customer

* Upload pharmacy bills

* Upload prescriptions

* View pharmacy history

Cannot:

* Access dental records

* Access clinic records

---

### CLINIC\_STAFF

Can:

* Create appointments

* Upload reports

* Upload consultations

* View clinic records

Cannot:

* Access pharmacy records

* Access dental records

---

### DENTAL\_STAFF

Can:

* Upload dental treatments

* View dental records

Cannot:

* Access clinic records

* Access pharmacy records

---

### CRM\_EXECUTIVE

Can:

* View customer profile

* Create follow-ups

* Create complaints

* Create notes

Cannot:

* Access clinical data

* Access wallet management

---

### SHIELD\_EXECUTIVE

Can:

* Create customer

* Approve customer

* Issue membership

* Manage memberships

* Approve reversals

Cannot:

* Modify healthcare records

---

### MANAGER

Can:

* View reports

* View analytics

* Approve overrides

* Approve credit requests

---

### SUPER\_ADMIN

Full system access.

---

# ABAC Rules

Every record must contain:

Business Department Record Type Visibility Level Owner

Example:

Lab Report

Business \= Smart Clinic Department \= Laboratory Visibility \= Clinical

Only authorized clinical users can access.

---

# Entity Relationship Model

## Core Identity

User Role Permission Business Department

---

## Customer

Customer Membership Shield Card

Relationship:

Customer → Membership Customer → Shield Card

---

## Wallet

Wallet Wallet Transaction Wallet Adjustment Credit Account

Relationship:

Customer → Wallet Wallet → Transactions

---

## Healthcare

Prescription Lab Report Consultation Dental Treatment Home Visit

Relationship:

Customer → Healthcare Records

---

## CRM

CRM Activity Complaint Follow-Up Task

Relationship:

Customer → CRM Activities

---

## Documents

Document Document Classification Document Processing Log

Relationship:

Customer → Documents

---

## Transactions

Purchase Invoice Service Usage

Relationship:

Customer → Purchases Customer → Services

---

# Functional Modules

## Module 1

Identity & Access

Features:

* Login

* OTP

* RBAC

* ABAC

* Session Management

---

## Module 2

Customer Management

Features:

* Registration

* Verification

* Membership Approval

* Customer Search

---

## Module 3

Membership Management

Features:

* Founding Members

* Standard Members

* Membership Plans

* Membership Approvals

---

## Module 4

SHIELD Balance

Features:

* Balance Management

* Recharges

* Adjustments

* Credits

* Discounts

---

## Module 5

Document Intelligence Engine

Purpose:

Process customer documents automatically.

Document Types:

* Pharmacy Bills

* Prescriptions

* Lab Reports

* Invoices

* Dental Reports

Workflow:

Upload ↓ Classification ↓ Extraction ↓ Validation ↓ Approval ↓ Storage

---

# Document Intelligence Engine Design

## Layer 1

Document Upload

Supported:

* PDF

* Image

---

## Layer 2

Document Classification

Identify:

* Pharmacy Bill

* Prescription

* Lab Report

* Dental Report

* Invoice

* Unknown

---

## Layer 3

PDF Text Extraction

Primary Processing Method.

Because most uploaded files contain selectable text.

Process:

PDF ↓ Extract Text ↓ Parse Data ↓ Store Structured Data

No OCR required.

---

## Layer 4

OCR Engine

Used only when:

* Scanned PDF

* Image Upload

* Non-selectable PDFs

OCR Result ↓ Human Verification ↓ Save

---

## Layer 5

Data Mapping

Extract:

Bill Number Provider Date Products Services Amounts

---

## Layer 6

Audit Layer

Store:

Original File Extracted Data User Approval Processing History

---

# Screen Inventory

## Customer Screens

Login

Dashboard

Profile

Membership Card

Wallet

Transactions

Documents

Prescriptions

Reports

Appointments

Notifications

Settings

---

## Pharmacy Screens

Dashboard

Customer Search

Customer Verification

Bill Upload

Prescription Upload

Transaction Entry

History

---

## Clinic Screens

Dashboard

Appointments

Reports

Consultations

Home Visits

Customer Records

---

## Dental Screens

Dashboard

Treatments

Reports

Customer Records

---

## CRM Screens

Dashboard

Customer List

Follow-Ups

Tasks

Complaints

Notes

Campaigns

---

## Shield Team Screens

Dashboard

Membership Approvals

Customer Verification

Balance Adjustments

Reversal Requests

Customer Management

---

## Management Screens

Dashboard

Reports

Analytics

Membership Metrics

Revenue Metrics

Customer Retention

Credit Requests

---

## Admin Screens

Users

Roles

Permissions

Businesses

Departments

Membership Plans

Discount Rules

Audit Logs

System Settings

---

# MVP Scope

Mandatory

* Customer Management

* Membership Management

* SHIELD Balance

* OTP Verification

* QR Verification

* Document Intelligence Engine

* PDF Text Extraction

* OCR Fallback

* Bill Upload

* Report Upload

* CRM

* Notifications

* Audit Logs

* RBAC

* ABAC

Excluded

* AI Recommendations

* Predictive Analytics

* Automated Credit Scoring

* Disease Prediction

* Advanced Automation

These will be Phase 2 and Phase 3 enhancements.