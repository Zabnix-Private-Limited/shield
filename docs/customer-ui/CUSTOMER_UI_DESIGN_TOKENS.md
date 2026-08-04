# Customer UI design tokens

Source: `frontend/lib/features/customer/shared/theme/customer_design_tokens.dart`.

| Group | Tokens |
|---|---|
| Canvas/surfaces | `pageBackground`, `surface`, `border`, `textPrimary`, `textSecondary` |
| Semantic accents | `cash` teal, `reward` amber, `document` purple, `commerce` orange; primary actions use `AppColors.shieldBlue` |
| Spacing | 4, 8, 12, 16, 20, 24, 32, 40 logical pixels |
| Radius | 14 controls, 20 cards, 24 large cards, 999 pills |
| Motion | 140 ms fast feedback, 240 ms standard transition |
| Type | Existing `AppTypography` through token `pageTitle`, `sectionTitle`, and `caption` |

Rules: customer screens use white/near-neutral surfaces, navy hierarchy, cobalt action colour, semantic ledger colours, and shared card/radius values. No per-screen replacement theme or hardcoded customer data.
