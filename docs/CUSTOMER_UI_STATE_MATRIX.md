# Customer UI State Matrix

| Area | Loading | Empty | Error | Cached/offline |
|---|---|---|---|---|
| Dashboard | `DashboardShimmer` | Explicit unavailable state | Retry `ErrorCard` | Per-customer dashboard cache |
| Wallet | `WalletShimmer` | Zero ledger values/list empty | Retry `ErrorCard` | Per-customer wallet cache |
| Membership | Membership skeleton | Pending/unissued membership state | Retry `ErrorCard` | Per-customer membership cache |
| Visits | Section skeleton | Upcoming/history-specific empty state | Retry `ErrorCard` | Backend response only |
| Documents | Skeleton | `No documents yet` | Retry state | Backend response only |
| Prescriptions | Skeleton | `No prescriptions yet` | Retry state | Backend response only |
| Activity Timeline | Progress indicator | `No activity yet` | Retry `ErrorCard` | Backend response only |
| Alternative contacts | Inline progress indicator | `No alternative contacts added` | Inline retry | Backend response only |
| Protected customer sections (appointments, documents, prescriptions) | Profile-access skeleton | Access rules/section empty states | `Access status unavailable` with retry | No shared fallback data |
| Header chips | Compact loading labels | `₹0` / `0` only after API resolves | Refresh icon | Dashboard repository cache |

New screens must define all five states before being marked complete.
