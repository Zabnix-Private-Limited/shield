# OPEN OR CONFIGURATION-DEPENDENT BUSINESS RULES

The agent must verify current configuration/documentation before implementing these. Do not hardcode a speculative answer.

## Membership pricing and entitlement

Examples have used ₹10,000 customer contribution, ₹1,000 SHIELD Benefit and ₹11,000 total entitlement. Treat them as configured plan examples, not permanent source-code constants.

Verify:

- Active plan values
- Allocation basis
- Monthly rounding
- Final-month reconciliation
- Carry-forward policy
- Eligible services/products
- Expiry and renewal behavior

## Reward conversion and expiry

Do not invent:

- Points-to-rupee conversion
- Minimum redemption
- Expiry period
- Catalogue values
- Immediate referral credit

Use configured rules and existing reward/referral services.

## Physical-card lifecycle

Verify supported statuses, fees, address rules, replacement policy and operational actions before enabling mutations.

## Payment gateway

Do not fake successful add-funds, subscription or order payments. Use the current approved gateway/sandbox contract or show an unavailable state.

## Family/dependents

Family linking may be a phased capability. Verify models and customer APIs before creating persistent flows. Do not create independent login identities silently.

## Insurance and future services

Do not add an insurance purchase workflow merely because a label appears in an old design board. Implement only supported customer-facing service information and APIs.

## OCR and document intelligence

Original document storage and metadata are primary. OCR/extraction is optional/deferred unless current backend support is verified.

## Legal, retention and deletion

Do not promise immediate permanent deletion when healthcare, audit, financial or legal retention obligations apply. Use an auditable request workflow.

## Product inventory classification

Wellness product imports may be demo, staging or live. Preserve backend classification and the demo disclosure until management explicitly approves live inventory.

## Customer activation

A separate backend process may activate eligible waiting customer memberships. The UI must render actual backend membership states and must not mass-activate users locally.
