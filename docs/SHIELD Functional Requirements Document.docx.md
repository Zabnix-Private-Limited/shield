# SHIELD Functional Requirements Document (FRD)

Version: 1.0

Project: SHIELD (Sahakar Healthcare Initiative to Exempt Lifestyle Disease)

Document Type: Functional Requirements Document

---

# 1. Project Overview

SHIELD is a unified healthcare membership, customer relationship management, healthcare records, privilege card, and balance management platform for the Sahakar ecosystem.

The platform will support:

* Sahakar Hyper Pharmacy

* Sahakar Smart Clinic

* Meiodia Aesthetic Clinic

* Future Sahakar businesses

The system will operate using a unified platform architecture with RBAC and ABAC security models.

---

# 2. System Users

## Customer

Access:

* Profile

* Membership

* SHIELD Balance

* Transactions

* Documents

* Reports

* Appointments

---

## Pharmacy Staff

Access:

* Customer Verification

* Bill Upload

* Prescription Upload

* Purchase Management

---

## Clinic Staff

Access:

* Appointments

* Consultations

* Reports

* Home Visits

---

## Dental Staff

Access:

* Dental Records

* Treatments

* Reports

---

## CRM Executive

Access:

* Follow-ups

* Tasks

* Complaints

* Notes

---

## Shield Executive

Access:

* Customer Approval

* Membership Management

* Balance Adjustments

* Reversal Requests

---

## Manager

Access:

* Reports

* Analytics

* Approvals

---

## Super Admin

Access:

* Complete System

---

# 3. Identity & Access Module

## Features

* Mobile OTP Login

* Role Assignment

* Permission Assignment

* Session Management

* Device Tracking

## Functional Requirements

FR-001

System shall authenticate users using OTP.

FR-002

System shall assign roles during onboarding.

FR-003

System shall restrict access using RBAC.

FR-004

System shall apply ABAC policies on every request.

FR-005

System shall log all login activities.

---

# 4. Customer Management Module

## Features

* Customer Registration

* Customer Approval

* Profile Management

* Customer Search

## Functional Requirements

FR-006

System shall create customer records.

FR-007

System shall validate Aadhaar uniqueness.

FR-008

System shall validate mobile uniqueness.

FR-009

System shall support customer approval workflow.

FR-010

System shall support customer deactivation.

FR-011

System shall maintain customer status history.

Statuses:

* Draft

* Pending Approval

* Active

* Suspended

* Closed

---

# 5. Membership Module

## Features

* Membership Creation

* Membership Approval

* Membership Plans

Membership Types:

* Founding Member

* Standard Member

FR-012

System shall generate unique membership IDs.

FR-013

System shall generate digital membership cards.

FR-014

System shall generate QR codes.

FR-015

System shall support configurable joining fees.

FR-016

System shall support configurable discounts.

---

# 6. SHIELD Balance Module

## Features

* Balance Creation

* Recharge

* Balance Deduction

* Credit Facility

* Ledger Tracking

FR-017

System shall maintain a ledger-based balance model.

FR-018

System shall record every transaction.

FR-019

System shall support recharge transactions.

FR-020

System shall support promotional credits.

FR-021

System shall support manual adjustments.

FR-022

System shall calculate current balance dynamically.

FR-023

System shall maintain transaction audit trails.

Transaction Types:

* Opening Balance

* Recharge

* Purchase

* Discount

* Adjustment

* Credit

* Reversal

---

# 7. Credit Facility Module

## Features

* Credit Limits

* Credit Usage

* Credit Settlement

FR-024

System shall maintain customer credit accounts.

FR-025

System shall track credit utilization.

FR-026

System shall track outstanding balances.

FR-027

System shall support manager approval workflows.

---

# 8. Customer Verification Module

Methods:

* QR Code

* Membership ID

* Mobile Number

FR-028

System shall support OTP verification.

FR-029

System shall support QR verification.

FR-030

System shall support card number verification.

---

# 9. Document Intelligence Engine

Purpose:

Automated document processing.

## Supported Documents

* Pharmacy Bills

* Prescriptions

* Lab Reports

* Dental Reports

* Invoices

