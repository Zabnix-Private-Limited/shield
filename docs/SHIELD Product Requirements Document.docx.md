# SHIELD Product Requirements Document (PRD)

Version: 1.0

Project Name: SHIELD

Full Form: Sahakar Healthcare Initiative to Exempt Lifestyle Disease

Document Type: Product Requirements Document (PRD)

Prepared For: Sahakar Group

---

# 1. Product Overview

SHIELD is a unified healthcare engagement platform designed to connect customers, healthcare providers, pharmacies, clinics, CRM teams, and management through a single digital ecosystem.

The platform combines:

* Membership Management

* Digital Privilege Card

* Healthcare Wallet

* Customer Relationship Management (CRM)

* Healthcare Record Management

* Appointment Management

* Document Intelligence

* Reporting & Analytics

The system serves as the digital backbone for all participating Sahakar healthcare businesses.

---

# 2. Product Vision

Create a healthcare ecosystem where customers can manage healthcare spending, access services, maintain medical records, receive benefits, and interact with Sahakar healthcare businesses through a single platform.

---

# 3. Business Goals

## Customer Goals

* Easy healthcare access

* Digital healthcare records

* Healthcare spending convenience

* Membership benefits

* Faster service delivery

---

## Business Goals

* Customer retention

* Cross-business utilization

* Increased repeat purchases

* Improved customer engagement

* Centralized healthcare data

* Digital transformation

---

# 4. Product Objectives

The platform shall:

* Maintain customer profiles

* Manage memberships

* Issue SHIELD cards

* Maintain SHIELD balances

* Support healthcare transactions

* Store healthcare documents

* Manage appointments

* Track customer interactions

* Provide operational analytics

---

# 5. Target Users

## Customer

Uses SHIELD services.

---

## Pharmacy Staff

Handles pharmacy transactions.

---

## Clinic Staff

Handles consultations, reports, and appointments.

---

## Dental Staff

Handles dental treatments and reports.

---

## CRM Team

Handles customer engagement.

---

## Shield Team

Handles onboarding, verification, approvals, and support.

---

## Management

Monitors operations and performance.

---

## System Administrators

Manages platform configuration.

---

## Sahakar Group Agent

Registers customers and facilitates membership onboarding using agent codes.

---

# 6. Product Scope

## In Scope

### Membership

* Customer registration

* Membership approval

* Membership plans

* Digital cards

---

### Wallet

* Opening balance

* Recharge

* Balance deduction

* Credit support

---

### Healthcare

* Prescriptions

* Reports

* Appointments

* Consultations

* Dental records

---

### CRM

* Calls

* Tasks

* Follow-ups

* Complaints

---

### Document Processing

* PDF extraction

* OCR processing

* Document classification

---

### Analytics

* Operational reports

* Customer reports

* Revenue reports

---

# 7. Out of Scope

Version 1 excludes:

* Disease prediction

* AI diagnosis

* Automated treatment recommendations

* Insurance integration

* Wearable integrations

* Telemedicine

---

# 8. Membership Model

## Founding Members

Eligibility:

* Existing RC customers

Benefits:

* Free enrollment

* Lifetime membership

---

## Standard Members

Eligibility:

* New enrollments

Benefits:

* Membership privileges

Requires:

* One-time enrollment fee

---

## Registration Rules

* **Agent-Mediated Signup**: Customer registration is strictly through Sahakar Group agents. Customer creation requires a valid `agent_code` of the agent who initiated or assisted with the creation.

## Card Utilization Rules

* **Hyperpharmacies Restriction**: Customers cannot use the card at another location if it was purchased from a store in the case of hyperpharmacies (retaining customers within their local branch).
* **Cross-Provider Compatibility**: The card can be utilized at clinics, cosmetic consulting, dental consulting, homecare, and other general service providers regardless of their locations.
* **Customer Retention Focus**: The card's primary business driver is to retain and engage customer spending within their local Sahakar hyperpharmacies.

---

# 9. Wallet Model

The SHIELD Balance operates as a prepaid healthcare spending account and contains segregated sub-ledgers.

## Wallet Options

* **Cash**: Customer's recharged or preloaded amount (real money loaded into the account).
* **Points**: Promotional balance earned via the referral loop. Referral points are automatically added to the customer's wallet following the successful registration of a new customer who signs up using their referral code.
* **Transaction History**: An immutable ledger of all wallet transactions (credits, debits, adjustments, and referrals).

## Characteristics:

* Customer-owned

* Rechargeable

* Non-transferable

* Non-withdrawable

* Ecosystem-restricted

---

