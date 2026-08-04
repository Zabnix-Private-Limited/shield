# Customer UI Component Guide

| Component | Responsibility | Data ownership |
|---|---|---|
| `CustomerScaffold` | Customer shell and adaptive navigation | Route/portal metadata |
| `CustomerAppBar` | Responsive main/subpage header | Existing dashboard bundle; retry state |
| `CustomerBottomNavigation` | Five primary customer destinations | GoRouter routes |
| `GreetingHeader` | Membership/privilege summary | Dashboard membership payload |
| `WalletSummaryCard` | Linked dashboard summary item | Parent-supplied API value |
| `ErrorCard`, `EmptyState`, shimmers | Failure/empty/loading presentation | Parent state |

Never put catalogue, customer, wallet, or banner records directly in widget source.
