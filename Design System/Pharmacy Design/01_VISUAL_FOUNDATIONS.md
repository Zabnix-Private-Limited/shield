# Visual Foundations

## 1. Brand direction

The reference system uses a restrained healthcare-tech visual language:

- Dominant white surfaces
- Very light gray/blue page canvas
- Teal/emerald brand accent
- Dark navy headings and high-emphasis controls
- Soft blue, mint, amber, purple status accents
- Thin neutral borders
- Low-elevation shadows
- Rounded but not overly playful geometry

The interface should not feel like a consumer shopping app. It is an **operations workspace**.

## 2. Canonical color palette

The exact original design-tool metadata is not embedded in the reference images, so the values below are the **implementation-standard canonicalization** of the approved visual direction.

### Brand / primary

| Token | Hex | Usage |
|---|---:|---|
| `primary.50` | `#ECF9F5` | selected nav background, subtle success surface |
| `primary.100` | `#D9F3EB` | badges, light highlights |
| `primary.200` | `#B8E8D9` | borders/highlight rings |
| `primary.400` | `#2BBF98` | secondary accent |
| `primary.500` | `#12A77E` | active/positive action |
| `primary.600` | `#0B9C78` | canonical SHIELD Pharmacy teal |
| `primary.700` | `#087E63` | hover/pressed teal |
| `primary.800` | `#06604D` | dark teal text/icon |
| `primary.900` | `#06483B` | deep teal |

### Navy / text

| Token | Hex | Usage |
|---|---:|---|
| `navy.950` | `#091B35` | strongest headings / dark CTA |
| `navy.900` | `#10213F` | primary text |
| `navy.800` | `#1C3155` | secondary strong text |
| `navy.700` | `#334766` | muted headings / icons |
| `navy.600` | `#52627A` | secondary labels |

### Neutral

| Token | Hex | Usage |
|---|---:|---|
| `neutral.0` | `#FFFFFF` | primary surface |
| `neutral.25` | `#FBFCFE` | elevated section background |
| `neutral.50` | `#F7F9FC` | application canvas |
| `neutral.100` | `#F1F4F8` | subtle fill |
| `neutral.200` | `#E4E9F0` | default border |
| `neutral.300` | `#D4DBE5` | stronger border |
| `neutral.400` | `#A8B2C1` | placeholder/icon |
| `neutral.500` | `#7A8699` | tertiary text |
| `neutral.600` | `#5F6C80` | secondary text |
| `neutral.700` | `#445166` | body dark |
| `neutral.900` | `#182230` | near-black text |

## 3. Semantic colors

### Success / ready / approved

- Foreground: `#079455`
- Strong: `#12B76A`
- Background: `#ECFDF3`
- Border: `#ABEFC6`

Use for:
- Approved
- In Stock
- Ready
- Paid
- Active
- Verified

### Warning / low stock / partial

- Foreground: `#B54708`
- Strong: `#F79009`
- Background: `#FFFAEB`
- Border: `#FEDF89`

Use for:
- Low Stock
- Partial Approval
- Pending
- Attention banner
- Customer confirmation required

### Danger / rejected / out of stock

- Foreground: `#B42318`
- Strong: `#F04438`
- Background: `#FEF3F2`
- Border: `#FECDCA`

Use for:
- Rejected
- Out of Stock
- Cancelled
- destructive button
- blocking errors

### Info / new / system

- Foreground: `#175CD3`
- Strong: `#2E90FA`
- Background: `#EFF8FF`
- Border: `#B2DDFF`

### Purple / delivery or alternate informational category

- Foreground: `#6941C6`
- Strong: `#7F56D9`
- Background: `#F4F3FF`
- Border: `#D9D6FE`

## 4. Color-use rules

- Never use semantic colors decoratively.
- Green does not mean "generic primary" when it risks being confused with Approved/Success.
- Use navy for high-confidence primary CTA where a green CTA would be confused with success.
- Use teal/green for Pharmacy branding, active navigation, and positive action.
- Use red only for destructive/rejection/error actions.
- Status foreground/background pairs must meet accessible contrast.
- Avoid colored full-page backgrounds.

## 5. Surfaces

Recommended hierarchy:

1. App canvas — `neutral.50`
2. Main panel — white
3. Card — white with border
4. Selected interactive card — `primary.50` or white + primary border
5. Subtle group surface — `neutral.25`
6. Warning group surface — warning background
7. Error group surface — danger background

## 6. Borders

Default:
```text
1px #E4E9F0
```

Selected:
```text
1px #0B9C78
```

Focus:
```text
2px #2E90FA + 2px outer soft ring
```

Do not create heavy gray outlines around every container.

## 7. Shadows

Use sparingly.

### Card shadow
```text
0 1px 2px rgba(16, 33, 63, 0.04)
0 4px 12px rgba(16, 33, 63, 0.04)
```

### Floating / sticky action shadow
```text
0 -4px 20px rgba(16, 33, 63, 0.08)
```

### Dialog / menu
```text
0 12px 32px rgba(16, 33, 63, 0.14)
```

## 8. Radius

| Token | Value |
|---|---:|
| `radius.xs` | 4 |
| `radius.sm` | 6 |
| `radius.md` | 8 |
| `radius.lg` | 12 |
| `radius.xl` | 16 |
| `radius.2xl` | 20 |
| `radius.pill` | 999 |

Canonical:
- Buttons / fields: 8
- List cards: 10–12
- Main cards: 12
- Major panels: 16
- Status chips: pill
