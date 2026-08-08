# Customer Services and Provider Discovery API matrix

Audited: 2026-08-08. `current_schema.md` and customer-reachable routes are authoritative.

| Capability | Customer route | Backend route | Contract | Support |
|---|---|---|---|---|
| Service categories | `/portal/customer/services` | `GET /customer/providers/categories` | Active `service_providers.provider_type`, category count | Supported |
| Provider listing | `/portal/customer/providers` | `GET /customer/providers` | Active provider name, type, linked business; page/pageSize | Supported |
| Provider search | same | `GET /customer/providers?query=` | Case-insensitive public name/type/business search | Supported |
| Provider type filter | `/portal/customer/services?type=` | `GET /customer/providers?type=` | Exact active provider type; route-backed selection | Supported |
| Provider detail | `/portal/customer/services?provider=` | `GET /customer/providers/:id` | Same customer-safe active provider projection; route-backed detail | Supported |
| Doctor/lab/pharmacy/dental/home-care/dietitian/wellness listings | category routes | Same listing with `type` | Depends on active rows in existing `service_providers` | Supported when data exists |
| Wellness product catalogue | `/portal/customer/shop` | `GET /customer/wellness-products` | Existing separate product catalogue | Supported; not provider discovery |
| Booking entry | existing booking section | Existing appointment contract | Existing UI navigation only | Preserved |
| Prescription upload | existing documents/prescriptions | Existing document upload contract | Existing customer upload flow | Preserved |
| Pagination | provider listing | `page`, `pageSize` (max 50) | Stable name/id ordering | Supported |
| Search suggestions/history | none | none | No safe persisted/search-suggestion contract | Not supported |
| Sorting/popular/recommended | none | none | No priority, feature flag, rating, or aggregate signal | Not supported |
| Nearby/location/distance | none | none | No customer/provider coordinates or locality contract | Not supported |
| Covered services | none | none | No customer eligibility/provider coverage response | Not supported |
| Provider availability/hours | summary label only | active provider status | No appointment-slot/hours projection | Partial: active only |
| Ratings/languages/pricing | none | none | No public fields in current provider schema | Not supported |
| Favourite/recently viewed | none | none | No customer-owned persistence model or route | Not supported |
| Insurance/support | support destination | existing support surface | No insurer/provider directory contract | Support-only, no insurance claim |

Customer authentication is required on every new route. Responses intentionally omit provider UUIDs, business codes, internal status, performance, settlement, credentials, staff contacts, and audit metadata. `availabilityLabel` is explicitly directory-active status, not an appointment-slot claim. No Prisma migration is required.
