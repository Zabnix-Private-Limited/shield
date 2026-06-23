# SHIELD Change Request Document

## CR-001 – Business Rules, Customer Experience & Agent Ecosystem Updates

Version: 1.1

Date: June 2026

Status: Approved

---

# 1. Authentication Updates

## Customer Authentication

Customers shall authenticate using:

* Mobile Number
* OTP Verification

No password required.

Workflow:

Mobile Number
↓
OTP
↓
Login

---

## Staff Authentication

The following users shall authenticate using:

* Email Address
* Password

Roles:

* PHARMACY_STAFF
* CLINIC_STAFF
* DENTAL_STAFF
* CRM_EXECUTIVE
* SHIELD_EXECUTIVE
* MANAGER
* SUPER_ADMIN

Workflow:

Email
↓
Password
↓
Login

Future:

* MFA
* OTP Secondary Authentication

---

# 2. Hyper Pharmacy Wallet Restriction Rule

Purpose:

Customer retention within the originating pharmacy branch.

Rule:

Wallet balance utilized at a Hyper Pharmacy can only be redeemed at the originating pharmacy branch where the wallet transaction was initiated.

Example:

Customer purchases card/recharges through:

Perinthalmanna Hyper Pharmacy

Allowed:

* Perinthalmanna Hyper Pharmacy

Not Allowed:

* Branch A
* Branch B
* Branch C

---

# 3. Non-Pharmacy Service Utilization Rule

For all other services:

* Smart Clinic
* Home Care
* Dental
* Cosmetic
* Dietitian
* Consultation Services

Wallet can be utilized across all approved Sahakar service providers.

No branch restriction.

---

# 4. Customer Retention Objective

Primary Business Objective:

Increase retention and repeat purchases within Hyper Pharmacies.

Secondary Objective:

Increase utilization of Sahakar healthcare services.

---

# 5. Customer Mobile Application Navigation

Bottom Navigation:

Home

Services

Wallet

Profile

More

---

# 6. Customer Home Dashboard

Sections:

Membership Card

Wallet Summary

Points Summary

Upcoming Appointments

Recent Transactions

Notifications

Recommended Services

Quick Actions

---

# 7. Wallet Module Enhancement

Wallet shall contain:

## Cash Wallet

Stores:

* Recharge Amount
* Preloaded Amount
* Promotional Cash Credits

---

## Points Wallet

Stores:

* Referral Rewards
* Loyalty Rewards
* Promotional Rewards

Points are separate from cash.

---

## Transaction History

Displays:

* Wallet Credits
* Wallet Debits
* Points Credits
* Points Debits

Filters:

* Date
* Transaction Type
* Service Provider

---

# 8. Referral System

Customer receives referral code.

Workflow:

Customer Shares Referral Code
↓
New Customer Registers
↓
Registration Approved
↓
Points Credited

Conditions:

Points only awarded after successful approval.

No points for rejected registrations.

---

# 9. Customer Services Module

## Pharmacy

Features:

* Prescription Upload
* Previous Purchases
* Frequently Purchased Products
* Product Suggestions
* Reorder Assistance

---

## Laboratory

Features:

* Lab Service Catalogue
* Test Packages
* Appointment Booking

---

## Home Care

Features:

* Home Nursing
* Home Collection
* Home Healthcare Services
* Service Requests

---

## Dental Consultation

Features:

* Appointment Booking
* Tele Consultation
* Video Consultation

---

## Doctor Consultation

Features:

* Appointment Booking
* Tele Consultation
* Video Consultation

---

## Cosmetic Consultation

Features:

* Appointment Booking
* Tele Consultation
* Video Consultation

---

## Dietitian Services

Features:

* Consultation Booking
* Diet Plans
* Nutrition Programs

---

# 10. Customer Profile Module

Fields:

* Name
* Address
* Pincode
* Phone Number
* Date of Birth
* Age (Auto Calculated)
* Blood Group
* Gender
* Membership Details

---

# 11. Service Provider Dashboard

New Module:

Customer Card Utilization

Displays:

* Customer
* Membership Number
* Service Used
* Amount Utilized
* Wallet Used
* Date

---

# 12. Admin Dashboard Enhancements

## Branch Wise Membership IDs

Displays:

* Branch
* Active IDs
* Suspended IDs
* New Registrations

---

## Service Utilization Dashboard

Displays:

* Pharmacy Utilization
* Lab Utilization
* Home Care Utilization
* Dental Utilization
* Consultation Utilization

---

## Reports

New Reports:

* Branch Utilization Report
* Wallet Utilization Report
* Points Utilization Report
* Referral Report
* Agent Performance Report

---

# 13. Agent Ecosystem

Customer self-registration is NOT permitted.

Only authorized Sahakar agents may register customers.

---

# 14. Agent Module

New Entity:

Agent

Fields:

* Agent Code
* Agent Name
* Branch
* Status
* Joining Date

---

# 15. Customer Creation Workflow

Workflow:

Agent Login
↓
Customer Registration
↓
Agent Code Captured
↓
Customer Verification
↓
Approval
↓
Membership Creation

Mandatory:

Every customer record must contain:

created_by_agent_id

---

# 16. Agent Attribution

Every customer shall be linked to:

* Registering Agent

Purpose:

* Incentives
* Performance Tracking
* Referral Analysis

---

# 17. Database Changes

New Tables:

agents

referrals

points_wallets

points_transactions

service_catalogues

service_categories

branch_wallet_rules

---

# 18. ERD Changes

Customer

├── Agent
├── Referral
├── Cash Wallet
├── Points Wallet

Agent

├── Customers
├── Referrals

Branch

├── Wallet Restriction Rules

---

# 19. API Changes

New APIs:

POST /agents

GET /agents

POST /referrals

GET /referrals

GET /wallets/points

GET /wallets/cash

GET /agent-performance

GET /branch-utilization

---

# 20. UI Changes

New Screens:

Agent Dashboard

Agent Customer Registration

Referral Dashboard

Points Wallet

Service Catalogue

Tele Consultation Booking

Video Consultation Booking

Agent Performance Dashboard

---

# 21. Future AI Recommendation Engine

Future Phase:

Based on:

* Previous Purchases
* Chronic Purchases
* Service Utilization
* Lab History

Provide:

* Reorder Suggestions
* Service Recommendations
* Appointment Reminders

Not part of MVP.

---

# Mandatory Update Instruction

All existing project documents including:

* PRD
* FRD
* ERD
* Database Schema
* TDA
* TRD
* Workflow
* UIUX
* API Specification

must be updated to incorporate this Change Request Document.

This document supersedes conflicting sections in previous versions.

End of CR-001
