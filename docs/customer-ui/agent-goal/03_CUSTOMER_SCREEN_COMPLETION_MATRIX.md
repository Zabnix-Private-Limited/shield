# CUSTOMER SCREEN COMPLETION MATRIX

This is the minimum completion inventory. Reconcile it against the repository before implementation. Existing route names are authoritative; suggested route/surface values must not create duplicates. A row may be implemented as a page, nested route, dialog, bottom sheet or deliberate state when that best matches the current architecture.

Completion requires all of: route audited, functional, visual, states, responsive, tests and screenshot QA.

## Authentication

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 001 | Splash / Bootstrap | `/splash` | Secure startup, config and session restoration | local config + auth/session |
| 002 | Onboarding — Connected Care | `/onboarding/connected-care` | Explain unified care ecosystem | public app content/config |
| 003 | Onboarding — Membership | `/onboarding/membership` | Explain membership and privilege card | public plan summary |
| 004 | Onboarding — Rewards | `/onboarding/rewards` | Explain rewards without unapproved conversion promises | public reward rules |
| 005 | Welcome / Entry Choice | `/welcome` | Choose login or registration | local navigation |
| 006 | Customer Phone Login | `/customer/login` | Start Firebase phone authentication | Firebase + customer auth repository |
| 007 | OTP Verification | `/customer/otp` | Verify OTP and establish session | Firebase + auth exchange |
| 008 | OTP Resend / Timeout | `same auth surface` | Handle resend countdown and retry | Firebase auth |
| 009 | OTP Error / Rate Limit | `same auth surface` | Explain invalid/expired/rate-limited OTP | Firebase/auth errors |
| 010 | Existing Customer Lookup | `/register/lookup` | Prevent duplicate customer registration | customer lookup API |
| 011 | Existing Customer Found | `/register/existing` | Review and convert/link legacy customer | customer conversion API |
| 012 | Registration — Personal Details | `/register/personal` | Capture customer profile | customer create/update |
| 013 | Registration — Contact and Address | `/register/contact` | Capture alternative contact and address | customer contacts + addresses |
| 014 | Registration — Consent | `/register/consent` | Capture versioned consent | consent/legal API |
| 015 | Registration — Review | `/register/review` | Review before submit | registration draft |
| 016 | Registration Complete | `/register/complete` | Confirm account/membership result | registration response |
| 017 | Membership Pending | `auth/portal gate` | Truthful pending state | membership status |
| 018 | Account Suspended / Archived | `auth/portal gate` | Blocked-account explanation and support action | customer status |
| 019 | Session Expired | `global auth state` | Reauthenticate safely | session/auth |
## Home

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 020 | Customer Dashboard | `/portal/customer/dashboard` | Primary customer home | dashboard aggregate |
| 021 | Operations Banner Details | `/portal/customer/banner/:id` | View eligible campaign/offer details | published banner detail |
| 022 | Offers and Benefits List | `/portal/customer/offers` | Browse eligible customer offers | Operations content API |
| 023 | Global Search Entry | `/portal/customer/search` | Search supported customer content | search APIs where supported |
## Membership & Card

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 024 | Membership Dashboard | `/portal/customer/membership` | Membership and plan overview | membership aggregate |
| 025 | Privilege Card | `/portal/customer/card` | Card and subscription summary | membership/card/subscription |
| 026 | Digital Card | `/portal/customer/card/digital` | Full digital card | membership card API |
| 027 | QR Card | `/portal/customer/card/qr` | Scannable signed identity token | card token API |
| 028 | Membership Benefits | `/portal/customer/membership/benefits` | Eligible benefits and limits | plan benefits API |
| 029 | Subscription Details | `/portal/customer/membership/subscription` | Plan contribution and validity | subscription API |
| 030 | Entitlement Details | `/portal/customer/membership/entitlement` | Total/monthly entitlement | entitlement API |
| 031 | Carry Forward Details | `/portal/customer/membership/carry-forward` | Carry-forward breakdown | entitlement ledger/config |
| 032 | Benefit Usage History | `/portal/customer/membership/usage` | Applied benefit events | benefit application API |
| 033 | Request Physical Card | `/portal/customer/card/request` | Submit supported card request | card request API |
| 034 | Card Request Review | `same request flow` | Review request/address | card request draft |
| 035 | Card Request Confirmation | `same request flow` | Confirm submission | card request response |
| 036 | Card Request Tracking | `/portal/customer/card/tracking` | Track lifecycle | card request/events |
| 037 | Card History | `/portal/customer/card/history` | Issue/activation/replacement events | card events API |
| 038 | Report Lost Card | `/portal/customer/card/lost` | Block/report lost card | card lifecycle API |
| 039 | Report Damaged Card | `/portal/customer/card/damaged` | Request damaged-card handling | card lifecycle API |
| 040 | Replacement Card | `/portal/customer/card/replacement` | Request replacement | card lifecycle API |
| 041 | Membership Renewal Overview | `/portal/customer/membership/renew` | Renewal eligibility and plan | renewal API/config |
| 042 | Membership Renewal Review | `same renewal flow` | Review renewal values | renewal quote |
| 043 | Membership Renewal Payment | `same renewal flow` | Complete approved payment | payment/renewal API |
| 044 | Membership Renewal Success | `same renewal flow` | Confirm renewal | renewal result |
| 045 | Membership Renewal Failure | `same renewal flow` | Recover from payment/renewal failure | renewal error |
| 046 | Expired Membership | `membership state` | Explain expiry and supported actions | membership status |
| 047 | Suspended Membership | `membership state` | Explain suspension and support | membership status |
## Cash Wallet

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 048 | Cash Wallet Dashboard | `/portal/customer/wallet` | Show CASH balance and actions | customer wallet API |
| 049 | Wallet Transaction History | `/portal/customer/wallet/transactions` | Ledger history | wallet ledger API |
| 050 | Wallet Transaction Filters | `same history surface` | Filter credits/debits/refunds/status | wallet ledger API |
| 051 | Wallet Transaction Detail | `/portal/customer/wallet/transactions/:id` | Explain one ledger entry | wallet transaction API |
| 052 | Add Funds — Amount | `/portal/customer/wallet/add-funds` | Enter supported amount | payment/top-up config |
| 053 | Add Funds — Payment Method | `same add-funds flow` | Choose approved method | payment methods API |
| 054 | Add Funds — Review | `same add-funds flow` | Review authoritative amount/fees | top-up quote |
| 055 | Add Funds — Processing | `same add-funds flow` | Prevent duplicate submit | payment transaction |
| 056 | Add Funds — Success | `same add-funds flow` | Confirm credit after backend success | payment/wallet result |
| 057 | Add Funds — Failure | `same add-funds flow` | Recover safely | payment error |
| 058 | Wallet Statement | `/portal/customer/wallet/statements` | Statement periods/download | statement API |
| 059 | Statement Filters | `same statement surface` | Select range/type | statement API |
| 060 | Statement Download/Share | `same statement surface` | Authorized export | report API |
| 061 | Refund Detail | `/portal/customer/wallet/refunds/:id` | Explain refund status | wallet transaction/refund |
| 062 | Reversal Detail | `/portal/customer/wallet/reversals/:id` | Explain reversal | wallet transaction |
| 063 | Pending/Locked Balance | `/portal/customer/wallet/locked` | Explain unavailable amount | wallet holds API |
| 064 | Wallet Rules | `/portal/customer/wallet/rules` | Explain supported usage | wallet config/content |
## Reward Points

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 065 | Reward Points Dashboard | `/portal/customer/rewards` | Available points and summary | REWARD_POINTS ledger |
| 066 | Reward History | `/portal/customer/rewards/history` | Reward ledger events | reward ledger API |
| 067 | Reward Transaction Detail | `/portal/customer/rewards/history/:id` | Explain one points event | reward transaction API |
| 068 | Pending Points | `/portal/customer/rewards/pending` | Pending qualification events | reward/referral API |
| 069 | Earned Points | `/portal/customer/rewards/earned` | Qualified credits | reward ledger API |
| 070 | Redeemed Points | `/portal/customer/rewards/redeemed` | Redemption history | reward ledger API |
| 071 | Expiring Points | `/portal/customer/rewards/expiring` | Expiry only when supported | reward rule API |
| 072 | How to Earn | `/portal/customer/rewards/earn` | Approved earning rules | reward rules |
| 073 | Reward Rules | `/portal/customer/rewards/rules` | Eligibility and limitations | reward rules |
| 074 | Redemption Catalogue | `/portal/customer/rewards/redeem` | Supported redemption choices | redemption config/API |
| 075 | Redemption Detail | `/portal/customer/rewards/redeem/:id` | Review selected redemption | redemption API |
| 076 | Redemption Review | `same redemption flow` | Confirm points/cost | redemption quote |
| 077 | Redemption Success | `same redemption flow` | Confirm persisted event | redemption result |
| 078 | Redemption Failure | `same redemption flow` | Recover safely | redemption error |
## Services & Providers

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 079 | Services Landing | `/portal/customer/services` | Browse service families | service catalogue API |
| 080 | Service Search | `/portal/customer/services/search` | Search services/providers | service/provider search |
| 081 | Service Search Results | `same search flow` | Display categorized results | search API |
| 082 | Service Categories | `/portal/customer/services/categories` | Browse categories | master data/API |
| 083 | Service Category Detail | `/portal/customer/services/categories/:id` | Category services/providers | service API |
| 084 | Service Filters and Sort | `same listing surface` | Filter location/type/availability | provider API |
| 085 | Provider Listing | `/portal/customer/providers` | List eligible providers | provider API |
| 086 | Provider Detail | `/portal/customer/providers/:id` | Provider branch/services/contact | provider profile API |
| 087 | Doctor Listing | `/portal/customer/doctors` | List doctors | provider/practitioner API |
| 088 | Doctor Profile | `/portal/customer/doctors/:id` | Doctor details and availability | practitioner API |
| 089 | Lab Listing | `/portal/customer/labs` | List labs | provider API |
| 090 | Lab Detail | `/portal/customer/labs/:id` | Lab services and availability | provider/service API |
| 091 | Pharmacy Listing | `/portal/customer/pharmacies` | List pharmacies | provider API |
| 092 | Pharmacy Detail | `/portal/customer/pharmacies/:id` | Pharmacy services and preferred action | provider API |
| 093 | Dental Providers | `/portal/customer/dental` | Dental discovery | provider API |
| 094 | Home Care | `/portal/customer/home-care` | Home-care services | service/provider API |
| 095 | Dietitian | `/portal/customer/dietitian` | Dietitian services | service/provider API |
| 096 | Cosmetic/Wellness Services | `/portal/customer/wellness-services` | Supported wellness services | service/provider API |
| 097 | Nearby Services | `/portal/customer/services/nearby` | Location-aware list where supported | provider/location API |
| 098 | Favourite Providers | `/portal/customer/providers/favourites` | Saved providers where supported | favourites API |
## Booking & Visits

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 099 | Book Visit Start | `/portal/customer/book` | Start booking | service/provider APIs |
| 100 | Select Service | `same booking flow` | Choose service | service API |
| 101 | Select Provider | `same booking flow` | Choose provider/branch | provider API |
| 102 | Select Practitioner | `same booking flow` | Choose doctor/practitioner | practitioner API |
| 103 | Select Patient | `same booking flow` | Choose self/family where supported | customer/family API |
| 104 | Select Visit Type | `same booking flow` | In-person/online/home where supported | service config |
| 105 | Select Date | `same booking flow` | Choose date | availability API |
| 106 | Select Time Slot | `same booking flow` | Choose live slot | slot API |
| 107 | Booking Notes | `same booking flow` | Capture allowed notes | appointment DTO |
| 108 | Pricing and Coverage | `same booking flow` | Display backend quote/benefit | pricing evaluate API |
| 109 | Booking Review | `same booking flow` | Review details | booking draft/quote |
| 110 | Booking Confirmation | `same booking flow` | Confirm mutation | appointment API |
| 111 | Booking Success | `same booking flow` | Show persisted appointment | appointment result |
| 112 | Booking Failure | `same booking flow` | Retry without duplicates | appointment error |
| 113 | My Visits | `/portal/customer/visits` | Upcoming/completed/cancelled | appointment API |
| 114 | Visit Filters | `same visits surface` | Filter status/type/date | appointment API |
| 115 | Visit Detail | `/portal/customer/visits/:id` | Full appointment information | appointment API |
| 116 | Reschedule Visit | `/portal/customer/visits/:id/reschedule` | Select new slot | appointment API |
| 117 | Cancel Visit | `/portal/customer/visits/:id/cancel` | Confirm cancellation | appointment API |
| 118 | Cancellation Result | `same cancel flow` | Show status/refund effect | appointment result |
| 119 | Online Consultation Detail | `/portal/customer/visits/:id/online` | Join/instructions where supported | consultation API |
| 120 | No Available Slots | `booking state` | Truthful no-slot recovery | availability API |
## Documents & Prescriptions

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 121 | Documents Landing | `/portal/customer/documents` | Document overview/categories | documents API |
| 122 | Document Categories | `/portal/customer/documents/categories` | Browse supported types | document metadata |
| 123 | Document List | `/portal/customer/documents/list` | List owned documents | documents API |
| 124 | Document Detail | `/portal/customer/documents/:id` | Metadata/actions | document API |
| 125 | Secure Document Viewer | `/portal/customer/documents/:id/view` | Authorized view | signed access API |
| 126 | Upload Document | `/portal/customer/documents/upload` | Upload with metadata | document upload API |
| 127 | Document Upload Progress | `same upload flow` | Progress/cancel/retry | upload API |
| 128 | Document Share | `/portal/customer/documents/:id/share` | Authorized sharing where supported | document access API |
| 129 | Document Download | `same document surface` | Authorized download | signed access API |
| 130 | Lab Reports | `/portal/customer/documents/lab-reports` | Lab report list | documents/lab API |
| 131 | Lab Result Detail | `/portal/customer/documents/lab-reports/:id` | View result safely | lab report API |
| 132 | Medical Records | `/portal/customer/documents/medical-records` | Medical record grouping | documents API |
| 133 | Vaccination Records | `/portal/customer/documents/vaccinations` | Vaccination records where supported | documents API |
| 134 | Prescriptions List | `/portal/customer/prescriptions` | Owned prescriptions | documents/prescription API |
| 135 | Upload Prescription | `/portal/customer/prescriptions/upload` | Upload prescription | document upload API |
| 136 | Prescription Detail | `/portal/customer/prescriptions/:id` | Metadata/status/actions | prescription API |
| 137 | Prescription Viewer | `/portal/customer/prescriptions/:id/view` | Secure view | signed access API |
| 138 | Prescription Processing | `prescription state` | Show processing without invented OCR | document status |
| 139 | Prescription Verified | `prescription state` | Show verified status | document status |
| 140 | Prescription Rejected | `prescription state` | Explain rejection/reupload | document status |
| 141 | Prescription to Pharmacy | `/portal/customer/prescriptions/:id/pharmacy` | Send/link where supported | pharmacy request API |
## Wellness Shop & Orders

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 142 | Wellness Shop Landing | `/portal/customer/shop` | Catalogue landing | wellness products API |
| 143 | Product Search | `/portal/customer/shop/search` | Search catalogue | product search API |
| 144 | Search Suggestions | `same search surface` | Suggestions/recent searches | search API/local history |
| 145 | Product Categories | `/portal/customer/shop/categories` | Browse categories | product categories API |
| 146 | Product Listing | `/portal/customer/shop/products` | List database products | products API |
| 147 | Product Filters | `same listing surface` | Category/brand/price/availability | products API |
| 148 | Product Sort | `same listing surface` | Sort supported fields | products API |
| 149 | Product Detail | `/portal/customer/shop/products/:id` | Product information/price/stock | product API |
| 150 | Product Image Gallery | `same detail surface` | View product images | product media API |
| 151 | Wishlist | `/portal/customer/shop/wishlist` | Saved products where supported | wishlist API |
| 152 | Cart | `/portal/customer/shop/cart` | Current customer cart | cart API |
| 153 | Cart Item Edit | `same cart surface` | Quantity/remove | cart API |
| 154 | Apply Coupon | `same cart/checkout flow` | Validate approved coupon | promotion API |
| 155 | Address Selection | `/portal/customer/shop/checkout/address` | Choose delivery address | address API |
| 156 | Add Delivery Address | `same checkout flow` | Create address | address API |
| 157 | Edit Delivery Address | `same checkout flow` | Update address | address API |
| 158 | Checkout | `/portal/customer/shop/checkout` | Checkout summary | checkout quote API |
| 159 | Payment Selection | `same checkout flow` | Select supported method | payment config |
| 160 | Wallet Payment Review | `same checkout flow` | Confirm wallet charge | checkout/payment API |
| 161 | Order Review | `same checkout flow` | Server-authoritative totals | checkout quote |
| 162 | Place Order Processing | `same checkout flow` | Idempotent creation | orders API |
| 163 | Order Success | `same checkout flow` | Show persisted order | orders API |
| 164 | Order Failure | `same checkout flow` | Recover safely | orders error |
| 165 | My Orders | `/portal/customer/orders` | List owned orders | orders API |
| 166 | Order Filters | `same orders surface` | Filter statuses/date | orders API |
| 167 | Order Detail | `/portal/customer/orders/:id` | Items/totals/status/address | order API |
| 168 | Order Tracking | `/portal/customer/orders/:id/tracking` | Status timeline | order events API |
| 169 | Cancel Order | `/portal/customer/orders/:id/cancel` | Cancel when eligible | orders API |
| 170 | Return Request | `/portal/customer/orders/:id/return` | Return where supported | return API |
| 171 | Refund Status | `/portal/customer/orders/:id/refund` | Refund lifecycle | refund/payment API |
| 172 | Reorder | `/portal/customer/orders/:id/reorder` | Create cart from prior order | cart/orders API |
## Referrals

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 173 | Referral Dashboard | `/portal/customer/referrals` | Summary and code | referral summary API |
| 174 | Referral Code | `same referral surface` | Display unique code | referral API |
| 175 | Referral QR | `/portal/customer/referrals/qr` | Shareable QR | referral API |
| 176 | Share Referral | `same referral surface` | Native/web share | referral link API |
| 177 | Referral History | `/portal/customer/referrals/history` | Owned referrals | referral API |
| 178 | Referral Detail | `/portal/customer/referrals/:id` | Privacy-safe status | referral API |
| 179 | Pending Referrals | `/portal/customer/referrals/pending` | Awaiting qualification | referral API |
| 180 | Qualified Referrals | `/portal/customer/referrals/qualified` | Qualified status | referral API |
| 181 | Rewarded Referrals | `/portal/customer/referrals/rewarded` | Rewarded status | referral/reward API |
| 182 | Rejected Referrals | `/portal/customer/referrals/rejected` | Rejected status/reason | referral API |
| 183 | Referral Rewards | `/portal/customer/referrals/rewards` | Reward events | reward ledger API |
| 184 | Referral Rules | `/portal/customer/referrals/rules` | Qualification rules | referral config/content |
## Activity & Notifications

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 185 | Activity Timeline | `/portal/customer/activity` | Customer event history | timeline API |
| 186 | Activity Detail | `/portal/customer/activity/:id` | Event detail | timeline API |
| 187 | Activity Filters | `same activity surface` | Filter event types/date | timeline API |
| 188 | Notifications Inbox | `/portal/customer/notifications` | Live inbox | notifications API |
| 189 | Notification Filters | `same notification surface` | Filter type/read state | notifications API |
| 190 | Notification Detail | `/portal/customer/notifications/:id` | Read detail/action | notifications API |
| 191 | Mark All Read | `same notification surface` | Persist read state | notifications API |
| 192 | Notification Preferences | `/portal/customer/settings/notifications` | Channel/type preferences | preference API |
| 193 | Service Notifications | `notification filter/state` | Service events | notifications API |
| 194 | Order Notifications | `notification filter/state` | Order events | notifications API |
| 195 | Reward Notifications | `notification filter/state` | Reward events | notifications API |
| 196 | Membership/Card Notifications | `notification filter/state` | Membership/card events | notifications API |
## Profile & Family

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 197 | Profile | `/portal/customer/profile` | Customer account overview | profile/session API |
| 198 | Edit Profile | `/portal/customer/profile/edit` | Update allowed fields | customer API |
| 199 | Personal Details | `/portal/customer/profile/personal` | View demographic fields | customer API |
| 200 | Alternative Contact | `/portal/customer/profile/contact` | Manage non-login contact | customer contacts API |
| 201 | Profile Photo | `/portal/customer/profile/photo` | Upload/remove photo where supported | profile media API |
| 202 | Address Book | `/portal/customer/profile/addresses` | Owned addresses | address API |
| 203 | Address Detail | `/portal/customer/profile/addresses/:id` | View address | address API |
| 204 | Add Address | `/portal/customer/profile/addresses/add` | Create address | address API |
| 205 | Edit Address | `/portal/customer/profile/addresses/:id/edit` | Update address | address API |
| 206 | Family Members | `/portal/customer/family` | Owned family/dependents | family API |
| 207 | Family Member Detail | `/portal/customer/family/:id` | View dependent | family API |
| 208 | Add Family Member | `/portal/customer/family/add` | Create dependent where supported | family API |
| 209 | Edit Family Member | `/portal/customer/family/:id/edit` | Update dependent | family API |
| 210 | Remove Family Member Confirmation | `same family flow` | Safe removal/unlink | family API |
| 211 | Emergency Contacts | `/portal/customer/profile/emergency-contacts` | Emergency contacts | contacts API |
| 212 | Add Emergency Contact | `same contact flow` | Create emergency contact | contacts API |
| 213 | Edit Emergency Contact | `same contact flow` | Update emergency contact | contacts API |
| 214 | Preferred Pharmacy | `/portal/customer/profile/preferred-pharmacy` | Current preferred provider | customer/provider API |
| 215 | Select Preferred Pharmacy | `same preferred pharmacy flow` | Choose eligible pharmacy | provider API |
| 216 | Linked Accounts | `/portal/customer/profile/linked-accounts` | Linked identities where supported | auth/account API |
| 217 | Account Information | `/portal/customer/profile/account` | Membership/customer identifiers | profile API |
## Settings, Privacy & Support

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 218 | Settings | `/portal/customer/settings` | Settings landing | preferences API/local settings |
| 219 | Appearance | `/portal/customer/settings/appearance` | Theme preference where supported | local preference |
| 220 | Language | `/portal/customer/settings/language` | Language preference where supported | preference/content |
| 221 | Notification Settings | `/portal/customer/settings/notifications` | Channel/type preferences | notifications API |
| 222 | Biometric Settings | `/portal/customer/settings/biometrics` | Local biometric unlock where supported | device secure storage |
| 223 | Security | `/portal/customer/settings/security` | Security overview | session/auth API |
| 224 | Change Primary Mobile | `/portal/customer/settings/security/mobile` | Verified mobile-change workflow | auth/customer API |
| 225 | Verify New Mobile | `same mobile flow` | Firebase verification | Firebase/auth API |
| 226 | Active Sessions | `/portal/customer/settings/security/sessions` | View/revoke sessions | session API |
| 227 | Privacy & Security | `/portal/customer/privacy` | Privacy/security hub | legal/config/session APIs |
| 228 | Privacy Policy | `/portal/customer/privacy/policy` | Versioned policy | legal content API |
| 229 | Terms and Conditions | `/portal/customer/privacy/terms` | Versioned terms | legal content API |
| 230 | Consent Management | `/portal/customer/privacy/consents` | View/manage consents | consent API |
| 231 | Data Usage | `/portal/customer/privacy/data-usage` | Explain data use | legal content |
| 232 | Download My Data | `/portal/customer/privacy/export` | Request export where supported | data export API |
| 233 | Delete Account | `/portal/customer/settings/delete-account` | Auditable deletion request | account deletion API |
| 234 | Delete Account Confirmation | `same delete flow` | Deliberate confirmation | account deletion API |
| 235 | Help & Support | `/portal/customer/support` | Support landing | support content/API |
| 236 | Help Search | `/portal/customer/support/search` | Search help content | support/FAQ API |
| 237 | FAQ | `/portal/customer/support/faq` | FAQ list | support content API |
| 238 | FAQ Detail | `/portal/customer/support/faq/:id` | FAQ article | support content API |
| 239 | Contact Support | `/portal/customer/support/contact` | Support channels | support config |
| 240 | Create Support Ticket | `/portal/customer/support/tickets/new` | Create ticket | support API |
| 241 | Support Ticket Detail | `/portal/customer/support/tickets/:id` | Ticket history/replies | support API |
| 242 | Support History | `/portal/customer/support/tickets` | Owned tickets | support API |
| 243 | Feedback | `/portal/customer/support/feedback` | Submit feedback | feedback API |
| 244 | Rate App | `/portal/customer/support/rate` | Platform rating action | platform deep link/config |
| 245 | About SHIELD | `/portal/customer/about` | Product information | app content/config |
| 246 | App Version | `same about/settings surface` | Display build/version | local package info |
| 247 | Logout Confirmation | `global account action` | Confirm logout and clear scope | auth/session |
## Global States

| ID | Screen or state | Target route/surface | Purpose | Data/API |
|---:|---|---|---|---|
| 248 | Global Loading Skeleton | `shared state` | Reusable loading treatment | n/a |
| 249 | Global Empty State | `shared state` | Reusable legitimate-empty treatment | n/a |
| 250 | Global Recoverable Error | `shared state` | Retryable error | n/a |
| 251 | Offline / No Internet | `global state` | Explain cached/offline behavior | connectivity/cache |
| 252 | Maintenance | `global state` | Planned maintenance | platform config |
| 253 | Service Unavailable | `global state` | Backend unavailable | API errors |
| 254 | Feature Unavailable | `shared state` | Unsupported/disabled capability | capabilities/config |
| 255 | Permission Denied | `global state` | Authorization failure | API 403 |
| 256 | Session Expired | `global state` | Reauthenticate | API 401/session |
| 257 | Update Required | `global state` | Minimum-version enforcement where supported | app config |
| 258 | Not Found | `global state` | Unknown route/resource | router/API 404 |
| 259 | Account Suspended | `global state` | Restricted customer | customer status |

**Total inventory rows: 259**

The agent must add any customer-facing route discovered in the repository that is not listed here.
