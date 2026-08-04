# Customer UI state matrix

| Feature | Loading | Empty | Failure | Safety rule |
|---|---|---|---|---|
| Dashboard | Dashboard shimmer | Backend-provided no-data state | Retryable error card | Never show cached/shared customer values as current data |
| Membership | Membership skeleton | Membership unavailable | Retryable error card | No invented entitlement values |
| Privilege Card | Membership/profile/card-status progress | No issued digital card | Retryable card-status panel | QR only from server payload |
| Wallet/Rewards | Wallet shimmer | No visible transactions | Retryable wallet error | Failed API is not zero balance; benefit stays hidden |
| Services/providers | Access skeleton and provider progress | No active backend provider | Provider retry panel | Do not substitute a provider or service locally |
| Visits | Access/load states | Upcoming/history empty state | Retryable error card | Mutations remain self-scoped |
| Documents/prescriptions | List/upload progress | Customer archive empty state | Generic retryable error | No storage URL exposure |
| Wellness catalogue | Progress indicator | Catalogue empty state | Retry action | Product data remains API/database-derived |
| Orders/referrals/activity | Screen loading | Per-feature empty state | Retryable error | No shared demo records in authenticated accounts |
| Notifications | Inbox loading | No notifications | Retryable mutation/error message | Do not mark read locally on failed API |
| Settings/support | N/A for unsupported preferences | Explicit unavailable labels | Generic submit failure | Do not present local-only settings as persisted |
