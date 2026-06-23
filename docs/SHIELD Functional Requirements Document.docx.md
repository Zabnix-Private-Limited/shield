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

* **Profile**: Name, Address, Pin Code, Phone Number, Date of Birth, Age, Blood Group

* **Wallet**: Cash, Points, Transaction History

* **Services**: Pharmacy, Lab, Homecare, Dental Consultation, Doctor Consultation, Cosmetic Consultation, Dietitian Consultation

* **Appointments**: Book appointments, Tele-consultation, Online Video consultation

---

## Service Providers (Pharmacy, Clinic, Dental, Cosmetic, Homecare, Dietitian Staff)

Access:

* **Customer Card Utilisation**: Scan QR/Card and record service utilization under local rules.

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

* Customer Approval (validating agent_code)

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

## Super Admin / Administrator

Access:

* Branch-wise IDs list

* IDs service utilization

* System reports

* Complete System configuration

---

# 3. Identity & Access Module

## Features

* Customer Mobile OTP Login

* Staff & Service Provider Email Login (Email/Password)

* Role & Permission Assignment

* Session Management

* Device Tracking

## Functional Requirements

FR-001.1

System shall authenticate Customers using Mobile OTP.

FR-001.2

System shall authenticate Staff, Service Providers, and Admins using Email and Password credentials.

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

* Agent-driven Customer Registration

* Customer Approval Workflow

* Profile Management (Name, Address, Pin Code, Phone Number, DOB, Blood Group)

* Age Auto-Calculation

* Customer Search

## Functional Requirements

FR-006

System shall create customer records exclusively via Sahakar Group Agents, requiring a valid `agent_code` of the initiating or assisting agent.

FR-006.1

System shall record customer profile details: first_name, last_name, address_line1, address_line2, city, district, state, pincode, mobile, dob, and blood_group.

FR-006.2

System shall automatically calculate and display the customer's age based on the provided date of birth (dob).

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

* Ledger-Based Balance Creation

* Cash & Points Ledger Segregation

* Customer Balance Recharge (Cash)

* Referral Points Crediting

* Balance Deduction

* Credit Facility

* Ledger Tracking

FR-017

System shall maintain a ledger-based balance model.

FR-017.1

System shall track Cash balances separately (recharged or preloaded amounts).

FR-017.2

System shall track Points balances separately (referrals points credited after successful registration of a referred customer).

FR-018

System shall record every transaction.

FR-019

System shall support recharge transactions.

FR-020

System shall support promotional/referral credits to the Points sub-ledger.

FR-021

System shall support manual adjustments to either Cash or Points sub-ledgers.

FR-022

System shall calculate current Cash and Points balances dynamically.

FR-023

System shall maintain transaction audit trails.

Transaction Types:

* Opening Balance

* Recharge (Cash)

* Referral Credits (Points)

* Purchase (Debited from Cash or Points)

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

* Prescription Upload (Staff & Customer Interface)

* Purchase Tracking

* Regularly Purchased Products Preloading

* Patient Suggestions (Frequently bought together by similar patients)

FR-039

System shall allow pharmacy staff to upload bills.

FR-039.1

System shall allow customers to upload prescriptions directly from their mobile interface.

FR-040

System shall extract product information.

FR-041

System shall categorize products.

FR-042

System shall record purchases.

FR-043

System shall maintain purchase history.

FR-043.1

System shall preload regularly used products in the customer's interface based on past purchase history.

FR-043.2

System shall display suggestions of other patients' products who usually buy the same regular items.

---

# 11. Smart Clinic Module

## Features

* Doctor Appointments (In-Person booking)

* Tele-Consultation (Audio appointments)

* Online Video Consultation

* Laboratory Services Directory Listing

* Homecare Services Directory Listing

* Consultations

* Reports & Records

FR-044

System shall support booking doctor appointments, tele-consultations, and online video consultations.

FR-045

System shall manage appointment statuses (Pending, Confirmed, Completed, Cancelled, No Show).

FR-046

System shall upload and link consultation records.

FR-047

System shall retrieve and display the directory listing of available Laboratory Services.

FR-048

System shall retrieve and display the directory listing of available Homecare Services.

FR-049

System shall maintain consultation, video meeting, and home visit histories.

---

# 12. Dental & Special Consultation Module

## Features

* Dental Consulting: Booking, Tele-consultation, Video consultation

* Cosmetic Consulting: Booking, Tele-consultation, Video consultation

* Dietitian Services: Doctor Consultations and Preset Diet Plans Listing

* Treatment Plans & Dental/Aesthetic Records

FR-050

System shall book dental and cosmetic consultations including tele-consultation and online video sessions.

FR-050.1

System shall retrieve and display dietitian consultations and the directory list of dietitian-prescribed preset plans.

FR-051

System shall upload dental and cosmetic reports.

FR-052

System shall maintain comprehensive dental, cosmetic, and dietitian consultation histories.

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