# 10. Credit Model

Selected customers may receive credit facilities.

Approval Factors:

* Membership history

* Purchase behavior

* Payment reliability

Credit can be:

* Automated

* Manually approved

---

# 11. Customer Verification

Supported Methods:

* QR Code

* Membership Number

* Mobile Number

* OTP Verification

---

# 12. Document Intelligence Engine

Purpose:

Convert uploaded documents into structured records.

Supported Inputs:

* PDFs

* Images

Supported Outputs:

* Purchases

* Prescriptions

* Reports

* Service records

Workflow:

Upload ↓ Classification ↓ Extraction ↓ Validation ↓ Storage

---

# 13. Healthcare Records

The system shall maintain:

### Prescriptions

Doctor-issued prescriptions.

### Lab Reports

Laboratory test results.

### Dental Records

Dental treatments and procedures.

### Consultation Records

Clinical visit history.

### Home Visit Records

Healthcare services delivered at home.

---

# 14. Appointment System

Supported Appointment Types:

* Consultation

* Lab Test

* Dental Appointment

* Home Visit

Statuses:

* Pending

* Confirmed

* Completed

* Cancelled

* No Show

---

# 15. CRM System

Purpose:

Maintain customer engagement.

Capabilities:

* Follow-ups

* Notes

* Tasks

* Complaints

* Customer interactions

---

# 16. Security Model

## Authentication

* **Customer Authentication**: Mobile OTP-based authentication (phone number login).
* **Staff & Service Provider Authentication**: Email sign-in (email and password credentials).

---

## Authorization

RBAC

Role-based permissions.

ABAC

Attribute-based visibility rules.

---

## Audit

Every critical action shall be recorded.

No deletion permitted.

---

# 17. Dashboard Requirements

## Customer Dashboard

Must support mobile-first layout. Sections:

* **Wallet**: Separate Cash and Points ledger views, and Transaction History.
* **Services**: 
  * Pharmacy: Prescription Upload, regularly bought products, and similar patient suggestions.
  * Lab: Directory of lab tests and booking.
  * Homecare: Homecare assistance plan listings.
  * Dental Consultation: Doctor booking, tele-consultation, and video consultation.
  * Doctor Consultation: Doctor booking, tele-consultation, and video consultation.
  * Cosmetic Consultation: Doctor booking, tele-consultation, and video consultation.
  * Dietitian Consultation: Consultation booking and preset plans list.
* **Profile**: Name, Address, Pincode, Phone number, DOB (with auto age calculation), Blood Group.

---

## Service Provider Dashboard

Must support desktop-locked layout. Sections:

* **Customer Card Utilization**: Verify customer digital privilege cards, read QR codes, and record service utilization at clinics, dental centers, pharmacies, etc.

---

## Admin Dashboard

Must support desktop-locked layout. Sections:

* **Branch-wise IDs List**: Directory of registered customer IDs grouped by hyperpharmacy branch and store of registration.
* **IDs Service Utilization**: Track utilization statistics of SHIELD cards across various service providers.
* **Reports**: System revenue, retention metrics, and utilization audits.

---

## CRM Dashboard

Displays:

* Tasks

* Follow-ups

* Complaints

---

## Management Dashboard

Displays:

* Membership Growth

* Revenue

* Customer Retention

* Service Usage

---

# 18. Notifications

Channels:

* Push Notifications

* SMS

* WhatsApp (Future)

Supported Events:

* OTP

* Transaction Success

* Appointment Reminder

* Report Availability

* Follow-Up Reminder

---

# 19. Reporting

Supported Reports:

* Membership Report

* Revenue Report

* Wallet Report

* Credit Report

* CRM Report

* Healthcare Utilization Report

* Document Processing Report

Export Formats:

* PDF

* Excel

---

# 20. Success Metrics

Customer Metrics:

* Active Members

* Membership Growth

* Customer Retention

Operational Metrics:

* Transaction Volume

* Appointment Volume

* Service Utilization

Business Metrics:

* Revenue Growth

* Repeat Purchases

* Wallet Usage

---

# 21. Platform Targets

Primary:

* Android Application

Secondary:

* Web Application

* Progressive Web App (PWA)

Future:

* iOS Application

---

# 22. Product Deliverables

Version 1 Deliverables:

* Membership Platform

* SHIELD Card

* Wallet

* Credit Framework

* Customer Management

* CRM

* Healthcare Records

* Appointments

* Document Intelligence Engine

* Notifications

* Reports

* Admin Panel

* Audit Logging

* RBAC

* ABAC

End of Product Requirements Document.