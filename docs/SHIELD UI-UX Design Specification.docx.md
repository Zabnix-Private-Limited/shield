# SHIELD UI/UX Design Specification

Version: 1.0

Project: SHIELD

Document Type: UI/UX Design Specification

Platform Targets:

* Android App

* Web App

* Progressive Web App (PWA)

* Future iOS App

Design Philosophy:

* Healthcare First

* Minimal Learning Curve

* Role Driven Experience

* Mobile First

* Fast Access to Critical Actions

* Accessibility Focused

---

# 1. Design System

## Primary Colors

SHIELD Brand

text id="g4n3sp" Primary      \#0F172A Secondary    \#1E293B Success      \#10B981 Warning      \#F59E0B Danger       \#EF4444 Info         \#3B82F6

---

## Background Colors

text id="0t4k2j" Background       \#FFFFFF Surface          \#F8FAFC Card             \#FFFFFF Divider          \#E2E8F0

---

## Typography

Primary Font

text id="zk8o2u" Inter

Fallback

text id="bt79k6" Roboto

---

## Font Scale

text id="n5v0yy" H1   32 H2   28 H3   24 H4   20 Body 16 Small 14 Tiny 12

---

# 2. Navigation Architecture

## Customer

Bottom Navigation

\`\`\`text id=“9a2q6w” Home

Wallet

Appointments

Documents

Profile

\---

\#\# Staff

Sidebar Navigation

\`\`\`text id="m7fymg"  
Dashboard

Customers

Memberships

Transactions

Appointments

Documents

CRM

Reports

Settings

---

## Admin

Sidebar Navigation

\`\`\`text id=“uk7l3g” Dashboard

Users

Roles

Permissions

Businesses

Membership Plans

Reports

System Settings

\---

\# 3. Login Screens

\#\# Screen 1

Mobile Login

Components

\- Mobile Number Input  
\- Continue Button

Layout

\`\`\`text id="q0zh6u"  
Logo

Welcome

Mobile Number

Continue

---

## Screen 2

OTP Verification

Components

* OTP Input

* Resend OTP

* Verify Button

---

# 4. Customer Dashboard

Purpose

Primary customer landing page.

---

## Sections

### Membership Card

Displays

* Customer Name

* Membership Number

* QR Code

* Membership Type

---

### Balance Card

Displays

* Current Balance

* Credit Available

---

### Quick Actions

Buttons

* Recharge

* Appointments

* Documents

* Support

---

### Recent Activity

Displays

* Purchases

* Appointments

* Reports

---

### Notifications

Displays

* Alerts

* Reminders

* Updates

---

Layout

\`\`\`text id=“x0jtw7” Header

Membership Card

Balance

Quick Actions

Recent Activity

Notifications

\---

\# 5. Wallet Module

\#\# Wallet Dashboard

Displays

\- Current Balance  
\- Available Credit  
\- Last Transactions

\---

\#\# Transaction History

Filters

\- Date  
\- Type  
\- Amount

\---

\#\# Recharge Screen

Phase 1

Manual Request

Phase 2

Gateway Payment

\---

\# 6. Customer Profile

Sections

Personal Information

Address

Contacts

Membership

Documents

\---

Actions

\- Edit Profile  
\- Update Contact

\---

\# 7. Documents Module

\#\# Document Dashboard

Displays

\- Prescriptions  
\- Lab Reports  
\- Dental Records  
\- Invoices

\---

Filters

\- Type  
\- Date  
\- Provider

\---

\#\# Upload Screen

Components

\- File Picker  
\- Camera Upload  
\- Upload Button

\---

\# 8. Appointment Module

\#\# Appointment Dashboard

Displays

Upcoming

Completed

Cancelled

\---

Actions

Book Appointment

Reschedule

Cancel

\---

\#\# Appointment Details

Displays

Provider

Date

Status

Notes

\---

\# 9. Pharmacy Screens

\#\# Pharmacy Dashboard

Cards

\- Customer Search  
\- Upload Bill  
\- Upload Prescription

\---

\#\# Customer Search

Methods

\- QR Scan  
\- Mobile Number  
\- Membership Number

\---

\#\# Bill Upload

Components

\- Customer Verification  
\- PDF Upload  
\- Extraction Results  
\- Validation  
\- Submit

\---

Workflow

\`\`\`text id="a2c5eg"  
Search  
↓  
Verify  
↓  
Upload  
↓  
Review  
↓  
Submit

---

# 10. Clinic Screens

## Clinic Dashboard

Cards

* Appointments

* Reports

* Consultations

* Home Visits

---

## Consultation Screen

Fields

* Diagnosis

* Notes

* Attachments

---

## Report Upload

Components

* Upload PDF

* Review

* Save

---

# 11. Dental Screens

## Dental Dashboard

Cards

* Appointments

* Treatments

* Reports

---

## Treatment Screen

Fields

* Procedure

* Notes

* Attachments

---

# 12. CRM Screens

## CRM Dashboard

Widgets

* Today’s Tasks

* Pending Follow-Ups

* Complaints

---

## Follow-Up Screen

Fields

* Customer

* Notes

* Next Follow-Up Date

---

## Complaint Screen

Fields

* Complaint Type

* Description

* Status

---

# 13. Shield Team Screens

## Shield Dashboard

Widgets

* Pending Approvals

* Reversal Requests

* Membership Requests

---

## Customer Approval

Actions

* Approve

* Reject

* Request Changes

---

## Membership Management

Actions

* Activate

* Suspend

* Cancel

---

# 14. Management Dashboard

Purpose

Executive Overview

---

Widgets

### Membership Metrics

* Active Members

* New Members

---

### Revenue Metrics

* Daily Revenue

* Monthly Revenue

---

### Service Metrics

* Pharmacy Usage

* Clinic Usage

* Dental Usage

---

### Wallet Metrics

* Total Balance

* Credit Utilization

---

# 15. Admin Screens

## User Management

Table

* User

* Role

* Department

* Status

Actions

* Add

* Edit

* Disable

---

## Role Management

Create

Edit

Delete

Permissions

---

## Permission Management

Assign

Remove

Review

---

# 16. Notification Center

Displays

* Read

* Unread

* Archived

---

Actions

* Mark Read

* Delete Local Copy

---

# 17. Global Search

Available To

Staff

Managers

Admins

---

Search Types

Customer

Membership

Appointment

Document

Transaction

Complaint

---

# 18. QR Components

Customer Card

Contains

* Membership Number

* Customer ID

* Verification Token

---

Scanner

Supports

* Camera

* Manual Entry

---

# 19. Tables

Standard Features

Pagination

Sorting

Search

Export

Filters

---

# 20. Forms

Standards

Auto Save Draft

Validation

Error Highlighting

Field Help

---

# 21. Mobile Responsive Rules

Phone

1 Column Layout

---

Tablet

2 Column Layout

---

Desktop

3 Column Layout

Sidebar Navigation

---

# 22. Accessibility

Minimum Contrast Ratio

4.5:1

---

Font Scaling

Supported

---

Keyboard Navigation

Supported

---

Screen Readers

Supported

---

# 23. Empty States

Examples

No Appointments

No Documents

No Transactions

No Notifications

---

# 24. Loading States

Skeleton Loaders

Required

---

Progress Indicators

Required

---

# 25. Error States

Network Error

Permission Error

Validation Error

File Upload Error

OTP Error

---

# 26. Design Components Library

Buttons

Cards

Dialogs

Forms

Tables

Chips

Badges

Avatars

Loaders

Empty States

Charts

Notifications

QR Components

---

# 27. UI Principles

* Minimal Clicks

* Healthcare Focused

* Mobile First

* Consistent Components

* Fast Access To Critical Actions

* Role Based Experience

* Scalable Design System

End of UI/UX Design Specification.