### Processing Workflow

Upload ↓ Classification ↓ Extraction ↓ Validation ↓ Approval ↓ Storage

FR-031

System shall support PDF uploads.

FR-032

System shall support image uploads.

FR-033

System shall classify uploaded documents.

FR-034

System shall extract text from PDFs.

FR-035

System shall use OCR for scanned files.

FR-036

System shall allow manual verification.

FR-037

System shall maintain processing logs.

FR-038

System shall retain original files.

---

# 10. Pharmacy Module

## Features

* Bill Upload

* Prescription Upload

* Purchase Tracking

FR-039

System shall allow pharmacy staff to upload bills.

FR-040

System shall extract product information.

FR-041

System shall categorize products.

FR-042

System shall record purchases.

FR-043

System shall maintain purchase history.

---

# 11. Smart Clinic Module

## Features

* Appointments

* Consultations

* Reports

* Home Visits

FR-044

System shall create appointments.

FR-045

System shall manage appointment statuses.

FR-046

System shall upload consultation records.

FR-047

System shall upload reports.

FR-048

System shall create home visit records.

FR-049

System shall maintain consultation history.

---

# 12. Dental Module

## Features

* Dental Treatments

* Treatment Plans

* Dental Reports

FR-050

System shall record dental procedures.

FR-051

System shall upload dental reports.

FR-052

System shall maintain dental history.

---

# 13. CRM Module

## Features

* Follow-Ups

* Complaints

* Notes

* Tasks

FR-053

System shall create CRM activities.

FR-054

System shall schedule follow-ups.

FR-055

System shall assign tasks.

FR-056

System shall record customer interactions.

FR-057

System shall track complaint statuses.

---

# 14. Appointment Module

FR-058

System shall support appointment booking.

FR-059

System shall support appointment approval.

FR-060

System shall send appointment reminders.

Statuses:

* Pending

* Confirmed

* Completed

* Cancelled

* No Show

---

# 15. Notification Module

Channels:

* Push Notifications

* SMS

* WhatsApp

FR-061

System shall send OTP notifications.

FR-062

System shall send balance alerts.

FR-063

System shall send appointment reminders.

FR-064

System shall send CRM reminders.

FR-065

System shall maintain notification history.

---

# 16. Audit Module

FR-066

System shall record all user activities.

FR-067

System shall record transaction activities.

FR-068

System shall record document activities.

FR-069

System shall prevent deletion of audit logs.

---

# 17. Reporting Module

Reports:

* Membership Report

* Customer Report

* Revenue Report

* Balance Report

* Credit Report

* CRM Report

* Service Usage Report

FR-070

System shall generate role-based reports.

FR-071

System shall support export to PDF.

FR-072

System shall support export to Excel.

---

# 18. Admin Module

Features:

* User Management

* Role Management

* Business Management

* Membership Configuration

* Discount Rules

FR-073

System shall manage users.

FR-074

System shall manage roles.

FR-075

System shall manage permissions.

FR-076

System shall manage businesses.

FR-077

System shall manage departments.

FR-078

System shall manage membership plans.

---

# 19. Dashboard Module

Customer Dashboard

* Membership Card

* Balance

* Transactions

* Notifications

Operational Dashboard

* New Customers

* Pending Approvals

* Pending Documents

* CRM Tasks

Management Dashboard

* Membership Growth

* Revenue

* Transactions

* Customer Retention

FR-079

System shall provide role-specific dashboards.

---

# 20. Security Requirements

FR-080

All sensitive data shall be encrypted.

FR-081

All APIs shall require authentication.

FR-082

Medical records shall be access-controlled.

FR-083

Financial transactions shall be immutable.

FR-084

System shall support audit logging.

FR-085

System shall support device tracking.

---

# 21. MVP Deliverables

Mandatory:

* Customer Management

* Membership Management

* SHIELD Balance

* Credit Framework

* Document Intelligence Engine

* Pharmacy Module

* Smart Clinic Module

* Dental Module

* CRM Module

* Appointment Module

* Notification Module

* Reporting Module

* Admin Module

* Dashboard Module

* RBAC

* ABAC

* Audit Logging

End of Document