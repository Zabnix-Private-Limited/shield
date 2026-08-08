# Customer Profile API Matrix

Current database authority: `current_schema.md` (`customers`, `customer_addresses`, `customer_contacts`, and `customer_preferences`). This matrix reflects the live schema, not an assumed migration state.

| Capability | UI route | API | DB / Prisma | Ownership and validation | Classification |
|---|---|---|---|---|---|
| Personal profile read | `/portal/customer/profile` | `GET /customer/profile` | `customers` / `Customer` | JWT customer ID only; safe projection excludes Firebase UID, Aadhaar, referral and agent data | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Personal profile edit | `/portal/customer/profile` | `PATCH /customer/profile` | `customers` / `Customer` | Only names, DOB, gender, email, legacy address fields and blood group; names required, email syntax, DOB cannot be future; phone/status ignored | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Primary phone | `/portal/customer/profile` | profile projection only | `customers.mobile` | Read-only login identity; Firebase re-verification workflow does not exist | DEFERRED — BACKEND CONTRACT REQUIRED |
| Address book | `/portal/customer/account` | `GET/POST/PATCH/DELETE /customer/addresses` | `customer_addresses` / `CustomerAddress` | Principal-derived ownership; line 1 required; multiple/default/soft delete are live-schema features | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Alternative/emergency contacts | `/portal/customer/account` | `GET/POST/PATCH/DELETE /customer/contacts` | `customer_contacts` / `CustomerContact` | Principal-derived ownership; typed contacts; normalized mobile cannot match login mobile | COMPLETE — SUPPORTED FUNCTIONAL SCOPE |
| Profile image/completion | Profile | none | No field / no backend calculation | Do not fabricate image upload or completion percentage | NOT SUPPORTED IN CURRENT CONTRACT |

## Field authority

Names, DOB, gender, primary phone, email, customer status and legacy address fields live on `customers`. The dedicated `customer_addresses` table is the multi-address/default/archive source. Contacts are never login identities. Membership reference is read from the existing customer membership contract; it is not mutable here.
