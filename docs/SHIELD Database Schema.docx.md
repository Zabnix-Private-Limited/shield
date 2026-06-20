# SHIELD Database Schema (PostgreSQL Physical Design)

Version: 1.0

Project: SHIELD

Database: PostgreSQL 16+

Schema Strategy:

* public

* auth

* audit

* reporting

---

# Naming Standards

Primary Key

id BIGSERIAL PRIMARY KEY

UUID

uuid UUID UNIQUE NOT NULL

Timestamps

created\_at TIMESTAMPTZ updated\_at TIMESTAMPTZ

Soft Delete

deleted\_at TIMESTAMPTZ NULL

Status Fields

VARCHAR(50)

---

# businesses

CREATE TABLE businesses (

id BIGSERIAL PRIMARY KEY,

uuid UUID NOT NULL UNIQUE,

code VARCHAR(50) UNIQUE NOT NULL,

name VARCHAR(255) NOT NULL,

business\_type VARCHAR(100),

status VARCHAR(50) DEFAULT ‘ACTIVE’,

created\_at TIMESTAMPTZ DEFAULT NOW(),

updated\_at TIMESTAMPTZ DEFAULT NOW()

);

Indexes:

idx\_business\_code

---

# departments

CREATE TABLE departments (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE NOT NULL,

business\_id BIGINT NOT NULL,

code VARCHAR(50),

name VARCHAR(255),

status VARCHAR(50),

created\_at TIMESTAMPTZ DEFAULT NOW(),

updated\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY (business\_id)

REFERENCES businesses(id)

);

---

# roles

CREATE TABLE roles (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

code VARCHAR(50) UNIQUE,

name VARCHAR(255),

description TEXT

);

---

# permissions

CREATE TABLE permissions (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

code VARCHAR(100) UNIQUE,

name VARCHAR(255),

description TEXT

);

---

# role\_permissions

CREATE TABLE role\_permissions (

role\_id BIGINT,

permission\_id BIGINT,

PRIMARY KEY(role\_id, permission\_id),

FOREIGN KEY(role\_id)

REFERENCES roles(id),

FOREIGN KEY(permission\_id)

REFERENCES permissions(id)

);

---

# users

CREATE TABLE users (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE NOT NULL,

employee\_code VARCHAR(50),

first\_name VARCHAR(255),

last\_name VARCHAR(255),

mobile VARCHAR(20) UNIQUE,

email VARCHAR(255) UNIQUE,

password\_hash TEXT,

role\_id BIGINT,

department\_id BIGINT,

status VARCHAR(50),

last\_login\_at TIMESTAMPTZ,

created\_at TIMESTAMPTZ DEFAULT NOW(),

updated\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(role\_id)

REFERENCES roles(id),

FOREIGN KEY(department\_id)

REFERENCES departments(id)

);

Indexes:

idx\_user\_mobile

idx\_user\_email

idx\_user\_role

---

# customers

CREATE TABLE customers (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE NOT NULL,

customer\_code VARCHAR(50) UNIQUE,

aadhaar\_number VARCHAR(20) UNIQUE,

first\_name VARCHAR(255),

last\_name VARCHAR(255),

dob DATE,

gender VARCHAR(20),

mobile VARCHAR(20) UNIQUE,

email VARCHAR(255),

address\_line1 TEXT,

address\_line2 TEXT,

city VARCHAR(100),

district VARCHAR(100),

state VARCHAR(100),

pincode VARCHAR(20),

status VARCHAR(50),

created\_by BIGINT,

approved\_by BIGINT,

created\_at TIMESTAMPTZ DEFAULT NOW(),

updated\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(created\_by)

REFERENCES users(id),

FOREIGN KEY(approved\_by)

REFERENCES users(id)

);

Indexes:

idx\_customer\_mobile

idx\_customer\_aadhaar

idx\_customer\_name

---

# customer\_contacts

CREATE TABLE customer\_contacts (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT NOT NULL,

name VARCHAR(255),

relation VARCHAR(100),

mobile VARCHAR(20),

is\_primary BOOLEAN DEFAULT FALSE,

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(customer\_id)

REFERENCES customers(id)

);

---

# membership\_types

