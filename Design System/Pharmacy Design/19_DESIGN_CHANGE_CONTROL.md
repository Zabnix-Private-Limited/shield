# Pharmacy Design Change Control

## Why this exists

The Pharmacy visual system must not drift as different agents or developers work on different modules.

## A change is "system-level" if it modifies

- brand primary color
- base typeface
- spacing scale
- standard card radius
- button hierarchy
- status color semantics
- desktop sidebar model
- mobile bottom navigation model
- canonical Pharmacy route family
- shared order-item presentation
- common form control dimensions

System-level changes require updating this design package before broad implementation.

## Screen-level flexibility

Allowed without system revision:
- card count based on real data
- minor layout wrapping
- adding a field required by business logic
- changing copy for correctness
- rearranging controls at compact widths
- accessibility-driven adjustments

## Reference consistency review

Before merging a major Pharmacy UI change:

1. Compare Dashboard
2. Compare Orders
3. Compare Payments
4. Compare Profile
5. Compare Settings
6. Compare compact/mobile state

Ask:
> Does this still look like the same SHIELD Pharmacy product?

If the answer is uncertain, resolve the system before adding more pages.
