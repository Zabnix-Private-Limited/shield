# Pharmacy Design Tokens

This file is the implementation token contract. Components should consume tokens instead of scattered hard-coded values.

## Color tokens

```text
pharmacyPrimary              #0B9C78
pharmacyPrimaryHover         #087E63
pharmacyPrimarySoft          #ECF9F5

pharmacyNavy                 #10213F
pharmacyNavyStrong           #091B35
pharmacyText                 #182230
pharmacyTextSecondary        #5F6C80
pharmacyTextTertiary         #7A8699

pharmacyCanvas               #F7F9FC
pharmacySurface              #FFFFFF
pharmacySurfaceSubtle        #FBFCFE
pharmacyBorder               #E4E9F0
pharmacyBorderStrong         #D4DBE5

pharmacySuccess              #12B76A
pharmacySuccessText          #079455
pharmacySuccessBg            #ECFDF3

pharmacyWarning              #F79009
pharmacyWarningText          #B54708
pharmacyWarningBg            #FFFAEB

pharmacyDanger               #F04438
pharmacyDangerText           #B42318
pharmacyDangerBg             #FEF3F2

pharmacyInfo                 #2E90FA
pharmacyInfoText             #175CD3
pharmacyInfoBg               #EFF8FF

pharmacyPurple               #7F56D9
pharmacyPurpleBg             #F4F3FF
```

## Spacing scale

Use an 4/8 based spacing system.

| Token | px |
|---|---:|
| `space.0` | 0 |
| `space.1` | 4 |
| `space.2` | 8 |
| `space.3` | 12 |
| `space.4` | 16 |
| `space.5` | 20 |
| `space.6` | 24 |
| `space.8` | 32 |
| `space.10` | 40 |
| `space.12` | 48 |
| `space.16` | 64 |

Avoid random 13/17/19/27 pixel spacing.

## Sizing tokens

```text
controlHeightSm   32
controlHeightMd   40
controlHeightLg   44
touchTargetMin    44
sidebarWidth      248
topBarHeight      72
mobileTopBar      56
mobileBottomNav   64
desktopContentMax 1440
```

## Radius

```text
radiusField       8
radiusButton      8
radiusCard        12
radiusPanel       16
radiusChip        999
```

## Icon sizes

```text
iconXs   14
iconSm   16
iconMd   20
iconLg   24
iconXl   32
```

## Animation

```text
durationFast      120ms
durationNormal    180ms
durationSlow      240ms

curveStandard     easeOutCubic
curveEmphasized   easeInOutCubic
```

Use animation to explain state, not decorate.

## Z/elevation intent

```text
base      0
sticky    10
dropdown  20
dialog    30
toast     40
```

## Flutter implementation guidance

Recommended central token structure:

```dart
class PharmacyColors { ... }
class PharmacySpacing { ... }
class PharmacyRadius { ... }
class PharmacyTypography { ... }
class PharmacyBreakpoints { ... }
```

Do not duplicate values per feature.

## Token ownership

Shared SHIELD tokens may be reused if visually identical. Pharmacy-specific semantic tokens should remain inside the Pharmacy design layer rather than changing unrelated portals.