CREATE TABLE membership\_types (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

code VARCHAR(50) UNIQUE,

name VARCHAR(255),

joining\_fee NUMERIC(12,2),

discount\_percentage NUMERIC(5,2),

credit\_eligible BOOLEAN,

status VARCHAR(50)

);

---

# memberships

CREATE TABLE memberships (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

customer\_id BIGINT UNIQUE,

membership\_type\_id BIGINT,

membership\_number VARCHAR(100) UNIQUE,

joining\_fee NUMERIC(12,2),

activation\_date DATE,

expiry\_date DATE,

status VARCHAR(50),

created\_at TIMESTAMPTZ DEFAULT NOW(),

updated\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(membership\_type\_id)

REFERENCES membership\_types(id)

);

---

# shield\_cards

CREATE TABLE shield\_cards (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

customer\_id BIGINT,

card\_number VARCHAR(100) UNIQUE,

qr\_code TEXT,

status VARCHAR(50),

issued\_at TIMESTAMPTZ,

FOREIGN KEY(customer\_id)

REFERENCES customers(id)

);

---

# wallets

CREATE TABLE wallets (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

customer\_id BIGINT UNIQUE,

status VARCHAR(50),

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(customer\_id)

REFERENCES customers(id)

);

Important:

NO BALANCE COLUMN

Balance is calculated.

---

# wallet\_transactions

CREATE TABLE wallet\_transactions (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

wallet\_id BIGINT,

transaction\_type VARCHAR(50),

amount NUMERIC(15,2),

reference\_type VARCHAR(100),

reference\_id BIGINT,

remarks TEXT,

created\_by BIGINT,

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(wallet\_id)

REFERENCES wallets(id),

FOREIGN KEY(created\_by)

REFERENCES users(id)

);

Indexes:

idx\_wallet\_transaction\_wallet

idx\_wallet\_transaction\_type

idx\_wallet\_transaction\_date

---

# credit\_accounts

CREATE TABLE credit\_accounts (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

customer\_id BIGINT UNIQUE,

credit\_limit NUMERIC(15,2),

available\_credit NUMERIC(15,2),

outstanding\_amount NUMERIC(15,2),

status VARCHAR(50),

FOREIGN KEY(customer\_id)

REFERENCES customers(id)

);

---

# credit\_transactions

CREATE TABLE credit\_transactions (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

credit\_account\_id BIGINT,

transaction\_type VARCHAR(50),

amount NUMERIC(15,2),

remarks TEXT,

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(credit\_account\_id)

REFERENCES credit\_accounts(id)

);

---

# service\_providers

CREATE TABLE service\_providers (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

business\_id BIGINT,

provider\_name VARCHAR(255),

provider\_type VARCHAR(100),

status VARCHAR(50),

FOREIGN KEY(business\_id)

REFERENCES businesses(id)

);

---

# products

CREATE TABLE products (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

product\_code VARCHAR(100),

product\_name VARCHAR(255),

brand VARCHAR(255),

category\_id BIGINT,

unit VARCHAR(50)

);

---

# product\_categories

CREATE TABLE product\_categories (

id BIGSERIAL PRIMARY KEY,

name VARCHAR(255)

);

---

# purchases

CREATE TABLE purchases (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

customer\_id BIGINT,

provider\_id BIGINT,

invoice\_number VARCHAR(255),

total\_amount NUMERIC(15,2),

discount\_amount NUMERIC(15,2),

payable\_amount NUMERIC(15,2),

purchase\_date TIMESTAMPTZ,

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(provider\_id)

REFERENCES service\_providers(id)

);

---

# purchase\_items

CREATE TABLE purchase\_items (

id BIGSERIAL PRIMARY KEY,

purchase\_id BIGINT,

product\_id BIGINT,

quantity NUMERIC(12,2),

unit\_price NUMERIC(15,2),

total\_price NUMERIC(15,2),

FOREIGN KEY(purchase\_id)

REFERENCES purchases(id),

FOREIGN KEY(product\_id)

REFERENCES products(id)

);

---

# appointments

CREATE TABLE appointments (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

customer\_id BIGINT,

provider\_id BIGINT,

appointment\_type VARCHAR(50),

appointment\_date TIMESTAMPTZ,

status VARCHAR(50),

remarks TEXT,

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(provider\_id)

REFERENCES service\_providers(id)

);

---

# consultations

