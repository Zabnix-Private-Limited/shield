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

Bottom Navigation (Mobile first)

```text id="9a2q6w"
Wallet (Cash, Points, Transactions)
Services (Pharmacy, Lab, Homecare, Consultations)
Profile (Personal Info, DOB/Age, Blood Group)
```

---

## Service Providers (Staff)

Sidebar Navigation (Desktop locked)

```text id="m7fymg"
Dashboard
Customer Card Utilisation (QR Scan / Manual verify)
Appointments
Documents (Prescription/Bill upload)
CRM
Reports
Settings
```

---

## Admin

Sidebar Navigation (Desktop locked)

```text id="uk7l3g"
Dashboard
Branch-wise IDs List
IDs Service Utilization
Users & Roles
System Settings
Reports
```

---

# 3. Login Screens

## Customer Login Screen (Mobile & OTP)

### Screen 1.1: Mobile Number Entry

Components:
- Mobile Number Input Field
- Continue / Send OTP Button
- Sahakar Branding

Layout:
```text id="q0zh6u"
Logo
Welcome Customers
[Mobile Number Input]
[Continue (Send OTP) Button]
```

### Screen 1.2: OTP Verification

Components:
- 6-digit OTP Input Fields
- Resend OTP Link (with countdown)
- Verify & Sign In Button

Layout:
```text
Logo
Verification Code Sent
[ _ _ _ _ _ _ OTP Fields ]
[Verify & Sign In Button]
[Resend OTP Link (after 30s)]
```

---

## Staff & Service Provider Login Screen (Email & Password)

### Screen 2.1: Email Sign-In

Components:
- Email Input Field
- Password Input Field
- Sign In Button
- Portal Select Dropdown (Pharmacy Portal, Clinic Portal, Dental Portal, Admin Portal, CRM Portal)

Layout:
```text
Logo
Welcome Staff & Service Providers
[Email Address Input]
[Password Input]
[Select Portal Dropdown]
[Sign In Button]
```

---

# 4. Customer Dashboard

Purpose: Primary customer landing page (mobile-first).

## Layout & Components

```text id="x0jtw7"
Header: Branding & Profile Avatar
---------------------------------
[Digital Membership Privilege Card]
- Customer Name
- Membership ID & QR Code
- Local Store of Purchase/Registration
---------------------------------
[Wallet Summary Card]
- Cash: $XXXX.XX  |  Points: XXX pts
- [Recharge Button]
---------------------------------
[Services Quick Grid]
[Pharmacy] [Lab] [Homecare]
[Doctor]   [Dental] [Cosmetic] [Dietitian]
---------------------------------
[Recent Activity / Appointments]
```

---

# 5. Wallet Module

## Wallet Dashboard

Displays segregated sub-ledger cards:
- **Cash Card**: Recharged or preloaded amount. Includes a button to request a manual recharge.
- **Points Card**: Points earned from referring other customers (credited after successful registration of referred user with referral code).
- **Transaction History List**: Immutable list of transactions.
  - Filters: Date Range, Sub-ledger type (Cash / Points), Transaction Type (Recharge, Referral Credit, Purchase, Reversal).

---

# 6. Customer Profile

## Profile Screen

Displays personal details and auto-calculated age:
- **Full Name**
- **Phone Number** (Verified)
- **Email Address**
- **Date of Birth** (Auto-calculates age dynamically e.g., "DOB: 1990-05-15 (Age: 36)")
- **Blood Group** (Selectable dropdown of valid groups)
- **Address Details**: Address Line 1, Address Line 2, City, District, State, Pincode
- **Onboarding Agent Code**: The code of the agent who helped register the customer.

---

# 7. Customer Services Modules

## Pharmacy Screen
- **Prescription Upload Option**: Camera capture or file picker to upload doctor prescriptions.
- **Regular Products Section**: Preloaded list of regularly bought products for fast repeat purchase.
- **Suggestions Slider**: Product suggestions matching "other patients' products which they usually buy".

## Laboratory Services Screen
- **Lab Services List**: Searchable directory of lab tests (e.g., Blood Sugar, Thyroid Profile, Lipid Profile).
- **Booking Form**: Date/time slot booking with home-collection option.

## Homecare Services Screen
- **Homecare Assistance List**: Searchable directory of home visits and homecare plans (e.g., Nursing care, Physiotherapy, Elderly care).

## Consultations (Doctor / Dental / Cosmetic / Dietitian)
- **Consultation Selection**: List of available consultants and doctors.
- **Consultation Modes**: Select between In-Person appointment, Tele-consultation (Audio call), or Online Video consultation.
- **Dietitian Presets**: Browse dietitian consultations and view the list of preset diet plans.

---

# 9. Service Provider & Card Utilization Screens

## Customer Card Utilisation Screen
* **Verification Methods**: Scan QR Code using camera scanner or manually input Membership Number or Mobile Number.
* **Store Rule Check Banner**:
  - If card is used at a different Hyperpharmacy branch than the purchase branch: Display warning banner `[Error: Local store mismatch. Store-issued card cannot be utilized at other Hyperpharmacy branches.]`.
  - If card is used at clinic, cosmetic, dental, dietitian, or homecare providers: Display success banner `[Success: Cross-compatible service provider. Access granted.]`.
* **Details Panel**: Shows customer name, profile photo, DOB/Age, blood group, current Cash balance, and Points balance.
* **Deduction Form**: Select service, enter bill amount, select sub-ledger (Cash or Points), and click "Process Transaction" to log the utilization.

---

# 10. Service Provider Workplaces

## Pharmacy Staff Console
* **Prescription Verification**: Viewer for customer-uploaded or clinic-shared prescriptions.
* **Suggestive Selling Drawer**: Lists regularly bought items and similar customer suggestions.
* **Bill Processing**: Invoice uploading and wallet balance processing.

## Clinician / Consultant Console
* **Appointment Queue**: Lists daily appointments (In-Person, Tele-consultation, Video consultation).
* **Consultation Workspace**: Input diagnosis, clinical notes, and prescribe medicine.
* **Video / Tele Call Interface**: Integrates online audio/video session controls.

## Dietitian Console
* **Diet Plans Catalog**: Manage and select preset diet plans to assign to the customer profile.

---

# 11. Admin Screens

## Branch-Wise IDs Directory
* **Dashboard Filter**: Select branch location (e.g., Sahakar Hyperpharmacy - Branch A, Branch B).
* **IDs Table**: Lists Customer ID, Name, Registration Date, Issuing Agent Code, and status.

## IDs Service Utilization Table
* **Dashboard Summary**: Searchable records of SHIELD card scans.
* **Columns**: Transaction ID, Customer ID, Service Provider Name, Service Category, Amount Deducted, Ledger Type (Cash/Points), Date & Time.

## System Reports
* **Reports Generator**: Select from Membership Report, Revenue Report, Wallet Report, and Service Utilization Audits.
* **Export Options**: PDF export layout, Excel export layout.

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

* **Customer-Facing Screens**: Mobile-first and fully responsive (collapsing smoothly on narrow viewports: 1 Column on Phone, 2 Columns on Tablet, 3 Columns on Desktop with Sidebar Navigation).

* **Staff & Portal Screens**: Desktop-locked. To preserve dashboard visibility, multi-column metric grids, and side-by-side queues, these pages lock at a fixed width of `1300` pixels and scroll horizontally on smaller/mobile viewports instead of collapsing.

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