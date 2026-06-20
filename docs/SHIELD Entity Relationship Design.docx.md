# SHIELD Entity Relationship Design (ERD)

Version: 1.0

Project: SHIELD

---

# Core Domains

1. Identity & Access

2. Customer Management

3. Membership Management

4. Wallet & Ledger

5. Healthcare Records

6. Document Intelligence

7. Appointments

8. CRM

9. Notifications

10. Audit & Compliance

---

# Identity & Access Domain

## users

Purpose: System users.

Fields:

* id (PK)

* uuid

* employee\_code

* first\_name

* last\_name

* mobile

* email

* password\_hash

* role\_id

* department\_id

* status

* last\_login\_at

* created\_at

* updated\_at

Relationship:

users → roles

users → departments

---

## roles

Fields:

* id (PK)

* code

* name

* description

Examples:

* CUSTOMER

* PHARMACY\_STAFF

* CLINIC\_STAFF

* DENTAL\_STAFF

* CRM\_EXECUTIVE

* SHIELD\_EXECUTIVE

* MANAGER

* SUPER\_ADMIN

---

## permissions

Fields:

* id

* code

* name

* description

---

## role\_permissions

Fields:

* role\_id

* permission\_id

---

## departments

Fields:

* id

* business\_id

* code

* name

---

## businesses

Fields:

* id

* code

* name

* type

Examples:

* Pharmacy

* Clinic

* Dental

---

# Customer Domain

## customers

Fields:

* id

* customer\_code

* membership\_id

* aadhaar\_number

* first\_name

* last\_name

* dob

* gender

* mobile

* email

* address

* city

* state

* pincode

* status

* created\_by

* approved\_by

* created\_at

* updated\_at

Relationship:

Customer → Membership

Customer → Wallet

Customer → Documents

Customer → Appointments

Customer → CRM Activities

Customer → Customer Status History

---

## customer_contacts

Fields:

* id

* customer_id

* name

* relation

* mobile

* is_primary

Purpose:

Emergency and family contacts.

---

## customer_status_history

Fields:

* id

* uuid

* customer_id

* old_status

* new_status

* changed_by

* remarks

* created_at

Purpose:

Track all customer status changes (draft → pending approval → active → suspended → closed).

Relationship:

Customer Status History → Customer

Customer Status History → User (changed_by)

---

# Membership Domain

## memberships

Fields:

* id

* customer\_id

* membership\_type\_id

* membership\_number

* joining\_fee

* activation\_date

* expiry\_date

* status

---

## membership\_types

Fields:

* id

* code

* name

* joining\_fee

* default\_discount\_percentage

* credit\_eligible

Examples:

* FOUNDING\_MEMBER

* STANDARD\_MEMBER

---

## shield\_cards

Fields:

* id

* customer\_id

* card\_number

* qr\_code

* status

* issued\_at

---

# Wallet Domain

## wallets

Fields:

* id

* customer\_id

* status

* created\_at

No balance column.

Balance calculated from ledger.

---

## wallet\_transactions

Fields:

* id

* wallet\_id

* transaction\_type

* amount

* reference\_type

* reference\_id

* remarks

* created\_by

* created\_at

Types:

* OPENING\_BALANCE

* RECHARGE

* PURCHASE

* DISCOUNT

* CREDIT

* REVERSAL

* ADJUSTMENT

---

## credit\_accounts

Fields:

* id

* customer\_id

* credit\_limit

* available\_credit

* outstanding\_amount

* status

---

## credit\_transactions

Fields:

* id

* credit\_account\_id

* transaction\_type

* amount

* remarks

* created\_at

---

# Purchase Domain

## purchases

Fields:

* id

* customer\_id

* provider\_id

* invoice\_id

* total\_amount

* discount\_amount

* payable\_amount

* purchase\_date

---

## purchase\_items

Fields:

* id

* purchase\_id

* product\_id

* quantity

* unit\_price

* total\_price

---

## products

Fields:

* id

* product\_code

* product\_name

* category\_id

* brand

* unit

---

## product\_categories

Fields:

* id

* category\_name

---

# Healthcare Domain

## appointments

Fields:

* id

* customer\_id

* provider\_id

* appointment\_type

* appointment\_date

* appointment\_status

* remarks

Types:

* CONSULTATION

* LAB\_TEST

* DENTAL

* HOME\_VISIT

---

## consultations

Fields:

* id

* customer\_id

* appointment\_id

* doctor\_name

* diagnosis

* notes

---

## prescriptions

Fields:

* id

* customer\_id

* consultation\_id

* document\_id

* issue\_date

---

## lab\_reports

Fields:

* id

* customer\_id

* appointment\_id

* document\_id

* report\_date

---

## dental\_records

Fields:

* id

* customer\_id

* appointment\_id

* treatment\_name

* notes

---

## home\_visits

Fields:

* id

* customer\_id

* appointment\_id

* staff\_id

* visit\_date

* notes

---

# Provider Domain

## service\_providers

Fields:

* id

* business\_id

* provider\_name

* provider\_type

* status

Examples:

* Sahakar Hyper Pharmacy

* Sahakar Smart Clinic

* Meiodia

---

# Document Intelligence Domain

## documents

Fields:

* id

* customer\_id

* uploaded\_by

* document\_type

* file\_name

* storage\_path

* upload\_date

* status

---

## document\_processing\_logs

Fields:

* id

* document\_id

* stage

* status

* processed\_at

Stages:

* Uploaded

* Classified

* Extracted

* Validated

* Approved

* Archived

---

## document\_extractions

Fields:

* id

* document\_id

* extracted\_text

* confidence\_score

* extraction\_status

---

## document\_classifications

Fields:

* id

* document\_id

* classification

Values:

* PHARMACY\_BILL

* PRESCRIPTION

* LAB\_REPORT

* DENTAL\_REPORT

* INVOICE

* UNKNOWN

---

# CRM Domain

## crm\_activities

Fields:

* id

* customer\_id

* activity\_type

* notes

* created\_by

* created\_at

Types:

* CALL

* FOLLOWUP

* VISIT

* SUPPORT

---

## crm\_tasks

Fields:

* id

* customer\_id

* assigned\_to

* due\_date

* task\_status

* notes

---

## complaints

Fields:

* id

* customer\_id

* complaint\_type

* description

* status

---

# Notification Domain

## notifications

Fields:

* id

* customer\_id

* title

* message

* channel

* sent\_at

* status

Channels:

* PUSH

* SMS

* WHATSAPP

---

# Audit Domain

## audit\_logs

Fields:

* id

* user\_id

* action

* entity\_type

* entity\_id

* old\_data

* new\_data

* ip\_address

* device\_info

* created\_at

Immutable.

No delete allowed.

---

# Customer ├── Membership ├── Shield Card ├── Wallet │ └── Wallet Transactions ├── Credit Account │ └── Credit Transactions ├── Purchases │ └── Purchase Items ├── Appointments ├── Consultations ├── Prescriptions ├── Lab Reports ├── Dental Records ├── Home Visits ├── Documents │ ├── Processing Logs │ ├── Extractions │ └── Classifications ├── CRM Activities ├── CRM Tasks ├── Complaints ├── Customer Status History └── Notifications

Users ├── Roles ├── Permissions └── Departments

Businesses ├── Departments └── Service Providers

All critical operations generate Audit Logs.

End of ERD Document.