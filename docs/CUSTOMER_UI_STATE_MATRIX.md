# Customer UI State Matrix

| Area | Loading | Empty | Error | Cached/offline |
|---|---|---|---|---|
| Dashboard | `DashboardShimmer` | Explicit unavailable state | Retry `ErrorCard` | Per-customer dashboard cache |
| Wallet | `WalletShimmer` | Zero ledger values/list empty | Retry `ErrorCard` | Per-customer wallet cache |
| Membership | Membership skeleton | Pending/unissued membership state | Retry `ErrorCard` | Per-customer membership cache |
| Visits | Section skeleton | Upcoming/history-specific empty state | Retry `ErrorCard` | Backend response only |
| Documents | Skeleton or upload indicator | `No documents yet` | Retry state plus safe upload/open/download failure feedback | Backend response only; upload and document actions use authenticated endpoints |
| Prescriptions | Skeleton | `No prescriptions yet` | Retry state plus safe open/download failure feedback | Backend response only; document actions request a signed URL |
| Activity Timeline | Progress indicator | `No activity yet` | Retry `ErrorCard` | Backend response only |
| Alternative contacts | Inline progress indicator | `No alternative contacts added` | Inline retry; client validation and safe save/remove feedback | Backend response only |
| Protected customer sections (appointments, documents, prescriptions) | Profile-access skeleton | Access rules/section empty states | `Access status unavailable` with retry | No shared fallback data |
| Header chips | Compact loading labels | `₹0` / `0` only after API resolves | Refresh icon | Dashboard repository cache |

New screens must define all five states before being marked complete.