CREATE TABLE consultations (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

appointment\_id BIGINT,

doctor\_name VARCHAR(255),

diagnosis TEXT,

notes TEXT,

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(appointment\_id)

REFERENCES appointments(id)

);

---

# documents

CREATE TABLE documents (

id BIGSERIAL PRIMARY KEY,

uuid UUID UNIQUE,

customer\_id BIGINT,

uploaded\_by BIGINT,

document\_type VARCHAR(100),

file\_name VARCHAR(255),

storage\_path TEXT,

file\_size BIGINT,

mime\_type VARCHAR(100),

status VARCHAR(50),

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(uploaded\_by)

REFERENCES users(id)

);

---

# document\_classifications

CREATE TABLE document\_classifications (

id BIGSERIAL PRIMARY KEY,

document\_id BIGINT,

classification VARCHAR(100),

confidence NUMERIC(5,2),

FOREIGN KEY(document\_id)

REFERENCES documents(id)

);

---

# document\_extractions

CREATE TABLE document\_extractions (

id BIGSERIAL PRIMARY KEY,

document\_id BIGINT,

extracted\_text TEXT,

confidence\_score NUMERIC(5,2),

extraction\_status VARCHAR(50),

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(document\_id)

REFERENCES documents(id)

);

---

# document\_processing\_logs

CREATE TABLE document\_processing\_logs (

id BIGSERIAL PRIMARY KEY,

document\_id BIGINT,

stage VARCHAR(100),

status VARCHAR(50),

remarks TEXT,

processed\_at TIMESTAMPTZ,

FOREIGN KEY(document\_id)

REFERENCES documents(id)

);

---

# prescriptions

CREATE TABLE prescriptions (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

consultation\_id BIGINT,

document\_id BIGINT,

issue\_date DATE,

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(consultation\_id)

REFERENCES consultations(id),

FOREIGN KEY(document\_id)

REFERENCES documents(id)

);

---

# lab\_reports

CREATE TABLE lab\_reports (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

appointment\_id BIGINT,

document\_id BIGINT,

report\_date DATE,

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(appointment\_id)

REFERENCES appointments(id),

FOREIGN KEY(document\_id)

REFERENCES documents(id)

);

---

# dental\_records

CREATE TABLE dental\_records (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

appointment\_id BIGINT,

treatment\_name VARCHAR(255),

notes TEXT,

FOREIGN KEY(customer\_id)

REFERENCES customers(id)

);

---

# crm\_activities

CREATE TABLE crm\_activities (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

activity\_type VARCHAR(50),

notes TEXT,

created\_by BIGINT,

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(created\_by)

REFERENCES users(id)

);

---

# crm\_tasks

CREATE TABLE crm\_tasks (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

assigned\_to BIGINT,

due\_date TIMESTAMPTZ,

status VARCHAR(50),

notes TEXT,

FOREIGN KEY(customer\_id)

REFERENCES customers(id),

FOREIGN KEY(assigned\_to)

REFERENCES users(id)

);

---

# complaints

CREATE TABLE complaints (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

complaint\_type VARCHAR(100),

description TEXT,

status VARCHAR(50),

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(customer\_id)

REFERENCES customers(id)

);

---

# notifications

CREATE TABLE notifications (

id BIGSERIAL PRIMARY KEY,

customer\_id BIGINT,

title VARCHAR(255),

message TEXT,

channel VARCHAR(50),

status VARCHAR(50),

sent\_at TIMESTAMPTZ,

FOREIGN KEY(customer\_id)

REFERENCES customers(id)

);

---

# audit\_logs

CREATE TABLE audit\_logs (

id BIGSERIAL PRIMARY KEY,

user\_id BIGINT,

action VARCHAR(255),

entity\_type VARCHAR(100),

entity\_id BIGINT,

old\_data JSONB,

new\_data JSONB,

ip\_address VARCHAR(100),

device\_info TEXT,

created\_at TIMESTAMPTZ DEFAULT NOW(),

FOREIGN KEY(user\_id)

REFERENCES users(id)

);

Partition by month after scale.

No update. No delete.

Append only.

---

# Reporting Views

vw\_customer\_balance

vw\_customer\_credit

vw\_membership\_summary

vw\_monthly\_revenue

vw\_service\_usage

vw\_document\_processing

vw\_crm\_performance

End of Physical Database Design.