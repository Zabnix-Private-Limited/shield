# Customer Portal Manual UAT Checklist

All Actual/Pass/Fail/evidence fields are intentionally blank. Do not mark this document passed from source inspection.

| ID | Area / route | Precondition and action | Expected result | Actual | PASS/FAIL | Evidence / notes |
|---|---|---|---|---|---|---|
| CU-001–005 | Launch, phone, OTP, login, dashboard | fresh launch; sign in with test customer | safe loading, OTP/resend/errors, persistent session, dashboard | | | |
| CU-006–011 | Membership lifecycle | no-app apply; pending; staff reject/reapply; approve; activate/card | real reference/status; no fake card; card only after issuance | | | |
| CU-012–013 | Wallet | open wallet/history | ledger values and states match API | | | |
| CU-013A | Wallet recharge | attempt customer recharge/payment initiation, callback and duplicate callback | only release-approved, idempotent payment flow may credit wallet; otherwise record missing capability | | | |
| CU-013B | Preferred pharmacy / store change | view pharmacy, request a change with reason, inspect status | eligible pharmacy, reason, history and status must be customer-visible | | | |
| CU-014–017 | Services/booking handoff | filter, detail, continue to booking | safe factual provider data and clean navigation | | | |
| CU-018–021 | Booking/visits | submit request; view status changes | request is not shown as confirmed; visits retain pending | | | |
| CU-022–024 | Documents/prescriptions | list/upload/preview/request | customer-owned secure data and useful errors | | | |
| CU-025–030 | Orders/referrals/notifications/activity/profile/support | exercise implemented routes | only supported backend states/actions exposed | | | |
| CU-027A | Notification deep links | tap notification valid/invalid targets | safe route mapping or recovery screen; unread/read state stays consistent | | | |
| CU-030A | Support and complaint history | create request; staff reply/escalate/resolve; refresh customer detail | request/reference/status remain customer-owned; customer sees only visible reply/resolution, never internal notes/escalation | | | |
| CU-014A–017A | Provider-specific journeys | Pharmacy, Smart Lab, Clinic/Doctor, Home Care, Dietitian, Dental, Skin Care | each supported provider type is discoverable and correctly hands off to request/booking | | | |
| CU-031–036 | Logout, relogin, refresh, history, expiry, account isolation | switch/expire sessions | safe redirect and no prior customer cache | | | |
| CU-037–038 | Responsive | phone and tablet/web widths | no overflow; usable navigation | | | |
| CU-039–046 | 2026-08-16 remediation | persistent reopen, identity phone, active-membership/no-card wallet wording, card request, public catalogue, pharmacy prescription handoff, requested booking date/time, referral attribution | record deployed evidence; do not infer a pass from source checks | | | |
