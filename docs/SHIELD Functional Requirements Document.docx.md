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

* **Wallet**: Cash Wallet, Reward Points, Transaction History, Applied SHIELD Benefits

* **Services**: Pharmacy, Lab, Homecare, Dental Consultation, Doctor Consultation, Cosmetic Consultation, Dietitian Consultation

* **Appointments**: Book appointments, Tele-consultation, Online Video consultation

* **Referral**: Referral Code, Referral Tree (own subtree only), Points Summary

---

## SHIELD Agent

Access:

* Customer Registration

* Membership Creation

* Referral Tree for Owned Customers

* Wallet Recharge / Manual Assistance for Owned Customers

---

## CRM Executive

Access:

* Follow-ups

* Tasks

* Complaints

* Notes

* Assigned Customer Retention View

---

## Service Providers (Pharmacy, Lab, Doctor, Homecare, Dental, Cosmetic, Dietitian)

Access:

* **Customer Card Utilisation**: Scan QR/Card and record service utilization under local rules.

* **Documents & Medical Records**: View/upload records for assigned or validly-related customers only

* **Service Workflow**: Appointments, bills, reports, prescriptions, or visit notes based on provider type

---

## Admin

Access:

* Full platform access

* User / Role / Permission Management

* Business Rules and Benefit Configuration

* Referral Analytics

* System Reports and Operations Center

---

# 3. Identity & Access Module

## Features

* Customer Mobile OTP Login

* Internal User Google Sign-In (Firebase)

* Role & Permission Assignment

* Session Management

* Device Tracking

## Functional Requirements

FR-001.1

System shall authenticate Customers using Mobile OTP.

FR-001.2

System shall authenticate Staff, Service Providers, and Admins using Firebase Google Sign-In and server-side Firebase ID token verification.

FR-002

System shall assign roles during onboarding.

FR-003

System shall restrict access using RBAC with scoped access enforcement.

FR-004

System shall apply scope and relationship-based access policies on every request.

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

* Cash, Reward Points, and Hidden SHIELD Benefit Ledger Segregation

* Customer Balance Recharge (Cash)

* Delayed Referral Points Crediting

* Benefit Application Tracking (Hidden from customer balance)

* Balance Deduction

* Credit Facility

* Ledger Tracking

FR-017

System shall maintain a ledger-based balance model.

FR-017.1

System shall track Cash balances separately (recharged or preloaded amounts).

FR-017.2

System shall track Reward Points separately and only credit them after referral qualification rules have been satisfied.

FR-017.3

System shall maintain a hidden SHIELD Benefit ledger for company-funded promotional credit.

FR-017.4

System shall never expose remaining SHIELD Benefit balance in the customer wallet UI; only applied benefit amounts may be shown per transaction.

FR-018

System shall record every transaction.

FR-019

System shall support recharge transactions.

FR-020

System shall support promotional and referral credits to the Reward Points sub-ledger and promotional service subsidies to the hidden SHIELD Benefit ledger.

FR-021

System shall support manual adjustments to Cash, Reward Points, or SHIELD Benefit ledgers based on role and policy.

FR-022

System shall calculate current Cash, Reward Points, and SHIELD Benefit balances dynamically from ledger entries.

FR-023

System shall maintain transaction audit trails.

Transaction Types:

* Opening Balance

* Recharge (Cash)

* Referral Credits (Reward Points)

* Benefit Grant (Hidden)

* Purchase (Debited from Cash)

* Reward Redemption

* Benefit Application

* Discount

* Adjustment

* Credit

* Reversal

---

# 7. Referral & Rewards Module

## Features

* Referral Code per Customer

* Customer Referral Tree (own subtree only)

* Agent Referral Tree for Owned Customers

* Delayed Referral Qualification Workflow

* Reward Points Ledger

* Reward Redemption Rules

FR-024

System shall assign each customer a unique referral code.

FR-025

System shall store customer-to-customer referral relationships using a parent-child graph.

FR-026

System shall support referral reward statuses: Pending, Verified, Qualified, Rewarded, and Rejected.

FR-027

System shall only credit referral reward points after the referred customer completes the first eligible qualifying transaction.

FR-028

System shall allow customers to view only their own referral subtree.

FR-029

System shall allow admins to view platform-wide referral analytics.

FR-030

System shall redeem reward points only through configured business rules and never through bank, UPI, or cash withdrawal.

---

# 8. Credit Facility Module

## Features

* Credit Limits

* Credit Usage

* Credit Settlement

FR-031

System shall maintain customer credit accounts.

FR-032

System shall track credit utilization.

FR-033

System shall track outstanding balances.

FR-034

System shall support manager approval workflows.

---

# 9. Customer Verification Module

Methods:

* QR Code

* Membership ID

* Mobile Number

FR-035

System shall support OTP verification.

FR-036

System shall support QR verification.

FR-037

System shall support card number verification.

---

# 10. Document Intelligence Engine

Purpose:

Secure document storage with optional downstream extraction workflows.

## Supported Documents

* Pharmacy Bills

* Prescriptions

* Lab Reports

* Dental Reports

* Invoices

### Processing Workflow

Upload ↓ Storage ↓ Metadata Capture ↓ Optional Classification/Extraction ↓ Validation ↓ Approval

FR-038

System shall support PDF uploads.

FR-039

System shall support image uploads.

FR-040

System shall retain the original uploaded file without destructive conversion.

FR-041

System shall capture document metadata and access controls at upload time.

FR-042

System may run optional document classification or extraction workflows outside the critical customer upload path.

FR-043

System shall allow manual review or validation for extracted document intelligence data.

FR-044

System shall maintain processing logs.

---

# 11. Pharmacy Module

## Features

* Bill Upload

* Prescription Upload (Staff & Customer Interface)

* Purchase Tracking

* Regularly Purchased Products Preloading

* Centralized Pricing Evaluation

FR-045

System shall allow pharmacy staff to upload bills.

FR-045.1

System shall allow customers to upload prescriptions directly from their mobile interface.

FR-046

System shall store uploaded prescriptions as original medical documents even when no extraction workflow is triggered.

FR-047

System shall evaluate pharmacy pricing through a centralized pricing engine rather than module-local UI calculations.

FR-048

System shall not apply SHIELD Benefit promotional credit to pharmacy medicine billing.

FR-049

System shall record purchases.

FR-050

System shall maintain purchase history.

FR-050.1

System shall preload regularly used products in the customer's interface based on past purchase history.

FR-050.2

System may preload customer-specific regular products, but pricing and entitlements must still be evaluated server-side.

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

# 19. Admin Module

Features:

* User Management

* Role Management

* Business Management

* Membership Configuration

* Discount Rules

* Service Benefit Rules

* Reward Redemption Rules

* Referral Analytics and Referral Operations

FR-079

System shall manage users.

FR-080

System shall manage roles.

FR-081

System shall manage permissions.

FR-082

System shall manage businesses.

FR-083

System shall manage departments.

FR-084

System shall manage membership plans.

FR-085

System shall centrally manage service benefit eligibility, maximum benefit rules, and referral qualification rules.

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
