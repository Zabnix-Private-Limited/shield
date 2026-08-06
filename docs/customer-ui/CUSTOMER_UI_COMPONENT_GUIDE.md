# Customer UI component guide

| Component | Source | Use |
|---|---|---|
| Customer shell | `customer_scaffold.dart` | Authenticated app frame, drawer, header and five-item bottom navigation |
| Main/subpage header | `customer_app_bar.dart` | Main balances/notifications or compact back/title header |
| Bottom navigation | `bottom_navigation.dart` | Home, Wallet, Services, Visits, Profile only |
| Services discovery | `CustomerServicesScreen` | Search, category chips, provider cards, error/empty states, and booking/support entry points |
| Page frame | `app_page_frame.dart` | Centered responsive content width and shared padding |
| Error state | `error_card.dart` | Generic customer-safe error plus optional retry |
| Loading state | `loading_card.dart` and feature shimmers | Loading without fabricated values |
| Surface | `app_card.dart` / `glass_card.dart` | Bordered rounded content cards |
| Actions | `primary_button.dart`, `app_button.dart` | Primary and secondary customer actions |

Keep business semantics in backend contracts. Reuse these presentation primitives instead of duplicating cards, navigations, balance chips, or error UI.
